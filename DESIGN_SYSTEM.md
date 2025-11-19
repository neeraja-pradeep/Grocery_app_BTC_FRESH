# Grocery App Design System & UI Guide

## Overview
This document provides a comprehensive guide on how to use colors, text, folder structure, and component patterns in the Grocery App.

---

## 1. Color System

### Location
All colors are defined in: [`lib/app/theme/colors.dart`](lib/app/theme/colors.dart)

### Available Colors

```dart
class AppColors {
  // Primary Green (Main brand color)
  static const Color green = Color.fromARGB(255, 132, 195, 24);  // #84C318

  // Light Green (Background/hover state)
  static const Color green60 = Color(0xFFD7F1C6);  // #D7F1C6

  // White (Default background)
  static const Color white = Colors.white;

  // Black (Text color)
  static const Color black = Colors.black;

  // Grey (Secondary text/borders)
  static const Color grey = Colors.grey;

  // Dark Teal (Headings/selected states)
  static const Color green100 = Color(0xFF016064);  // #016064

  // Very Light Green (Light background)
  static const Color green10 = Color.fromARGB(255, 239, 244, 235);  // #EFF4EB
}
```

### How to Use Colors

```dart
import 'package:grocery_app/app/theme/colors.dart';

// In widgets
Container(
  color: AppColors.green,  // Primary green
)

Text(
  'Product Name',
  style: TextStyle(color: AppColors.green100),  // Dark text
)

Button(
  backgroundColor: AppColors.green,
  textColor: AppColors.white,
)
```

### Color Usage Guidelines

| Color | Use Case |
|-------|----------|
| `green` | Primary buttons, actions, links, highlights |
| `green60` | Light backgrounds, hover states, accents |
| `green100` | Headings, selected items, dark text |
| `green10` | Very light backgrounds, containers |
| `white` | Main background, card backgrounds |
| `grey` | Secondary text, borders, disabled states |

---

## 2. Typography & Text

### Location
Text configuration: [`lib/app/theme/typography.dart`](lib/app/theme/typography.dart)

### Text Widget: AppText

All text in the app uses the custom `AppText` widget from [`lib/core/widgets/app_text.dart`](lib/core/widgets/app_text.dart)

```dart
import 'package:grocery_app/core/widgets/app_text.dart';

// Basic usage
AppText(
  text: 'Hello',
  fontSize: 14.sp,
  fontWeight: FontWeight.w600,
  color: AppColors.green100,
)

// Preset styles
AppText.pageTitle(text: 'Product Name')  // Large, bold heading
```

### Available Font Weights
- `FontWeight.w400` - Regular (default)
- `FontWeight.w500` - Medium
- `FontWeight.w600` - Semibold
- `FontWeight.w700` - Bold

### Font Size Scaling
Using `flutter_screenutil` for responsive sizes:

```dart
fontSize: 14.sp  // .sp makes it responsive
fontSize: 16.sp  // scales automatically on different devices
```

### Text Examples

```dart
// Heading (18sp, bold, dark)
AppText(
  text: 'Product Name',
  fontSize: 18.sp,
  fontWeight: FontWeight.w700,
  color: AppColors.green100,
)

// Subheading (14sp, semibold, dark)
AppText(
  text: 'Variants',
  fontSize: 14.sp,
  fontWeight: FontWeight.w600,
  color: AppColors.green100,
)

// Body text (12-13sp, regular, grey)
AppText(
  text: 'Product description',
  fontSize: 12.sp,
  fontWeight: FontWeight.w400,
  color: AppColors.grey,
)

// With decoration
AppText(
  text: 'Original Price',
  fontSize: 10.sp,
  decoration: TextDecoration.lineThrough,
  color: AppColors.grey,
)
```

---

## 3. Spacing System

### Location
[`lib/app/theme/app_spacing.dart`](lib/app/theme/app_spacing.dart)

### Available Spacing Tokens

