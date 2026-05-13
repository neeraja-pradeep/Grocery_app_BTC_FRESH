// lib/features/home/presentation/screen/categories_with_sidebar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../category/presentation/screen/category_screen.dart';

class CategoriesWithSidebarScreen extends ConsumerWidget {
  final int? initialCategoryId;
  const CategoriesWithSidebarScreen({super.key, this.initialCategoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac),
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: CategoryScreen(
          initialCategoryId: initialCategoryId?.toString(),
        ),
      ),
    );
  }
}
