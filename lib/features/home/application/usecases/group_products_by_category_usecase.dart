// lib/features/home/application/usecases/group_products_by_category_usecase.dart

import '../../domain/entities/category.dart';
import '../../domain/entities/category_discount_group.dart';
import '../../domain/entities/product_variant.dart';

/// UseCase for grouping product variants by category
/// This handles the business logic of organizing products into discount groups
class GroupProductsByCategoryUseCase {
  /// Groups product variants by their associated categories.
  ///
  /// [variants] - List of product variants to group
  /// [categories] - Available categories to match against
  /// [productCategoryMap] - Lookup of productId → categoryId derived from the
  ///   products endpoint. Required to correctly assign each variant to its
  ///   real category (variants do not carry a categoryId of their own).
  ///
  /// Returns a list of CategoryDiscountGroup sorted by number of products (descending)
  List<CategoryDiscountGroup> execute({
    required List<ProductVariant> variants,
    required List<Category> categories,
    Map<int, int> productCategoryMap = const {},
  }) {
    if (variants.isEmpty) return [];

    // Group variants by product ID
    final Map<int, List<ProductVariant>> groupedMap = {};

    for (var variant in variants) {
      final productId = variant.productId;
      if (!groupedMap.containsKey(productId)) {
        groupedMap[productId] = [];
      }
      groupedMap[productId]!.add(variant);
    }

    // Aggregate variants by their real category (looked up via productCategoryMap)
    // so multiple products in the same category collapse into one group.
    final Map<int, List<ProductVariant>> categoryGrouped = {};
    final List<ProductVariant> orphans = [];

    groupedMap.forEach((productId, productVariants) {
      final categoryId = productCategoryMap[productId];
      if (categoryId == null) {
        orphans.addAll(productVariants);
        return;
      }
      categoryGrouped.putIfAbsent(categoryId, () => []).addAll(productVariants);
    });

    final List<CategoryDiscountGroup> groups = [];

    categoryGrouped.forEach((categoryId, categoryVariants) {
      final category = _findCategoryById(categoryId, categories);
      groups.add(
        CategoryDiscountGroup(
          category: category,
          discountedProducts: categoryVariants,
        ),
      );
    });

    if (orphans.isNotEmpty) {
      groups.add(
        CategoryDiscountGroup(
          category: _fallbackCategory(),
          discountedProducts: orphans,
        ),
      );
    }

    // Sort by number of discounted products (highest first)
    groups.sort(
      (a, b) =>
          b.discountedProducts.length.compareTo(a.discountedProducts.length),
    );

    return groups;
  }

  Category _findCategoryById(int categoryId, List<Category> categories) {
    try {
      return categories.firstWhere((cat) => cat.id == categoryId);
    } catch (_) {
      return Category(
        id: categoryId,
        name: 'Special Offers',
        slug: 'special-offers-$categoryId',
        description: 'Limited time deals and discounts',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Category _fallbackCategory() {
    return Category(
      id: 0,
      name: 'Special Offers',
      slug: 'special-offers',
      description: 'Limited time deals and discounts',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
