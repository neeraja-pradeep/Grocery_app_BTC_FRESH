import '../../domain/entities/product_base.dart';
import '../../domain/entities/product_variant.dart';

/// Merges supplementary product base data (description, rating, media) into a variant.
///
/// The product details API returns two separate responses:
/// - Variant API: pricing, stock, SKU, weight
/// - Product base API: description, rating, media gallery
///
/// This use case combines them so the UI has a single complete object.
class MergeProductDataUseCase {
  const MergeProductDataUseCase();

  ProductVariant execute(ProductVariant variant, ProductBase? productBase) {
    if (productBase == null) return variant;

    return ProductVariant(
      id: variant.id,
      sku: variant.sku,
      name: variant.name,
      variantName: variant.variantName,
      productId: variant.productId,
      trackInventory: variant.trackInventory,
      price: variant.price,
      originalPrice: variant.originalPrice,
      discountedPrice: variant.discountedPrice,
      isSelected: variant.isSelected,
      isPreorder: variant.isPreorder,
      preorderEndDate: variant.preorderEndDate,
      preorderGlobalThreshold: variant.preorderGlobalThreshold,
      quantityLimitPerCustomer: variant.quantityLimitPerCustomer,
      createdAt: variant.createdAt,
      updatedAt: variant.updatedAt,
      weight: variant.weight,
      status: variant.status,
      tags: variant.tags,
      barCode: variant.barCode,
      media: productBase.media ?? variant.media,
      currentQuantity: variant.currentQuantity,
      stockUnit: variant.stockUnit,
      prodDescription: variant.prodDescription,
      productRating: variant.productRating,
      warehouseName: variant.warehouseName,
      categoryId: variant.categoryId,
      description: productBase.description ?? variant.description,
      reviews: variant.reviews,
      nutritionFacts: variant.nutritionFacts,
      images: variant.images,
      imageUrl: variant.imageUrl,
      thumbnailUrl: variant.thumbnailUrl,
      rating: productBase.rating ?? variant.rating,
      reviewCount: productBase.reviewCount ?? variant.reviewCount,
    );
  }
}
