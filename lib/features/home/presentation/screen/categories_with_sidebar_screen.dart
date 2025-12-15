// lib/features/home/presentation/screen/categories_with_sidebar_screen.dart

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/home_provider.dart';
import '../../domain/entities/category.dart';
// import 'package:grocery_app/features/home/domain/entities/product.dart';
// import 'package:grocery_app/features/home/presentation/components/category_sidebar.dart';
// import 'package:grocery_app/features/home/presentation/components/product_card.dart';
// import 'package:grocery_app/features/wishlist/application/providers/wishlist_provider.dart';

class CategoriesWithSidebarScreen extends ConsumerStatefulWidget {
  final int? initialCategoryId;
  const CategoriesWithSidebarScreen({super.key, this.initialCategoryId});

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
      if (widget.initialCategoryId != null) {
        final match = categories.firstWhere(
          (cat) => cat.id == widget.initialCategoryId,
          orElse: () => categories.first,
        );
        setState(() => selectedCategory = match);
        return;
      }

      // Otherwise select first category by default
      if (categories.isNotEmpty && selectedCategory == null) {
        setState(() => selectedCategory = categories.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac), // Custom green color
        statusBarIconBrightness: Brightness.dark, // Dark icons
      ),
      child: Scaffold(
        body: SafeArea(child: const Center(child: Text('category'))),
      ),
    );
  }
}
