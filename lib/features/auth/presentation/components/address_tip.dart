import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

class AddressTip extends StatelessWidget {
  const AddressTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),

      child: const Center(
        child: Text(
          'A Detailed address will help our delivery partner reach your doorstep easily',

          style: TextStyle(
            fontSize: 14,
            color: AppColors.titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
