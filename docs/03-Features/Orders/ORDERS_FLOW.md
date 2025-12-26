# Orders Flow - Complete Documentation

## Overview

The Orders Flow handles viewing order history, order details, order tracking, and reordering. Users can see past orders, track active deliveries, rate completed orders, and quickly reorder previous purchases.

---

## Architecture

### Files Involved

```
lib/
├── features/
│   ├── orders/
│   │   ├── application/
│   │   │   ├── providers/
│   │   │   │   └── orders_provider.dart         # Orders state management
│   │   │   └── states/
│   │   │       └── orders_state.dart            # Orders state
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── order.dart                   # Order entity
│   │   │       └── order_item.dart              # Order line item
│   │   ├── infrastructure/
│   │   │   └── data_sources/
│   │   │       └── orders_api.dart              # API calls
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── orders_screen.dart           # Order history list
│   │       │   └── order_details_screen.dart    # Single order view
│   │       └── components/
│   │           ├── order_card.dart              # Order summary card
│   │           ├── order_status_badge.dart      # Status indicator
│   │           └── order_item_row.dart          # Item in order
│   ├── home/
│   │   └── application/
│   │       └── providers/
│   │           └── delivery_status_provider.dart # Active delivery tracking
│   └── category/
│       └── presentation/
│           └── components/
│               └── widgets/
│                   └── review_bottom_sheet.dart  # Rating after delivery
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            ORDERS FLOW                                       │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                          VIEW ORDER HISTORY                                  │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│  Profile Screen         │
│  or Menu                │
│                         │
│  User taps "My Orders"  │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  OrdersScreen                                                    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  AppBar: "My Orders"                                         │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  State: Loading                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Shimmer loading placeholders                                │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  State: Empty                                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  EmptyState: "No orders yet"                                 │ │
│  │  [Start Shopping] button                                     │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  State: Loaded                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  ListView of OrderCards                                      │ │
│  │                                                              │ │
│  │  ┌─────────────────────────────────────────────────────────┐│ │
│  │  │ Order #123          Dec 20, 2025    [Delivered] ✓      ││ │
│  │  │ 3 items • ₹450.00                                       ││ │
│  │  │ [View Details]  [Reorder]  [Rate ⭐]                    ││ │
│  │  └─────────────────────────────────────────────────────────┘│ │
│  │                                                              │ │
│  │  ┌─────────────────────────────────────────────────────────┐│ │
│  │  │ Order #122          Dec 18, 2025    [Out for Delivery] ││ │
│  │  │ 5 items • ₹780.00                                       ││ │
│  │  │ [View Details]  [Track Order]                           ││ │
│  │  └─────────────────────────────────────────────────────────┘│ │
│  │                                                              │ │
│  │  ┌─────────────────────────────────────────────────────────┐│ │
│  │  │ Order #121          Dec 15, 2025    [Cancelled] ✗      ││ │
│  │  │ 2 items • ₹320.00                                       ││ │
│  │  │ [View Details]  [Reorder]                               ││ │
│  │  └─────────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                          VIEW ORDER DETAILS                                  │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│  User taps "View Details"│
│  on an OrderCard         │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  OrderDetailsScreen                                              │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Order #123                              [Delivered] ✓       │ │
│  │  Placed on Dec 20, 2025 at 10:30 AM                          │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Order Status Timeline                                       │ │
│  │  ● Order Placed      - Dec 20, 10:30 AM                      │ │
│  │  ● Confirmed         - Dec 20, 10:35 AM                      │ │
│  │  ● Out for Delivery  - Dec 20, 02:00 PM                      │ │
│  │  ● Delivered         - Dec 20, 03:15 PM                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Items (3)                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────┐│ │
│  │  │ [🍎] Organic Apples    2 x ₹120     ₹240.00            ││ │
│  │  │ [🥕] Carrots           1 x ₹50      ₹50.00             ││ │
│  │  │ [🥛] Milk              2 x ₹80      ₹160.00            ││ │
│  │  └─────────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Delivery Address                                            │ │
│  │  123 Main St, Apt 4B                                         │ │
│  │  Mumbai, 400001                                              │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Payment Summary                                             │ │
│  │  Subtotal:        ₹450.00                                    │ │
│  │  Delivery Fee:    ₹40.00                                     │ │
│  │  Discount:        -₹40.00                                    │ │
│  │  ─────────────────────────                                   │ │
│  │  Total:           ₹450.00                                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  [Reorder All Items]                                         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                              REORDER                                         │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│  User taps "Reorder"     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Reorder Flow                                                    │
│                                                                  │
│  1. Show loading indicator                                       │
│                                                                  │
│  2. For each item in order:                                      │
│     - Check if product still exists                              │
│     - Check if in stock                                          │
│     - Add to cart with same quantity                             │
│                                                                  │
│  3. Handle unavailable items:                                    │
│     - Show dialog: "Some items are unavailable"                  │
│     - List unavailable items                                     │
│     - "Continue with available items" button                     │
│                                                                  │
│  4. Navigate to Cart                                             │
│     - Show success: "X items added to cart"                      │
│     - BottomNavigation.navigateToTab(3)                         │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                          RATE ORDER                                          │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│  Delivery Completed      │
│  or User taps "Rate"     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  ReviewBottomSheet                                               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  How was your experience?                                    │ │
│  │                                                              │ │
│  │       ⭐ ⭐ ⭐ ⭐ ⭐                                          │ │
│  │       1  2  3  4  5                                          │ │
│  │                                                              │ │
│  │  ┌─────────────────────────────────────────────────────────┐│ │
│  │  │  Add a comment (optional)                                ││ │
│  │  │  _______________________________________________         ││ │
│  │  └─────────────────────────────────────────────────────────┘│ │
│  │                                                              │ │
│  │  [Submit Rating]                                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Submit Rating API                                               │
│                                                                  │
│  POST /api/order/v1/orders/{orderId}/rating/                    │
│  { "rating": 5, "comment": "Great service!" }                   │
│                                                                  │
│  OR (if updating existing rating)                                │
│  PATCH /api/order/v1/orders/{orderId}/rating/{ratingId}/        │
│  { "rating": 4, "comment": "Good, but late" }                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### 1. Get Order History

**Endpoint:**
```
GET /api/order/v1/orders/
```

**Response:**
```json
{
  "count": 15,
  "next": "...?page=2",
  "results": [
    {
      "id": 123,
      "order_number": "ORD-2025-123",
      "status": "delivered",
      "created_at": "2025-12-20T10:30:00Z",
      "delivered_at": "2025-12-20T15:15:00Z",
      "total": "450.00",
      "item_count": 3,
      "rating": {
        "id": 45,
        "rating": 5,
        "comment": "Great service!"
      }
    }
  ]
}
```

### 2. Get Order Details

**Endpoint:**
```
GET /api/order/v1/orders/{id}/
```

**Response:**
```json
{
  "id": 123,
  "order_number": "ORD-2025-123",
  "status": "delivered",
  "created_at": "2025-12-20T10:30:00Z",
  "confirmed_at": "2025-12-20T10:35:00Z",
  "out_for_delivery_at": "2025-12-20T14:00:00Z",
  "delivered_at": "2025-12-20T15:15:00Z",
  "items": [
    {
      "id": 501,
      "product_variant": 45,
      "product_name": "Organic Apples",
      "quantity": 2,
      "unit_price": "120.00",
      "line_total": "240.00",
      "image": "https://..."
    }
  ],
  "delivery_address": {
    "street_address_1": "123 Main St",
    "city": "Mumbai",
    "postal_code": "400001"
  },
  "subtotal": "450.00",
  "delivery_fee": "40.00",
  "discount": "40.00",
  "total": "450.00",
  "payment_method": "razorpay",
  "payment_id": "pay_xyz123"
}
```

### 3. Get Delivery Status (Active Order)

**Endpoint:**
```
GET /api/order/v1/orders/{id}/delivery-status/
```

**Response:**
```json
{
  "order_id": 123,
  "status": "out_for_delivery",
  "estimated_delivery": "2025-12-20T15:00:00Z",
  "driver": {
    "name": "Rahul",
    "phone": "+91-9876543210"
  },
  "current_location": {
    "latitude": 19.1234,
    "longitude": 72.5678
  }
}
```

### 4. Submit Rating

**Endpoint:**
```
POST /api/order/v1/orders/{id}/rating/
```

**Request:**
```json
{
  "rating": 5,
  "comment": "Excellent service!"
}
```

### 5. Update Rating

**Endpoint:**
```
PATCH /api/order/v1/orders/{id}/rating/{ratingId}/
```

**Request:**
```json
{
  "rating": 4,
  "comment": "Good, but delivery was late"
}
```

---

## Order Statuses

| Status | Description | Actions Available |
|--------|-------------|-------------------|
| `pending` | Order placed, awaiting confirmation | Cancel |
| `confirmed` | Order confirmed by store | Track |
| `processing` | Order being prepared | Track |
| `out_for_delivery` | Driver en route | Track, Contact Driver |
| `delivered` | Order delivered | Rate, Reorder |
| `cancelled` | Order cancelled | Reorder |
| `failed` | Payment/delivery failed | Reorder |

---

## State Management

### OrdersState

```dart
class OrdersState {
  final OrdersStatus status;
  final List<Order> orders;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;
}

