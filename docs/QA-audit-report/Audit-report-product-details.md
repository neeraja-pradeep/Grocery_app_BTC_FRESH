# Product Details — Code Audit Report

**Scope:** Product Details Screen · Variants · Reviews · Add to Cart · Wishlist · Rating Submission

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 6

**Date:** 2026-05-01

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 1 | 2 | 1 | 4 |
| Prompt 2 — Security & Data Persistence | 1 | 1 | 1 | 3 |
| Prompt 3 — Performance & Error Handling | 0 | 2 | 3 | 5 |
| Prompt 4 — Code Quality & Deployment | 2 | 2 | 4 | 8 |
| Prompt 6 — Architecture Compliance | 3 | 2 | 3 | 8 |
| **Total** | **7** | **9** | **12** | **28** |

---

## Top Blockers Before Any Production Release

1. **Rating submission calls infrastructure API directly from screen** — `product_details_screen.dart:565` — `ref.read(ordersApiProvider).submitOrderRating(...)` completely bypasses the orders application layer. Ratings are invisible to any global state, analytics, or error tracking.
2. **Presentation catches `InsufficientStockException` from cart infrastructure** — `product_details_screen.dart:16` — exception types from infrastructure layer are used directly in presentation. Domain must own its exception contracts.
3. **Application layer instantiates infrastructure concrete classes** — `product_detail_providers.dart:13–15` — three infrastructure imports inside the application layer break dependency inversion.
4. **Zero test files exist for the entire feature** — no unit, widget, or integration test for any of the 27 files in this feature.
5. **Three dead methods in `ProductDetailController`** — `toggleWishlist()`, `addToCart()`, `setQuantity()` are never called. The screen bypasses them completely, creating false documentation of the system's intent.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

---

### C1 — `_handleRatingSubmit()` calls infrastructure API directly, bypassing the application layer

**File:** `lib/features/product_details/presentation/screen/product_details_screen.dart:20, 565`

**Severity:** CRITICAL

**Issue:** The screen imports `orders_api.dart` (infrastructure remote layer) and calls `ref.read(ordersApiProvider).submitOrderRating(...)` directly from `_handleRatingSubmit()`. The orders `StateNotifier` is completely bypassed. No `OrdersState` is emitted on rating success or failure. Loading state is unmanaged.

**Code:**
```dart
import '../../../orders/infrastructure/data_sources/orders_api.dart';
// ...
await ref
    .read(ordersApiProvider)
    .submitOrderRating(orderId: orderId, stars: rating);
```

**Impact:** Rating submissions are invisible to the application state layer. There is no way to globally observe, retry, or test rating submission. If the API endpoint changes, the fix must be made in the UI layer rather than the infrastructure layer where it belongs.

**Fix Required:** Add a `submitRating(int orderId, int stars)` method to the `OrdersNotifier`. The screen calls `ref.read(ordersProvider.notifier).submitRating(orderId, rating)` and listens via `ref.listen` for state changes.

---

## High Priority Issues

---

### H1 — Application layer imports and instantiates infrastructure concrete implementations

**File:** `lib/features/product_details/application/providers/product_detail_providers.dart:13–15, 64–87`

**Severity:** HIGH

**Issue:** The application-layer provider file imports three concrete infrastructure implementations directly — `ProductDetailRepositoryImpl`, `ProductDetailLocalDataSourceImpl`, and `ProductDetailRemoteDataSourceImpl` — and constructs them inside provider bodies. The application layer should only reference domain interfaces.

**Code:**
```dart
import '../../infrastructure/data_sources/local/product_detail_local_data_source.dart';
import '../../infrastructure/data_sources/remote/product_detail_remote_data_source.dart';
import '../../infrastructure/repositories/product_detail_repository_impl.dart';
// ...
final productDetailLocalDataSourceProvider = Provider<ProductDetailLocalDataSource>((ref) {
  return ProductDetailLocalDataSourceImpl(); // concrete class instantiated in application layer
});
```

