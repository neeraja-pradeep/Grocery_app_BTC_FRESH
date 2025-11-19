import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';

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
class CategoryList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, index) {
          if (index == selectedIndex) {
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
          final item = categories[index];
          final isSelected = index == selectedIndex;
          final isAfterSelected = index == selectedIndex + 1;
          final BorderRadius? borderRadius = isSelected
              ? const BorderRadius.only(bottomRight: Radius.circular(10))
              : isAfterSelected
              ? const BorderRadius.only(topRight: Radius.circular(10))
              : null;

          return GestureDetector(
            onTap: () => onCategorySelected(index),
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
