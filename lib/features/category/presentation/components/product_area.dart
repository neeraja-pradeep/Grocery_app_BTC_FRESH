import 'package:flutter/material.dart';
import 'package:grocery_app/features/category/application/states/category_product_state.dart';
import 'package:grocery_app/features/category/domain/entities/category_product.dart';
import 'package:grocery_app/features/category/presentation/components/product_grid.dart';
import 'package:grocery_app/features/category/presentation/components/product_error_view.dart';
import 'package:grocery_app/features/category/presentation/components/product_empty_view.dart';

class ProductArea extends StatelessWidget {
  const ProductArea({
    super.key,
    required this.state,
    required this.categoryId,
    required this.onRetry,
    required this.onAddToCart,
  });

  final CategoryProductState? state;
  final String? categoryId;
  final VoidCallback? onRetry;
  final ValueChanged<CategoryProduct> onAddToCart;

  @override
  Widget build(BuildContext context) {
    if (categoryId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final productState = state;
    if (productState == null ||
        (productState.isLoading && !productState.hasData)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productState.isError && !productState.hasData) {
      return ProductErrorView(
        message: productState.errorMessage ?? 'Unable to load products.',
        onRetry: onRetry,
      );
    }

    if (productState.isEmpty) {
      return const ProductEmptyView();
    }

    return ProductGrid(
      products: productState.products,
      onAddToCart: onAddToCart,
    );
  }
}
