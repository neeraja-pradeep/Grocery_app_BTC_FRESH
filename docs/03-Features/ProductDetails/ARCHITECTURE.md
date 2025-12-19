# Product Details Feature Architecture

## Overview

The Product Details feature implements a **clean, modular architecture** with clear separation of concerns:
- **Presentation Layer**: Thin coordinator screen + focused component widgets
- **Application Layer**: Riverpod state management (FamilyNotifier pattern)
- **Domain Layer**: Business logic and entities
- **Infrastructure Layer**: API calls, local caching, and data mapping

## Folder Structure

```
lib/features/product_details/
├── application/
│   ├── providers/
│   │   └── product_detail_providers.dart      # Riverpod providers, polling logic
│   └── states/
│       └── product_detail_state.dart          # State class with Equatable for value-based equality
│
├── domain/
│   ├── entities/
│   │   ├── product_variant.dart               # Main product entity + nested entities (Equatable)
│   │   └── product_variant.dart               # Contains 3 equatable classes:
│   │       ├── ProductVariant                 # Core product with all attributes
│   │       ├── ProductVariantMedia            # Image/media items
│   │       └── ProductVariantReview           # Customer reviews
│   └── repositories/
│       └── product_detail_repository.dart     # Repository interface
│
├── infrastructure/
│   ├── data_sources/
│   │   ├── local/
│   │   │   ├── product_detail_local_data_source.dart      # Hive caching
│   │   │   └── product_detail_cache_dto.dart              # Cache DTO
│   │   └── remote/
│   │       └── product_detail_remote_data_source.dart      # API calls
│   ├── models/
│   │   └── product_detail_dto.dart            # API response DTOs
│   └── repositories/
│       └── product_detail_repository_impl.dart # Repository implementation
│
└── presentation/
    ├── screen/
    │   └── product_details_screen.dart        # Thin coordinator (~110 lines)
    │
    └── components/
        ├── add_to_cart_section/
        │   └── add_to_cart_button.dart        # Add/quantity controls with animations
        ├── expandable_section/
        │   └── expandable_section.dart        # Reusable expandable container
        ├── product_header/
        │   └── product_header.dart            # Image carousel with wishlist (not used in current screen)
        ├── product_image_section/
        │   └── product_image_section.dart     # Main/thumbnail image gallery
        ├── product_info/
        │   └── product_info.dart              # Name, price, rating, description
        ├── product_list_item/
        │   └── product_list_item.dart         # (Legacy component)
        └── product_reviews/
            └── product_reviews.dart            # Customer reviews list with animations
```

## Architecture Patterns

### 1. State Management (Riverpod + Equatable)

**ProductDetailState** (`product_detail_state.dart`):
- Extends `Equatable` for value-based equality comparison
- Contains all state fields: product data, quantity, wishlist status, etc.
- Riverpod change detection relies on Equatable's `props` getter

**ProductVariant** (`product_variant.dart`):
- Main entity with 30+ properties
- Extends `Equatable` so Riverpod detects when product data changes
- Contains 2 nested equatable classes:
  - `ProductVariantMedia`: Image/gallery items
  - `ProductVariantReview`: Customer reviews

**Why Equatable?**
- Riverpod's state change detection uses `==` comparison
- Without Equatable, `ProductVariant(...)` instances are compared by reference
- With Equatable, instances are compared by their `props` values
- This allows Riverpod to detect when API returns new product data and trigger UI rebuilds

### 2. Presentation Architecture

**Thin Coordinator Screen** (`product_details_screen.dart`):
```dart
class ProductDetailsScreen extends ConsumerStatefulWidget {
  // Watches Riverpod state for business logic
  // Reads Riverpod controller for actions
  // Delegates rendering to component widgets
}
```

**Key Characteristics**:
- ~110 lines (vs original 504 lines - 78% reduction)
- ConsumerStatefulWidget = Riverpod state watching + widget state management
- Widget state: Only `_isProductDetailExpanded` (UI-only)
- Riverpod state: All business logic (product data, quantity, wishlist, etc.)

**Component Composition**:
```
ProductDetailsScreen (Coordinator)
├── AppBar (_buildAppBar)
├── Body (_buildBody)
│   ├── ProductImageSection (component)
│   ├── ProductInfo (component)
│   ├── AddToCartButton (component)
│   ├── ExpandableSection (reusable)
│   │   ├── Product details text
│   │   └── Product weight/info
│   └── ProductReviews (component)
└── BottomSheet (_buildBottomSheet)
    └── Price + View Cart button
```

### 3. Component Responsibilities

#### ProductImageSection (`product_image_section.dart`)
- Displays main product image + thumbnails
- Image carousel with indicator dots
- Manages current image index state
- Handles image loading/error states

#### ProductInfo (`product_info.dart`)
- Shows product name, variant name, weight
- Displays price with discount calculation
- Shows rating with visual stars
- Includes product description with read-more

#### AddToCartButton (`add_to_cart_section/add_to_cart_button.dart`)
- Two states: "Add" button vs Quantity selector
- Animated cross-fade between states
- Increment/decrement with animations
- "View Cart" action button
- Complete with micro-interactions (scale, fade)

