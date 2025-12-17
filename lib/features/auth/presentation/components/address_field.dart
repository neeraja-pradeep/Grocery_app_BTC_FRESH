import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

class AddressField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  const AddressField({super.key, required this.hint, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: AppColors.grey,
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.grey),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
        focusColor: AppColors.titleColor,
        hoverColor: AppColors.titleColor,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.titleColor, width: 1.5),
        ),
      ),
    );
  }
}
