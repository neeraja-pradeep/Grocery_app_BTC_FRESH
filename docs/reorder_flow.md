# Reorder Flow - Complete Documentation

## Overview

The Reorder feature allows users to quickly re-purchase items from their previous orders. When a user taps "Reorder" on a completed order, all products from that order are automatically added to their cart with the original quantities, and they're navigated to the cart screen.

---

## Architecture

### Files Involved

```
lib/
├── features/
│   ├── orders/
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── order_entity.dart              # OrderEntity, OrderLineEntity
│   │   ├── application/
│   │   │   └── providers/
│   │   │       └── orders_provider.dart           # Orders state management
│   │   ├── infrastructure/
│   │   │   └── data_sources/
│   │   │       └── orders_api.dart                # API calls for orders
│   │   └── presentation/
│   │       └── screens/
│   │           └── orders_screen.dart             # Reorder button & logic
│   ├── cart/
│   │   └── application/
│   │       └── providers/
│   │           └── checkout_line_provider.dart    # Cart management
│   └── bottomnavbar/
│       └── bottom_navbar.dart                     # Navigation handler
└── core/
    └── network/
        └── endpoints.dart                         # API endpoint definitions
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              REORDER FLOW                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│   OrdersScreen       │
│   (Previous Tab)     │
│                      │
│   User taps          │
│   "Reorder" button   │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  _handleReorder(OrderEntity order)                            │
│                                                               │
│  1. Show loading indicator: "Loading order items..."          │
│  2. Fetch order lines from API                                │
│     ordersApi.getOrderLines(order.id)                         │
│  3. Validate order lines not empty                            │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  OrdersApi.getOrderLines(orderId)                             │
│                                                               │
│  1. Call: /api/order/v1/order-lines/?order={orderId}         │
│  2. Parse paginated response {count, results[]}               │
│  3. Filter results where orderLine.orderId == orderId         │
│     (Client-side filtering for data consistency)              │
│  4. Return List<OrderLineEntity>                              │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Loop through orderLines                                      │
│                                                               │
│  for (final orderLine in orderLines) {                        │
│    // Skip invalid products                                   │
│    if (orderLine.productVariantId <= 0) continue;             │
│                                                               │
│    // Add to cart with original quantity                      │
│    await checkoutLineNotifier.addToCart(                      │
│      productVariantId: orderLine.productVariantId,            │
│      quantity: orderLine.quantity,                            │
│    );                                                         │
│  }                                                            │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  CheckoutLineController.addToCart()                           │
│                                                               │
│  For each product:                                            │
│  1. Check if already in cart                                  │
│     - If YES: Update quantity (PATCH /checkout-lines/{id}/)   │
│     - If NO: Add new item (POST /checkout-lines/)             │
│  2. Refresh cart state                                        │
│  3. Update UI automatically via Riverpod                      │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Navigate to Cart Tab                                         │
│                                                               │
│  1. Pop current screen: Navigator.pop(context)                │
│  2. Navigate to cart via bottom navigation:                   │
│     BottomNavigation.globalKey.currentState?.navigateToTab(3) │
│  3. Show success message:                                     │
│     "{count} items added to cart"                             │
└───────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### OrderEntity Structure

```dart
class OrderEntity {
  final int id;                      // Order ID
  final String status;               // 'delivered', 'active', 'pending', etc.
  final double totalAmount;          // Total order cost
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderLineEntity> orderLines;  // Products (may be empty in list view)
  final OrderAddressEntity? deliveryAddress;
  final int orderlinesCount;         // *** Count from API, not array length

