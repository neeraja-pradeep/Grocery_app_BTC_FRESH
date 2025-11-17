// features/home/presentation/components/category_grid.dart

// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// IMPORT REAL PROVIDERS and ENTITIES
import 'package:new_app/features/home/application/providers/home_provider.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/presentation/screen/category_detail_screen.dart';

// --- DUMMY DEFINITIONS REMOVED ---

class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WATCH THE REAL PROVIDER
    final categories = ref.watch(categoriesProvider);

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Inline Component: CategoryCard
    Widget buildCategoryCard(Category category) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryDetailScreen(category: category),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: category.iconUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadiusGeometry.all(
                        Radius.circular(10),
                      ),
                      child: Image.network(
                        category.iconUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // print(
                          //   'Category image load error for ${category.name}: $error',
                          // );
                          return const Icon(
                            Icons.category,
                            color: Colors.green,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.category, color: Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        // Cast is technically only necessary if generics are lost, but good practice if using List<dynamic> from FutureProvider's .data
        return buildCategoryCard(categories[index]);
      },
    );
  }
}
