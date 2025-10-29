import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';

class CategoryItem {
  const CategoryItem({required this.title, this.assetPath});

  final String title;
  final String? assetPath;
}

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
                      if (isSelected && item.assetPath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: Image.asset(
                            item.assetPath!,
                            height: 68.h,
                            width: double.infinity,
                            fit: BoxFit.fitHeight,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        AppSpacing.h8,
                      ],
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
}