  // Getters
  bool get isCompleted => status.toLowerCase() == 'completed' ||
                         status.toLowerCase() == 'delivered';
}
```

### OrderLineEntity Structure

```dart
class OrderLineEntity {
  final int id;                      // Order line ID
  final int orderId;                 // *** Parent order ID (for filtering)
  final int productVariantId;        // Product variant to add to cart
  final String productName;
  final String? productImage;
  final int quantity;                // *** Original quantity to reorder
  final double price;                // Price at time of order
  final double totalPrice;           // price × quantity
}
```

**Key Points:**
- `orderId` field added to filter order lines correctly
- `orderlinesCount` comes from API response, not `orderLines.length`
- Orders list endpoint doesn't include full `orderLines` array

---

## API Integration

### Endpoint: Get Order Lines by Order ID

```
GET /api/order/v1/order-lines/?order={orderId}
```

**Request Example:**
```http
GET /api/order/v1/order-lines/?order=66
Cookie: sessionid=...; csrftoken=...
```

**Response Structure (Paginated):**
```json
{
  "count": 8,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 71,
      "order": 66,                    // Order ID
      "product_variant": 2,           // Product variant ID
      "product_variant_details": {
        "id": 2,
        "name": "Apple",
        "price": "200.00",
        "current_quantity": 1937,
        ...
      },
      "quantity": 1                   // Quantity ordered
    },
    {
      "id": 72,
      "order": 66,
      "product_variant": 19,
      "quantity": 2
    }
  ]
}
```

**Important Notes:**
1. API returns **paginated response** with `results` array
2. Response may include order lines from **multiple orders** (API quirk)
3. **Client-side filtering required**: Filter where `order == orderId`
4. Each `product_variant_details` contains full product information

### Implementation in orders_api.dart

```dart
Future<List<OrderLineEntity>> getOrderLines(String orderId) async {
  final response = await _apiClient.get(
    ApiEndpoints.orderLinesByOrder(orderId),
  );

  if (response.statusCode == 200 && response.data != null) {
    // Parse paginated response
    final data = response.data as Map<String, dynamic>;
    final results = data['results'] as List? ?? [];

    final orderIdInt = int.parse(orderId);

    // *** CRITICAL: Filter to only include order lines for this order
    return results
        .map((e) => OrderLineEntity.fromJson(e as Map<String, dynamic>))
        .where((orderLine) => orderLine.orderId == orderIdInt)
        .toList();
  }

  throw Exception('Failed to load order lines');
}
```

**Why Filtering is Necessary:**
- API may return order lines from different orders
- Without filtering, duplicate products get added multiple times
- Ensures only the requested order's items are reordered

---

## State Management

### Orders Provider

```dart
final ordersControllerProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final ordersApi = ref.watch(ordersApiProvider);
  return OrdersNotifier(ordersApi);
});
```

**Key Methods:**
- `fetchActiveOrders()` - Fetch orders with status='active'
- `fetchCompletedOrders()` - Fetch orders with status='delivered'
- `refresh()` - Refresh current order list

### Cart Provider

```dart
final checkoutLineControllerProvider =
    StateNotifierProvider<CheckoutLineController, CheckoutLineState>((ref) {
  final dataSource = ref.watch(checkoutLineDataSourceProvider);
  return CheckoutLineController(dataSource);
});
```

**Key Methods:**
- `addToCart(productVariantId, quantity)` - Add item or update quantity
- `refreshCart()` - Reload cart from API
- State automatically updates UI via Riverpod

---

## UI Implementation

### Reorder Button Location

```dart
// In orders_screen.dart - _OrderCard widget
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    // View Details Button
    OutlinedButton(
      onPressed: () => _navigateToOrderDetails(order.id),
      child: Text('View Details'),
    ),

    SizedBox(width: 8.w),

    // Reorder Button (only for completed orders)
    if (order.isCompleted)
      ElevatedButton(
        onPressed: () => _handleReorder(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.refresh, size: 16.sp),
            SizedBox(width: 4.w),
            Text('Reorder'),
          ],
        ),
      ),
  ],
)
```

### Reorder Handler Implementation

```dart
/// Reorders items from a previous order
/// Fetches order lines from order-lines endpoint, adds items to cart with
/// original quantities, then navigates to cart tab
Future<void> _handleReorder(OrderEntity order) async {
  // Show loading indicator
  if (mounted) {
    AppSnackbar.info(context, 'Loading order items...');
  }

  try {
    // 1. Fetch order lines from the order-lines endpoint
    final ordersApi = ref.read(ordersApiProvider);
    final orderLines = await ordersApi.getOrderLines(order.id.toString());

    // 2. Validate order has items
    if (orderLines.isEmpty) {
      if (mounted) {
        AppSnackbar.warning(context, 'This order has no items to reorder');
      }
      return;
    }

    // 3. Show progress message
    if (mounted) {
      AppSnackbar.info(context, 'Adding ${orderLines.length} items to cart...');
    }

    // 4. Get cart controller
    final checkoutLineNotifier = ref.read(
      checkoutLineControllerProvider.notifier,
    );

    int successCount = 0;
    int failedCount = 0;

    // 5. Add each item from the order to cart with original quantities
    for (final orderLine in orderLines) {
      // Skip items with invalid product variant ID
      if (orderLine.productVariantId <= 0) {
        failedCount++;
        Logger.warning(
          'Skipping item with invalid variant ID: ${orderLine.productName}',
        );
        continue;
      }

      try {
        // Add to cart (will auto-update if already exists)
        await checkoutLineNotifier.addToCart(
          productVariantId: orderLine.productVariantId,
          quantity: orderLine.quantity,
        );

        successCount++;
        Logger.info('Added item to cart for reorder', data: {
          'product_variant_id': orderLine.productVariantId,
          'product_name': orderLine.productName,
          'quantity': orderLine.quantity,
        });
      } catch (e) {
        failedCount++;
        Logger.error('Failed to add item to cart', error: e);
      }
    }

    // 6. Show result message
    if (mounted) {
      if (successCount > 0) {
        AppSnackbar.success(
          context,
          '$successCount items added to cart',
        );

        // Navigate to cart tab via bottom navigation
        _navigateToCart();
      } else {
        AppSnackbar.error(
          context,
          'Failed to add items to cart. Please try again.',
        );
      }
    }
  } catch (e) {
    Logger.error('Reorder failed', error: e);
    if (mounted) {
      AppSnackbar.error(context, 'Failed to reorder. Please try again.');
    }
  }
}

