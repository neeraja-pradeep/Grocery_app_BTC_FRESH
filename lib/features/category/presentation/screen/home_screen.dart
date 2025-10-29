import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grocery', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.horizontal(24),
          vertical: AppSpacing.vertical(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(text: 'Welcome back!', fontSize: 28.sp, maxLines: 2),
            AppSpacing.h12,
            AppText(
              text: 'Start exploring fresh products tailored for you.',
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              maxLines: 3,
            ),
            AppSpacing.h24,
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRouter.login),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.horizontal(12),
                  vertical: AppSpacing.vertical(8),
                ),
                child: Text('Go to login', style: TextStyle(fontSize: 16.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