**Impact:** The application layer is now tightly coupled to infrastructure implementation details. Swapping the remote data source (e.g. for a mock in tests) requires editing the application-layer provider file.

**Fix Required:** Move the concrete provider registrations into an infrastructure-layer DI file (e.g. `infrastructure/di/product_detail_di.dart`). The application-layer providers depend only on the abstract `ProductDetailRepository` interface.

---

### H2 — Three dead methods in `ProductDetailController` are never called from the screen

**File:** `lib/features/product_details/application/providers/product_detail_providers.dart:420–489`

**Severity:** HIGH

**Issue:** `toggleWishlist()` (line 420), `addToCart()` (line 456), and `setQuantity()` (line 448) exist in the controller but are never used. The actual screen calls `wishlistProvider.notifier.toggleWishlist()`, `checkoutLineControllerProvider.notifier.addToCart()`, and `checkoutLineControllerProvider.notifier.updateQuantity()` directly.

**Code:**
```dart
/// Toggle wishlist status
Future<bool> toggleWishlist() async { ... } // never called by screen

/// Add current product to cart
Future<void> addToCart() async { ... } // never called by screen

/// Update quantity
void setQuantity(int quantity) { ... } // never called by screen
```

**Impact:** Developers reading the controller believe these are the canonical entry points for these actions, but they are dead code. The `isInWishlist` field in `ProductDetailState` is also stale — it is set by `toggleWishlist()` but the screen reads `isInWishlistProvider` from the wishlist feature instead.

**Fix Required:** Remove all three dead methods and remove `isInWishlist` and `quantity` from `ProductDetailState`. Alternatively, make the screen use these methods and remove the cross-feature direct provider calls — but pick one pattern and be consistent.

---

## Medium Priority Issues

---

### M1 — UI-specific string literal embedded in application-layer notifier

**File:** `lib/features/product_details/application/providers/product_detail_providers.dart:427`

**Severity:** MEDIUM

**Issue:** The `toggleWishlist()` method in the controller sets `errorMessage` to a UI-facing user-visible string.

**Code:**
```dart
state = state.copyWith(
  errorMessage: 'Please login to add items to wishlist',
);
```

**Impact:** User-visible text embedded in the business logic layer. Translating the app or updating the message copy requires editing the notifier.

**Fix Required:** Either return a typed error state (e.g. `WishlistError.unauthenticated`) that the UI layer converts to a string, or remove this dead method entirely (see H2).

---

---

# QA Prompt 2 — Security & Data Persistence Violations

---

## Critical Issues

---

### C1 — Hive read errors silently swallowed with no logging in local data source

**File:** `lib/features/product_details/infrastructure/data_sources/local/product_detail_local_data_source.dart:103–105, 157–159`

**Severity:** CRITICAL

**Issue:** Both `getCachedProductDetail()` and `getCachedProductBase()` catch all exceptions and return `null` with zero logging. A `HiveError`, `FormatException`, or type cast failure is silently discarded, making cache corruption completely invisible.

**Code:**
```dart
Future<ProductDetailCacheDto?> getCachedProductDetail(String productId) async {
  try {
    final key = '$_variantMetadataPrefix$productId';
    final json = _box.get(key) as Map<String, dynamic>?;
    return json != null ? ProductDetailCacheDto.fromJson(json) : null;
  } catch (e) {
    return null; // ← exception swallowed, no log, no signal to caller
  }
}
```

**Impact:** If cache data is corrupted (e.g. wrong type stored under the key), every product detail load silently falls back to a force-refresh, burning bandwidth without any diagnostic signal. The team will have no way to detect or track cache corruption rates.

**Fix Required:**
```dart
} catch (e, st) {
  Logger.error('[ProductDetailCache] getCachedProductDetail failed: $e', error: e, stackTrace: st);
  return null;
}
```

---

## High Priority Issues

---

### H1 — Product detail cache metadata is never cleared on logout

**File:** `lib/features/product_details/infrastructure/data_sources/local/product_detail_local_data_source.dart`