enum OrdersStatus {
  initial,
  loading,
  loaded,
  error,
}
```

### OrdersController

```dart
class OrdersController extends StateNotifier<OrdersState> {
  // Fetch orders
  Future<void> fetchOrders();

  // Load more (pagination)
  Future<void> loadMore();

  // Refresh orders
  Future<void> refresh();

  // Get single order details
  Future<Order> getOrderDetails(int orderId);
}
```

---

## Order Card Component

```dart
class OrderCard extends StatelessWidget {
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),

            SizedBox(height: 8),

            // Order info
            Text(
              '${order.itemCount} items • ₹${order.total}',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              DateFormat('MMM dd, yyyy').format(order.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            SizedBox(height: 12),

            // Actions
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _viewDetails(context),
                  child: Text('View Details'),
                ),
                SizedBox(width: 8),
                if (order.status == 'delivered' && order.rating == null)
                  OutlinedButton(
                    onPressed: () => _rateOrder(context),
                    child: Text('Rate ⭐'),
                  ),
                if (order.canReorder)
                  ElevatedButton(
                    onPressed: () => _reorder(context),
                    child: Text('Reorder'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Delivery Status Bar

Shows on Home screen for active orders:

```dart
class DeliveryStatusBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryState = ref.watch(deliveryStatusProvider);

    return deliveryState.when(
      hidden: () => SizedBox.shrink(),
      loading: (orderId) => _buildLoadingBar(),
      active: (orderId, status, estimatedTime) => _buildActiveBar(
        context,
        orderId,
        status,
        estimatedTime,
      ),
      completed: (orderId) => _buildCompletedBar(context, orderId),
      failed: (orderId, error) => _buildFailedBar(context, error),
    );
  }

  Widget _buildActiveBar(
    BuildContext context,
    int orderId,
    String status,
    DateTime? estimatedTime,
  ) {
    return Container(
      color: Colors.green.shade50,
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.green),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$orderId',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _statusText(status),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _trackOrder(context, orderId),
            child: Text('Track'),
          ),
        ],
      ),
    );
  }
}
```

---

## Reorder Flow

```dart
Future<void> _handleReorder(BuildContext context, Order order) async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  try {
    final cartController = ref.read(checkoutLineControllerProvider.notifier);
    final unavailableItems = <String>[];
    int addedCount = 0;

    for (final item in order.items) {
      try {
        // Check if product is available
        final isAvailable = await _checkAvailability(item.productVariant);

        if (isAvailable) {
          await cartController.addToCart(item.productVariant, item.quantity);
          addedCount++;
        } else {
          unavailableItems.add(item.productName);
        }
      } catch (e) {
        unavailableItems.add(item.productName);
      }
    }

    Navigator.pop(context);  // Close loading

    if (unavailableItems.isNotEmpty) {
      // Show unavailable items dialog
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Some items unavailable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The following items are no longer available:'),
              SizedBox(height: 8),
              ...unavailableItems.map((name) => Text('• $name')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }

    if (addedCount > 0) {
      AppSnackbar.success(context, '$addedCount items added to cart');
      BottomNavigation.globalKey.currentState?.navigateToTab(3);
    }
  } catch (e) {
    Navigator.pop(context);
    AppSnackbar.error(context, 'Failed to reorder');
  }
}
```

---

## Rating Bottom Sheet

```dart
class ReviewBottomSheet extends ConsumerStatefulWidget {
  final int orderId;
  final int? existingRatingId;
  final int? existingRating;
  final String? existingComment;

  static Future<void> show(BuildContext context, {
    required int orderId,
    int? existingRatingId,
    int? existingRating,
    String? existingComment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReviewBottomSheet(
        orderId: orderId,
        existingRatingId: existingRatingId,
        existingRating: existingRating,
        existingComment: existingComment,
      ),
    );
  }
}

class _ReviewBottomSheetState extends ConsumerState<ReviewBottomSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rating = widget.existingRating ?? 0;
    _commentController.text = widget.existingComment ?? '';
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      AppSnackbar.error(context, 'Please select a rating');
      return;
    }

    try {
      if (widget.existingRatingId != null) {
        // Update existing rating
        await ref.read(ordersApiProvider).updateRating(
          orderId: widget.orderId,
          ratingId: widget.existingRatingId!,
          rating: _rating,
          comment: _commentController.text,
        );
      } else {
        // Submit new rating
        await ref.read(ordersApiProvider).submitRating(
          orderId: widget.orderId,
          rating: _rating,
          comment: _commentController.text,
        );
      }

      Navigator.pop(context);
      AppSnackbar.success(context, 'Thank you for your feedback!');
    } catch (e) {
      AppSnackbar.error(context, 'Failed to submit rating');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How was your experience?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitRating,
            child: Text('Submit Rating'),
          ),
        ],
      ),
    );
  }
}
```

---

## Related Documentation

- [Payment Flow](../../payment_flow.md) - Order creation
- [Reorder Flow](../../reorder_flow.md) - Detailed reorder implementation
- [Delivery Status Flow](../Delivery/delivery_status_flow.md) - Tracking
- [Order Rating](../../ORDER_RATING_COMPLETE_SUMMARY.md) - Rating system

---

**Last Updated:** 2025-12-25
