import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../application/providers/category_providers.dart';
import '../../../application/states/category_state.dart';
import '../views/category_empty_view.dart';
import '../views/category_error_view.dart';
import '../widgets/category_list.dart';
import '../widgets/filter_bar.dart';
import '../product_grid/product_grid.dart';

/// Main category screen layout that combines:
/// - Left sidebar: Category list for navigation
/// - Right side: Filter bar + Product grid with category headings
///
/// Handles bidirectional sync:
/// - Click category → scrolls product grid to that category
/// - Scroll products → updates selected category in sidebar
class CategoryScreenBody extends ConsumerStatefulWidget {
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
  ConsumerState<CategoryScreenBody> createState() => CategoryScreenBodyState();
}

class CategoryScreenBodyState extends ConsumerState<CategoryScreenBody> {
  /// Key to access ProductGrid state and trigger scroll-to-category
  late final GlobalKey<ProductGridState> _productGridKey;

  @override
  void initState() {
    super.initState();
    _productGridKey = GlobalKey<ProductGridState>();
  }

  /// Public method to trigger scroll to a specific category
  void scrollToCategory(int index) {
    _productGridKey.currentState?.scrollToCategory(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildBody(
      context,
      ref,
      colorScheme: colorScheme,
      state: widget.categoryState,
      categories: widget.categories,
    );
  }

  /// Builds the layout with state handling (loading, error, empty, content)
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required ColorScheme colorScheme,
    required CategoryState state,
    required List<CategoryItem> categories,
  }) {
    // Loading state
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (state.isError && !state.hasData) {
      return CategoryErrorView(
        message: state.errorMessage ?? 'Unable to load categories.',
        onRetry: () {
          ref.read(categoryControllerProvider.notifier).refresh(force: true);
        },
      );
    }

    // Empty state
    if (state.isEmpty || categories.isEmpty) {
      return const CategoryEmptyView();
    }

    // Main content: Left sidebar + Right content area
    return Row(
      children: [
        // LEFT SIDEBAR: Category list for navigation
        Expanded(
          flex: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryList(
                categories: categories,
                selectedIndex: widget.selectedCategoryIndex,
                onCategorySelected: (index) {
                  widget.onCategorySelected(index);
                  // Scroll product grid to selected category
                  _productGridKey.currentState?.scrollToCategory(index);
                },
              ),
            ],
          ),
        ),
        // RIGHT CONTENT: Filter bar + Product grid with category headings
        Expanded(
          flex: 2,
          child: Column(
            children: [
              AppSpacing.h4,
              // Filter controls (Brand, Price Drop, Popular)
              FilterBar(
                filters: CategoryScreenBody._filters,
                selectedIndex: widget.selectedFilterIndex,
                onFilterSelected: widget.onFilterSelected,
                leadingIconAsset: 'assets/svgs/category_screen/filter_icon.svg',
              ),
              AppSpacing.h4,
              // Products grid with category headings + scroll detection
              Expanded(
                child: ProductGrid(
                  key: _productGridKey,
                  categories: categories,
                  selectedCategoryIndex: widget.selectedCategoryIndex,
                  onCategoryInViewChanged: widget.onCategorySelected,
                  onAddToCart: (product) {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
