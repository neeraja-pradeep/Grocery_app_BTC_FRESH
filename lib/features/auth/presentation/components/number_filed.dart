import 'package:flutter/material.dart';

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
      decoration: InputDecoration(
        hintText: "Mobile Number",
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xff84C318)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xff84C318)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xff84C318)),
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
