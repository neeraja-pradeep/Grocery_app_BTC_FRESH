import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

class MobileNumberField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const MobileNumberField({
    super.key,
    required this.controller,
    required this.enabled,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      cursorColor: AppColors.grey,
      decoration: InputDecoration(
        hintText: 'Mobile Number',
        hintStyle: const TextStyle(color: AppColors.grey),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondaryGreenLogo),
        ),
        enabledBorder: OutlineInputBorder(
          gapPadding: 2,
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.secondaryGreenLogo),
        ),
        border: OutlineInputBorder(
          gapPadding: 2,
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.secondaryGreenLogo),
        ),
      ),
      keyboardType: TextInputType.phone,
      maxLength: 10,
      enabled: enabled,

      validator: (value) {
        if (value?.isEmpty ?? true) return 'Mobile number is required';
        if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
          return 'Enter valid 10-digit mobile number';
        }
        return null;
      },
    );
  }
}
