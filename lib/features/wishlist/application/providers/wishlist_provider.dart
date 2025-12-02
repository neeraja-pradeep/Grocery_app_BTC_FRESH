// lib/features/wishlist/application/providers/wishlist_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../infrastructure/repositories/wishlist_repository_impl.dart';
import '../states/wishlist_state.dart';

// ----------------------------------------------------------------------
// 1. Wishlist Notifier (Manages the entire Wishlist State)
// ----------------------------------------------------------------------

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistRepository _repository;

  WishlistNotifier({required WishlistRepository repository})
    : _repository = repository,
      super(const WishlistState.initial()) {
    // Load wishlist data on app start
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    // Only set loading if we are in initial or error state
    state.maybeMap(
      refreshing: (_) {}, // Don't overwrite refreshing state with loading
      orElse: () => state = const WishlistState.loading(),
    );

    final result = await _repository.getWishlist();

    result.fold(
      (failure) {
        state = WishlistState.error(
          failure: failure,
          previousState: state, // Keep old data visible if available
        );
      },
      (items) {
        state = WishlistState.loaded(items: items);
      },
    );
  }

  Future<void> refresh() async {
    // Only refresh if we have data loaded
    state.mapOrNull(
      loaded: (loadedState) {
        state = WishlistState.refreshing(items: loadedState.items);
        _loadWishlist();
      },
      error: (_) => _loadWishlist(), // Retry on error
    );
  }

  Future<void> clearCacheAndRefresh() async {
    // Clear cache first
    await _repository.clearCache();

    // Then refresh data
    await refresh();
  }

  Future<bool> addToWishlist(String productId) async {
    // Check if item is already in wishlist to prevent duplicates
    if (isInWishlist(productId)) {
      return false; // Already in wishlist
    }

    final result = await _repository.addToWishlist(productId);

    return result.fold(
      (failure) {
        // Update state to show error but don't change the items
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
      (item) {
        // Reload the wishlist to get updated data
        _loadWishlist();
        return true;
      },
    );
  }

  Future<bool> removeFromWishlist(String wishlistItemId) async {
    final result = await _repository.removeFromWishlist(wishlistItemId);

    return result.fold(
      (failure) {
        // Update state to show error but don't change the items
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
        // Reload the wishlist to get updated data
        _loadWishlist();
        return true;
      },
    );
  }

  Future<bool> removeFromWishlistByProductId(String productId) async {
    final result = await _repository.removeFromWishlistByProductId(productId);

    return result.fold(
      (failure) {
        // Update state to show error but don't change the items
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
        // Reload the wishlist to get updated data
        _loadWishlist();
        return true;
      },
    );
  }

  Future<bool> toggleWishlist(String productId) async {
    if (isInWishlist(productId)) {
      return await removeFromWishlistByProductId(productId);
    } else {
      return await addToWishlist(productId);
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
// 2. Providers Definition
// ----------------------------------------------------------------------

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) {
    final repository = ref.watch(wishlistRepositoryProvider);
    return WishlistNotifier(repository: repository);
  },
);

// ----------------------------------------------------------------------
// 3. Selectors (Helpers for UI optimization)
// ----------------------------------------------------------------------

// Watch only wishlist items to avoid rebuilding entire screens
final wishlistItemsProvider = Provider.autoDispose<List<WishlistItem>>((ref) {
  final wishlistState = ref.watch(wishlistProvider);
  return wishlistState.items;
});

// Check if a specific product is in wishlist
final isInWishlistProvider = Provider.autoDispose.family<bool, String>((
  ref,
  productId,
) {
  final wishlistState = ref.watch(wishlistProvider);
  return wishlistState.isInWishlist(productId);
});

// Get wishlist item count
final wishlistCountProvider = Provider.autoDispose<int>((ref) {
  final wishlistState = ref.watch(wishlistProvider);
  return wishlistState.itemCount;
});
