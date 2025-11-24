import 'package:flutter/material.dart';

class OtpField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const OtpField({super.key, required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
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
      keyboardType: TextInputType.number,
      maxLength: 6,
      enabled: enabled,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 8,
        fontWeight: FontWeight.bold,
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'OTP is required';

        if (!RegExp(r'^\d{6}$').hasMatch(value!)) {
          return 'Enter valid 6-digit OTP';
        }

        return null;
      },
    );
  }
}
