import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/category_product_providers.dart'
    as category_products;
import '../../application/providers/category_providers.dart';
import '../../application/states/category_state.dart';
import 'category_selection_manager.dart';

/// Handles category state listening and side effects
class CategoryStateListener {
  final WidgetRef ref;
  final BuildContext context;

  CategoryStateListener({required this.ref, required this.context});

  /// Setup listener for category state changes
  void listen({
    required CategorySelectionManager selectionManager,
    required void Function(void Function()) setState,
  }) {
    ref.listen<CategoryState>(categoryControllerProvider, (previous, next) {
      if (!context.mounted) return;

      _handleErrorMessages(previous, next);
      _handleCategorySelection(previous, next, selectionManager, setState);
    });
  }

  /// Handle error message display
  void _handleErrorMessages(CategoryState? previous, CategoryState next) {
    if (next.errorMessage != null &&
        next.errorMessage!.isNotEmpty &&
        next.errorMessage != previous?.errorMessage &&
        (next.status != CategoryStatus.error || next.hasData)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        AppSnackbar.error(context, 'Unable to load categories');
      });
    }
  }

  /// Handle category selection synchronization
  void _handleCategorySelection(
    CategoryState? previous,
    CategoryState next,
    CategorySelectionManager selectionManager,
    void Function(void Function()) setState,
  ) {
    final previousCategories = previous?.categories ?? [];
    final nextCategories = next.categories;

    final selectionChanged = selectionManager.updateSelection(
      previousCategories: previousCategories,
      nextCategories: nextCategories,
    );

    if (selectionChanged) {
      setState(() {
        // Selection updated in manager
      });
    }

    // Refresh products for the selected category
    if (nextCategories.isNotEmpty &&
        selectionManager.selectedCategoryId != null) {
      final productController = ref.read(
        category_products
            .categoryProductControllerProvider(
              selectionManager.selectedCategoryId!,
            )
            .notifier,
      );
      unawaited(productController.refreshIfStale());
    }
  }
}