**Severity:** HIGH

**Issue:** The `ProductDetailLocalDataSource` has a `clearAllCache()` method but it is never called during logout. The Hive metadata (lastModified, eTag) for every previously viewed product persists across user sessions.

**Impact:** When User B logs in after User A on the same device, the If-Modified-Since headers from User A's browsing session are sent to the server. If the server ties Last-Modified to user-specific data, User B may receive stale or incorrect 304 responses from the server based on User A's cache state.

**Fix Required:** Call `productDetailLocalDataSource.clearAllCache()` inside the logout flow, alongside the existing wishlist/cart/category clearing logic in `AuthNotifier._clearUserData()`.

---

## Medium Priority Issues

---

### M1 — High-volume debug logging fires on every product load and every 30-second poll

**File:** `lib/features/product_details/infrastructure/models/product_variant_dto.dart:357–363`

**Severity:** MEDIUM

**Issue:** `ProductVariantMediaDto.fromJson()` calls `developer.log()` for every media item parsed. A product with 5 media items generates 5 log lines on initial load and another 5 every 30 seconds during polling.

**Code:**
```dart
developer.log(
  '📸 ProductVariantMediaDto.fromJson(): Parsed media item\n'
  '   Raw image: $rawImage\n'
  '   Clean image: $cleanImage\n'
  '   Match: ${rawImage == cleanImage ? "NO CHANGE" : "CLEANED"}',
  name: 'ProductVariantMediaDto',
);
```

**Impact:** In production, `developer.log` is not stripped by Flutter's release mode by default. This adds significant log noise to production crash reports and monitoring tools. A user viewing 10 products generates 50+ log lines per minute in steady state.

**Fix Required:** Wrap in `assert()` or guard with `kDebugMode`. Only log when a URL was actually mutated (i.e. `rawImage != cleanImage`).

---

---

# QA Prompt 3 — Error Handling & Performance

---

## Critical Issues

*No critical violations found in this section.*

---

## High Priority Issues

---

### H1 — Reviews list uses `shrinkWrap: true` with no virtualization — all items rendered eagerly

**File:** `lib/features/product_details/presentation/components/product_reviews/product_reviews.dart:92–107`

**Severity:** HIGH

**Issue:** `ProductReviews` uses `ListView.separated` with `shrinkWrap: true` and `NeverScrollableScrollPhysics()` inside a parent `SingleChildScrollView`. This renders every review card into the widget tree simultaneously — there is no lazy loading or viewport-based virtualization.

**Code:**
```dart
ListView.separated(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: widget.reviews!.length, // all N items rendered at once
  itemBuilder: (context, index) {
    return _AnimatedReviewCard(...);
  },
),
```

**Impact:** If a product has 50+ reviews, all 50 `_AnimatedReviewCard` widgets are instantiated, animated, and laid out on the first render. This causes visible frame drops on entry to the product detail screen on mid-range devices.

**Fix Required:** Cap the visible reviews to a fixed number (e.g. 5) with a "Show all reviews" button that navigates to a separate paginated screen, or use a `SliverList` inside a `CustomScrollView` to replace the nested `SingleChildScrollView` / `shrinkWrap` pattern.

---

### H2 — Polling continues indefinitely on consecutive network failures — no backoff strategy

**File:** `lib/features/product_details/application/providers/product_detail_providers.dart:385–392`

**Severity:** HIGH

**Issue:** The polling timer fires `refresh()` unconditionally every 30 seconds regardless of prior failure state. If the server is down or unreachable, the app makes a network request every 30 seconds for every open product detail screen indefinitely, with no exponential backoff and no failure counter.

**Code:**
```dart
_pollingTimer = Timer.periodic(_pollingInterval, (_) async {
  if (state.isRefreshing) return;
  if (!state.hasData && state.status == ProductDetailStatus.loading) return;
  await refresh(); // fires unconditionally — no backoff on failure
});
```

