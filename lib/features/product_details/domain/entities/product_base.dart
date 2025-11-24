import 'package:equatable/equatable.dart';
import 'product_variant.dart';

/// Product base entity
/// Represents clean product-level data (description, rating, media)
/// These fields are fetched from the product-level API endpoint
/// Uses Equatable for value-based equality to ensure Riverpod state updates work correctly
class ProductBase extends Equatable {
  const ProductBase({
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
  final List<ProductVariantMedia>? media;

  /// Equatable props for value-based equality comparison.
  /// This ensures Riverpod detects when product data changes.
  @override
  List<Object?> get props => [
    id,
    productId,
    description,
    rating,
    reviewCount,
    media,
  ];
}
