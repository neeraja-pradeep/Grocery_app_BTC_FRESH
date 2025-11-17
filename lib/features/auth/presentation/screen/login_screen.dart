// lib/features/auth/presentation/screen/login_screen.dart

import 'package:flutter/material.dart';
import '../components/header_section.dart';

/// Login screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthHeaderSection(
              title: 'Welcome Back',
              subtitle: 'Sign in to your account',
            ),
            // TODO: Add login form
          ],
        ),
      ),
    );
  }
}
