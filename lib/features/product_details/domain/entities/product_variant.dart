import 'package:equatable/equatable.dart';

/// Product variant entity
/// Represents a specific variant of a product with different attributes
/// Includes extended information like reviews, ratings, and descriptions
/// Uses Equatable for value-based equality to ensure Riverpod state updates work correctly
class ProductVariant extends Equatable {
  const ProductVariant({
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
  final String? variantName; // Alias for UI compatibility
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
  final List<ProductVariantMedia>? media;
  final int currentQuantity;
  final String? stockUnit;
  final String? prodDescription;
  final String? productRating;
  final String? warehouseName;

  // Extended fields
  final String? categoryId;
  final String? description;
  final List<ProductVariantReview>? reviews;
  final Map<String, String>? nutritionFacts;
  final List<String>? images;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? rating;
  final int? reviewCount;

  /// Equatable props for value-based equality comparison.
  /// This ensures Riverpod detects when product data changes.
  @override
  List<Object?> get props => [
    id,
    sku,
    name,
    variantName,
    productId,
    trackInventory,
    price,
    originalPrice,
    discountedPrice,
    isSelected,
    isPreorder,
    preorderEndDate,
    preorderGlobalThreshold,
    quantityLimitPerCustomer,
    createdAt,
    updatedAt,
    weight,
    status,
    tags,
    barCode,
    media,
    currentQuantity,
    stockUnit,
    prodDescription,
    productRating,
    warehouseName,
    categoryId,
    description,
    reviews,
    nutritionFacts,
    images,
    imageUrl,
    thumbnailUrl,
    rating,
    reviewCount,
  ];
}

/// Product variant media entity
/// Uses Equatable for proper list comparison in ProductVariant
class ProductVariantMedia extends Equatable {
  const ProductVariantMedia({
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

  @override
  List<Object?> get props => [
    id,
    filePath,
    image,
    alt,
    externalUrl,
    // oembedData excluded - dynamic types can cause issues
    toRemove,
    productId,
    createdAt,
    updatedAt,
  ];
}

/// Product variant review entity
/// Uses Equatable for proper list comparison in ProductVariant
class ProductVariantReview extends Equatable {
  const ProductVariantReview({
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

  @override
  List<Object?> get props => [
    id,
    userName,
    rating,
    comment,
    createdAt,
    userImage,
    helpfulCount,
  ];
}