**Impact:** During a server outage, a user with the product detail screen open floods the server with retries (one per 30 seconds per open product). On reconnection the server receives a burst of requests from all affected clients simultaneously.

**Fix Required:** Track a consecutive failure counter. Apply exponential backoff: after 1 failure, wait 60s; after 2 failures, wait 120s; after 3 failures, wait 240s. Reset counter on success.

---

## Medium Priority Issues

---

### M1 — Identical price calculation logic duplicated between `_buildBody()` and `_buildBottomSheet()`

**File:** `lib/features/product_details/presentation/screen/product_details_screen.dart:215–231, 406–415`

**Severity:** MEDIUM

**Issue:** The logic for resolving `displayPrice` from `socketPriceUpdate`, `discountedPrice`, or fallback `price` appears in two separate methods within the same widget.

**Code:**
```dart
// _buildBody() — lines 215–231
if (socketPriceUpdate != null) {
  displayPrice = socketPriceUpdate.newPrice.toString();
  originalPrice = socketPriceUpdate.oldPrice?.toString();
} else if (productDetail.discountedPrice != null &&
    productDetail.discountedPrice!.isNotEmpty) {
  displayPrice = productDetail.discountedPrice!;
  originalPrice = productDetail.price;
} else {
  displayPrice = productDetail.price;
  originalPrice = null;
}

// _buildBottomSheet() — lines 406–415 (same logic, no originalPrice)
if (socketPriceUpdate != null) {
  displayPrice = socketPriceUpdate.newPrice.toString();
} else if (productDetail.discountedPrice != null &&
    productDetail.discountedPrice!.isNotEmpty) {
  displayPrice = productDetail.discountedPrice!;
} else {
  displayPrice = productDetail.price;
}
```

**Impact:** If the price resolution logic needs to change (e.g. currency formatting, different fallback rules), it must be updated in two places. Risk of the bottom sheet showing a different price than the main body.

**Fix Required:** Extract a `_resolveDisplayPrice(ProductVariant product, PriceUpdateEvent? socketUpdate)` helper function and call it from both methods.

---

### M2 — Empty try-catch-rethrow blocks in repository add no value

**File:** `lib/features/product_details/infrastructure/repositories/product_detail_repository_impl.dart:178–229`

**Severity:** MEDIUM

**Issue:** Five methods (`getProductReviews`, `getProductVariant`, `isInWishlist`, `addToWishlist`, `removeFromWishlist`) wrap their entire body in `try { ... } catch (e) { rethrow; }`. This adds no error handling, no logging, and no transformation — it is equivalent to no try-catch at all.

**Code:**
```dart
@override
Future<List<ProductVariantReview>> getProductReviews(String productId) async {
  try {
    final remoteReviews = await _remoteDataSource.getProductReviews(productId);
    return remoteReviews.map((e) => e.toDomain()).toList();
  } catch (e) {
    rethrow; // ← identical to having no try-catch
  }
}
```

**Impact:** Dead code wrapping. Adds indentation noise, makes the methods harder to read, and gives reviewers the false impression that error handling is in place.

**Fix Required:** Remove the try-catch-rethrow wrappers. If logging is desired, add it before rethrowing.

---

### M3 — Debug log fires on every media parse during every 30-second poll

**File:** `lib/features/product_details/infrastructure/models/product_variant_dto.dart:357–363`

**Severity:** MEDIUM

**Issue:** Identical to Prompt 2 M1 — stated here from a performance perspective. Every 30-second poll for a product with 5 media items triggers 5 separate `developer.log()` calls that serialize multi-line strings with URL comparisons. This adds measurable cost to the parse path at high polling frequency.

**Fix Required:** Guard with `kDebugMode` and only log when `rawImage != cleanImage` (i.e. when a URL was actually mutated).

---

---

# QA Prompt 4 — Code Quality & Deployment Readiness

---

## Critical Issues

---

### C1 — Zero test files exist for the entire product_details feature

**File:** `lib/features/product_details/` (entire directory — 27 files)

**Severity:** CRITICAL

