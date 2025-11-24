import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final bool isObscure;
  final String hintText;
  final IconData? icon;
  final TextEditingController controller;
  const AppTextField({
    super.key,
    required this.isObscure,
    required this.hintText,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
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
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: Icon(icon),
      ),
    );
  }
}
