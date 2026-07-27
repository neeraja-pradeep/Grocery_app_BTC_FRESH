import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/polling/polling_manager.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../application/providers/category_product_providers.dart'
    as category_products;
import '../../../domain/entities/category_product.dart';
import '../widgets/_product_card.dart';
import '../widgets/category_list.dart';

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
    required this.selectedFilterIndex,
    required this.onCategoryInViewChanged,
  });

  /// Filter chip index in CategoryScreenBody._filters (['Price Drop']).
  /// -1 means no filter active.
  static const int priceDropFilterIndex = 0;

  final List<CategoryItem> categories;
  final int selectedCategoryIndex;
  final int selectedFilterIndex;
  final ValueChanged<int> onCategoryInViewChanged;

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

  /// Feature name the category product pollers register under.
  static const String _pollingFeature = 'category_products';

  /// How often the section sweep may run while the user is dragging.
  ///
  /// The sweep measures every category heading's position, which walks the
  /// render tree once per section. At 120 fps with 25 categories that is 3000
  /// `localToGlobal` calls a second if it runs unthrottled on every scroll
  /// notification, so it is capped to ~8 sweeps/second instead.
  static const Duration _scrollThrottle = Duration(milliseconds: 120);

  Timer? _throttleTimer;
  bool _sweepQueued = false;

  @override
  void initState() {
    super.initState();
    _buildSectionKeys();
    _scrollController.addListener(_handleScroll);

    // Establish the initial visible set once the first frame has laid out, so
    // only on-screen categories start polling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sweepSections();
    });
  }

  @override
  void didUpdateWidget(ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories.length != widget.categories.length) {
      _buildSectionKeys();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sweepSections();
      });
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
    _throttleTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    // Drop the visibility filter so other screens using this feature are not
    // constrained by a set this (now gone) grid published.
    PollingManager.instance.setVisibleResources(_pollingFeature, null);
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

  /// Scroll notification handler.
  ///
  /// Scroll notifications arrive once per frame while dragging, but the sweep
  /// they trigger is O(number of categories) in render-tree walks. This runs
  /// the sweep immediately, then coalesces everything that arrives during the
  /// next [_scrollThrottle] window into a single trailing sweep.
  void _handleScroll() {
    if (_isProgrammaticScroll || !_scrollController.hasClients) return;

    if (_throttleTimer != null) {
      _sweepQueued = true;
      return;
    }

    _sweepSections();
    _throttleTimer = Timer(_scrollThrottle, () {
      _throttleTimer = null;
      if (_sweepQueued) {
        _sweepQueued = false;
        _handleScroll();
      }
    });
  }

  /// Measures every category section once and derives two things from the
  /// single pass:
  ///
  ///  1. the topmost section in the viewport, to sync the sidebar selection;
  ///  2. the set of sections near the viewport, so only those keep polling.
  void _sweepSections() {
    if (!_scrollController.hasClients) return;

    final scrollBox = context.findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    final viewportHeight = scrollBox.size.height;
    const viewportTop = 0.0;

    // Sections within one viewport above/below still poll, so data is fresh by
    // the time the user scrolls onto them.
    final pollMargin = viewportHeight;

    int? visibleIndex;
    double smallestTop = double.infinity;
    final pollable = <String>{};
    var measuredAny = false;

    for (var i = 0; i < _sectionKeys.length; i++) {
      final sectionContext = _sectionKeys[i].currentContext;
      if (sectionContext == null) continue;

      final sectionBox = sectionContext.findRenderObject() as RenderBox?;
      if (sectionBox == null || !sectionBox.attached) continue;

      measuredAny = true;

      // Get position relative to viewport top
      final top = sectionBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      final bottom = top + sectionBox.size.height;

      // Check if heading is visible in viewport
      if (top < viewportHeight && bottom > viewportTop) {
        // Prioritize the one closest to the top (but still visible)
        // If top is negative (above viewport), use 0 for comparison
        final effectiveTop = top < viewportTop ? viewportTop : top;

        if (effectiveTop < smallestTop) {
          smallestTop = effectiveTop;
          visibleIndex = i;
        }
      }

      if (top < viewportHeight + pollMargin && bottom > viewportTop - pollMargin) {
        final id = widget.categories[i].id;
        if (id != null && id.isNotEmpty) pollable.add(id);
      }
    }

    // Update sidebar if category changed (works for scroll up and down)
    if (visibleIndex != null && visibleIndex != widget.selectedCategoryIndex) {
      widget.onCategoryInViewChanged(visibleIndex);
    }

    // Only narrow polling once at least one section has actually been laid
    // out. Before first layout every context is null, and publishing an empty
    // set then would pause all polling until the next scroll.
    if (measuredAny) {
      PollingManager.instance.setVisibleResources(_pollingFeature, pollable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isPriceDrop =
        widget.selectedFilterIndex == ProductGrid.priceDropFilterIndex;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        for (var i = 0; i < widget.categories.length; i++) ...[
          // Only render category if it has products
          _CategorySectionBuilder(
            sectionKey: _sectionKeys[i],
            category: widget.categories[i],
            isFirst: i == 0,
            colorScheme: colorScheme,
            isPriceDrop: isPriceDrop,
          ),
        ],
      ],
    );
  }
}

