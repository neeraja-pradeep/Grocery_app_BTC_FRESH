// lib/features/wishlist/domain/entities/wishlist_item.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';
import 'package:new_app/features/home/domain/entities/product_media.dart';

part 'wishlist_item.freezed.dart';

@freezed
class WishlistItem with _$WishlistItem {
  const factory WishlistItem({
    required int id,
    required String productId,
    required String name,
    required double price,
    required double mrp,
    required String imageUrl,
    required String unitLabel,
    required int discountPct,
    DateTime? addedAt,
  }) = _WishlistItem;

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    // Parse according to the actual API response format
    return WishlistItem(
      id: _parseInt(json['id']) ?? 0,
      productId: json['product_variant']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']) ?? 0.0,
      // Since API doesn't provide MRP, use price as MRP
      mrp: _parseDouble(json['price']) ?? 0.0,
      imageUrl: json['image']?.toString() ?? '',
      // API doesn't provide unit_label, so we'll use empty string
      unitLabel: '',
      // API doesn't provide discount info, calculate from price if needed
      discountPct: 0,
      // API doesn't provide added_at, use current time
      addedAt: DateTime.now(),
    );
  }

  // Helper methods for parsing
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Factory method to create WishlistItem from ProductVariant
  factory WishlistItem.fromProductVariant({
    required int id,
    required ProductVariant productVariant,
    DateTime? addedAt,
  }) {
    // Get image URL from media
    String imageUrl = '';
    if (productVariant.media.isNotEmpty) {
      imageUrl = productVariant.media.first.imageUrl;
    }

    // Calculate discount percentage
    final discountPct = productVariant.hasDiscount
        ? productVariant.discountPercentage.round()
        : 0;

    // Use discounted price if available, otherwise regular price
    final currentPrice = productVariant.hasDiscount
        ? (productVariant.discountedPrice ?? productVariant.price)
        : productVariant.price;

    return WishlistItem(
      id: id,
      productId: productVariant.id.toString(),
      name: productVariant.name,
      price: currentPrice,
      mrp: productVariant.price, // Original price as MRP
      imageUrl: imageUrl,
      unitLabel: productVariant.stockUnit ?? '',
      discountPct: discountPct,
      addedAt: addedAt ?? DateTime.now(),
    );
  }
}

// Extension methods for convenience
extension WishlistItemX on WishlistItem {
  bool get hasDiscount => discountPct > 0;

  double get displayPrice => hasDiscount ? price : mrp;

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_variant': int.tryParse(productId) ?? 0,
      'name': name,
      'price': price.toString(),
      'image': imageUrl,
    };
  }

  // Convert WishlistItem to ProductVariant for compatibility
  ProductVariant toProductVariant() {
    return ProductVariant(
      id: int.tryParse(productId) ?? 0,
      name: name,
      productId: int.tryParse(productId) ?? 0,
      sku: 'wishlist-$productId',
      price: mrp,
      discountedPrice: hasDiscount ? price : null,
      stockUnit: unitLabel,
      currentQuantity: '1',
      status: true,
      media: imageUrl.isNotEmpty
          ? [
              ProductMedia(
                id: 1,
                imageUrl: imageUrl,
                productId: int.tryParse(productId) ?? 0,
                createdAt: addedAt ?? DateTime.now(),
              ),
            ]
          : [],
      isPreorder: false,
      createdAt: addedAt ?? DateTime.now(),
      updatedAt: addedAt ?? DateTime.now(),
    );
  }
}
