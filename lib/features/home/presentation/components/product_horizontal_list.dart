import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product_variant.dart';
import 'product_card.dart';

class ProductHorizontalList extends ConsumerWidget {
  final List<ProductVariant> products;
  final ValueChanged<ProductVariant> onProductClick;

  const ProductHorizontalList({
    super.key,
    required this.products,
    required this.onProductClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 220, // Adjusted to match 200h + padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Vertical padding ensures the floating "+" button isn't cut off
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        clipBehavior: Clip.none,
        itemCount: products.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ProductCard(
              product: products[index],
              onTap: () => onProductClick(products[index]),
              width: 140, // Match wishlist card width
            ),
          );
        },
      ),
    );
  }
}
