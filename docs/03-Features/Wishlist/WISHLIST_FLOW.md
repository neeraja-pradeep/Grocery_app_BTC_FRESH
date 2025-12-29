# Wishlist Flow - Complete Documentation

## Overview

The Wishlist Flow allows users to save products for later purchase. Users can add/remove items from the wishlist and move items to cart. The wishlist is only accessible to authenticated users.

---

## Architecture

### Files Involved

```
lib/
├── features/
│   ├── wishlist/
│   │   ├── application/
│   │   │   ├── providers/
│   │   │   │   └── wishlist_provider.dart      # Wishlist state management
│   │   │   └── states/
│   │   │       └── wishlist_state.dart         # Wishlist state
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── wishlist_item.dart          # Wishlist item entity
│   │   ├── infrastructure/
│   │   │   └── data_sources/
│   │   │       └── wishlist_api.dart           # API calls
│   │   └── presentation/
│   │       ├── screen/
│   │       │   └── wishlist_screen.dart        # Main wishlist UI
│   │       └── components/
│   │           └── wishlist_item_card.dart     # Individual item
│   └── product_details/
│       └── presentation/
│           └── components/
│               └── wishlist_button.dart        # Heart icon button
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            WISHLIST FLOW                                     │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                        ADD TO WISHLIST                                       │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│  Product Card           │
│  or Product Details     │
│                         │
│  User taps ♡ (heart)    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Check Authentication                                            │
│                                                                  │
│  Is User Authenticated?                                          │
│  ├─► YES: Proceed to add                                         │
│  └─► NO: Show "Please login" → Navigate to OTP                   │
└───────────┬─────────────────────────────────────────────────────┘
            │ Authenticated
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  wishlistController.addToWishlist(variantId)                     │
│                                                                  │
│  1. Optimistic Update:                                           │
│     - Toggle heart to filled (♥)                                 │
│     - Add to local wishlist state                                │
│                                                                  │
│  2. API Call:                                                    │
│     POST /api/product/v1/wishlist/                               │
│     { "product_variant": variantId }                             │
│                                                                  │
│  3. Handle Response:                                             │
│     - Success: Show "Added to wishlist" snackbar                 │
│     - Failure: Rollback heart state, show error                  │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                      REMOVE FROM WISHLIST                                    │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│  Wishlist Screen        │
│  User taps ♥ or delete  │
│                         │
│  OR                     │
│                         │
│  Product Card           │
│  User taps ♥ (filled)   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  wishlistController.removeFromWishlist(wishlistItemId)           │
│                                                                  │
│  1. Optimistic Update:                                           │
│     - Toggle heart to empty (♡)                                  │
│     - Remove from local wishlist state                           │
│                                                                  │
│  2. API Call:                                                    │
│     DELETE /api/product/v1/wishlist/{id}/                        │
│                                                                  │
│  3. Handle Response:                                             │
│     - Success: Show "Removed from wishlist"                      │
│     - Failure: Restore heart state, show error                   │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                        VIEW WISHLIST                                         │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│  Bottom Navigation      │
│  Wishlist Tab (index 2) │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  WishlistScreen                                                  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  AppBar: "My Wishlist"                                       │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  State: Loading                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  CircularProgressIndicator                                   │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  State: Empty                                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  EmptyState illustration                                     │ │
│  │  "Your wishlist is empty"                                    │ │
│  │  "Browse products to add favorites"                          │ │
│  │  [Browse Products] button                                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  State: Loaded                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  GridView of WishlistItemCards                               │ │
│  │  - Product image                                             │ │
│  │  - Product name                                              │ │
│  │  - Price (with discount if applicable)                       │ │
│  │  - "Add to Cart" button                                      │ │
│  │  - Remove (X) button                                         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                        MOVE TO CART                                          │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│  WishlistItemCard       │
│  User taps "Add to Cart"│
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. Add to Cart                                                  │
│     checkoutLineController.addToCart(variantId, 1)              │
│                                                                  │
│  2. Optionally Remove from Wishlist                              │
│     wishlistController.removeFromWishlist(itemId)               │
│     (Based on app preference - keep or remove)                   │
│                                                                  │
│  3. Show Success                                                 │
│     "Item moved to cart"                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### 1. Get Wishlist

**Endpoint:**
```
GET /api/product/v1/wishlist/
```

**Response:**
```json
{
  "count": 3,
  "results": [
    {
      "id": 101,
      "product_variant": 45,
      "created_at": "2025-12-20T10:30:00Z",
      "product_details": {
        "id": 45,
        "name": "Organic Apples",
        "price": "150.00",
        "discounted_price": "120.00",
        "image": "https://...",
        "in_stock": true,
        "current_quantity": 50
      }
    }
  ]
}
```

### 2. Add to Wishlist

**Endpoint:**
```
POST /api/product/v1/wishlist/
```

**Request:**
```json
{
  "product_variant": 45
}
```

**Response:**
```json
{
  "id": 101,
  "product_variant": 45,
  "created_at": "2025-12-20T10:30:00Z"
}
```

### 3. Remove from Wishlist

**Endpoint:**
```
DELETE /api/product/v1/wishlist/{id}/
```

**Response:** `204 No Content`

### 4. Check if in Wishlist

**Endpoint:**
```
GET /api/product/v1/wishlist/?product_variant={variantId}
```

**Response:**
```json
{
  "count": 1,
  "results": [
    {
      "id": 101,
      "product_variant": 45
    }
  ]
}
```

---

## State Management

### WishlistState

```dart
class WishlistState {
  final WishlistStatus status;
  final List<WishlistItem> items;
  final bool isRefreshing;
  final String? error;

