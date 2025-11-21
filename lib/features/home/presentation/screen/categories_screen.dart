// lib/features/categories/presentation/screen/categories_screen.dart

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:new_app/features/home/application/providers/home_provider.dart';
// import 'package:new_app/features/home/domain/entities/category.dart';
// import 'package:new_app/features/home/presentation/screen/category_detail_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: const Center(child: Text("category")));
  }
}
