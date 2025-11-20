import 'package:flutter/foundation.dart';

import '../../domain/entities/product_variant.dart';

/// Data Transfer Object for ProductVariant
/// Used for JSON serialization/deserialization from API
class ProductVariantDto {
  ProductVariantDto({
    required this.id,
    required this.sku,
    required this.name,
    this.variantName,
    required this.productId,
    required this.trackInventory,
    required this.price,
    this.originalPrice,
    this.discountedPrice,
    this.isSelected = false,
    this.isPreorder = false,
    this.preorderEndDate,
    this.preorderGlobalThreshold,
    this.quantityLimitPerCustomer,
    required this.createdAt,
    required this.updatedAt,
    this.weight,
    this.status = false,
    this.tags,
    this.barCode,
    this.media,
    this.currentQuantity = 0,
    this.stockUnit,
    this.prodDescription,
    this.productRating,
    this.warehouseName,
    this.categoryId,
    this.description,
    this.reviews,
    this.nutritionFacts,
    this.images,
    this.imageUrl,
    this.thumbnailUrl,
    this.rating,
    this.reviewCount,
  });

  final int id;
  final String sku;
  final String name;
  final String? variantName;
  final int productId;
  final bool trackInventory;
  final String price;
  final String? originalPrice;
  final String? discountedPrice;
  final bool isSelected;
  final bool isPreorder;
  final String? preorderEndDate;
  final int? preorderGlobalThreshold;
  final int? quantityLimitPerCustomer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? weight;
  final bool status;
  final String? tags;
  final String? barCode;
  final List<ProductVariantMediaDto>? media;
  final int currentQuantity;
  final String? stockUnit;
  final String? prodDescription;
  final String? productRating;
  final String? warehouseName;

  // Extended fields
  final String? categoryId;
  final String? description;
  final List<ProductVariantReviewDto>? reviews;
  final Map<String, String>? nutritionFacts;
  final List<String>? images;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? rating;
  final int? reviewCount;

  /// Transform image URL to use CDN domain
  static String _formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // If already a full HTTPS URL, check if it needs domain replacement
    if (url.startsWith('https://')) {
      return url;
    }

    // Replace internal server URLs with CDN domain
    if (url.startsWith('http://156.67.104.149:8080')) {
      return url.replaceFirst(
        'http://156.67.104.149:8080',
        'https://grocery-application.b-cdn.net',
      );
    }

    // Handle relative paths
    if (url.startsWith('/')) {
      return 'https://grocery-application.b-cdn.net$url';
    }