**Issue:** There are no unit, widget, or integration tests for any file in the product_details feature. The entire state machine (`ProductDetailController`), repository, remote data source, and all presentation components are untested.

**Impact:** Any regression in product loading, price display, add-to-cart, wishlist toggle, or rating submission silently ships to production. The product details screen is the highest-traffic screen after home — a regression here directly impacts conversion.

**Fix Required:** At minimum, add:
- Unit tests for `ProductDetailController` state transitions (initial load, 304 response, 200 response, error, refresh)
- Unit tests for `ProductDetailRepositoryImpl` mocking the remote and local data sources
- Widget tests for `PriceRow` (add/increment/decrement flows, out-of-stock state)
- Widget tests for `ProductDetailsScreen` (loading state, error state, in-stock / out-of-stock display)

---

### C2 — `int.parse(product.id)` throws on non-numeric product IDs with no guard

**File:** `lib/features/product_details/presentation/helpers/product_details_helpers.dart:36, 39`

**Severity:** CRITICAL

**Issue:** `convertToProductVariant()` calls `int.parse(product.id)` twice without any null-safety or parse guard. If the API returns a product with a non-numeric ID (e.g. a UUID slug), this throws an uncaught `FormatException` and crashes the app.

**Code:**
```dart
return ProductVariant(
  id: int.parse(product.id),       // throws on non-numeric ID
  sku: product.id,
  // ...
  productId: int.parse(product.id), // same uncaught throw
  ...
);
```

**Impact:** A single product with a non-numeric ID from the API crashes the product detail screen for all users attempting to open it. The error is silent in the calling code.

**Fix Required:**
```dart
final parsedId = int.tryParse(product.id) ?? 0;
return ProductVariant(
  id: parsedId,
  productId: parsedId,
  ...
);
```

---

## High Priority Issues

---

### H1 — Three unused methods in `ProductDetailController` are dead code

**File:** `lib/features/product_details/application/providers/product_detail_providers.dart:420–489`

**Severity:** HIGH

**Issue:** `toggleWishlist()` (line 420), `addToCart()` (line 456), and `setQuantity()` (line 448) are fully implemented methods in the controller that are never called by the screen or any other code. The screen uses `wishlistProvider`, `checkoutLineControllerProvider`, and direct quantity management instead.

**Impact:** Future developers will spend time reading and maintaining these methods under the assumption they are active code paths. The `isInWishlist` and `quantity` fields in `ProductDetailState` exist solely to support these dead methods, bloating the state object.

**Fix Required:** Remove all three methods and their supporting state fields (`isInWishlist`, `quantity`, `isInCart` getter). If there is intent to centralize these in the product controller in future, document the decision with a TODO comment referencing a tracking issue.

---

### H2 — `ProductDetailConfig` is marked deprecated but still actively used

**File:** `lib/features/product_details/application/config/product_detail_config.dart:1–44`

**Severity:** HIGH

**Issue:** The class header comment reads `DEPRECATED: Use CacheConfig instead` yet `ProductDetailConfig` is imported and used in `product_detail_providers.dart`. This creates a maintenance bifurcation — developers editing polling intervals may update `CacheConfig` and assume the change propagates, missing that this wrapper exists.

**Code:**
```dart
/// DEPRECATED: Use CacheConfig instead for global consistency
class ProductDetailConfig {
  static Duration get pollingInterval => CacheConfig.pollingInterval; // delegation wrapper
```

**Impact:** The deprecation comment is misleading — the class is still the active import in the application layer. If `CacheConfig` values are changed, the delegation pattern means `ProductDetailConfig` values are silently updated too, but the reverse path is unclear.

**Fix Required:** Either remove `ProductDetailConfig` entirely and update `product_detail_providers.dart` to import `CacheConfig` directly, or remove the deprecation notice and treat it as a valid feature-level config alias.

---

## Medium Priority Issues

---

### M1 — Emoji characters in production infrastructure logging

**File:** `lib/features/product_details/infrastructure/models/product_variant_dto.dart:35–63`

