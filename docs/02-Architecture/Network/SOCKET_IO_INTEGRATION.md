# Socket.IO Real-Time Integration Guide

## Overview

This guide shows how to integrate Socket.IO for real-time price, inventory, and delivery location updates in your Flutter Grocery App.

### Architecture Flow

```
API Endpoint (Category Products)
         ↓
CategoryProductDto (contains variant_id)
         ↓
SocketService.joinVariantRoom(variant_id)
         ↓
Django Socket.IO Server
         ↓
PriceUpdateEvent / InventoryUpdateEvent
         ↓
Riverpod Notifiers (Update State)
         ↓
UI Listens to Changes
```

## Setup

### 1. Initialize Socket Service (App Level)

In your `main.dart` or bootstrap file, initialize the Socket.IO connection once:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/core/network/socket_provider.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize socket service on app startup
    ref.watch(socketServiceProvider);

    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
```

### 2. Join Variant Rooms in Category Products Screen

When displaying products, join their variant rooms:

```dart
// In category_screen.dart or product list widget

@override
void initState() {
  super.initState();

  // Get variants and join their rooms
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(socketServiceProvider).joinVariantRoom(variantId);
  });
}

@override
void dispose() {
  // Optional: Leave room when screen closes
  ref.read(socketServiceProvider).leaveVariantRoom(variantId);
  super.dispose();
}
```

### 3. Listen to Real-Time Price Updates in UI

```dart
// In product_list_item.dart or product card widget