    // Default: treat as relative path
    return 'https://grocery-application.b-cdn.net/$url';
  }

  /// Convert DTO to domain entity
  ProductVariant toDomain() {
    final formattedImageUrl = imageUrl != null && imageUrl!.isNotEmpty
        ? _formatImageUrl(imageUrl)
        : null;
    if (kDebugMode) {
      print(
        'ProductVariantDto.toDomain() - imageUrl Original: $imageUrl => Formatted: $formattedImageUrl',
      );
      if (media != null) {
        print('ProductVariantDto.toDomain() - media count: ${media!.length}');
      }
    }
    return ProductVariant(
      id: id,
      sku: sku,
      name: name,
      variantName: variantName,
      productId: productId,
      trackInventory: trackInventory,
      price: price,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      isSelected: isSelected,
      isPreorder: isPreorder,
      preorderEndDate: preorderEndDate,
      preorderGlobalThreshold: preorderGlobalThreshold,
      quantityLimitPerCustomer: quantityLimitPerCustomer,
      createdAt: createdAt,
      updatedAt: updatedAt,
      weight: weight,
      status: status,
      tags: tags,
      barCode: barCode,
      media: media?.map((m) => m.toDomain()).toList(),
      currentQuantity: currentQuantity,
      stockUnit: stockUnit,
      prodDescription: prodDescription,
      productRating: productRating,
      warehouseName: warehouseName,
      categoryId: categoryId,
      description: description,
      reviews: reviews?.map((r) => r.toDomain()).toList(),
      nutritionFacts: nutritionFacts,
      images: images
          ?.map((img) => _formatImageUrl(img))
          .where((img) => img.isNotEmpty)
          .toList(),
      imageUrl: formattedImageUrl,
      thumbnailUrl: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
          ? _formatImageUrl(thumbnailUrl)
          : null,
      rating: rating,
      reviewCount: reviewCount,
    );
  }

  /// Parse from JSON response
  factory ProductVariantDto.fromJson(Map<String, dynamic> json) {
    return ProductVariantDto(
      id: json['id'] as int? ?? 0,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      variantName: json['variant_name'] as String?,
      productId: json['product_id'] as int? ?? 0,
      trackInventory: json['track_inventory'] as bool? ?? false,
      price: json['price'] as String? ?? '0',
      originalPrice: json['original_price'] as String?,
      discountedPrice: json['discounted_price'] as String?,
      isSelected: json['is_selected'] as bool? ?? false,
      isPreorder: json['is_preorder'] as bool? ?? false,
      preorderEndDate: json['preorder_end_date'] as String?,
      preorderGlobalThreshold: json['preorder_global_threshold'] as int?,
      quantityLimitPerCustomer: json['quantity_limit_per_customer'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      weight: json['weight'] as String?,
      status: json['status'] as bool? ?? false,
      tags: json['tags'] as String?,
      barCode: json['bar_code'] as String?,
      media: (json['media'] as List<dynamic>?)
          ?.map(
            (e) => ProductVariantMediaDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      currentQuantity: json['current_quantity'] as int? ?? 0,
      stockUnit: json['stock_unit'] as String?,
      prodDescription: json['prod_description'] as String?,
      productRating: json['product_rating'] as String?,
      warehouseName: json['warehouse_name'] as String?,
      categoryId: json['category_id'] as String?,
      description: json['description'] as String?,
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map(
            (e) => ProductVariantReviewDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      nutritionFacts: (json['nutrition_facts'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imageUrl: json['image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'id': id,
    'sku': sku,
    'name': name,
    'variant_name': variantName,
    'product_id': productId,
    'track_inventory': trackInventory,
    'price': price,
    'original_price': originalPrice,
    'discounted_price': discountedPrice,
    'is_selected': isSelected,
    'is_preorder': isPreorder,
    'preorder_end_date': preorderEndDate,
    'preorder_global_threshold': preorderGlobalThreshold,
    'quantity_limit_per_customer': quantityLimitPerCustomer,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'weight': weight,
    'status': status,
    'tags': tags,
    'bar_code': barCode,
    'media': media?.map((e) => e.toJson()).toList(),
    'current_quantity': currentQuantity,
    'stock_unit': stockUnit,
    'prod_description': prodDescription,
    'product_rating': productRating,
    'warehouse_name': warehouseName,
    'category_id': categoryId,
    'description': description,
    'reviews': reviews?.map((e) => e.toJson()).toList(),
    'nutrition_facts': nutritionFacts,
    'images': images,
    'image_url': imageUrl,
    'thumbnail_url': thumbnailUrl,
    'rating': rating,
    'review_count': reviewCount,
  };
}

/// Data Transfer Object for ProductVariantMedia
class ProductVariantMediaDto {
  ProductVariantMediaDto({
    required this.id,
    required this.filePath,
    required this.image,
    required this.alt,
    this.externalUrl,
    this.oembedData,
    this.toRemove = false,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String filePath;
  final String image;
  final String alt;
  final String? externalUrl;
  final dynamic oembedData;
  final bool toRemove;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Transform image URL to use CDN domain
  static String _formatImageUrl(String url) {
    if (url.isEmpty) return '';

    // If already a full HTTPS URL, check if it needs domain replacement
    if (url.startsWith('https://')) {
      return url;
    }

    // Replace internal server URLs with CDN domain
    if (url.startsWith('http://156.67.104.149:8080')) {
      return url.replaceFirst(
        'http://156.67.104.149:8080',
        'https://grocery-application.b-cdn.net',
      );
    }

    // Handle relative paths
    if (url.startsWith('/')) {
      return 'https://grocery-application.b-cdn.net$url';
    }

    // Default: treat as relative path
    return 'https://grocery-application.b-cdn.net/$url';
  }

  /// Convert DTO to domain entity
  ProductVariantMedia toDomain() {
    final formattedUrl = _formatImageUrl(image);
    if (kDebugMode) {
      print(
        'ProductVariantMediaDto.toDomain() - Original: $image => Formatted: $formattedUrl',
      );
    }
    return ProductVariantMedia(
      id: id,
      filePath: filePath,
      image: formattedUrl,
      alt: alt,
      externalUrl: externalUrl,
      oembedData: oembedData,
      toRemove: toRemove,
      productId: productId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Parse from JSON response
  factory ProductVariantMediaDto.fromJson(Map<String, dynamic> json) {
    return ProductVariantMediaDto(
      id: json['id'] as int? ?? 0,
      filePath: json['file_path'] as String? ?? '',
      image: json['image'] as String? ?? '',
      alt: json['alt'] as String? ?? '',
      externalUrl: json['external_url'] as String?,
      oembedData: json['oembed_data'],
      toRemove: json['to_remove'] as bool? ?? false,
      productId: json['product_id'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'id': id,
    'file_path': filePath,
    'image': image,
    'alt': alt,
    'external_url': externalUrl,
    'oembed_data': oembedData,
    'to_remove': toRemove,
    'product_id': productId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Data Transfer Object for ProductVariantReview
class ProductVariantReviewDto {
  ProductVariantReviewDto({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userImage,
    this.helpfulCount,
  });

  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? userImage;
  final int? helpfulCount;

  /// Convert DTO to domain entity
  ProductVariantReview toDomain() {
    return ProductVariantReview(
      id: id,
      userName: userName,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      userImage: userImage,
      helpfulCount: helpfulCount,
    );
  }

  /// Parse from JSON response
  factory ProductVariantReviewDto.fromJson(Map<String, dynamic> json) {
    return ProductVariantReviewDto(
      id: json['id'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      userImage: json['user_image'] as String?,
      helpfulCount: json['helpful_count'] as int?,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_name': userName,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
    'user_image': userImage,
    'helpful_count': helpfulCount,
  };
}
