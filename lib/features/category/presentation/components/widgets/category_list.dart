import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

/// Category data model with title, id, and optional images (local or network)
class CategoryItem {
  const CategoryItem({
    required this.title,
    this.id,
    this.assetPath,
    this.imageUrl,
  });

  final String? id;
  final String title;
  final String? assetPath; // Local asset path (assets/...)
  final String? imageUrl; // Network image URL
}

/// Left sidebar category navigation list
/// - Shows all categories
/// - Selected item has green highlight + image preview
/// - Notifies parent when category is tapped
/// - Auto-scrolls to keep selected category visible
class CategoryList extends StatefulWidget {
  const CategoryList({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  final List<CategoryItem> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  final ScrollController _scrollController = ScrollController();
  final double _itemHeight = 75.0; // Approximate height of unselected item
  final double _selectedItemHeight =
      155.0; // Approximate height when selected (with image)

  @override
  void initState() {
    super.initState();
    // Scroll to initial selected category after first frame
    if (widget.selectedIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedCategory();
      });
    }
  }

  @override
  void didUpdateWidget(CategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll when selected index changes (from product scrolling)
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelectedCategory();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls the category list to keep the selected category visible
  void _scrollToSelectedCategory() {
    if (!_scrollController.hasClients) return;

    // Calculate approximate position of the selected item
    double targetOffset = 0;
    for (int i = 0; i < widget.selectedIndex; i++) {
      targetOffset += _itemHeight;
    }

    // Get viewport info
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    final maxOffset = _scrollController.position.maxScrollExtent;

    // Check if item is already visible
    final itemTop = targetOffset;
    final itemBottom = targetOffset + _selectedItemHeight;
    final viewportTop = currentOffset;
    final viewportBottom = currentOffset + viewportHeight;

    // Only scroll if item is not fully visible
    if (itemTop < viewportTop || itemBottom > viewportBottom) {
      // Center the selected item in viewport
      final centeredOffset =
          targetOffset - (viewportHeight / 2) + (_selectedItemHeight / 2);
      final clampedOffset = centeredOffset.clamp(0.0, maxOffset);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        itemCount: widget.categories.length,
        separatorBuilder: (_, index) {
          if (index == widget.selectedIndex) {
            return const SizedBox.shrink();
          }
          // Divider between unselected categories
          return Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppColors.green100.withValues(alpha: 0.15),
          );
        },
        itemBuilder: (context, index) {
          final item = widget.categories[index];
          final isSelected = index == widget.selectedIndex;
          final isAfterSelected = index == widget.selectedIndex + 1;
          final BorderRadius? borderRadius = isSelected
              ? const BorderRadius.only(bottomRight: Radius.circular(10))
              : isAfterSelected
              ? const BorderRadius.only(topRight: Radius.circular(10))
              : null;

          return GestureDetector(
            onTap: () => widget.onCategorySelected(index),
            child: Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: AnimatedScale(
                scale: isSelected ? 1.02 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: isSelected ? null : 75.h,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: isSelected ? 12.h : 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.green10 : AppColors.white,
                    borderRadius: borderRadius,
                    // Green left border for selected item
                    border: Border(
                      left: BorderSide(
                        color: isSelected
                            ? AppColors.green100
                            : Colors.transparent,
                        width: 6.w,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Show image only when selected (local or network)
                      if (isSelected &&
                          (item.assetPath != null ||
                              item.imageUrl != null)) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: _buildCategoryImage(item),
                        ),
                        AppSpacing.h8,
                      ],
                      // Category name
                      AppText(
                        text: item.title,
                        fontSize: 13.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        maxLines: 2,
                        color: AppColors.green100,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build category image: local asset or network with fallback
  Widget _buildCategoryImage(CategoryItem item) {
    // Local asset
    if (item.assetPath != null && item.assetPath!.isNotEmpty) {
      return Image.asset(
        item.assetPath!,
        height: 68.h,
        width: double.infinity,
        fit: BoxFit.fitHeight,
        alignment: Alignment.centerLeft,
      );
    }

    // Network image
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Image.network(
        item.imageUrl!,
        height: 68.h,
        width: double.infinity,
        fit: BoxFit.fitHeight,
        alignment: Alignment.centerLeft,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 68.h,
          color: AppColors.green10,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.green100,
            size: 20,
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 68.h,
            color: AppColors.green10,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    // Fallback: no image
    return Container(
      height: 68.h,
      color: AppColors.green10,
      alignment: Alignment.center,
      child: const Icon(
        Icons.category_outlined,
        color: AppColors.green100,
        size: 20,
      ),
    );
  }
}
