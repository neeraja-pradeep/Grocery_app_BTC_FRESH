import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText(text: 'Sign in', maxLines: 1)),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.horizontal(24),
          vertical: AppSpacing.vertical(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(text: 'Welcome back', fontSize: 26.sp, maxLines: 1),
            AppSpacing.h24,
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            AppSpacing.h16,
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            AppSpacing.h24,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => FocusScope.of(context).unfocus(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.vertical(10),
                  ),
                  child: Text('Continue', style: TextStyle(fontSize: 16.sp)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
