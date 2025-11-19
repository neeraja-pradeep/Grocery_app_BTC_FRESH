import '../../domain/entities/product_detail.dart';

/// Data Transfer Object for ProductDetail
/// Used for JSON serialization/deserialization from API
class ProductDetailDto {
  ProductDetailDto({
    required this.id,
    required this.name,
    required this.variantId,
    required this.variantName,
    this.price,
    this.originalPrice,
    this.weight,
    this.rating,
    this.reviewCount,
    this.imageUrl,
    this.thumbnailUrl,
    this.categoryId,
    this.description,
    this.nutritionFacts,
    this.images,
    this.reviews,
  });

  final String id;
  final String name;
  final String variantId;
  final String variantName;
  final String? price;
  final String? originalPrice;
  final String? weight;
  final double? rating;
  final int? reviewCount;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? categoryId;
  final String? description;
  final Map<String, String>? nutritionFacts;
  final List<String>? images;
  final List<ProductReviewDto>? reviews;

  /// Convert DTO to domain entity
  ProductDetail toDomain() {
    return ProductDetail(
      id: id,
      name: name,
      variantId: variantId,
      variantName: variantName,
      price: price,
      originalPrice: originalPrice,
      weight: weight,
      rating: rating,
      reviewCount: reviewCount,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      categoryId: categoryId,
      description: description,
      nutritionFacts: nutritionFacts,
      images: images,
      reviews: reviews?.map((r) => r.toDomain()).toList(),
    );
  }

  /// Parse from JSON response
  factory ProductDetailDto.fromJson(Map<String, dynamic> json) {
    return ProductDetailDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      variantId: json['variantId'] as String? ?? '',
      variantName: json['variantName'] as String? ?? '',
      price: json['price'] as String?,
      originalPrice: json['originalPrice'] as String?,
      weight: json['weight'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      imageUrl: json['imageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      categoryId: json['categoryId'] as String?,
      description: json['description'] as String?,
      nutritionFacts: (json['nutritionFacts'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => ProductReviewDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'variantId': variantId,
    'variantName': variantName,
    'price': price,
    'originalPrice': originalPrice,
    'weight': weight,
    'rating': rating,
    'reviewCount': reviewCount,
    'imageUrl': imageUrl,
    'thumbnailUrl': thumbnailUrl,
    'categoryId': categoryId,
    'description': description,
    'nutritionFacts': nutritionFacts,
    'images': images,
    'reviews': reviews?.map((e) => e.toJson()).toList(),
  };
}

/// Data Transfer Object for ProductReview
class ProductReviewDto {
  ProductReviewDto({
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
  ProductReview toDomain() {
    return ProductReview(
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
  factory ProductReviewDto.fromJson(Map<String, dynamic> json) {
    return ProductReviewDto(
      id: json['id'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      userImage: json['userImage'] as String?,
      helpfulCount: json['helpfulCount'] as int?,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'id': id,
    'userName': userName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'userImage': userImage,
    'helpfulCount': helpfulCount,
  };
}
