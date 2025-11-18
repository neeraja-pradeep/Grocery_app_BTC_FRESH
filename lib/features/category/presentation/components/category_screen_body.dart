import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/features/category/application/providers/category_product_providers.dart'
    as category_products;
import 'package:grocery_app/features/category/application/providers/category_providers.dart';
import 'package:grocery_app/features/category/application/states/category_state.dart';
import 'package:grocery_app/features/category/application/states/category_product_state.dart';
import 'package:grocery_app/features/category/presentation/components/category_empty_view.dart';
import 'package:grocery_app/features/category/presentation/components/category_error_view.dart';
import 'package:grocery_app/features/category/presentation/components/category_list.dart';
import 'package:grocery_app/features/category/presentation/components/filter_bar.dart';
import 'package:grocery_app/features/category/presentation/components/product_area.dart';

class CategoryScreenBody extends ConsumerWidget {
  static const List<String> _filters = ['Brand', 'Price Drop', 'Popular'];

  final CategoryState categoryState;
  final List<CategoryItem> categories;
  final int selectedCategoryIndex;
  final String? selectedCategoryId;
  final int selectedFilterIndex;
  final void Function(int index) onCategorySelected;
  final void Function(int index) onFilterSelected;

  const CategoryScreenBody({
    required this.categoryState,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.selectedCategoryId,
    required this.selectedFilterIndex,
    required this.onCategorySelected,
    required this.onFilterSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedProductState = selectedCategoryId != null
        ? ref.watch(
            category_products.categoryProductControllerProvider(
              selectedCategoryId!,
            ),
          )
        : null;

    return _buildBody(
      context,
      ref,
      colorScheme: colorScheme,
      state: categoryState,
      categories: categories,
      productState: selectedProductState,
      selectedCategoryId: selectedCategoryId,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required ColorScheme colorScheme,
    required CategoryState state,
    required List<CategoryItem> categories,
    CategoryProductState? productState,
    String? selectedCategoryId,
  }) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isError && !state.hasData) {
      return CategoryErrorView(
        message: state.errorMessage ?? 'Unable to load categories.',
        onRetry: () =>
            ref.read(categoryControllerProvider.notifier).refresh(force: true),
      );
    }

    if (state.isEmpty || categories.isEmpty) {
      return const CategoryEmptyView();
    }

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryList(
                categories: categories,
                selectedIndex: selectedCategoryIndex,
                onCategorySelected: (index) {
                  final category = categories[index];
                  final categoryId = category.id;
                  onCategorySelected(index);

                  if (categoryId != null) {
                    unawaited(
                      ref
                          .read(
                            category_products
                                .categoryProductControllerProvider(categoryId)
                                .notifier,
                          )
                          .refreshIfStale(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              AppSpacing.h4,
              FilterBar(
                filters: _filters,
                selectedIndex: selectedFilterIndex,
                onFilterSelected: onFilterSelected,
                leadingIconAsset: 'assets/svgs/filter_icon.svg',
              ),
              AppSpacing.h4,
              Expanded(
                child: ProductArea(
                  state: productState,
                  categoryId: selectedCategoryId,
                  onRetry: selectedCategoryId == null
                      ? null
                      : () => ref
                            .read(
                              category_products
                                  .categoryProductControllerProvider(
                                    selectedCategoryId,
                                  )
                                  .notifier,
                            )
                            .refresh(force: true),
                  onAddToCart: (product) {
                    // TODO: Implement add to cart functionality
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
