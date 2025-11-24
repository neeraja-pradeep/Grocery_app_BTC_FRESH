import '../../domain/entities/product_base.dart';
import 'product_variant_dto.dart';

/// Data Transfer Object for ProductBase
/// Used for JSON serialization/deserialization from product-level API
class ProductBaseDto {
  ProductBaseDto({
    required this.id,
    required this.productId,
    this.description,
    this.rating,
    this.reviewCount,
    this.media,
  });

  final int id;
  final int productId;
  final String? description;
  final double? rating;
  final int? reviewCount;
  final List<ProductVariantMediaDto>? media;

  /// Convert DTO to domain entity
  ProductBase toDomain() {
    return ProductBase(
      id: id,
      productId: productId,
      description: description,
      rating: rating,
      reviewCount: reviewCount,
      media: media?.map((m) => m.toDomain()).toList(),
    );
  }

  /// Parse from JSON response
  factory ProductBaseDto.fromJson(Map<String, dynamic> json) {
    // Parse rating - can be num or string
    double? parsedRating;
    final ratingValue = json['rating'];
    if (ratingValue != null) {
      if (ratingValue is num) {
        parsedRating = ratingValue.toDouble();
      } else if (ratingValue is String) {
        parsedRating = double.tryParse(ratingValue);
      }
    }

    return ProductBaseDto(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      description: json['description_plaintext'] as String?,
      rating: parsedRating,
      reviewCount: json['review_count'] as int?,
      media: (json['media'] as List<dynamic>?)
          ?.map(
            (e) => ProductVariantMediaDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'description_plaintext': description,
    'rating': rating,
    'review_count': reviewCount,
    'media': media?.map((e) => e.toJson()).toList(),
  };
}
