import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../home/presentation/screen/search_screen.dart';

class Header extends StatelessWidget {
  const Header({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final iconColor = isDark ? colorScheme.onPrimary : colorScheme.secondary;
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Container(
        height: 51.h,

        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          border: const Border(
            bottom: BorderSide(width: 1, color: AppColors.grey),
          ),
        ),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.w12,
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: SvgPicture.asset(
                'assets/svgs/category_screen/category_icon.svg',
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                width: 22.w,
                height: 22.w,
              ),
            ),
            AppSpacing.w16,
            const AppText.pageTitle(
              text: 'Shop By Category',
              color: AppColors.black,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // Navigate to search screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/svgs/category_screen/search_icon.svg',
                  width: 22.w,
                  height: 22.w,
                ),
              ),
            ),
            AppSpacing.w12,
          ],
        ),
      ),
    );
  }
}