/// Builds a category section only if it has products
/// Conditionally renders category heading + products grid
class _CategorySectionBuilder extends ConsumerWidget {
  const _CategorySectionBuilder({
    required this.sectionKey,
    required this.category,
    required this.isFirst,
    required this.colorScheme,
    required this.isPriceDrop,
  });

  final GlobalKey sectionKey;
  final CategoryItem category;
  final bool isFirst;
  final ColorScheme colorScheme;
  final bool isPriceDrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the product state for this category.
    // Price Drop reads from the separate discount provider (no cache, no polling).
    final categoryId = category.id ?? '';
    final productState = isPriceDrop
        ? ref.watch(
            category_products.categoryDiscountProductControllerProvider(
              categoryId,
            ),
          )
        : ref.watch(
            category_products.categoryProductControllerProvider(categoryId),
          );

    // Filter: Don't render if category has no products
    // Check both null and empty conditions
    if (productState.products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Category has products - render heading + grid
    return SliverMainAxisGroup(
      slivers: [
        // Category heading
        SliverToBoxAdapter(
          child: Padding(
            key: sectionKey,
            padding: EdgeInsets.only(
              top: isFirst ? 0.h : 5.h,
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
                  text: category.title,
                  color: AppColors.green100,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ),
        // Products in 2-column grid
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 1.w),
          sliver: _CategoryProductsSliver(
            categoryId: category.id ?? '',
            colorScheme: colorScheme,
            isPriceDrop: isPriceDrop,
          ),
        ),
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
    required this.isPriceDrop,
  });

  final String categoryId;
  final ColorScheme colorScheme;
  final bool isPriceDrop;

  /// Navigate to product details screen with variant ID only
  void _navigateToProductDetails(
    BuildContext context,
    CategoryProduct product,
  ) {
    context.push('/product-details/${product.variantId}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = isPriceDrop
        ? ref.watch(
            category_products.categoryDiscountProductControllerProvider(
              categoryId,
            ),
          )
        : ref.watch(
            category_products.categoryProductControllerProvider(categoryId),
          );

    // Loading state
    if (productState.isLoading && !productState.hasData) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 200.h,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Error state
    if (productState.isError && !productState.hasData) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 100.h,
          child: const Center(
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
        crossAxisSpacing: 3.5.w,
        mainAxisSpacing: 5.h,
        mainAxisExtent: 175.h,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final product = products[index];
        // Use ValueKey with data fields to force rebuild when product changes
        return ProductCard(
          key: ValueKey(
            '${product.variantId}_${product.weight}_${product.price}',
          ),
          product: product,
          colorScheme: colorScheme,
          onTap: () => _navigateToProductDetails(context, product),
        );
      }, childCount: products.length),
    );
  }
}
