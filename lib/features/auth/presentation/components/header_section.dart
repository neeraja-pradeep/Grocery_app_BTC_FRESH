// lib/features/auth/presentation/components/header_section.dart

import 'package:flutter/material.dart';

/// Authentication header section
class AuthHeaderSection extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeaderSection({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
