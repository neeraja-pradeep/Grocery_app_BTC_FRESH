/// Product detail entity with extended information
/// Extends CategoryProduct with additional details like description, ratings, reviews
class ProductDetail {
  ProductDetail({
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
  final List<ProductReview>? reviews;
}

/// Product review entity
class ProductReview {
  ProductReview({
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
}
