// lib/features/categories/presentation/screen/category_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/features/home/domain/entities/category.dart';

class CategoryDetailScreen extends StatelessWidget {
  final Category category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac), // Custom green color
        statusBarIconBrightness: Brightness.dark, // Dark icons
      ),
      child: Scaffold(body: Center(child: Text("category"))),
    );
  }
}
