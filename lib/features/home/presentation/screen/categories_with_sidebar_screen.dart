// lib/features/home/presentation/screen/categories_with_sidebar_screen.dart

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/home/application/providers/home_provider.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
// import 'package:new_app/features/home/domain/entities/product.dart';
// import 'package:new_app/features/home/presentation/components/category_sidebar.dart';
// import 'package:new_app/features/home/presentation/components/product_card.dart';
// import 'package:new_app/features/wishlist/application/providers/wishlist_provider.dart';

class CategoriesWithSidebarScreen extends ConsumerStatefulWidget {
  const CategoriesWithSidebarScreen({super.key});

  @override
  ConsumerState<CategoriesWithSidebarScreen> createState() =>
      _CategoriesWithSidebarScreenState();
}

class _CategoriesWithSidebarScreenState
    extends ConsumerState<CategoriesWithSidebarScreen> {
  Category? selectedCategory;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Select first category by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoriesProvider);
      if (categories.isNotEmpty && selectedCategory == null) {
        setState(() {
          selectedCategory = categories.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const Center(child: Text("category")));
  }
}