class ProductCard extends ConsumerWidget {
  final int variantId;
  final String currentPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch price updates for this variant
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);
    final priceEvent = priceUpdates.getUpdate(variantId);

    // Display price: use real-time price if available, else current price
    final displayPrice = priceEvent?.newPrice.toString() ?? currentPrice;
    final oldPrice = priceEvent?.oldPrice?.toString();

    return Column(
      children: [
        Text(
          displayPrice,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        if (oldPrice != null)
          Text(
            oldPrice,
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }
}
```

### 4. Listen to Real-Time Inventory Updates

```dart
// In product details or product card

class InventoryBadge extends ConsumerWidget {
  final int variantId;
  final int currentQuantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch inventory updates for this variant
    final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);
    final inventoryEvent = inventoryUpdates.getUpdate(variantId);

    // Use real-time quantity or fallback to current quantity
    final quantity = inventoryEvent?.currentQuantity ?? currentQuantity;
    final isLowStock = quantity < 5;
    final outOfStock = quantity <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: outOfStock
            ? Colors.red
            : isLowStock
                ? Colors.orange
                : Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        outOfStock
            ? 'Out of Stock'
            : isLowStock
                ? 'Only $quantity left'
                : '$quantity in stock',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
```

### 5. Full Example: Category Products Screen Integration

```dart
// lib/features/category/presentation/screen/category_screen.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/core/network/socket_provider.dart';

class CategoryScreenBody extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryScreenBody({required this.categoryId});

  @override
  ConsumerState<CategoryScreenBody> createState() => _CategoryScreenBodyState();
}

class _CategoryScreenBodyState extends ConsumerState<CategoryScreenBody> {
  @override
  void initState() {
    super.initState();
    _joinVariantRooms();
  }

  /// Join Socket.IO rooms for all variants in this category
  void _joinVariantRooms() {
    // Get category products
    final productsAsync = ref.read(
      categoryProductsProvider(widget.categoryId),
    );

    productsAsync.whenData((products) {
      final socketService = ref.read(socketServiceProvider);

      for (final product in products) {
        // Extract variantId from CategoryProductDto
        final variantId = int.tryParse(product.variantId) ?? 0;
        if (variantId > 0) {
          socketService.joinVariantRoom(variantId);
        }
      }
    });
  }

  @override
  void dispose() {
    // Optional: Clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProductGridView(categoryId: widget.categoryId);
  }
}
```

### 6. Example: Product Card with Real-Time Updates

```dart
// lib/features/category/presentation/components/widgets/_product_card.dart

import 'package:grocery_app/core/network/socket_provider.dart';
import 'package:grocery_app/features/category/application/providers/price_update_notifier.dart';
import 'package:grocery_app/features/category/application/providers/inventory_update_notifier.dart';

class ProductCard extends ConsumerWidget {
  final CategoryProductDto product;

  const ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse variant ID
    final variantId = int.tryParse(product.variantId) ?? 0;

    // Watch price updates
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);
    final priceEvent = priceUpdates.getUpdate(variantId);

    // Watch inventory updates
    final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);
    final inventoryEvent = inventoryUpdates.getUpdate(variantId);

    // Determine display values
    final displayPrice = priceEvent?.newPrice ?? double.tryParse(product.price ?? '0');
    final originalPrice = priceEvent?.oldPrice ?? double.tryParse(product.originalPrice ?? '');
    final inStock = (inventoryEvent?.currentQuantity ?? 0) > 0;

    return GestureDetector(
      onTap: () {
        // Navigate to product details
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Image.network(
              product.imageUrl ?? '',
              height: 150,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  // Price with Real-Time Update
                  Row(
                    children: [
                      Text(
                        '\$${displayPrice?.toStringAsFixed(2) ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (originalPrice != null && originalPrice > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '\$${originalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      // Price update indicator
                      if (priceEvent != null)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.sync, size: 16, color: Colors.blue),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Stock Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: inStock ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      inStock ? 'In Stock' : 'Out of Stock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Server Events Reference

### Price Update Event

**Socket.IO Event:** `price_update`

**Data Structure:**
```json
{
  "variant_id": 5,
  "new_price": 900.00,
  "old_price": 1000.00,
  "discounted_price": 750.00
}
```

### Inventory Update Event

**Socket.IO Event:** `inventory_update`

**Data Structure:**
```json
{
  "variant_id": 5,
  "current_quantity": 22,
  "previous_quantity": 25,
  "current_stock_unit": "units",
  "warehouse_id": 1
}
```

### Delivery Location Event

**Socket.IO Event:** `delivery_location_update`

**Data Structure:**
```json
{
  "delivery_id": 101,
  "latitude": 40.7128,
  "longitude": -74.0060,
  "accuracy": 10.5,
  "timestamp": "2025-11-22T10:30:00Z"
}
```

## API to Socket.IO Flow

### Example: Category Products API Response

**API:** `http://156.67.104.149:8080/api/products/?category_id=1`

**Response:**
```json
{
  "results": [
    {
      "id": 1,
      "name": "Apple",
      "variants": [
        {
          "id": 5,            ← Use this as variant_id for Socket.IO
          "price": "900.00",
          "current_quantity": 22
        }
      ]
    }
  ]
}
```

**Integration Flow:**
1. Fetch products from API → `CategoryProductDto` (extracts `variant_id = 5`)
2. When product card renders → Join Socket.IO room: `socketService.joinVariantRoom(5)`
3. Server sends `price_update` → Real-time price displayed in UI
4. Server sends `inventory_update` → Real-time stock displayed in UI

## Best Practices

1. **Join rooms on product display**, not on app startup
2. **Leave rooms when products disappear** (offscreen, screen closed)
3. **Use consumer widgets** to automatically rebuild when updates come
4. **Cache variant IDs** to avoid repeated parsing
5. **Handle parsing errors** gracefully (already done in `socket_models.dart`)
6. **Monitor connection status** using `socketConnectionStatusProvider`

## Troubleshooting

### Socket not connecting?

```dart
// Check connection status
final isConnected = ref.watch(socketConnectionStatusProvider);

isConnected.when(
  data: (connected) {
    if (connected) {
      print('✅ Socket connected');
    } else {
      print('❌ Socket disconnected');
    }
  },
  error: (err, stack) => print('Error: $err'),
  loading: () => print('Checking connection...'),
);
```

### Price updates not showing?

1. Verify variant_id is correct (from API response)
2. Check logger output for `[INFO] Price Update Received:`
3. Ensure `listenForPriceUpdates()` is called
4. Verify server is broadcasting to correct room

### UI not rebuilding?

- Use `ConsumerWidget` or `ConsumerStatefulWidget`
- Watch the notifier: `ref.watch(priceUpdateNotifierProvider)`
- Ensure variant_id in state matches your product
