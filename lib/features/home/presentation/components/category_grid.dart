// lib/features/home/presentation/components/category_grid.dart

import 'package:flutter/material.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/presentation/components/category_tile.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onCategoryClick;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryClick,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    // Calculate height based on rows (Assuming 4 columns, ~100px height per item including spacing)
    // This prevents the GridView from taking infinite height in a ScrollView without shrinkWrap
    // But explicit height is safer for performance than shrinkWrap: true
    return Container(
      // Dynamic height: (rows * itemHeight) + spacing
      // 2 rows max for home screen usually
      height: categories.length > 4 ? 240 : 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75, // Controls height of tile vs width
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryTile(
            category: categories[index],
            onTap: () => onCategoryClick(categories[index]),
          );
        },
      ),
    );
  }
}