```dart
// Vertical spacing
AppSpacing.h4   // 4.h height
AppSpacing.h8   // 8.h height (most common)
AppSpacing.h10  // 10.h height
AppSpacing.h12  // 12.h height
AppSpacing.h16  // 16.h height
AppSpacing.h24  // 24.h height
AppSpacing.h32  // 32.h height
AppSpacing.h40  // 40.h height
AppSpacing.h50  // 50.h height

// Horizontal spacing
AppSpacing.w4   // 4.w width
AppSpacing.w8   // 8.w width
AppSpacing.w12  // 12.w width
AppSpacing.w16  // 16.w width
AppSpacing.w24  // 24.w width
```

### How to Use

```dart
import 'package:grocery_app/app/theme/app_spacing.dart';

Column(
  children: [
    Text('Item 1'),
    AppSpacing.h12,  // 12.h vertical gap
    Text('Item 2'),
  ],
)

Row(
  children: [
    Icon(Icons.star),
    AppSpacing.w8,  // 8.w horizontal gap
    Text('Rating'),
  ],
)
```

---

## 4. Folder Structure

### Overall Architecture

```
lib/
├── app/                          # Application setup
│   ├── bootstrap/                # Initialization
│   ├── config/                   # Constants & configuration
│   ├── localization/             # Translations
│   ├── monitoring/               # Analytics & logging
│   ├── router/                   # Route definitions
│   └── theme/                    # Theming (colors, typography, spacing)
│
├── core/                         # Shared functionality
│   ├── error/                    # Error handling
│   ├── extensions/               # Context extensions
│   ├── network/                  # API client & endpoints
│   ├── storage/                  # Hive cache & secure storage
│   ├── utils/                    # Utilities (date, logger, validators)
│   └── widgets/                  # Reusable UI components
│
├── features/                     # Feature modules
│   ├── category/                 # Categories & Products
│   │   ├── domain/
│   │   ├── infrastructure/
│   │   ├── application/
│   │   └── presentation/
│   │
│   ├── product_details/          # Product Details (NEW)
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   ├── infrastructure/
│   │   │   ├── data_sources/
│   │   │   │   ├── local/
│   │   │   │   └── remote/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── application/
│   │   │   ├── providers/
│   │   │   └── states/
│   │   └── presentation/
│   │       ├── screen/
│   │       ├── components/
│   │       │   ├── product_header/
│   │       │   ├── product_info/
│   │       │   ├── product_reviews/
│   │       │   └── add_to_cart_section/
│   │       └── widgets/
│   │
│   ├── bottomnavbar/             # Bottom navigation
│   └── auth/                     # Authentication
│
├── main.dart                     # App entry point
├── globals.dart                  # Global variables
└── app.dart                      # App configuration
```

### Clean Architecture Pattern

Each feature follows Clean Architecture with **Riverpod** state management:

```
Feature Layer:
  Domain/
    ├── entities/         ← Business objects
    └── repositories/     ← Abstract interfaces

  Infrastructure/
    ├── data_sources/     ← Local cache & Remote API
    │   ├── local/
    │   └── remote/
    ├── models/           ← DTOs for serialization
    └── repositories/     ← Repository implementations

  Application/
    ├── providers/        ← Riverpod providers & controllers
    └── states/           ← State objects

  Presentation/
    ├── screen/           ← Full page widgets
    ├── components/       ← Reusable sections
    └── widgets/          ← Small UI pieces
```

---

## 5. Component Patterns

### Product Details Feature Example

#### Domain Layer (Business Logic)

