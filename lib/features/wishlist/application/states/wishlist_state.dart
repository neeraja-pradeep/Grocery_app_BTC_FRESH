// lib/features/wishlist/application/states/wishlist_state.dart

import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';

class WishlistState {
  final List<WishlistItem> items;
  final bool isLoading;
  final String? error;

  const WishlistState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  WishlistState copyWith({
    List<WishlistItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasError => error != null;
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistState &&
        other.items == items &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(items, isLoading, error);

  @override
  String toString() {
    return 'WishlistState(items: ${items.length}, isLoading: $isLoading, error: $error)';
  }
}
