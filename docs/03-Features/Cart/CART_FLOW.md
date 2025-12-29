# Cart Flow - Complete Documentation

## Overview

The Cart Flow manages the shopping cart functionality including adding products, updating quantities, removing items, viewing cart summary, and proceeding to checkout. The cart supports real-time updates via Socket.IO and polling.

---

## Architecture

### Files Involved

```
lib/
├── features/
│   ├── cart/
│   │   ├── application/
│   │   │   ├── providers/
│   │   │   │   ├── checkout_line_provider.dart  # Cart state management
│   │   │   │   ├── address_providers.dart       # Delivery address
│   │   │   │   ├── coupon_providers.dart        # Coupon/discount codes
│   │   │   │   └── payment_provider.dart        # Payment processing
│   │   │   └── states/
│   │   │       └── checkout_line_state.dart     # Cart state
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── checkout_line.dart           # Cart item entity
│   │   │       └── checkout_response.dart       # API response
│   │   ├── infrastructure/
│   │   │   └── data_sources/
│   │   │       └── remote/
│   │   │           └── checkout_line_data_source.dart  # API calls
│   │   └── presentation/
│   │       ├── screen/
│   │       │   ├── cart_screen.dart             # Main cart UI
│   │       │   ├── checkout_screen.dart         # Checkout summary
│   │       │   ├── confirm_order_screen.dart    # Success screen
│   │       │   └── failed_order_screen.dart     # Failure screen
│   │       └── components/
│   │           ├── cart_app_bar.dart            # Cart header
│   │           ├── cart_item_card.dart          # Individual item
│   │           ├── cart_summary.dart            # Total & checkout
│   │           ├── minimum_order_warning.dart   # Min order alert
│   │           └── address_sheet.dart           # Address selection
│   └── product_details/
│       └── presentation/
│           └── components/
│               └── add_to_cart_button.dart      # Add to cart action
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CART FLOW                                       │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                           ADD TO CART                                        │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│  Product Details    │
│  or Category Grid   │
│                     │
│  User taps          │
│  "Add to Cart"      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│  checkoutLineController.addToCart(variantId, quantity)          │
│                                                                  │
│  1. Optimistic Update:                                           │
│     - Immediately add item to local state                        │
│     - Show success feedback                                      │
│                                                                  │
│  2. API Call:                                                    │
│     POST /api/order/v1/checkout-lines/                           │
│     { "product_variant": variantId, "quantity": quantity }       │
│                                                                  │
│  3. On Success:                                                  │
│     - Refresh cart to get accurate data                          │
│     - Update badge count                                         │
│                                                                  │
│  4. On Failure:                                                  │
│     - Rollback optimistic update                                 │
│     - Show error message                                         │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                           VIEW CART                                          │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│  Bottom Navigation  │
│  Cart Tab (index 3) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│  CartScreen                                                      │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  TabBar                                                      │ │
│  │  [Cart Items]  [Checkout]                                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Tab 0: Cart Items                                               │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  • MinimumOrderWarning (if total < 150)                      │ │
│  │  • ListView of CartItemCard                                  │ │
│  │    - Product image, name, price                              │ │
│  │    - Quantity controls (+/-)                                 │ │
│  │    - Swipe to delete                                         │ │
│  │  • CartSummary (subtotal, delivery, total)                   │ │
│  │  • "Proceed to Checkout" button                              │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Tab 1: Checkout                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  • CheckoutScreen embedded                                   │ │
│  │  • Address selection                                         │ │
│  │  • Order summary                                             │ │
│  │  • "Place Order" button                                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                         UPDATE QUANTITY                                      │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐      ┌─────────────────────┐
│  Tap [+] Button     │      │  Tap [-] Button     │
└──────────┬──────────┘      └──────────┬──────────┘
           │                            │
           ▼                            ▼
┌─────────────────────┐      ┌─────────────────────┐
│  Increment by 1     │      │  quantity > 1?      │
│                     │      │  Yes → Decrement    │
│                     │      │  No → Show delete   │
│                     │      │       confirmation  │
└──────────┬──────────┘      └──────────┬──────────┘
           │                            │
           └────────────┬───────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│  checkoutLineController.updateQuantity(lineId, newQuantity)      │
│                                                                  │
│  1. Optimistic Update:                                           │
│     - Immediately update quantity in UI                          │
│     - Recalculate totals                                         │
│                                                                  │
│  2. API Call:                                                    │
│     PATCH /api/order/v1/checkout-lines/{lineId}/                 │
│     { "quantity": newQuantity }                                  │
│                                                                  │
│  3. Handle Response:                                             │
│     - Success: Confirm update                                    │
│     - Failure: Rollback to previous quantity                     │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                         REMOVE ITEM                                          │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│  Swipe Left on Item │
│  or Tap Delete Icon │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Show Confirmation (optional)                                    │
│  "Remove item from cart?"                                        │
└──────────┬──────────────────────────────────────────────────────┘
           │ Confirmed
           ▼
┌─────────────────────────────────────────────────────────────────┐
│  checkoutLineController.removeItem(lineId)                       │
│                                                                  │
│  1. Optimistic Update:                                           │
│     - Immediately remove from list                               │
│     - Recalculate totals                                         │
│                                                                  │
│  2. API Call:                                                    │
│     DELETE /api/order/v1/checkout-lines/{lineId}/                │
│                                                                  │
│  3. Handle Response:                                             │
│     - Success: Show "Item removed" snackbar                      │
│     - Failure: Restore item, show error                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### 1. Get Cart Items

**Endpoint:**
```
GET /api/order/v1/checkout-lines/
```

**Response:**
```json
{
  "count": 2,
  "results": [
    {
      "id": 123,
      "product_variant": 45,
      "quantity": 2,
      "product_details": {
        "id": 45,
        "name": "Organic Apples",
        "price": "150.00",
        "discounted_price": "120.00",
        "current_quantity": 50,
        "image": "https://..."
      },
      "line_total": "240.00"
    }
  ],
  "subtotal": "240.00",
  "delivery_fee": "40.00",
  "total": "280.00"
}
```

### 2. Add to Cart

**Endpoint:**
```
POST /api/order/v1/checkout-lines/
```

**Request:**
```json
{
  "product_variant": 45,
  "quantity": 2
}
```

**Response:**
```json
{
  "id": 123,
  "product_variant": 45,
  "quantity": 2,
  "product_details": {...},
  "line_total": "240.00"
}
```

### 3. Update Quantity

**Endpoint:**
```
PATCH /api/order/v1/checkout-lines/{id}/
```

**Request:**
```json
{
  "quantity": 3
}
```

### 4. Remove Item

**Endpoint:**
```
DELETE /api/order/v1/checkout-lines/{id}/
```

**Response:** `204 No Content`

---

## State Management

### CheckoutLineState

```dart
class CheckoutLineState {
  final CheckoutLineStatus status;
  final List<CheckoutLine> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final bool isRefreshing;
  final String? error;

