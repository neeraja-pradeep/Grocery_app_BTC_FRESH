// lib/features/categories/presentation/screen/category_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../category/presentation/screen/category_screen.dart';
import '../../domain/entities/category.dart';

class CategoryDetailScreen extends StatelessWidget {
  final Category category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac),
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: CategoryScreen(initialCategoryId: category.id.toString()),
      ),
    );
  }
}