```dart
// lib/features/product_details/domain/entities/product_detail.dart
class ProductDetail {
  ProductDetail({
    required this.id,
    required this.name,
    required this.variantName,
    this.price,
    this.originalPrice,
    this.weight,
    this.rating,
    this.reviewCount,
    this.imageUrl,
    this.thumbnailUrl,
    this.categoryId,
    this.description,
    this.nutritionFacts,
    this.images,
    this.reviews,
  });

  final String id;
  final String name;
  final String variantName;
  final String? price;
  // ... more fields
}

// lib/features/product_details/domain/repositories/product_detail_repository.dart
abstract class ProductDetailRepository {
  Future<ProductDetail> getProductDetail(String productId);
  Future<List<ProductReview>> getProductReviews(String productId);
  Future<bool> isInWishlist(String productId);
  Future<void> addToWishlist(String productId);
  Future<void> removeFromWishlist(String productId);
}
```

#### Infrastructure Layer (Data)

```dart
// lib/features/product_details/infrastructure/models/product_detail_dto.dart
class ProductDetailDto {
  // DTO for API responses
  factory ProductDetailDto.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
  ProductDetail toDomain() { ... }  // Convert to entity
}

// lib/features/product_details/infrastructure/repositories/product_detail_repository_impl.dart
class ProductDetailRepositoryImpl implements ProductDetailRepository {
  // Combines local cache + remote API
  // Implements fallback strategy
}
```

#### Application Layer (State Management)

```dart
// lib/features/product_details/application/states/product_detail_state.dart
class ProductDetailState {
  final ProductDetailStatus status;
  final ProductDetail? productDetail;
  final List<ProductReview>? reviews;
  final bool isInWishlist;
  final int quantity;
  // ... more fields
}

// lib/features/product_details/application/providers/product_detail_providers.dart
final productDetailControllerProvider = StateNotifierProvider.family<
    ProductDetailController,
    ProductDetailState,
    String>((ref, productId) {
  // Controller managing product detail state
});
```

#### Presentation Layer (UI)

```dart
// lib/features/product_details/presentation/screen/product_details_screen.dart
class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productDetailControllerProvider(productId));
    // ... build UI based on state
  }
}

// lib/features/product_details/presentation/components/...
// - ProductHeader (image carousel, wishlist)
// - ProductInfo (name, price, rating)
// - ProductReviews (customer reviews)
// - AddToCartButton (add/quantity selector)
```

---

## 6. Component Usage Examples

### Add to Cart Button

Two states:
1. **Add state** (quantity = 0): Shows "Add" button
2. **Cart state** (quantity > 0): Shows quantity selector + "View Cart" button

```dart
AddToCartButton(
  quantity: state.quantity,
  onAdd: () => controller.incrementQuantity(),
  onIncrement: () => controller.incrementQuantity(),
  onDecrement: () => controller.decrementQuantity(),
  onViewCart: () => navigateToCart(),
)
```

### Product Header (Image Carousel)

Displays product images with:
- Page indicator dots
- Wishlist button
- Image carousel

```dart
ProductHeader(
  productDetail: state.productDetail,
  isInWishlist: state.isInWishlist,
  onWishlistToggle: () => controller.toggleWishlist(),
)
```

### Product Info

Shows:
- Product name & variant
- Weight/quantity
- Price & discount
- Rating & reviews
- Description

```dart
ProductInfo(productDetail: state.productDetail)
```

### Product Reviews

Lists all customer reviews with:
- User name & rating
- Review comment
- Date & helpful count

```dart
ProductReviews(reviews: state.reviews)
```

---

## 7. State Management (Riverpod)

### Creating a Provider

```dart
// Dependency injection
final productDetailRepositoryProvider = Provider<ProductDetailRepository>((ref) {
  final localDataSource = ref.watch(productDetailLocalDataSourceProvider);
  final remoteDataSource = ref.watch(productDetailRemoteDataSourceProvider);
  return ProductDetailRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

// State provider with family (parameterized)
final productDetailControllerProvider = StateNotifierProvider.family<
    ProductDetailController,
    ProductDetailState,
    String>((ref, productId) {
  final repository = ref.watch(productDetailRepositoryProvider);
  return ProductDetailController(
    repository: repository,
    productId: productId,
  );
});
```

