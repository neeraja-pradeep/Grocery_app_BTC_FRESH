import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/features/category/application/providers/category_providers.dart';
import 'package:grocery_app/features/category/presentation/components/_header.dart';
import 'package:grocery_app/features/category/presentation/components/category_screen_body.dart';
import 'package:grocery_app/features/category/presentation/helpers/category_mapper.dart';
import 'package:grocery_app/features/category/presentation/helpers/category_selection_manager.dart';
import 'package:grocery_app/features/category/presentation/helpers/category_state_listener.dart';
import 'package:grocery_app/features/category/presentation/helpers/loading_helpers.dart';
import 'package:grocery_app/features/category/application/providers/category_product_providers.dart'
    as category_products;

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen>
    with WidgetsBindingObserver {
  late final CategorySelectionManager _selectionManager;
  late final CategoryStateListener _stateListener;
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectionManager = CategorySelectionManager();
    _stateListener = CategoryStateListener(ref: ref, context: context);
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
    // Setup state listener
    _stateListener.listen(
      selectionManager: _selectionManager,
      setState: setState,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final categoryState = ref.watch(categoryControllerProvider);
    final categories = CategoryMapper.toViewItems(categoryState);

    final selectedCategoryId =
        categories.isNotEmpty &&
            _selectionManager.selectedIndex < categories.length
        ? categories[_selectionManager.selectedIndex].id
        : null;

    final selectedProductState = selectedCategoryId != null
        ? ref.watch(
            category_products.categoryProductControllerProvider(
              selectedCategoryId,
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
                    child: CategoryScreenBody(
                      categoryState: categoryState,
                      categories: categories,
                      selectedCategoryIndex: _selectionManager.selectedIndex,
                      selectedCategoryId: selectedCategoryId,
                      selectedFilterIndex: _selectedFilterIndex,
                      onCategorySelected: (index) {
                        final categoryId = categories[index].id;
                        setState(() {
                          _selectionManager.selectCategory(index, categoryId);
                        });
                      },
                      onFilterSelected: (index) {
                        setState(() => _selectedFilterIndex = index);
                      },
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
}
