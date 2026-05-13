import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/category_product_providers.dart'
    as category_products;
import '../../application/providers/category_providers.dart';
import '../../application/states/category_state.dart';
import 'category_selection_manager.dart';

/// Handles category state listening and side effects.
///
/// M1: `context` is NOT stored as a field — it is passed per `listen()` call
/// to prevent stale-context bugs when the widget rebuilds.
class CategoryStateListener {
  final WidgetRef ref;

  CategoryStateListener({required this.ref});

  /// Setup listener for category state changes.
  /// [context] must be the current frame's BuildContext.
  /// [onSelectionChanged] receives the new immutable manager when selection changes.
  void listen({
    required BuildContext context,
    required CategorySelectionManager selectionManager,
    required void Function(void Function()) setState,
    required void Function(CategorySelectionManager) onSelectionChanged,
  }) {
    ref.listen<CategoryState>(categoryControllerProvider, (previous, next) {
      if (!context.mounted) return;

      _handleErrorMessages(context, previous, next);
      _handleCategorySelection(
        previous,
        next,
        selectionManager,
        setState,
        onSelectionChanged,
      );
    });
  }

  void _handleErrorMessages(
    BuildContext context,
    CategoryState? previous,
    CategoryState next,
  ) {
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

  void _handleCategorySelection(
    CategoryState? previous,
    CategoryState next,
    CategorySelectionManager selectionManager,
    void Function(void Function()) setState,
    void Function(CategorySelectionManager) onSelectionChanged,
  ) {
    final previousCategories = previous?.categories ?? [];
    final nextCategories = next.categories;

    final updated = selectionManager.tryUpdateSelection(
      previousCategories: previousCategories,
      nextCategories: nextCategories,
    );

    if (updated != null) {
      setState(() => onSelectionChanged(updated));
    }

    // Use updated manager's selected ID if available, else current
    final effectiveManager = updated ?? selectionManager;
    if (nextCategories.isNotEmpty &&
        effectiveManager.selectedCategoryId != null) {
      final productController = ref.read(
        category_products
            .categoryProductControllerProvider(
              effectiveManager.selectedCategoryId!,
            )
            .notifier,
      );
      unawaited(productController.refreshIfStale());
    }
  }
}