### Using Provider in Widget

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state
    final state = ref.watch(productDetailControllerProvider('product-123'));

    // Get controller for actions
    final controller = ref.read(productDetailControllerProvider('product-123').notifier);

    return Column(
      children: [
        Text(state.productDetail?.name ?? 'Loading...'),
        ElevatedButton(
          onPressed: () => controller.incrementQuantity(),
          child: Text('Add to Cart'),
        ),
      ],
    );
  }
}
```

---

## 8. Common Patterns

### Responsive Sizing

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Always use .sp, .h, .w for responsive design
Container(
  width: 100.w,    // 100 width units
  height: 50.h,    // 50 height units
  child: Text(
    'Hello',
    style: TextStyle(fontSize: 14.sp),  // responsive font size
  ),
)
```

### Error Handling

```dart
if (state.status == ProductDetailStatus.error) {
  return _ErrorView(
    error: state.errorMessage ?? 'Failed to load',
    onRetry: () => controller.refresh(),
  );
}
```

### Loading States

```dart
if (state.status == ProductDetailStatus.loading) {
  return const Center(
    child: CircularProgressIndicator(
      color: AppColors.green,
    ),
  );
}
```

### Empty States

```dart
if (state.reviews?.isEmpty ?? true) {
  return Center(
    child: AppText(
      text: 'No reviews yet',
      color: AppColors.grey,
    ),
  );
}
```

---

## 9. Best Practices

### 1. Colors
- Always use `AppColors.*` constants
- Don't hardcode colors
- Respect color hierarchy (primary, secondary, grey)

### 2. Text
- Always use `AppText` widget
- Use consistent font weights (w400, w600, w700)
- Scale text with `.sp`

### 3. Spacing
- Use `AppSpacing.*` tokens
- Maintain consistent gaps between elements
- Use `AppSpacing.h*` and `AppSpacing.w*`

### 4. Architecture
- Keep business logic in **Domain** layer
- Keep API/Cache logic in **Infrastructure** layer
- Keep state in **Application** layer
- Keep UI in **Presentation** layer
- One responsibility per class

### 5. State Management
- Use `StateNotifierProvider` for controllers
- Use `Provider` for simple values
- Use `.family` for parameterized providers
- Watch state in widgets, read controller for actions

### 6. Imports
```dart
// Always use package imports for files outside current directory
import 'package:grocery_app/core/widgets/app_text.dart';

// Use relative imports only within same module
import '../models/product_detail_dto.dart';
```

---

## 10. File Naming Conventions

### Dart Files
- `snake_case` for file names: `product_details_screen.dart`
- `PascalCase` for class names: `ProductDetailsScreen`
- Single export per file (except when needed)

### Folders
- `snake_case` for folder names: `product_details`, `add_to_cart_section`

### Private Classes
- Prefix with `_`: `class _QuantitySelector`
- Use for internal components only

---

## Quick Reference

### Color Imports
```dart
import 'package:grocery_app/app/theme/colors.dart';
```

### Text Widget
```dart
import 'package:grocery_app/core/widgets/app_text.dart';
```

### Spacing
```dart
import 'package:grocery_app/app/theme/app_spacing.dart';
```

### Screen Utils (Responsive)
```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
```

### Riverpod
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

---

## Resources

- **Main App Colors**: [`lib/app/theme/colors.dart`](lib/app/theme/colors.dart)
- **Spacing System**: [`lib/app/theme/app_spacing.dart`](lib/app/theme/app_spacing.dart)
- **Text Widget**: [`lib/core/widgets/app_text.dart`](lib/core/widgets/app_text.dart)
- **Product Details**: [`lib/features/product_details/`](lib/features/product_details/)
- **Category Feature**: [`lib/features/category/`](lib/features/category/)

---

**Version**: 1.0
**Last Updated**: November 2025
