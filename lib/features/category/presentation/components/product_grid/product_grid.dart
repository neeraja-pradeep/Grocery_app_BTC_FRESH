import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/category/application/providers/category_product_providers.dart'
    as category_products;
import 'package:grocery_app/features/category/domain/entities/category_product.dart';
import 'package:grocery_app/features/category/presentation/components/widgets/_product_card.dart';
import 'package:grocery_app/features/category/presentation/components/widgets/category_list.dart';

/// Displays products in a grid with category headings
///
/// Features:
/// - CustomScrollView with SliverGrid for performance
/// - Category headings with scroll detection
/// - Detects visible category and notifies parent
/// - Supports programmatic scroll-to-category animation
class ProductGrid extends ConsumerStatefulWidget {
  const ProductGrid({
    super.key,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.onCategoryInViewChanged,
    required this.onAddToCart,
  });

  final List<CategoryItem> categories;
  final int selectedCategoryIndex;
  final ValueChanged<int> onCategoryInViewChanged;
  final ValueChanged<CategoryProduct> onAddToCart;

  @override
  ConsumerState<ProductGrid> createState() => ProductGridState();
}

class ProductGridState extends ConsumerState<ProductGrid> {
  /// Manages product grid scrolling
  final ScrollController _scrollController = ScrollController();

  /// Tracks position of each category heading for scroll detection
  late List<GlobalKey> _sectionKeys;

  /// Prevents scroll detection during programmatic scrolls
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _buildSectionKeys();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories.length != widget.categories.length) {
      _buildSectionKeys();
    }
  }

  /// Creates GlobalKey for each category section
  void _buildSectionKeys() {
    _sectionKeys = List<GlobalKey>.generate(
      widget.categories.length,
      (_) => GlobalKey(),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to a specific category with smooth animation
  /// Called when user taps category in sidebar
  Future<void> scrollToCategory(int index) async {
    if (!_scrollController.hasClients) return;
    if (index < 0 || index >= _sectionKeys.length) return;

    final targetContext = _sectionKeys[index].currentContext;
    if (targetContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          scrollToCategory(index);
        }
      });
      return;
    }

    final renderBox = targetContext.findRenderObject() as RenderBox?;
    final scrollBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || scrollBox == null) return;

    final offsetWithinScroll = renderBox
        .localToGlobal(Offset.zero, ancestor: scrollBox)
        .dy;
    final targetOffset = _scrollController.offset + offsetWithinScroll;
    final position = _scrollController.position;
    final clampedOffset = targetOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    _isProgrammaticScroll = true;

    await _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _isProgrammaticScroll = false;
  }

  /// Detects which category heading is visible when user scrolls
  /// Updates parent with visible category index (works in both directions)
  void _handleScroll() {
    if (_isProgrammaticScroll || !_scrollController.hasClients) return;

    final scrollBox = context.findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    int? visibleIndex;
    double smallestTop = double.infinity;

    // Find the topmost category heading visible in viewport
    // (closest to top of screen but still visible)
    for (var i = 0; i < _sectionKeys.length; i++) {
      final sectionContext = _sectionKeys[i].currentContext;
      if (sectionContext == null) continue;

      final sectionBox = sectionContext.findRenderObject() as RenderBox?;
      if (sectionBox == null || !sectionBox.attached) continue;

      // Get position relative to viewport top
      final top = sectionBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      final bottom = top + sectionBox.size.height;
      const viewportTop = 0.0;
      final viewportBottom = scrollBox.size.height;

      // Check if heading is visible in viewport
      if (top < viewportBottom && bottom > viewportTop) {
        // Prioritize the one closest to the top (but still visible)
        // If top is negative (above viewport), use 0 for comparison
        final effectiveTop = top < viewportTop ? viewportTop : top;

        if (effectiveTop < smallestTop) {
          smallestTop = effectiveTop;
          visibleIndex = i;
        }
      }
    }

    // Update sidebar if category changed (works for scroll up and down)
    if (visibleIndex != null && visibleIndex != widget.selectedCategoryIndex) {
      widget.onCategoryInViewChanged(visibleIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        for (var i = 0; i < widget.categories.length; i++) ...[
          // Category heading
          SliverToBoxAdapter(
            child: Padding(
              key: _sectionKeys[i],
              padding: EdgeInsets.only(
                top: i == 0 ? 0.h : 5.h,
                bottom: 5.h,
                left: 4.w,
                right: 4.w,
              ),
              child: Container(
                height: 25.h,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.grey.withValues(alpha: 0.2),
                  ),
                  color: AppColors.white,
                ),
                child: Center(
                  child: AppText(
                    text: widget.categories[i].title,
                    color: AppColors.green100,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          ),
          // Products in 2-column grid
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            sliver: _CategoryProductsSliver(
              categoryId: widget.categories[i].id ?? '',
              colorScheme: colorScheme,
              onAddToCart: widget.onAddToCart,
            ),
          ),
        ],
      ],
    );
  }
}

/// Displays products for a single category in a 2-column grid
/// Uses Riverpod to fetch products in real-time
class _CategoryProductsSliver extends ConsumerWidget {
  const _CategoryProductsSliver({
    required this.categoryId,
    required this.colorScheme,
    required this.onAddToCart,
  });

  final String categoryId;
  final ColorScheme colorScheme;
  final ValueChanged<CategoryProduct> onAddToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(
      category_products.categoryProductControllerProvider(categoryId),
    );

    // Loading state
    if (productState.isLoading && !productState.hasData) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Error state
    if (productState.isError && !productState.hasData) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 100,
          child: Center(
            child: AppText(
              text: 'Unable to load products',
              color: AppColors.grey,
            ),
          ),
        ),
      );
    }

    // Empty state
    if (productState.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final products = productState.products;

    // 2-column grid with product cards
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4.w,
        mainAxisSpacing: 5.h,
        mainAxisExtent: 175.h,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          colorScheme: colorScheme,
          onAddToCart: () => onAddToCart(product),
        );
      }, childCount: products.length),
    );
  }
}
