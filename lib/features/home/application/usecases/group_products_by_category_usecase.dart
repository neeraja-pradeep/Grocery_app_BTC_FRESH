// lib/features/home/application/usecases/group_products_by_category_usecase.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/category_discount_group.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';

class GroupProductsByCategoryUseCase {
  List<CategoryDiscountGroup> call({
    required List<ProductVariant> products,
    int maxProductsPerCategory = 5,
  }) {
    // 1. Group products by their grouping key
    // Note: Since ProductVariant currently lacks a direct 'categoryId' field in the definition,
    // we are using 'productId' as the grouping key.
    // In a real scenario, you would access `product.categoryId` here.
    final Map<int, List<ProductVariant>> groupedMap = {};

    for (var product in products) {
      final key = product.productId;
      if (!groupedMap.containsKey(key)) {
        groupedMap[key] = [];
      }
      groupedMap[key]!.add(product);
    }

    final List<CategoryDiscountGroup> resultGroups = [];

    // 2. Process each group
    groupedMap.forEach((id, groupProducts) {
      // 3. Filter out categories with < 3 products (Business Rule)
      if (groupProducts.length < 3) {
        return;
      }

      // Extract category info from the first product in the group
      final firstProduct = groupProducts.first;

      // Create a synthetic Category object from the product info
      // (Since we don't have the full Category entity here)
      final category = Category(
        id: id,
        // Heuristic: Use the first word of the product name or a generic name
        name: firstProduct.name.split(' ').first,
        slug: 'category-$id',
        description: 'Deals for ${firstProduct.name}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Take only the top N products for horizontal display
      final displayProducts = groupProducts
          .take(maxProductsPerCategory)
          .toList();

      resultGroups.add(
        CategoryDiscountGroup(
          category: category,
          discountedProducts: displayProducts,
        ),
      );
    });

    // 4. Sort categories by total discount amount (Highest total savings first)
    resultGroups.sort((a, b) {
      final savingsA = _calculateTotalSavings(a.discountedProducts);
      final savingsB = _calculateTotalSavings(b.discountedProducts);
      return savingsB.compareTo(savingsA); // Descending order
    });

    return resultGroups;
  }

  /// Helper to calculate total money saved in a list of products
  double _calculateTotalSavings(List<ProductVariant> variants) {
    return variants.fold(0.0, (sum, item) {
      if (item.discountedPrice != null && item.discountedPrice! < item.price) {
        return sum + (item.price - item.discountedPrice!);
      }
      return sum;
    });
  }
}

// --- Provider ---
final groupProductsByCategoryUseCaseProvider =
    Provider<GroupProductsByCategoryUseCase>((ref) {
      return GroupProductsByCategoryUseCase();
    });
