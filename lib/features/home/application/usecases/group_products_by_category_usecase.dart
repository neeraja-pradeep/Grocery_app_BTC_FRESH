// lib/features/home/application/usecases/group_products_by_category_usecase.dart

import 'package:grocery_app/features/home/domain/entities/category.dart';
import 'package:grocery_app/features/home/domain/entities/category_discount_group.dart';
import 'package:grocery_app/features/home/domain/entities/product_variant.dart';

/// UseCase for grouping product variants by category
/// This handles the business logic of organizing products into discount groups
class GroupProductsByCategoryUseCase {
  /// Groups product variants by their associated categories
  ///
  /// [variants] - List of product variants to group
  /// [categories] - Available categories to match against
  ///
  /// Returns a list of CategoryDiscountGroup sorted by number of products (descending)
  List<CategoryDiscountGroup> execute({
    required List<ProductVariant> variants,
    required List<Category> categories,
  }) {
    if (variants.isEmpty) return [];

    // Group variants by product ID (assuming products belong to categories)
    final Map<int, List<ProductVariant>> groupedMap = {};

    for (var variant in variants) {
      final productId = variant.productId;
      if (!groupedMap.containsKey(productId)) {
        groupedMap[productId] = [];
      }
      groupedMap[productId]!.add(variant);
    }

    // Map product IDs to actual categories
    final List<CategoryDiscountGroup> groups = [];

    groupedMap.forEach((productId, productVariants) {
      // Try to find matching category
      // Note: This assumes a relationship between product and category
      // You might need to adjust this logic based on your actual data model
      final category = _findCategoryForProduct(productId, categories);

      groups.add(
        CategoryDiscountGroup(
          category: category,
          discountedProducts: productVariants,
        ),
      );
    });

    // Sort by number of discounted products (highest first)
    groups.sort(
      (a, b) =>
          b.discountedProducts.length.compareTo(a.discountedProducts.length),
    );

    return groups;
  }

  /// Finds the appropriate category for a product
  /// Creates a fallback category if no match is found
  Category _findCategoryForProduct(int productId, List<Category> categories) {
    // Try to find matching category by ID
    // Note: You might need to adjust this logic based on your data model
    // For example, if products have a categoryId field, use that instead
    try {
      return categories.firstWhere((cat) => cat.id == productId);
    } catch (e) {
      // Create fallback category for products without a matching category
      return Category(
        id: productId,
        name: "Special Offers",
        slug: "special-offers-$productId",
        description: "Limited time deals and discounts",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
}