/// Navigate to cart tab using bottom navigation
void _navigateToCart() {
  // Pop current screen
  Navigator.of(context).pop();

  // Navigate to cart tab (index 3)
  BottomNavigation.globalKey.currentState?.navigateToTab(3);
}
```

---

## Navigation Flow

### Bottom Navigation Integration

The app uses `BottomNavigation` with a global key to allow programmatic tab switching:

```dart
// In bottom_navbar.dart
class BottomNavigation extends ConsumerStatefulWidget {
  static final globalKey = GlobalKey<_BottomNavigationState>();

  const BottomNavigation({Key? key}) : super(key: key ?? globalKey);
}

// Navigation method
void navigateToTab(int index) {
  setState(() {
    _currentIndex = index;
  });
}
```

**Tab Indices:**
- 0: Home
- 1: Category
- 2: Wishlist
- **3: Cart** ← Reorder navigates here

### Navigation Methods Used

| Action | Method | Reason |
|--------|--------|--------|
| Close orders screen | `Navigator.pop(context)` | Return to previous screen |
| Go to cart | `BottomNavigation.globalKey.currentState?.navigateToTab(3)` | Navigate to cart tab |

**Why use globalKey instead of go_router?**
- Maintains bottom navigation state
- Smooth tab transition
- Cart badge updates automatically
- User can easily navigate back using bottom nav

---

## Error Handling

### Validation Checks

```dart
// 1. Empty order lines check
if (orderLines.isEmpty) {
  AppSnackbar.warning(context, 'This order has no items to reorder');
  return;
}

// 2. Invalid product variant ID
if (orderLine.productVariantId <= 0) {
  failedCount++;
  Logger.warning('Skipping item with invalid variant ID');
  continue;
}

// 3. API errors
try {
  await checkoutLineNotifier.addToCart(...);
} catch (e) {
  failedCount++;
  Logger.error('Failed to add item to cart', error: e);
}
```

### User Feedback

**Loading States:**
```dart
AppSnackbar.info(context, 'Loading order items...');
AppSnackbar.info(context, 'Adding ${orderLines.length} items to cart...');
```

**Success:**
```dart
AppSnackbar.success(context, '$successCount items added to cart');
```

**Errors:**
```dart
AppSnackbar.warning(context, 'This order has no items to reorder');
AppSnackbar.error(context, 'Failed to reorder. Please try again.');
```

---

## Key Implementation Details

### 1. Why Filter Order Lines Client-Side?

**Problem:** API endpoint `/api/order/v1/order-lines/?order=66` may return order lines from multiple orders (API inconsistency).

**Solution:**
```dart
return results
    .map((e) => OrderLineEntity.fromJson(e))
    .where((orderLine) => orderLine.orderId == orderIdInt)  // ← Filter here
    .toList();
