import 'package:freezed_annotation/freezed_annotation.dart';
import 'category.dart';
import 'product_variant.dart';

part 'category_discount_group.freezed.dart';

@freezed
class CategoryDiscountGroup with _$CategoryDiscountGroup {
  // Private constructor required for custom methods/getters
  const CategoryDiscountGroup._();

  const factory CategoryDiscountGroup({
    required Category category,
    required List<ProductVariant> discountedProducts,
  }) = _CategoryDiscountGroup;

  /// Business Rule Logic:
  /// Returns true if the group has enough products to be displayed (>= 1).
  /// This helps the UI filter out empty categories.
  bool get shouldDisplay => discountedProducts.isNotEmpty;

  /// Helper to get the optimal list for horizontal scrolling (max 5 items).
  /// Usage: Use this list in your ListView builder to ensure optimal performance/layout.
  List<ProductVariant> get displayList {
    return discountedProducts.length > 5
        ? discountedProducts.sublist(0, 5)
        : discountedProducts;
  }
}
