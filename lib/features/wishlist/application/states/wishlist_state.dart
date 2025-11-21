// lib/features/wishlist/application/states/wishlist_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:new_app/core/error/failure.dart';
import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';

part 'wishlist_state.freezed.dart';

@freezed
sealed class WishlistState with _$WishlistState {
  // Initial state before any action
  const factory WishlistState.initial() = WishlistInitial;

  // First-time full screen loading
  const factory WishlistState.loading() = WishlistLoading;

  // Successfully loaded content
  const factory WishlistState.loaded({
    required List<WishlistItem> items,
    @Default(false) bool isRefreshing,
  }) = WishlistLoaded;

  // Pull-to-refresh state (keeps data visible)
  const factory WishlistState.refreshing({required List<WishlistItem> items}) =
      WishlistRefreshing;

  // Error state (optional: keep previous state to show stale data + snackbar)
  const factory WishlistState.error({
    required Failure failure,
    WishlistState? previousState,
  }) = WishlistError;
}

// Extension methods for convenience
extension WishlistStateX on WishlistState {
  List<WishlistItem> get items => maybeMap(
    loaded: (s) => s.items,
    refreshing: (s) => s.items,
    orElse: () => [],
  );

  bool get hasItems => items.isNotEmpty;
  int get itemCount => items.length;

  bool isInWishlist(String productId) {
    return items.any((item) => item.productId == productId);
  }

  WishlistItem? getWishlistItem(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }
}