```

**Without filtering:**
- Same product added multiple times
- Incorrect quantities in cart
- User confusion

### 2. Why Add `orderId` to OrderLineEntity?

```dart
class OrderLineEntity {
  final int orderId;  // ← New field for filtering
  ...
}

// In fromJson:
orderId: json['order'] as int? ?? 0,
```

**Enables client-side filtering to ensure data consistency.**

### 3. Why Use `orderlinesCount` Instead of `orderLines.length`?

**Orders List Endpoint Response:**
```json
{
  "id": 66,
  "orderlines_count": 8,  // ← Use this
  "order_lines": []        // ← Empty in list view!
}
```

**Entity Definition:**
```dart
final int orderlinesCount = json['orderlines_count'] as int? ??
                            orderLinesList.length;  // Fallback
```

**Why:** API doesn't include full order_lines array in list endpoint to reduce payload size.

### 4. Why Pop Before Navigate?

```dart
void _navigateToCart() {
  Navigator.of(context).pop();  // ← Close orders screen first
  BottomNavigation.globalKey.currentState?.navigateToTab(3);
}
```

**Ensures clean navigation stack** - user can easily return to home via bottom nav.

---

## Testing the Flow

### Manual Test Steps

1. **Setup:**
   - Ensure user has completed orders with status='delivered'
   - Log in to authenticated account

2. **Navigate to Orders:**
   - Open Profile → Order History
   - Switch to "Previous" tab
   - Verify completed orders are displayed

3. **Initiate Reorder:**
   - Tap "Reorder" button on any completed order
   - Observe: "Loading order items..." snackbar appears

4. **Verify Cart Addition:**
   - Wait for "X items added to cart" success message
   - Observe: Automatically navigated to Cart tab
   - Check: Cart badge shows updated item count

5. **Verify Cart Contents:**
   - Check cart items match original order products
   - Verify quantities match original order
   - Confirm prices are current (not historical)

6. **Edge Cases:**
   - Try reordering an order with unavailable products
   - Reorder same order twice (should update quantities)
   - Reorder while cart already has items

### Debug Logging

```dart
// In orders_api.dart
Logger.info('Fetched order lines', data: {
  'order_id': orderId,
  'count': orderLines.length,
  'filtered_count': filteredLines.length,
});

// In orders_screen.dart
Logger.info('Added item to cart for reorder', data: {
  'product_variant_id': orderLine.productVariantId,
  'product_name': orderLine.productName,
  'quantity': orderLine.quantity,
});
```

### Network Debugging

Monitor API calls in logs:
```
*** Request ***
uri: http://156.67.104.149:8080/api/order/v1/order-lines/?order=66
method: GET

*** Response ***
{"count":8,"next":null,"previous":null,"results":[...]}
```

---

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Duplicate items in cart | No client-side filtering | Add `where((orderLine) => orderLine.orderId == orderIdInt)` |
| "No items to reorder" error | API returned order lines from different orders | Verify filtering logic is applied |
| Wrong item count on UI | Using `orderLines.length` instead of API field | Use `orderlinesCount` from JSON |
| Navigation doesn't work | Missing globalKey setup | Ensure `BottomNavigation.globalKey` is initialized |
| Items not appearing in cart | API error or network issue | Check logs for API response errors |
| Quantities incrementing on multiple taps | No loading state guard | Disable button while loading |

---

## Future Enhancements

1. **Unavailable Products Handling:**
   - Show which products are out of stock
   - Option to remove unavailable items or substitute

2. **Modified Pricing Notification:**
   - Alert user if prices have changed since original order
   - Show price difference

3. **Partial Reorder:**
   - Allow selecting specific items to reorder
   - Checkbox selection UI

4. **Quick Reorder from Order Details:**
   - Add reorder button on order details screen
   - Reorder individual items

5. **Reorder History:**
   - Track which orders were reordered
   - Show "Reordered on {date}" label

6. **Cart Merge Strategy:**
   - Ask user: "Replace cart" vs "Add to existing cart"
   - Option to clear cart before reorder

7. **Offline Support:**
   - Cache recent orders for offline reordering
   - Queue reorder action when back online

---

## Related Documentation

- [Delivery Status Flow](./delivery_status_flow.md)
- [Payment Flow](./payment_flow.md)
- [Cart Management](../features/cart/README.md)
- [API Integration](./API%20Integration%20Document%20-%20BTC%20Grocery.md)