  // Quick lookup
  Set<int> get wishlistVariantIds =>
      items.map((i) => i.productVariant).toSet();

  bool isInWishlist(int variantId) =>
      wishlistVariantIds.contains(variantId);
}

enum WishlistStatus {
  initial,
  loading,
  loaded,
  error,
}
```

### WishlistController

```dart
class WishlistController extends StateNotifier<WishlistState> {
  // Fetch all wishlist items
  Future<void> fetchWishlist();

  // Add item to wishlist
  Future<void> addToWishlist(int variantId);

  // Remove item from wishlist
  Future<void> removeFromWishlist(int wishlistItemId);

  // Toggle wishlist (add if not present, remove if present)
  Future<void> toggleWishlist(int variantId);

  // Check if variant is in wishlist
  bool isInWishlist(int variantId);

  // Get wishlist item ID for a variant
  int? getWishlistItemId(int variantId);
}
```

---

## Wishlist Button Component

Used in product cards and product details:

```dart
class WishlistButton extends ConsumerWidget {
  final int variantId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistControllerProvider);
    final isInWishlist = wishlistState.isInWishlist(variantId);
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState is Authenticated;

    return IconButton(
      icon: Icon(
        isInWishlist ? Icons.favorite : Icons.favorite_border,
        color: isInWishlist ? Colors.red : Colors.grey,
        size: size,
      ),
      onPressed: () async {
        // Check authentication
        if (!isAuthenticated) {
          AppSnackbar.info(context, 'Please login to add to wishlist');
          context.go('/otp');
          return;
        }

        // Toggle wishlist
        try {
          await ref.read(wishlistControllerProvider.notifier)
              .toggleWishlist(variantId);

          final message = isInWishlist
              ? 'Removed from wishlist'
              : 'Added to wishlist';
          AppSnackbar.success(context, message);
        } catch (e) {
          AppSnackbar.error(context, 'Failed to update wishlist');
        }
      },
    );
  }
}
```

---

## Wishlist Item Card

```dart
class WishlistItemCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final product = item.productDetails;

    return Card(
      child: Column(
        children: [
          // Product Image with Remove Button
          Stack(
            children: [
              CachedNetworkImage(imageUrl: product.image),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: onRemove,
                ),
              ),
            ],
          ),

          // Product Info
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 2),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${product.discountedPrice}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (product.discountedPrice != product.price) ...[
                      SizedBox(width: 8),
                      Text(
                        '₹${product.price}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Add to Cart Button
          Padding(
            padding: EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: product.inStock ? onAddToCart : null,
              child: Text(product.inStock ? 'Add to Cart' : 'Out of Stock'),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Guest Mode Restriction

Wishlist is not accessible to guest users:

```dart
// In BottomNavigation._onTabSelected
void _onTabSelected(int index) {
  final authState = ref.read(authProvider);
  final isGuest = authState is GuestMode;

  if (isGuest && index == 2) {  // Wishlist tab
    AppSnackbar.info(context, 'Please login to access Wishlist');
    context.go('/otp');
    return;
  }

  setState(() => _currentIndex = index);
}
```

---

## Optimistic Updates

### Adding to Wishlist

```dart
Future<void> addToWishlist(int variantId) async {
  // 1. Optimistic update
  final tempItem = WishlistItem(
    id: -1,  // Temporary ID
    productVariant: variantId,
    createdAt: DateTime.now(),
  );
  state = state.copyWith(
    items: [...state.items, tempItem],
  );

  try {
    // 2. API call
    final newItem = await _api.addToWishlist(variantId);

    // 3. Replace temp with real item
    state = state.copyWith(
      items: state.items.map((i) =>
        i.id == -1 ? newItem : i
      ).toList(),
    );
  } catch (e) {
    // 4. Rollback on failure
    state = state.copyWith(
      items: state.items.where((i) => i.id != -1).toList(),
    );
    rethrow;
  }
}
```

### Removing from Wishlist

```dart
Future<void> removeFromWishlist(int itemId) async {
  // 1. Save for rollback
  final removedItem = state.items.firstWhere((i) => i.id == itemId);

  // 2. Optimistic update
  state = state.copyWith(
    items: state.items.where((i) => i.id != itemId).toList(),
  );

  try {
    // 3. API call
    await _api.removeFromWishlist(itemId);
  } catch (e) {
    // 4. Rollback on failure
    state = state.copyWith(
      items: [...state.items, removedItem],
    );
    rethrow;
  }
}
```

---

## Empty State

```dart
class WishlistEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Save items you like by tapping the heart icon',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to home/categories
              BottomNavigation.globalKey.currentState?.navigateToTab(0);
            },
            child: Text('Browse Products'),
          ),
        ],
      ),
    );
  }
}
```

---

## Related Documentation

- [Cart Flow](../Cart/CART_FLOW.md) - Move to cart
- [Product Details](../ProductDetails/ARCHITECTURE.md) - Wishlist button source
- [Auth & Guest Mode](../Authentication/AUTH_GUEST_MODE.md) - Access restrictions

---

**Last Updated:** 2025-12-25
