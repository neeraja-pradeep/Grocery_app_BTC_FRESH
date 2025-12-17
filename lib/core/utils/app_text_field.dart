import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/colors.dart';

class AppTextField extends StatefulWidget {
  final bool isObscure;
  final String hintText;
  final IconData? icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.isObscure,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isObscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: AppColors.lightGrey,
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        counterText: '', // Hide the character counter
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
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: widget.icon != null
            ? IconButton(
                icon: Icon(
                  widget.isObscure
                      ? (_obscureText ? Icons.visibility_off : Icons.visibility)
                      : widget.icon,
                  color: Colors.grey,
                ),
                onPressed: widget.isObscure
                    ? () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      }
                    : null,
              )
            : null,
      ),
    );
  }
}