  // Computed properties
  int get itemCount => items.length;
  bool get isEmpty => items.isEmpty;
  bool get meetsMinimumOrder => subtotal >= 150.0;
}

enum CheckoutLineStatus {
  initial,
  loading,
  loaded,
  error,
}
```

### CheckoutLineController

```dart
class CheckoutLineController extends StateNotifier<CheckoutLineState> {
  // Add item to cart
  Future<void> addToCart(int variantId, int quantity);

  // Update item quantity
  Future<void> updateQuantity(int lineId, int newQuantity);

  // Remove item
  Future<void> removeItem(int lineId);

  // Refresh cart from server
  Future<void> refreshCart();

  // Clear cart (after successful order)
  void clearCart();
}
```

---

## Real-Time Updates

### Socket.IO Integration

Cart items receive real-time updates for:
- Price changes
- Stock availability changes
- Product unavailability

```dart
// In CartScreen
@override
void initState() {
  super.initState();
  _joinCartItemRooms();
}

void _joinCartItemRooms() {
  final cartItems = ref.read(checkoutLineControllerProvider).items;
  for (final item in cartItems) {
    socketService.joinRoom('variant_${item.productVariant}');
  }
}

// Listen for updates
socketService.onPriceUpdate((data) {
  final variantId = data['variant_id'];
  final newPrice = data['price'];
  ref.read(checkoutLineControllerProvider.notifier)
      .updateItemPrice(variantId, newPrice);
});

socketService.onInventoryUpdate((data) {
  final variantId = data['variant_id'];
  final newStock = data['quantity'];
  ref.read(checkoutLineControllerProvider.notifier)
      .updateItemStock(variantId, newStock);
});
```

### Polling

Cart data is polled every 30 seconds when user is on Cart tab:

```dart
void _startPolling() {
  PollingManager.instance.registerPoller(
    featureName: 'cart',
    resourceId: 'checkout_lines',
    onResume: _startPollingTimer,
    onPause: _stopPollingTimer,
  );
}

