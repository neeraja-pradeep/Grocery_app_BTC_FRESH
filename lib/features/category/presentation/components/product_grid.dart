import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/extensions/context_extensions.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/category/presentation/components/category_list.dart';

class ProductGrid extends StatefulWidget {
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
  final VoidCallback onAddToCart;

  @override
  ProductGridState createState() => ProductGridState();
}

class ProductGridState extends State<ProductGrid> {
  final ScrollController _scrollController = ScrollController();
  late List<GlobalKey> _sectionKeys;
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

  void _handleScroll() {
    if (_isProgrammaticScroll || !_scrollController.hasClients) return;

    final scrollBox = context.findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    final viewportHeight = scrollBox.size.height;
    final viewportCenter = viewportHeight / 2;

    const double threshold = 32.0;
    int? belowThresholdIndex;
    double bestBelowTop = double.negativeInfinity;
    int? aboveThresholdIndex;
    double closestAbove = double.infinity;
    int? nearestIndex;
    double nearestDistance = double.infinity;

    for (var i = 0; i < _sectionKeys.length; i++) {
      final sectionContext = _sectionKeys[i].currentContext;
      if (sectionContext == null) continue;
      final sectionBox = sectionContext.findRenderObject() as RenderBox?;
      if (sectionBox == null || !sectionBox.attached) continue;

      final top = sectionBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      final center = top + sectionBox.size.height / 2;
      final distance = (center - viewportCenter).abs();

      if (top <= threshold && top > bestBelowTop) {
        bestBelowTop = top;
        belowThresholdIndex = i;
      } else if (top > threshold && (top - threshold) < closestAbove) {
        closestAbove = top - threshold;
        aboveThresholdIndex = i;
      }

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    final newIndex = belowThresholdIndex ?? aboveThresholdIndex ?? nearestIndex;
    if (newIndex != null && newIndex != widget.selectedCategoryIndex) {
      widget.onCategoryInViewChanged(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        for (var i = 0; i < widget.categories.length; i++) ...[
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
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4.w,
                mainAxisSpacing: 5.h,
                mainAxisExtent: 175.h,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, _) => _ProductCard(
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onAddToCart: widget.onAddToCart,
                  isActiveSection: widget.selectedCategoryIndex == i,
                ),
                childCount: 4,
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.colorScheme,
    required this.isDark,
    required this.onAddToCart,
    required this.isActiveSection,
  });

  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onAddToCart;
  final bool isActiveSection;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActiveSection ? 1.0 : 0.93,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: Image.asset(
                          'assets/images/fruits.png',
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 5.w,
                    child: GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        width: 29.w,
                        height: 29.w,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.add,
                          color: AppColors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText.pageTitle(text: 'Apple...'),
                  AppSpacing.h8,
                  AppText(
                    text: '500 g',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                  AppSpacing.h8,
                  Row(
                    children: [
                      const AppText.pageTitle(text: '₹150'),
                      AppSpacing.w8,
                      AppText(
                        text: '₹200',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.favorite_border,
                        size: 24.sp,
                        color: isDark
                            ? colorScheme.outline
                            : AppColors.green100,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