**Severity:** MEDIUM

**Issue:** `developer.log()` calls in `_fixDuplicateDomainInUrl()` and `ProductVariantMediaDto.fromJson()` use emoji characters (`🔧`, `📸`, `⚠`).

**Code:**
```dart
developer.log(
  '🔧 URL fixed: Removed duplicate domain path\n'
  ...
  name: 'ProductVariantDto',
);
```

**Impact:** Emoji characters in log output can cause encoding issues in log aggregation tools (Sentry, Datadog, CloudWatch). Log parsing pipelines may reject or garble these entries.

**Fix Required:** Replace emoji prefixes with plain text tags: `[URL_FIXED]`, `[MEDIA_PARSE]`, `[URL_ERROR]`. Guard all logging with `kDebugMode`.

---

### M2 — Hardcoded icon size `18` without `.sp` in back button

**File:** `lib/features/product_details/presentation/screen/product_details_screen.dart:258`

**Severity:** MEDIUM

**Issue:** The back button icon uses a hardcoded raw pixel size.

**Code:**
```dart
child: const Icon(
  Icons.arrow_back_ios_new,
  size: 18, // ← should be 18.sp
  color: AppColors.black,
),
```

**Impact:** Icon does not scale on tablets or high-density displays. Inconsistent with the rest of the screen which correctly uses `.sp`, `.h`, `.w`, `.r`.

**Fix Required:** `size: 18.sp` and remove `const`.

---

### M3 — Hardcoded icon sizes `28` in `PriceRow` quantity selector

**File:** `lib/features/product_details/presentation/components/price_row/price_row.dart:149, 172`

**Severity:** MEDIUM

**Issue:** The decrement and increment icons both use hardcoded `size: 28` without ScreenUtil.

**Code:**
```dart
const Icon(Icons.remove, color: AppColors.green100, size: 28)
// ...
Icon(Icons.add, color: isEnabled ? AppColors.green100 : AppColors.grey, size: 28)
```

**Impact:** Quantity selector icons do not scale on tablets, appearing visually disproportionate to surrounding text which uses `.sp`.

**Fix Required:** `size: 28.sp` on both icons. Remove `const` from the `Icons.remove` widget.

---

### M4 — Bottom padding uses magic number `100.h` with no explanation

**File:** `lib/features/product_details/presentation/screen/product_details_screen.dart:391`

**Severity:** MEDIUM

**Issue:** `SizedBox(height: 100.h)` is added at the end of the scroll column to provide space above the bottom sheet. The `100` is undocumented.

**Code:**
```dart
// Add bottom padding for bottom sheet
SizedBox(height: 100.h),
```

**Impact:** If the bottom sheet height changes, this magic value must be updated manually. The comment acknowledges the connection but does not document how `100` was derived.

**Fix Required:** Extract `const double _bottomSheetHeight = 100` to a named constant, or compute it dynamically using `CheckoutSection`'s actual rendered height.

---

---

# QA Prompt 6 — Architecture Compliance (4-Layer Violations)

---

## Critical Issues

---

### C1 — Presentation layer calls orders infrastructure API directly, bypassing application layer

**File:** `lib/features/product_details/presentation/screen/product_details_screen.dart:20, 559–579`

**Layer:** Presentation → Infrastructure (Rule 4 violation)

**Severity:** CRITICAL

**Issue:** The screen imports `orders_api.dart` (infrastructure remote layer) and calls `ref.read(ordersApiProvider).submitOrderRating(...)` directly inside `_handleRatingSubmit()`. The `OrdersNotifier` is completely bypassed.

**Code:**
```dart
import '../../../orders/infrastructure/data_sources/orders_api.dart';
// ...
await ref
    .read(ordersApiProvider)
    .submitOrderRating(orderId: orderId, stars: rating);
```

**Impact:** The presentation layer holds a direct reference to infrastructure. The 4-layer boundary is broken. No `OrdersState` is emitted. Loading/error state is unobservable from the outside. GoRouter cannot react to rating submission outcomes.

