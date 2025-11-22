import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/network/socket_provider.dart';
import '../../../application/providers/inventory_update_notifier.dart';
import '../../../application/providers/price_update_notifier.dart';
import '../../../domain/entities/category_product.dart';

/// Example implementation of product card with real-time Socket.IO updates
///
/// This shows:
/// - How to join variant rooms
/// - How to listen for price updates
/// - How to listen for inventory updates
/// - How to display real-time data in UI
class ProductCardWithSocketIO extends ConsumerStatefulWidget {
  final CategoryProduct product;
  final VoidCallback onTap;

  const ProductCardWithSocketIO({
    required this.product,
    required this.onTap,
    super.key,
  });

  @override
  ConsumerState<ProductCardWithSocketIO> createState() =>
      _ProductCardWithSocketIOState();
}

class _ProductCardWithSocketIOState
    extends ConsumerState<ProductCardWithSocketIO> {
  late int variantId;

  @override
  void initState() {
    super.initState();
    // Parse variant ID from product
    variantId = int.tryParse(widget.product.variantId) ?? 0;

    // Join the variant room on mount
    if (variantId > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(socketServiceProvider).joinVariantRoom(variantId);
      });
    }
  }

  @override
  void dispose() {
    // Optional: Leave room when card is disposed
    if (variantId > 0) {
      ref.read(socketServiceProvider).leaveVariantRoom(variantId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch price updates for this variant
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);
    final priceEvent = priceUpdates.getUpdate(variantId);

    // Watch inventory updates for this variant
    final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);
    final inventoryEvent = inventoryUpdates.getUpdate(variantId);

    // Determine display values
    final displayPrice =
        priceEvent?.newPrice ?? double.tryParse(widget.product.price ?? '0');
    final originalPrice =
        priceEvent?.oldPrice ??
        double.tryParse(widget.product.originalPrice ?? '');
    final inStock = (inventoryEvent?.currentQuantity ?? 0) > 0;
    final quantity = inventoryEvent?.currentQuantity ?? 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container with Real-Time Indicator
            Stack(
              children: [
                // Product Image
                Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: widget.product.imageUrl != null
                      ? Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : const Center(child: Icon(Icons.shopping_bag)),
                ),
                // Real-Time Update Indicator
                if (priceEvent != null || inventoryEvent != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sync,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    // Variant Name (if different from product name)
                    if (widget.product.variantName != widget.product.name)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.product.variantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Price Row with Real-Time Updates
                    Row(
                      children: [
                        // Current Price
                        Text(
                          displayPrice != null
                              ? '\$${displayPrice.toStringAsFixed(2)}'
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),

                        // Original Price (crossed out)
                        if (originalPrice != null && originalPrice > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '\$${originalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Stock Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStockColor(inStock, quantity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            inStock ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStockText(inStock, quantity),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Real-time indicator for inventory
                          if (inventoryEvent != null)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.info,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get stock status color based on availability
  Color _getStockColor(bool inStock, int quantity) {
    if (!inStock) return Colors.red;
    if (quantity < 5) return Colors.orange;
    return Colors.green;
  }

  /// Get stock status text
  String _getStockText(bool inStock, int quantity) {
    if (!inStock) return 'Out of Stock';
    if (quantity < 5) return 'Only $quantity left';
    return 'In Stock';
  }
}

/// Example: Integration in ProductGrid
///
/// Replace your existing _product_card.dart usage with ProductCardWithSocketIO
class ProductGridExample extends ConsumerWidget {
  final List<CategoryProduct> products;

  const ProductGridExample({required this.products, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optional: Join all variant rooms at once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final variantIds = products
          .map((p) => int.tryParse(p.variantId) ?? 0)
          .where((id) => id > 0)
          .toList();

      if (variantIds.isNotEmpty) {
        ref.read(socketServiceProvider).socket;
        for (final variantId in variantIds) {
          ref.read(socketServiceProvider).joinVariantRoom(variantId);
        }
      }
    });

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCardWithSocketIO(
          product: product,
          onTap: () {
            // Navigate to product details
            // Navigator.push(...)
          },
        );
      },
    );
  }
}
