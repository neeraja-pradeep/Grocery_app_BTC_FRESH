import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/features/category/application/providers/category_product_providers.dart'
    as category_products;
import 'package:grocery_app/features/category/application/providers/category_providers.dart';
import 'package:grocery_app/features/category/application/states/category_state.dart';
import 'package:grocery_app/features/category/application/states/category_product_state.dart';
import 'package:grocery_app/features/category/domain/entities/category.dart';
import 'package:grocery_app/features/category/presentation/components/_header.dart';
import 'package:grocery_app/features/category/presentation/components/category_list.dart';
import 'package:grocery_app/features/category/presentation/components/filter_bar.dart';
import 'package:grocery_app/features/category/presentation/components/category_error_view.dart';
import 'package:grocery_app/features/category/presentation/components/category_empty_view.dart';
import 'package:grocery_app/features/category/presentation/components/product_area.dart';
import 'package:grocery_app/features/category/presentation/helpers/loading_helpers.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen>
    with WidgetsBindingObserver {
  static const List<String> _filters = ['Brand', 'Price Drop', 'Popular'];

  int _selectedCategoryIndex = 0;
  String? _selectedCategoryId;
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(categoryControllerProvider.notifier).refreshIfStale());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CategoryState>(categoryControllerProvider, (previous, next) {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty &&
          next.errorMessage != previous?.errorMessage &&
          (next.status != CategoryStatus.error || next.hasData)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        });
      }

      final previousCategories = previous?.categories ?? const <Category>[];
      final nextCategories = next.categories;

      if (nextCategories.isEmpty) {
        if (_selectedCategoryIndex != 0 || _selectedCategoryId != null) {
          setState(() {
            _selectedCategoryIndex = 0;
            _selectedCategoryId = null;
          });
        }
        return;
      }

      final currentSelectedId =
          _selectedCategoryId ??
          (() {
            if (previousCategories.isNotEmpty &&
                _selectedCategoryIndex < previousCategories.length) {
              return previousCategories[_selectedCategoryIndex].id;
            }
            return null;
          })() ??
          nextCategories.first.id;

      final resolvedIndex = nextCategories.indexWhere(
        (c) => c.id == currentSelectedId,
      );
      final targetIndex = resolvedIndex >= 0 ? resolvedIndex : 0;
      final targetId = nextCategories[targetIndex].id;

      if (_selectedCategoryIndex != targetIndex ||
          _selectedCategoryId != targetId) {
        setState(() {
          _selectedCategoryIndex = targetIndex;
          _selectedCategoryId = targetId;
        });
      }

      final productController = ref.read(
        category_products.categoryProductControllerProvider(targetId).notifier,
      );
      unawaited(productController.refreshIfStale());
    });

    final colorScheme = Theme.of(context).colorScheme;
    final categoryState = ref.watch(categoryControllerProvider);
    final categories = _buildViewItems(categoryState);
    final CategoryItem? selectedCategoryItem =
        categories.isNotEmpty && _selectedCategoryIndex < categories.length
        ? categories[_selectedCategoryIndex]
        : null;
    final selectedProductState = selectedCategoryItem?.id != null
        ? ref.watch(
            category_products.categoryProductControllerProvider(
              selectedCategoryItem!.id!,
            ),
          )
        : null;
    final bool showLoadingIndicator =
        shouldShowLoading(
          startedAt: categoryState.refreshStartedAt,
          endedAt: categoryState.refreshEndedAt,
        ) ||
        shouldShowLoading(
          startedAt: selectedProductState?.refreshStartedAt,
          endedAt: selectedProductState?.refreshEndedAt,
        );

    return Container(
      color: AppColors.green10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 42.h, color: AppColors.green60),
          Header(colorScheme: colorScheme),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background_graphics.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: showLoadingIndicator
                        ? const SizedBox(
                            height: 3,
                            child: LinearProgressIndicator(minHeight: 3),
                          )
                        : const SizedBox(height: 3),
                  ),
                  Expanded(
                    child: _buildBody(
                      context,
                      colorScheme: colorScheme,
                      state: categoryState,
                      categories: categories,
                      productState: selectedProductState,
                      selectedCategoryId: selectedCategoryItem?.id,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
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
                selectedIndex: _selectedCategoryIndex,
                onCategorySelected: (index) {
                  final category = categories[index];
                  final categoryId = category.id;
                  setState(() {
                    _selectedCategoryIndex = index;
                    _selectedCategoryId = categoryId;
                  });
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
                selectedIndex: _selectedFilterIndex,
                onFilterSelected: (index) =>
                    setState(() => _selectedFilterIndex = index),
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
                  onAddToCart: (product) {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<CategoryItem> _buildViewItems(CategoryState state) {
    return state.categories
        .map((category) {
          final image = category.imageUrl ?? category.imagePath;
          final isLocalAsset = image != null && image.startsWith('assets/');
          return CategoryItem(
            id: category.id,
            title: category.title,
            assetPath: isLocalAsset ? image : null,
            imageUrl: isLocalAsset ? null : image,
          );
        })
        .toList(growable: false);
  }
}
