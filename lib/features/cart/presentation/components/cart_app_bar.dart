import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';

/// Reusable green app bar for cart screens
class CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CartAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 42.h, color: AppColors.green60);
  }

  @override
  Size get preferredSize => Size.fromHeight(42.h);
}
