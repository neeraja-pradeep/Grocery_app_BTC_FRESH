// lib/features/home/presentation/components/category_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/category.dart';
import 'category_tile.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<int> onCategoryClick;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryClick,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 6.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 0.55,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryTile(
            category: categories[index],
            onTap: () => onCategoryClick(categories[index].id),
          );
        },
      ),
    );
  }
}