**Fix Required:** Add `submitRating(int orderId, int stars)` to `OrdersNotifier`. Screen uses `ref.read(ordersProvider.notifier).submitRating(...)` and listens via `ref.listen` for outcome.

---

### C2 — Presentation imports `InsufficientStockException` from cart infrastructure layer

**File:** `lib/features/product_details/presentation/screen/product_details_screen.dart:16`

**Layer:** Presentation → Infrastructure (Rule 4 violation)

**Severity:** CRITICAL

**Issue:** The screen imports `checkout_line_data_source.dart` from the cart infrastructure layer solely to catch `InsufficientStockException`. Domain exception types must be defined in the domain layer, not the infrastructure layer.

**Code:**
```dart
import '../../../cart/infrastructure/data_sources/remote/checkout_line_data_source.dart';
// ...
} on InsufficientStockException catch (e) {
  AppSnackbar.warning(context, e.message);
}
```

**Impact:** Any refactoring of the cart infrastructure (renaming the exception, moving the file) breaks this product details screen. The cart feature's internal infrastructure is now a transitive dependency of the product details presentation layer.

**Fix Required:** Move `InsufficientStockException` to `lib/features/cart/domain/exceptions/cart_exceptions.dart`. The presentation layer imports from the domain layer, not infrastructure.

---

### C3 — Application layer imports and uses infrastructure concrete classes directly

**File:** `lib/features/product_details/application/providers/product_detail_providers.dart:13–15`

**Layer:** Application → Infrastructure (Rule 5 violation)

**Severity:** CRITICAL

**Issue:** Three direct imports of infrastructure concrete implementations inside the application layer. Application layer must only depend on domain contracts.

**Code:**
```dart
import '../../infrastructure/data_sources/local/product_detail_local_data_source.dart';
import '../../infrastructure/data_sources/remote/product_detail_remote_data_source.dart';
import '../../infrastructure/repositories/product_detail_repository_impl.dart';
```

**Impact:** Dependency inversion is broken. The application layer cannot be tested without bringing the infrastructure layer into scope. Swapping implementations (e.g. using a mock remote source in tests) requires editing application-layer files.

**Fix Required:** Create `infrastructure/di/product_detail_di.dart` to house provider registrations for concrete implementations. Application-layer providers receive only the `ProductDetailRepository` abstract interface.

---

## High Priority Issues

---

### H1 — `ProductInfo` is a `StatefulWidget` with no widget state

**File:** `lib/features/product_details/presentation/components/product_info/product_info.dart`

**Layer:** Presentation (Rule 15 violation)

**Severity:** HIGH

**Issue:** `ProductInfo` extends `StatefulWidget` but `_ProductInfoState` contains no `setState()` calls, no `AnimationController`, and no local mutable state. The only method in the state class is `_parseWeight()`, a pure synchronous transformation function.

**Code:**
```dart
class ProductInfo extends StatefulWidget { ... }

class _ProductInfoState extends State<ProductInfo> {
  String _parseWeight(String weight) { ... } // pure function — not state

  @override
  Widget build(BuildContext context) { ... } // no setState anywhere
}
```

**Impact:** Creates unnecessary widget lifecycle overhead (two object allocations per render). Misleads developers into thinking there is stateful behavior when there is none.

**Fix Required:** Convert to `StatelessWidget`. Move `_parseWeight()` to `product_details_helpers.dart` (it is a pure utility function).

---

### H2 — `ProductDetailRepository` domain contract includes wishlist operations that belong in `WishlistRepository`

**File:** `lib/features/product_details/domain/repositories/product_detail_repository.dart:42–47`

**Layer:** Domain (Rule 9 — domain contract contains unrelated responsibilities)

**Severity:** HIGH

**Issue:** The `ProductDetailRepository` abstract contract declares `isInWishlist()`, `addToWishlist()`, and `removeFromWishlist()`. These operations belong to the wishlist domain, not the product detail domain. The screen bypasses these entirely and uses `wishlistProvider` directly.