void _startPollingTimer() {
  _pollingTimer = Timer.periodic(Duration(seconds: 30), (_) {
    refreshCart();
  });
}
```

---

## Cart Item Card

### UI Structure

```dart
class CartItemCard extends StatelessWidget {
  final CheckoutLine item;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('cart_item_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(),
      background: _deleteBackground(),
      child: Card(
        child: Row(
          children: [
            // Product Image
            CachedNetworkImage(imageUrl: item.productDetails.image),

            // Product Info
            Column(
              children: [
                Text(item.productDetails.name),
                Text('₹${item.productDetails.discountedPrice}'),
                if (item.productDetails.currentQuantity < item.quantity)
                  Text('Only ${item.productDetails.currentQuantity} left'),
              ],
            ),

            // Quantity Controls
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () => _decrementQuantity(),
                ),
                Text('${item.quantity}'),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _incrementQuantity(),
                ),
              ],
            ),

            // Line Total
            Text('₹${item.lineTotal}'),
          ],
        ),
      ),
    );
  }
}
```

---

## Minimum Order Warning

```dart
class MinimumOrderWarning extends StatelessWidget {
  final double currentTotal;
  final double minimumOrder = 150.0;

  @override
  Widget build(BuildContext context) {
    if (currentTotal >= minimumOrder) return SizedBox.shrink();

    final remaining = minimumOrder - currentTotal;

    return Container(
      color: Colors.orange.shade50,
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add ₹${remaining.toStringAsFixed(0)} more to meet minimum order',
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Cart Summary

```dart
class CartSummary extends StatelessWidget {
  final CheckoutLineState cartState;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow('Subtotal', cartState.subtotal),
        _buildRow('Delivery Fee', cartState.deliveryFee),
        Divider(),
        _buildRow('Total', cartState.total, isBold: true),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: cartState.meetsMinimumOrder
              ? () => _proceedToCheckout()
              : null,
          child: Text('Proceed to Checkout'),
        ),
      ],
    );
  }
}
```

---

## Error Handling

### Stock Validation

```dart
Future<void> _validateBeforeCheckout() async {
  final cartState = ref.read(checkoutLineControllerProvider);

  for (final item in cartState.items) {
    if (item.quantity > item.productDetails.currentQuantity) {
      AppSnackbar.error(
        context,
        '${item.productDetails.name} has only ${item.productDetails.currentQuantity} in stock',
      );
      return;
    }
  }

  // Proceed to checkout
}
```

### Network Errors

```dart
try {
  await ref.read(checkoutLineControllerProvider.notifier)
      .addToCart(variantId, quantity);
  AppSnackbar.success(context, 'Added to cart');
} catch (e) {
  if (e is DioException && e.response?.statusCode == 400) {
    final error = e.response?.data['error'] ?? 'Failed to add';
    AppSnackbar.error(context, error);
  } else {
    AppSnackbar.error(context, 'Network error. Please try again.');
  }
}
```

---

## Badge Count

Cart badge in bottom navigation:

```dart
// In BottomNavigation
final cartState = ref.watch(checkoutLineControllerProvider);
final cartItemCount = cartState.items.length;

BottomNavigationBarItem(
  icon: Badge(
    label: cartItemCount > 0 ? Text('$cartItemCount') : null,
    isLabelVisible: cartItemCount > 0,
    child: Icon(Icons.shopping_cart_outlined),
  ),
  label: 'Cart',
)
```

---

## Guest Mode Restriction

Cart is not accessible to guest users:

```dart
// In BottomNavigation._onTabSelected
void _onTabSelected(int index) {
  final authState = ref.read(authProvider);
  final isGuest = authState is GuestMode;

  if (isGuest && index == 3) {  // Cart tab
    AppSnackbar.info(context, 'Please login to access Cart');
    context.go('/otp');
    return;
  }

  setState(() => _currentIndex = index);
}
```

---

## Related Documentation

- [Payment Flow](../../payment_flow.md) - Checkout and payment
- [Address Flow](../Address/ADDRESS_FLOW.md) - Delivery address
- [Product Details](../ProductDetails/ARCHITECTURE.md) - Add to cart source
- [Screen-Aware Polling](../../02-Architecture/Performance/SCREEN_AWARE_POLLING_GUIDE.md)

---

**Last Updated:** 2025-12-25
