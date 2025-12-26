# Home & Category Flow - Complete Documentation

## Overview

The Home & Category Flow is the primary browsing experience of the app. Users land on the Home screen which displays categories, featured products, and the selected delivery address. The Category screen shows products filtered by category with a sidebar for navigation.

---

## Architecture

### Files Involved

```
lib/
├── features/
│   ├── home/
│   │   ├── application/
│   │   │   ├── providers/
│   │   │   │   ├── home_provider.dart           # Home state management
│   │   │   │   └── delivery_status_provider.dart # Delivery tracking
│   │   │   └── states/
│   │   │       └── home_state.dart              # Home state
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── category.dart                # Category entity
│   │   │       └── user_address.dart            # Address for display
│   │   ├── infrastructure/
│   │   │   └── data_sources/
│   │   │       └── home_api.dart                # API calls
│   │   └── presentation/
│   │       ├── screen/
│   │       │   └── home_screen.dart             # Main home UI
│   │       └── components/
│   │           ├── address_bar.dart             # Top address display
│   │           ├── category_grid.dart           # Category cards
│   │           ├── search_bar.dart              # Search input
│   │           └── delivery_status_bar.dart     # Active delivery
│   ├── category/
│   │   ├── application/
│   │   │   ├── providers/
│   │   │   │   └── category_product_providers.dart  # Products by category
│   │   │   └── states/
│   │   │       └── category_product_state.dart
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── product.dart                 # Product entity
│   │   ├── infrastructure/
│   │   │   └── data_sources/
│   │   │       └── category_product_api.dart    # API calls
│   │   └── presentation/
│   │       ├── screen/
│   │       │   ├── category_screen.dart         # Category with sidebar
│   │       │   └── categories_with_sidebar_screen.dart
│   │       └── components/
│   │           ├── category_sidebar.dart        # Left sidebar
│   │           ├── product_grid.dart            # Product cards
│   │           └── product_card.dart            # Individual product
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          HOME & CATEGORY FLOW                                │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                            HOME SCREEN                                       │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  HomeScreen (Tab 0 in BottomNavigation)                          │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  AddressBar                                                  │ │
│  │  ┌───────────────────────────────────────────────────────┐  │ │
│  │  │ 📍 Delivering to: 123 Main St, Mumbai          [Change]│  │ │
│  │  └───────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  DeliveryStatusBar (if active order)                         │ │
│  │  ┌───────────────────────────────────────────────────────┐  │ │
│  │  │ 🚚 Order #123 - Out for Delivery              [Track] │  │ │
│  │  └───────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  SearchBar                                                   │ │
│  │  ┌───────────────────────────────────────────────────────┐  │ │
│  │  │ 🔍 Search for products...                              │  │ │
│  │  └───────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  CategoryGrid                                                │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │ │
│  │  │  🍎    │ │  🥕    │ │  🥛    │ │  🍞    │            │ │
│  │  │ Fruits  │ │Veggies │ │ Dairy  │ │ Bakery │            │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘            │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │ │
│  │  │  🥩    │ │  🧴    │ │  🍿    │ │  🧊    │            │ │
│  │  │ Meat   │ │Personal │ │ Snacks │ │ Frozen │            │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘            │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
            │
            │ User taps a category
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Navigate to Category Screen                                     │
│  BottomNavigation.navigateToCategories(category)                │
│  → Switches to Tab 1 with selected category                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                          CATEGORY SCREEN                                     │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  CategoryScreen (Tab 1 in BottomNavigation)                      │
│                                                                  │
│  ┌────────┬────────────────────────────────────────────────────┐ │
│  │Sidebar │  Product Grid                                       │ │
│  │        │                                                     │ │
│  │ 🍎     │  ┌─────────────────────────────────────────────────┐│ │
│  │ Fruits │  │  AppBar: "Fruits" (selected category name)      ││ │
│  │ ●      │  └─────────────────────────────────────────────────┘│ │
│  │        │                                                     │ │
│  │ 🥕     │  ┌───────────┐ ┌───────────┐ ┌───────────┐         │ │
│  │Veggies │  │  [Image]  │ │  [Image]  │ │  [Image]  │         │ │
│  │        │  │  Apple    │ │  Orange   │ │  Banana   │         │ │
│  │ 🥛     │  │  ₹120/kg  │ │  ₹80/kg   │ │  ₹50/dozen│         │ │
│  │ Dairy  │  │  [♡][🛒] │ │  [♡][🛒] │ │  [♡][🛒] │         │ │
│  │        │  └───────────┘ └───────────┘ └───────────┘         │ │
│  │ 🍞     │                                                     │ │
│  │ Bakery │  ┌───────────┐ ┌───────────┐ ┌───────────┐         │ │
│  │        │  │  [Image]  │ │  [Image]  │ │  [Image]  │         │ │
│  │  ...   │  │  Grapes   │ │  Mango    │ │  Papaya   │         │ │
│  │        │  │  ₹200/kg  │ │  ₹150/kg  │ │  ₹60/pc   │         │ │
│  │        │  │  [♡][🛒] │ │  [♡][🛒] │ │  [♡][🛒] │         │ │
│  │        │  └───────────┘ └───────────┘ └───────────┘         │ │
│  └────────┴────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
            │
            │ User taps a product
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Navigate to Product Details                                     │
│  context.push('/product-details/${variantId}')                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### 1. Get Categories

**Endpoint:**
```
GET /api/product/v1/categories/
```

**Response:**
```json
{
  "count": 8,
  "results": [
    {
      "id": 1,
      "name": "Fruits",
      "description": "Fresh fruits",
      "image": "https://...",
      "product_count": 45
    },
    {
      "id": 2,
      "name": "Vegetables",
      "description": "Fresh vegetables",
      "image": "https://...",
      "product_count": 62
    }
  ]
}
```

### 2. Get Products by Category

**Endpoint:**
```
GET /api/product/v1/products/?category={categoryId}
```

**Response:**
```json
{
  "count": 45,
  "next": "...?page=2",
  "results": [
    {
      "id": 101,
      "name": "Organic Apples",
      "description": "Fresh organic apples",
      "category": 1,
      "variants": [
        {
          "id": 201,
          "name": "1 kg",
          "price": "150.00",
          "discounted_price": "120.00",
          "current_quantity": 50,
          "image": "https://..."
        }
      ]
    }
  ]
}
```

### 3. Get Selected Address

**Endpoint:**
```
GET /api/auth/v1/address/?selected=true
```

**Response:**
```json
{
  "count": 1,
  "results": [
    {
      "id": 46,
      "street_address_1": "123 Main St",
      "city": "Mumbai",
      "selected": true
    }
  ]
}
```

---

## State Management

### HomeState

```dart
@freezed
class HomeState with _$HomeState {
  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.loaded({
    required List<Category> categories,
    UserAddress? selectedAddress,
  }) = HomeLoaded;
  const factory HomeState.refreshing({
    required List<Category> categories,
    UserAddress? selectedAddress,
  }) = HomeRefreshing;
  const factory HomeState.error(String message) = HomeError;
}
```

### HomeProvider

```dart
class HomeNotifier extends StateNotifier<HomeState> {
  // Fetch categories and selected address
  Future<void> loadHome();