**Code:**
```dart
abstract class ProductDetailRepository {
  // ...product detail methods...

  /// Check if product is in wishlist
  Future<bool> isInWishlist(String productId);

  /// Add product to wishlist
  Future<void> addToWishlist(String productId);

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String productId);
}
```

**Impact:** The product detail repository implementation (`ProductDetailRepositoryImpl`) must implement six wishlist methods in its own remote data source even though wishlist already has its own full implementation. This creates duplicated, divergent implementations of the same operations.

**Fix Required:** Remove the three wishlist methods from `ProductDetailRepository`, `ProductDetailRepositoryImpl`, and `ProductDetailRemoteDataSource`. The screen already uses `wishlistProvider` directly — this is the correct pattern.

---

## Medium Priority Issues

---

### M1 — `ref.watch()` called inside `_buildBody()` — not directly in `build()`

**File:** `lib/features/product_details/presentation/screen/product_details_screen.dart:204`

**Layer:** Presentation (Rule 21 — ref.watch/read usage)

**Severity:** MEDIUM

**Issue:** `ref.watch(isInWishlistProvider(widget.variantId))` is called inside `_buildBody()`, not directly in `build()`. Although `_buildBody()` is called synchronously from `build()` (making this functionally correct today), it violates the explicit rule that `ref.watch()` must appear only inside `build()` — not in helper methods.

**Code:**
```dart
Widget _buildBody({ ... }) {
  // Check wishlist status from wishlist provider
  final isInWishlist = ref.watch(isInWishlistProvider(widget.variantId)); // ← in helper, not build()
  ...
}
```

**Impact:** If `_buildBody()` is ever called from a gesture handler or async callback by a future developer (a natural refactoring), this will silently break — `ref.watch` in a callback does not subscribe and returns a stale snapshot.

**Fix Required:** Move the `ref.watch(isInWishlistProvider(...))` call into `build()` and pass `isInWishlist` as a parameter to `_buildBody()`. All `ref.watch` calls are already at the top of `build()` — add this one there.

---

### M2 — Hardcoded pixel values violate ScreenUtil rule (Rule 19)

**File:** `lib/features/product_details/presentation/screen/product_details_screen.dart:258` and `lib/features/product_details/presentation/components/price_row/price_row.dart:149, 172`

**Layer:** Presentation (Rule 19 violation)

**Severity:** MEDIUM

**Issue:** Three icon size usages use raw pixel integers instead of ScreenUtil `.sp` units.

**Code:**
```dart
// product_details_screen.dart:258
Icon(Icons.arrow_back_ios_new, size: 18, ...) // → 18.sp

// price_row.dart:149
const Icon(Icons.remove, ..., size: 28) // → 28.sp

// price_row.dart:172
Icon(Icons.add, ..., size: 28) // → 28.sp
```

**Impact:** Icons do not scale on tablet form factors or high-density displays. Inconsistent with the majority of the codebase which uses `.sp` for icon sizes.

**Fix Required:** Replace all three with `.sp` equivalents and remove `const` where it prevents `.sp` usage.

---

### M3 — Feature folder is missing `usecases/` directory in application layer

**File:** `lib/features/product_details/application/`

**Layer:** Application (Rule 18 — folder structure)

**Severity:** MEDIUM

**Issue:** The `application/` directory contains `providers/`, `states/`, and `config/` but no `usecases/` directory. The merge-and-enrich logic (`_mergeProductData()`) currently lives inside the controller, which is a complex operation that warrants extraction to a use case.

**Impact:** The `_mergeProductData()` method is 50 lines of field-by-field merging inside the notifier. As the merge rules grow (more fields, more data sources), the notifier becomes increasingly complex without a natural home for the logic.

**Fix Required:** Create `application/usecases/merge_product_data_usecase.dart`. Extract `_mergeProductData()` from the controller into a `MergeProductDataUseCase` class. The controller calls `_mergeUseCase.execute(variant, productBase)`.

---
