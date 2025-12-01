// lib/features/wishlist/domain/entities/wishlist_item.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:grocery_app/features/home/domain/entities/product_variant.dart';
import 'package:grocery_app/features/home/domain/entities/product_media.dart';

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
    // Debug: Print the raw JSON to see what we're getting
    // print('WishlistItem.fromJson - Raw JSON: $json');

    // Parse according to the actual API response format
    String imageUrl = json['image']?.toString() ?? '';

    // Debug: Print the image URL
    // print('WishlistItem.fromJson - Image URL: $imageUrl');

    // Handle invalid/placeholder image URLs
    if (imageUrl == 'string' ||
        imageUrl.isEmpty ||
        !_isValidImageUrl(imageUrl)) {
      // print('WishlistItem.fromJson - Invalid image URL, setting to empty');
      imageUrl = ''; // Set to empty to show placeholder
    }

    return WishlistItem(
      id: _parseInt(json['id']) ?? 0,
      productId: json['product_variant']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']) ?? 0.0,
      // Since API doesn't provide MRP, use price as MRP
      mrp: _parseDouble(json['price']) ?? 0.0,
      imageUrl: imageUrl,
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

  // Helper method to validate image URLs
  static bool _isValidImageUrl(String url) {
    if (url.isEmpty || url == 'string') return false;

    // If it doesn't start with http, it might be a relative URL that we can fix
    if (!url.startsWith('http')) {
      return true; // We'll fix it later by adding https://
    }

    // Check if it's a valid URL format
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Check if it has a valid scheme
    return uri.scheme.startsWith('http');
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

  // Factory method to create WishlistItem from complete product API response
  factory WishlistItem.fromProductVariantResponse({
    required int wishlistId,
    required Map<String, dynamic> productData,
  }) {
    // Get image URL from media array (same as home screen)
    String imageUrl = '';
    final mediaList = productData['media'] as List<dynamic>?;
    if (mediaList != null && mediaList.isNotEmpty) {
      final firstMedia = mediaList.first as Map<String, dynamic>;
      final rawImageUrl = firstMedia['image']?.toString() ?? '';

      // Apply same URL processing as ProductMedia.fromJson
      if (rawImageUrl.isNotEmpty && !rawImageUrl.startsWith('http')) {
        imageUrl = 'https://$rawImageUrl';
      } else {
        imageUrl = rawImageUrl;
      }
    }

    // Parse prices
    final price = _parseDouble(productData['price']) ?? 0.0;
    final discountedPrice = _parseDouble(productData['discounted_price']);

    // Calculate discount percentage
    final hasDiscount =
        discountedPrice != null &&
        discountedPrice < price &&
        discountedPrice > 0;
    final discountPct = hasDiscount
        ? (((price - discountedPrice) / price) * 100).round()
        : 0;

    // Use discounted price if available, otherwise regular price
    final currentPrice = hasDiscount ? discountedPrice : price;

    // print('WishlistItem.fromProductVariantResponse - Image URL: $imageUrl');
    // print(
    //   'WishlistItem.fromProductVariantResponse - Product: ${productData['name']}',
    // );

    return WishlistItem(
      id: wishlistId,
      productId: productData['id']?.toString() ?? '',
      name: productData['name']?.toString() ?? '',
      price: currentPrice,
      mrp: price, // Original price as MRP
      imageUrl: imageUrl,
      unitLabel: productData['stock_unit']?.toString() ?? '',
      discountPct: discountPct,
      addedAt: DateTime.now(),
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
    // Process image URL similar to ProductMedia.fromJson
    String processedImageUrl = '';
    if (imageUrl.isNotEmpty && imageUrl != 'string') {
      if (!imageUrl.startsWith('http')) {
        processedImageUrl = 'https://$imageUrl';
      } else {
        processedImageUrl = imageUrl;
      }
    }

    // print('WishlistItem.toProductVariant - Original imageUrl: $imageUrl');
    // print(
    //   'WishlistItem.toProductVariant - Processed imageUrl: $processedImageUrl',
    // );

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
      media: processedImageUrl.isNotEmpty
          ? [
              ProductMedia(
                id: 1,
                imageUrl: processedImageUrl,
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
