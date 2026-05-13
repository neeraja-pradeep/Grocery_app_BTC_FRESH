// lib/features/categories/presentation/screen/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../category/presentation/screen/category_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac),
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(body: CategoryScreen()),
    );
  }
}
