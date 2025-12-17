import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';

class OtpField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const OtpField({super.key, required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
        enabled: enabled,
        textAlign: TextAlign.center,
        autofillHints: const [AutofillHints.oneTimeCode],
        style: TextStyle(
          fontSize: 18.sp,
          letterSpacing: 8,
          fontWeight: FontWeight.w600,
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'OTP is required';

          if (!RegExp(r'^\d{6}$').hasMatch(value!)) {
            return 'Enter valid 6-digit OTP';
          }

          return null;
        },
      ),
    );
  }
}
