// lib/features/wishlist/application/providers/wishlist_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../../home/domain/entities/product_variant.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/data_sources/wishlist_api.dart';
import '../../infrastructure/data_sources/wishlist_local_ds.dart';
import '../../infrastructure/repositories/wishlist_repository_impl.dart';
import '../states/wishlist_state.dart';

// ----------------------------------------------------------------------
// Infrastructure providers wired at the application layer (C10/C12)
// ----------------------------------------------------------------------

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final remoteDs = ref.watch(wishlistRemoteDataSourceProvider);
  final localDs = ref.watch(wishlistLocalDataSourceProvider);
  return WishlistRepositoryImpl(
    remoteDataSource: remoteDs,
    localDataSource: localDs,
  );
});

// ----------------------------------------------------------------------
// WishlistNotifier — migrated from StateNotifier to Notifier (C1/H1)
// ----------------------------------------------------------------------

class WishlistNotifier extends Notifier<WishlistState> {
  WishlistRepository get _repository => ref.read(wishlistRepositoryProvider);

  @override
  WishlistState build() {
    // Listen to auth state changes with lifecycle-managed listener (C1)
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is Authenticated && previous is! Authenticated) {
        _loadWishlist();
      } else if (next is GuestMode && previous is Authenticated) {
        _clearAndReset();
      }
    });

    // Initial load if user is already authenticated
    final currentAuthState = ref.read(authProvider);
    if (currentAuthState is Authenticated) {
      Future.microtask(_loadWishlist);
    }

    return const WishlistState.initial();
  }

  Future<void> _loadWishlist() async {
    state.maybeMap(
      refreshing: (_) {},
      orElse: () => state = const WishlistState.loading(),
    );

    final result = await _repository.getWishlist();

    result.fold(
      (failure) {
        state = WishlistState.error(
          failure: failure,
          previousState: state,
        );
      },
      (items) {
        state = WishlistState.loaded(items: items);
      },
    );
  }

  Future<void> _clearAndReset() async {
    await _repository.clearCache();
    state = const WishlistState.initial();
  }

  // Fixed: properly awaits _loadWishlist (C2)
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is WishlistLoaded) {
      state = WishlistState.refreshing(items: currentState.items);
    } else if (currentState is! WishlistError) {
      return;
    }
    await _loadWishlist();
  }

  Future<void> clearCacheAndRefresh() async {
    await _repository.clearCache();
    await refresh();
  }

  Future<bool> addToWishlist(String productId) async {
    if (isInWishlist(productId)) return false;

    final previousState = state;
    state.mapOrNull(
      loaded: (loadedState) {
        state = WishlistState.loaded(
          items: [
            ...loadedState.items,
            WishlistItem(
              id: -1,
              productId: productId,
              name: '',
              price: 0.0,
              mrp: 0.0,
              imageUrl: '',
              unitLabel: '',
              discountPct: 0,
              addedAt: DateTime.now(),
            ),
          ],
        );
      },
    );

    final result = await _repository.addToWishlist(productId);

    return result.fold(
      (failure) {
        state = WishlistState.error(
          failure: failure,
          previousState: previousState,
        );
        return false;
      },
      (_) {
        _loadWishlist();
        return true;
      },
    );
  }

  Future<bool> removeFromWishlist(String wishlistItemId) async {
    final result = await _repository.removeFromWishlist(wishlistItemId);

    return result.fold(
      (failure) {
        state.mapOrNull(
          loaded: (loadedState) {
            state = WishlistState.error(
              failure: failure,
              previousState: loadedState,
            );
          },
        );
        return false;
      },
      (_) {
        _loadWishlist();
        return true;
      },
    );
  }

  Future<bool> removeFromWishlistByProductId(String productId) async {
    final previousState = state;
    state.mapOrNull(
      loaded: (loadedState) {
        state = WishlistState.loaded(
          items: loadedState.items
              .where((item) => item.productId != productId)
              .toList(),
        );
      },
    );

    final result = await _repository.removeFromWishlistByProductId(productId);

    return result.fold(
      (failure) {
        state = WishlistState.error(
          failure: failure,
          previousState: previousState,
        );
        return false;
      },
      (_) {
        _loadWishlist();
        return true;
      },
    );
  }

  Future<bool> toggleWishlist(String productId) async {
    if (isInWishlist(productId)) {
      return removeFromWishlistByProductId(productId);
    } else {
      return addToWishlist(productId);
    }
  }

  bool isInWishlist(String productId) {
    return state.isInWishlist(productId);
  }

  void clearError() {
    state.mapOrNull(
      error: (errorState) {
        if (errorState.previousState != null) {
          state = errorState.previousState!;
        } else {
          state = const WishlistState.initial();
        }
      },
    );
  }
}

// ----------------------------------------------------------------------
// Main provider
// ----------------------------------------------------------------------

final wishlistProvider =
    NotifierProvider<WishlistNotifier, WishlistState>(WishlistNotifier.new);

// ----------------------------------------------------------------------
// Derived selectors
// ----------------------------------------------------------------------

/// Cached list of wishlist items — avoids full widget rebuild on unrelated state changes.
final wishlistItemsProvider = Provider.autoDispose<List<WishlistItem>>((ref) {
  return ref.watch(wishlistProvider).items;
});

/// Pre-computed ProductVariant list for the wishlist screen (M3 — moved out of build()).
final wishlistProductsProvider =
    Provider.autoDispose<List<ProductVariant>>((ref) {
      return ref.watch(wishlistItemsProvider)
          .map((item) => item.toProductVariant())
          .toList();
    });

/// Whether a specific product is in the wishlist.
final isInWishlistProvider = Provider.autoDispose.family<bool, String>((
  ref,
  productId,
) {
  return ref.watch(wishlistProvider).isInWishlist(productId);
});

/// Count of items in the wishlist.
final wishlistCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(wishlistProvider).itemCount;
});
