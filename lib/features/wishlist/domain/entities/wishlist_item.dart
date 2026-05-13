// lib/features/wishlist/domain/entities/wishlist_item.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../home/domain/entities/product_media.dart';
import '../../../home/domain/entities/product_variant.dart';

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
    String imageUrl = json['image']?.toString() ?? '';

    if (imageUrl == 'string' ||
        imageUrl.isEmpty ||
        !_isValidImageUrl(imageUrl)) {
      imageUrl = '';
    }

    return WishlistItem(
      id: _parseInt(json['id']) ?? 0,
      productId: json['product_variant_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']) ?? 0.0,
      mrp: _parseDouble(json['price']) ?? 0.0,
      imageUrl: imageUrl,
      unitLabel: '',
      discountPct: 0,
      addedAt: DateTime.now(),
    );
  }

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

  static bool _isValidImageUrl(String url) {
    if (url.isEmpty || url == 'string') return false;
    if (!url.startsWith('http')) return true;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.scheme.startsWith('http');
  }

  factory WishlistItem.fromProductVariant({
    required int id,
    required ProductVariant productVariant,
    DateTime? addedAt,
  }) {
    String imageUrl = '';
    if (productVariant.media.isNotEmpty) {
      imageUrl = productVariant.media.first.imageUrl;
    }

    final discountPct = productVariant.hasDiscount
        ? productVariant.discountPercentage.round()
        : 0;

    final currentPrice = productVariant.hasDiscount
        ? (productVariant.discountedPrice ?? productVariant.price)
        : productVariant.price;

    return WishlistItem(
      id: id,
      productId: productVariant.id.toString(),
      name: productVariant.name,
      price: currentPrice,
      mrp: productVariant.price,
      imageUrl: imageUrl,
      unitLabel: productVariant.stockUnit ?? '',
      discountPct: discountPct,
      addedAt: addedAt ?? DateTime.now(),
    );
  }

  factory WishlistItem.fromProductVariantResponse({
    required int wishlistId,
    required Map<String, dynamic> productData,
  }) {
    String imageUrl = '';
    final mediaList = productData['media'] as List<dynamic>?;
    if (mediaList != null && mediaList.isNotEmpty) {
      final firstMedia = mediaList.first as Map<String, dynamic>;
      final rawImageUrl = firstMedia['image']?.toString() ?? '';
      if (rawImageUrl.isNotEmpty && !rawImageUrl.startsWith('http')) {
        imageUrl = 'https://$rawImageUrl';
      } else {
        imageUrl = rawImageUrl;
      }
    }

    final price = _parseDouble(productData['price']) ?? 0.0;
    final discountedPrice = _parseDouble(productData['discounted_price']);

    final hasDiscount =
        discountedPrice != null &&
        discountedPrice < price &&
        discountedPrice > 0;
    final discountPct = hasDiscount
        ? (((price - discountedPrice) / price) * 100).round()
        : 0;

    final currentPrice = hasDiscount ? discountedPrice : price;

    return WishlistItem(
      id: wishlistId,
      productId: productData['id']?.toString() ?? '',
      name: productData['name']?.toString() ?? '',
      price: currentPrice,
      mrp: price,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_variant_id': int.tryParse(productId) ?? 0,
      'name': name,
      'price': price.toString(),
      'image': imageUrl,
    };
  }

  /// Full serialization for Hive cache persistence.
  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'productId': productId,
    'name': name,
    'price': price,
    'mrp': mrp,
    'imageUrl': imageUrl,
    'unitLabel': unitLabel,
    'discountPct': discountPct,
    if (addedAt != null) 'addedAt': addedAt!.toIso8601String(),
  };

  static WishlistItem fromCacheJson(Map<String, dynamic> json) => WishlistItem(
    id: json['id'] as int,
    productId: json['productId'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    mrp: (json['mrp'] as num).toDouble(),
    imageUrl: json['imageUrl'] as String,
    unitLabel: json['unitLabel'] as String,
    discountPct: json['discountPct'] as int,
    addedAt: json['addedAt'] != null
        ? DateTime.parse(json['addedAt'] as String)
        : null,
  );

  ProductVariant toProductVariant() {
    String processedImageUrl = '';
    if (imageUrl.isNotEmpty && imageUrl != 'string') {
      if (!imageUrl.startsWith('http')) {
        processedImageUrl = 'https://$imageUrl';
      } else {
        processedImageUrl = imageUrl;
      }
    }

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