#### ProductReviews (`product_reviews.dart`)
- Lists customer reviews with stagger animation
- Shows reviewer name, rating, comment
- Displays review date in relative format (e.g., "2 days ago")
- Shows helpful count with thumbs up icon

#### ExpandableSection (`expandable_section.dart`)
- Reusable expandable container
- Optional badge (e.g., weight, quantity)
- Expand/collapse chevron icon
- Top/bottom borders

### 4. State Management Flow

```
API Call (30-second polling)
    ↓
ProductDetailRemoteDataSource.getProductDetail()
    ↓
ProductDetailRepositoryImpl (handles If-Modified-Since headers)
    ↓
ProductDetailState (Equatable comparison)
    ↓
Riverpod detects change (via Equatable props)
    ↓
ProductDetailsScreen rebuilds
    ↓
Component widgets update with new data
```

## Key Improvements

### Before Refactoring
- ❌ 504 lines in single file
- ❌ Mixed state management (Riverpod + StatefulWidget + Consumer)
- ❌ UI logic scattered across helper methods
- ❌ Hard to maintain and test
- ❌ No code reuse of components

### After Refactoring
- ✅ 110 lines in coordinator screen
- ✅ Clear separation: ConsumerStatefulWidget (business) + components (UI)
- ✅ Widget state only for UI-specific state
- ✅ Each component has single responsibility
- ✅ Easy to maintain, test, and extend
- ✅ Components reusable across app (AddToCartButton, ProductInfo, ProductReviews, etc.)
- ✅ 78% code reduction

## Data Flow Example

### User adds product to cart:

```
AddToCartButton.onAdd()
  → ProductDetailsScreen passes controller.setQuantity(1)
    → ProductDetailController.setQuantity(1) (in Riverpod notifier)
      → Updates ProductDetailState.quantity = 1
        → Equatable props includes quantity
          → Riverpod detects state change
            → ProductDetailsScreen rebuilds
              → AddToCartButton receives new quantity: 1
                → Widget rebuilds: "Add" button → Quantity selector
```

## Polling & Caching

**Every 30 seconds**:
1. Check if cache is stale (>10 minutes old)
2. If stale, send GET request with `If-Modified-Since` header
3. Server responds:
   - **304 Not Modified**: Use cached data, update `lastSyncedAt` only
   - **200 OK**: Save new product data, update `lastModified` header
4. Riverpod detects state change via Equatable
5. UI automatically rebuilds with new data

See [CACHE_STRATEGY.md](../CACHE_STRATEGY.md) for detailed caching documentation.

## File Sizes Comparison

| File | Lines | Purpose |
|------|-------|---------|
| product_details_screen.dart (OLD) | 504 | Monolithic screen with all UI |
| product_details_screen.dart (NEW) | 110 | Thin coordinator + component delegation |
| product_image_section.dart | 273 | Image gallery component |
| product_info.dart | 210 | Product info component |
| add_to_cart_button.dart | 350 | Add to cart controls |
| product_reviews.dart | 239 | Reviews list component |
| **Total** | **1,182** | Modular, reusable components |

## Component Usage Examples

### Using ProductInfo elsewhere
```dart
import '../components/product_info/product_info.dart';

class ProductListItem extends StatelessWidget {
  final ProductVariant product;

  @override
  Widget build(BuildContext context) {
    return ProductInfo(productDetail: product);
  }
}
```

### Using AddToCartButton elsewhere
```dart
import '../components/add_to_cart_section/add_to_cart_button.dart';

AddToCartButton(
  quantity: cartItem.quantity,
  onAdd: () => addToCart(product),
  onIncrement: () => incrementCart(product),
  onDecrement: () => decrementCart(product),
  onViewCart: () => navigateToCart(),
)
```

## Testing Strategy

### Unit Tests
- ProductDetailState (copyWith, getters, props)
- ProductVariant equality via Equatable

### Widget Tests
- ProductDetailsScreen (mocked Riverpod provider)
- Individual components (ProductInfo, ProductReviews, etc.)
- User interactions (tapping buttons, expanding sections)

### Integration Tests
- Full flow: API call → State update → UI rebuild
- Polling mechanism with mock clock
- Wishlist toggle
- Add to cart → Quantity selector

## Best Practices Applied

1. **Separation of Concerns**
   - Business logic in Riverpod (productDetailControllerProvider)
   - UI state in ConsumerState (widget-specific)
   - Components handle their own rendering

2. **Equatable for Value-Based Equality**
   - All entities use Equatable
   - State classes use Equatable
   - Enables reliable Riverpod change detection

3. **Modular Components**
   - Each component has clear responsibility
   - Reusable across the app
   - Easy to test in isolation
   - Can be extracted to shared packages

4. **Thin Coordinator Pattern**
   - Screen only orchestrates components
   - No business logic in presentation
   - Single source of truth: Riverpod provider
   - Easy to swap components without affecting logic

5. **Proper State Management**
   - ConsumerStatefulWidget for Riverpod + widget state
   - Widget state for UI-only (expandable sections)
   - Riverpod state for business logic (product data, polling)
   - No mixed state management patterns
