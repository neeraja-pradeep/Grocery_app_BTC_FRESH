import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/core/extensions/context_extensions.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onFilterSelected,
    this.leadingIconAsset,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onFilterSelected;
  final String? leadingIconAsset;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = !isDark;
    final unselectedTextColor = isLight
        ? const Color(0xFF016064)
        : colorScheme.onSurfaceVariant;
    final unselectedBackground = isLight
        ? Colors.white
        : colorScheme.surfaceContainerHighest;

    return SizedBox(
      height: 35.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: isLight ? Colors.white : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              leadingIconAsset!,
              width: 18.w,
              height: 18.w,
              colorFilter: isDark
                  ? ColorFilter.mode(colorScheme.primary, BlendMode.srcIn)
                  : null,
            ),
          ),

          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 33.h,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, index) => AppSpacing.w8,
                  itemBuilder: (context, index) {
                    final isSelected = index == selectedIndex;
                    return ChoiceChip(
                      label: Text(filters[index]),
                      labelPadding: EdgeInsets.symmetric(horizontal: 10.w),
                      pressElevation: 0,
                      showCheckmark: false,
                      selected: isSelected,
                      onSelected: (_) => onFilterSelected(index),
                      selectedColor: colorScheme.primary,
                      backgroundColor: unselectedBackground,
                      labelStyle: TextStyle(
                        fontSize: 10.sp,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : unselectedTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.15,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