  // Refresh home data
  Future<void> refresh();

  // Update address in state (when changed from other screens)
  void updateAddressInState(UserAddress? address);
}
```

### CategoryProductState

```dart
class CategoryProductState {
  final CategoryProductStatus status;
  final List<Product> products;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;
}

enum CategoryProductStatus {
  initial,
  loading,
  loaded,
  error,
}
```

### CategoryProductController

```dart
class CategoryProductController extends StateNotifier<CategoryProductState> {
  final int categoryId;

  // Fetch products for category
  Future<void> fetchProducts();

  // Load more (pagination)
  Future<void> loadMore();

  // Refresh products
  Future<void> refresh();
}
```

---

## Address Bar

Displays selected delivery address on Home screen:

```dart
class AddressBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);

    return homeState.maybeWhen(
      loaded: (categories, address) => _buildAddressBar(context, address),
      refreshing: (categories, address) => _buildAddressBar(context, address),
      orElse: () => _buildLoadingBar(),
    );
  }

  Widget _buildAddressBar(BuildContext context, UserAddress? address) {
    return GestureDetector(
      onTap: () => _showAddressSheet(context),
      child: Container(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivering to', style: TextStyle(fontSize: 12)),
                  Text(
                    address?.streetAddress1 ?? 'Select delivery address',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text('Change', style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }

  void _showAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddressSheet(),
    );
  }
}
```

---

## Category Grid

```dart
class CategoryGrid extends StatelessWidget {
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: () {
            BottomNavigation.globalKey.currentState
                ?.navigateToCategories(category);
          },
        );
      },
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CachedNetworkImage(
              imageUrl: category.image,
              width: 60,
              height: 60,
            ),
          ),
          SizedBox(height: 4),
          Text(
            category.name,
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
```

---

## Category Sidebar

```dart
class CategorySidebar extends StatelessWidget {
  final List<Category> categories;
  final int selectedCategoryId;
  final Function(Category) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.grey.shade50,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;

          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : null,
                border: isSelected
                    ? Border(left: BorderSide(color: Colors.green, width: 3))
                    : null,
              ),
              child: Column(
                children: [
                  CachedNetworkImage(
                    imageUrl: category.image,
                    width: 40,
                    height: 40,
                  ),
                  SizedBox(height: 4),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## Product Card

```dart
class ProductCard extends ConsumerWidget {
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = product.variants.first;  // Default variant

    return GestureDetector(
      onTap: () => context.push('/product-details/${variant.id}'),
      child: Card(
        child: Column(
          children: [
            // Product Image with Wishlist Button
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: variant.image,
                  height: 120,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: WishlistButton(variantId: variant.id),
                ),
                if (variant.discountedPrice != variant.price)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: Colors.red,
                      child: Text(
                        '${_calculateDiscount()}% OFF',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
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
                        '₹${variant.discountedPrice}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (variant.discountedPrice != variant.price) ...[
                        SizedBox(width: 4),
                        Text(
                          '₹${variant.price}',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12,
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
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: AddToCartButton(variantId: variant.id),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Polling

### Category Products Polling

Only polls when user is on Category screen:

```dart
void _registerForPolling() {
  PollingManager.instance.registerPoller(
    featureName: 'category_products',
    resourceId: _categoryId.toString(),
    onResume: _startPollingTimer,
    onPause: _stopPollingTimer,
  );
}

void _startPollingTimer() {
  _pollingTimer = Timer.periodic(Duration(seconds: 30), (_) {
    refresh();
  });
}
```

---

## Real-Time Updates

### Socket.IO for Price/Inventory

```dart
// Join rooms for visible products
void _joinProductRooms() {
  for (final product in state.products) {
    for (final variant in product.variants) {
      socketService.joinRoom('variant_${variant.id}');
    }
  }
}

// Listen for updates
socketService.onPriceUpdate((data) {
  final variantId = data['variant_id'];
  final newPrice = data['price'];
  _updateProductPrice(variantId, newPrice);
});

socketService.onInventoryUpdate((data) {
  final variantId = data['variant_id'];
  final newStock = data['quantity'];
  _updateProductStock(variantId, newStock);
});
```

---

## Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    await ref.read(categoryProductProvider(categoryId).notifier).refresh();
  },
  child: GridView.builder(...),
)
```

---

## Pagination

```dart
class ProductGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryProductProvider(categoryId));

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            // Load more when near bottom
            if (state.hasMore && !state.isLoadingMore) {
              ref.read(categoryProductProvider(categoryId).notifier)
                  .loadMore();
            }
          }
        }
        return false;
      },
      child: GridView.builder(
        itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.products.length) {
            return Center(child: CircularProgressIndicator());
          }
          return ProductCard(product: state.products[index]);
        },
      ),
    );
  }
}
```

---

## Related Documentation

- [Product Details](../ProductDetails/ARCHITECTURE.md) - Product detail screen
- [Cart Flow](../Cart/CART_FLOW.md) - Add to cart
- [Wishlist Flow](../Wishlist/WISHLIST_FLOW.md) - Wishlist button
- [Address Flow](../Address/ADDRESS_FLOW.md) - Address selection
- [Search](../Search/SEARCH_IMPLEMENTATION.md) - Search functionality
- [Screen-Aware Polling](../../02-Architecture/Performance/SCREEN_AWARE_POLLING_GUIDE.md)

---

**Last Updated:** 2025-12-25
