# Orders Flow — Code Audit Report

**Scope:** Orders Screen (Order History · Active Orders · Previous Orders) — `/orders`

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 6

**Date:** 2026-05-02

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 2 | 3 | 2 | 7 |
| Prompt 2 — Security & Data Persistence | 0 | 2 | 1 | 3 |
| Prompt 3 — Performance & Error Handling | 2 | 3 | 3 | 8 |
| Prompt 4 — Code Quality & Deployment | 0 | 4 | 4 | 8 |
| Prompt 6 — Architecture Compliance | 3 | 3 | 4 | 10 |
| **Total** | **7** | **15** | **14** | **36** |

---

## Top Blockers Before Any Production Release

1. **No domain repository abstract class exists** — the entire `features/orders/domain/repositories/` folder is absent. `OrdersNotifier` holds a direct reference to `OrdersApi` (infrastructure), with no domain contract in between. There is no way to test, swap, or mock the orders data layer.
2. **Presentation layer imports and calls infrastructure directly** — `orders_screen.dart` imports `orders_api.dart` and calls `ref.read(ordersApiProvider)` from three separate UI methods (`_handleReorder`, `_submitOrderRating`, `_saveRating`). Business operations bypass the notifier entirely.
3. **N+1 API calls in the Previous tab** — `fetchCompletedOrders()` fires one `getOrderRating()` HTTP request per order via `Future.wait`. A user with 50 completed orders causes 51 simultaneous API requests every time the tab is opened.
4. **No pagination** — `getOrders()` fetches only page 1 and the UI has no load-more mechanism. Users with more orders than fit on page 1 silently miss their history.
5. **`ordersApiProvider` defined inside infrastructure** — provider registration is an application-layer concern; placing it in `orders_api.dart` forces all consumers to import the infrastructure file.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

---

### C1 — Presentation layer directly calls `ordersApiProvider` — bypasses notifier entirely

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:260, 451, 917`

**Severity:** CRITICAL

**Issue:** Three separate UI methods in the screen call `ref.read(ordersApiProvider)` to execute business operations directly against the infrastructure data source. `_handleReorder` fetches order lines, `_submitOrderRating` submits a rating, and `_OrderCardState._saveRating` submits a rating. All three bypass `OrdersNotifier`, which means state is not updated after the operation and the operations have no centrally managed error handling.

**Code:**
```dart
// _handleReorder (line 260)
final ordersApi = ref.read(ordersApiProvider);
final orderLines = await ordersApi.getOrderLines(order.id.toString());

// _submitOrderRating (line 451)
await ref.read(ordersApiProvider).submitOrderRating(orderId: orderId, stars: stars);

// _OrderCardState._saveRating (line 917)
await ref.read(ordersApiProvider).submitOrderRating(
  orderId: widget.order.id,
  stars: _rating,
  ...
);
```

**Impact:** UI widgets directly access infrastructure. State changes caused by these operations (order lines loaded, rating submitted) are not reflected in `ordersProvider` state. Two separate widgets (`_OrdersScreenState` and `_OrderCardState`) contain their own rating submission paths with different implementations, creating divergent behavior.

**Fix Required:** Move `reorderFromOrder()`, `submitRating()`, and `updateRating()` into `OrdersNotifier`. The screen calls `ref.read(ordersProvider.notifier).submitRating(orderId, stars)`. The notifier handles the API call, updates state, and emits the result.

---

### C2 — `OrdersNotifier` injects `OrdersApi` (infrastructure) directly — no domain repository contract

**File:** `lib/features/orders/application/providers/orders_provider.dart:49–52`

**Severity:** CRITICAL

**Issue:** `OrdersNotifier` takes `OrdersApi` (a concrete infrastructure class) as a constructor argument instead of an abstract `OrdersRepository` domain contract. There is no `OrdersRepository` abstract class anywhere in the feature. This collapses the dependency inversion principle — the application layer is hardwired to the infrastructure implementation.

**Code:**
```dart
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersApi _ordersApi; // ← infrastructure class, not domain interface

  OrdersNotifier(this._ordersApi) : super(const OrdersState());
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final ordersApi = ref.watch(ordersApiProvider); // ← infrastructure provider
  return OrdersNotifier(ordersApi);
});
```

**Impact:** `OrdersNotifier` cannot be unit tested without a real API. Swapping the data source (e.g. for offline caching) requires modifying the notifier. There is no clean boundary between what the notifier is allowed to call and the full set of HTTP operations.

**Fix Required:** Create `lib/features/orders/domain/repositories/orders_repository.dart` as an abstract class. Create `lib/features/orders/infrastructure/repositories/orders_repository_impl.dart` that implements it using `OrdersApi`. `OrdersNotifier` injects `OrdersRepository` (abstract), provided via `ordersRepositoryProvider` in the application layer.

---

## High Priority Issues

---

### H1 — `ordersProvider` uses deprecated `StateNotifier` / `StateNotifierProvider` pattern

**File:** `lib/features/orders/application/providers/orders_provider.dart:49, 132`

**Severity:** HIGH

**Issue:** `OrdersNotifier extends StateNotifier<OrdersState>` and `ordersProvider = StateNotifierProvider` use the deprecated Riverpod 1.x API. The rest of the codebase uses Riverpod 2.x codegen (`@riverpod`, `Notifier<T>`). This feature is architecturally inconsistent with the rest of the app.

**Code:**
```dart
class OrdersNotifier extends StateNotifier<OrdersState> { ... }

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final ordersApi = ref.watch(ordersApiProvider);
  return OrdersNotifier(ordersApi);
});
```

**Impact:** Two different state management paradigms in the same app. `StateNotifier` is deprecated in Riverpod 2.x. Developers must context-switch between the old and new patterns. Codegen providers gain type safety, `ref` access, and lifecycle benefits automatically.

**Fix Required:** Migrate to `@riverpod class OrdersController extends _$OrdersController` with the modern codegen pattern used across the rest of the codebase.

---

### H2 — `orderDetailsProvider = FutureProvider.family` missing `autoDispose` for per-order dynamic data

**File:** `lib/features/orders/application/providers/orders_provider.dart:140–146`

**Severity:** HIGH

**Issue:** `orderDetailsProvider` is a `FutureProvider.family` without `autoDispose`. Family providers keyed on dynamic values (here, `orderId: String`) accumulate one provider instance per unique order ID in memory and never release them. Each time an order is viewed, a new cached provider instance is created and retained indefinitely.

**Code:**
```dart
final orderDetailsProvider = FutureProvider.family<OrderEntity, String>((
  ref,
  orderId,
) async {
  final ordersApi = ref.watch(ordersApiProvider);
  return ordersApi.getOrderDetails(orderId);
});
```

**Impact:** Memory leak proportional to the number of unique order IDs the user accesses during a session. On a long session with many orders, this accumulates stale provider instances that are never garbage-collected.

**Fix Required:** `FutureProvider.family.autoDispose` — this ensures the provider instance is released when the consuming widget is disposed. If stale-while-revalidate behaviour is needed, use `keepAlive()` in the provider body with an explicit TTL.

---

### H3 — `fetchCompletedOrders` contains N+1 business logic that belongs in a use case

**File:** `lib/features/orders/application/providers/orders_provider.dart:83–122`

**Severity:** HIGH

**Issue:** `OrdersNotifier.fetchCompletedOrders()` performs application-level business logic: fetch orders, then for each order fetch its rating and merge the data. This is a multi-step orchestration that belongs in a dedicated use case class (`FetchCompletedOrdersWithRatingsUseCase`). The notifier should call a single use case method, not implement the orchestration itself.

**Code:**
```dart
Future<void> fetchCompletedOrders() async {
  final orders = await _ordersApi.getOrders(status: 'delivered');

  // N+1: one API call per order
  final ordersWithRatings = await Future.wait(
    orders.map((order) async {
      final rating = await _ordersApi.getOrderRating(order.id);
      if (rating != null) {
        return OrderEntity(id: order.id, ..., rating: rating);
      }
      return order;
    }),
  );
  state = state.copyWith(orders: ordersWithRatings, isLoading: false);
}
```

**Impact:** Business orchestration is locked inside the notifier, making it untestable in isolation. The N+1 pattern is a serious performance issue (see Prompt 3 C1). If the rating merge logic needs to change (e.g. batch ratings endpoint is added), the notifier must be modified.

**Fix Required:** Extract into `FetchCompletedOrdersWithRatingsUseCase`. The notifier calls `_useCase.execute()` and assigns the result to state. The use case owns the fetch-then-merge logic.

---

## Medium Priority Issues

---

### M1 — `OrdersState` is a plain mutable Dart class instead of a freezed sealed union

**File:** `lib/features/orders/application/providers/orders_provider.dart:7–46`

**Severity:** MEDIUM

**Issue:** `OrdersState` is a plain class with `const` constructor and manual `copyWith`. It has no sealed-union states (`loading`, `loaded`, `error`) — instead, `isLoading` and `errorMessage` are nullable fields that can appear in any combination. This allows impossible states such as `isLoading: true` and `errorMessage: 'Network error'` simultaneously.

**Code:**
```dart
class OrdersState {
  final List<OrderEntity> orders;
  final bool isLoading;       // can be true simultaneously with...
  final String? errorMessage; // ...a non-null error message
  final String? activeFilter;
  ...
}
```

**Impact:** Any combination of loading/error/data flags is technically legal. UI code must guard against impossible combinations manually. States like `errorMessage != null && isLoading == true` can occur if error and loading flags are set in different `copyWith` calls.

**Fix Required:** Convert to a `freezed` sealed union with `OrdersState.initial()`, `OrdersState.loading()`, `OrdersState.loaded(List<OrderEntity> orders)`, `OrdersState.error(String message)`. Use `state.when()` in the UI to exhaustively handle each case.

---

### M2 — `_statusText` business logic in `_OrderCardState` widget

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:516–535`

**Severity:** MEDIUM

**Issue:** The `_statusText` getter performs status string mapping inside the widget state class. This is business/domain logic — the canonical human-readable label for each order status — embedded in a UI component.

**Code:**
```dart
String get _statusText {
  final status = widget.order.status.toLowerCase();
  switch (status) {
    case 'active':
    case 'shipped':
    case 'on_delivery':
    case 'out_for_delivery':
      return 'On Delivery';
    case 'pending':
    case 'processing':
      return 'Processing';
    ...
  }
}
```

**Impact:** Status label logic is duplicated if another widget ever needs to display the same status text. The mapping cannot be unit tested without rendering the widget. If a new status is added to the API, this widget must be updated manually.

**Fix Required:** Add a `displayStatus` getter to `OrderEntity` in the domain layer (or an extension). The widget renders `widget.order.displayStatus` directly.

---

---

# QA Prompt 2 — Security & Data Persistence Violations

---

## Critical Issues

*No critical security violations found in this feature. The orders feature does not use Hive, SharedPreferences, Firebase Auth, or hardcoded credentials.*

---

## High Priority Issues

---

### H1 — `ordersApiProvider` defined inside the infrastructure data source file

**File:** `lib/features/orders/infrastructure/data_sources/orders_api.dart:238`

**Severity:** HIGH

**Issue:** The Riverpod provider `ordersApiProvider` is defined at the bottom of `orders_api.dart` — an infrastructure file. Provider registrations are application-layer constructs. Any file that needs the provider must import the infrastructure implementation file, collapsing the layer boundary.

**Code:**
```dart
// In orders_api.dart (infrastructure):
final ordersApiProvider = Provider<OrdersApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrdersApi(apiClient);
});
```

**Impact:** Presentation and application files must `import '../../infrastructure/data_sources/orders_api.dart'` to obtain the provider. This forces the entire feature to depend on the infrastructure file rather than the domain contract.

**Fix Required:** Move `ordersApiProvider` to `lib/features/orders/application/providers/orders_providers.dart`. Once `OrdersRepository` is introduced (see Prompt 1 C2), the only exported provider should be `ordersRepositoryProvider`. `ordersApiProvider` becomes an implementation detail that is only referenced inside the repository provider factory.

---

### H2 — No local caching — order history always fetched from network

**File:** `lib/features/orders/infrastructure/data_sources/orders_api.dart`

**Severity:** HIGH

**Issue:** The orders feature has no local data source at all (`infrastructure/data_sources/local/` is absent). Every visit to the orders screen triggers a full network fetch. There is no offline fallback — users without network connectivity see only the error state with no historical data.

**Code:**
```dart
// In OrdersNotifier.fetchOrders:
try {
  final orders = await _ordersApi.getOrders(status: status);
  state = state.copyWith(orders: orders, isLoading: false);
} catch (e) {
  state = state.copyWith(isLoading: false, errorMessage: e.toString());
}
// No cache-check-first pattern. No fallback to cached data on network error.
```

**Impact:** App fails silently offline — users travelling or in low-signal areas cannot view any order history. Combined with the N+1 rating calls (Prompt 3 C1), every tab switch to "Previous" hammers the network.

**Fix Required:** Add `lib/features/orders/infrastructure/data_sources/local/orders_local_data_source.dart` using Hive. The infrastructure repository checks the local cache first and falls back to the API. On successful API response, persist to cache.

---

## Medium Priority Issues

---

### M1 — `DioException.message` propagated directly in re-thrown exceptions

**File:** `lib/features/orders/infrastructure/data_sources/orders_api.dart:39–42, 102–105, 133–136`

**Severity:** MEDIUM

**Issue:** Every `DioException` is caught and re-thrown as a plain `Exception` with the raw `e.message` string concatenated. `DioException.message` can contain internal network details (DNS names, internal IP addresses, API base URLs) that are not appropriate for end-user-visible error strings.

**Code:**
```dart
on DioException catch (e) {
  throw Exception('Error loading orders: ${e.message}');
}
```

**Impact:** Internal network error details may surface in user-visible snackbars (since `OrdersNotifier` assigns `e.toString()` directly to `state.errorMessage`). Minor information disclosure risk and poor UX.

**Fix Required:** Map `DioException` to typed domain failures (`NetworkFailure`, `ServerFailure`, `NotFoundFailure`) using the same exception-mapping pattern used in the rest of the app. The UI renders a generic friendly message; the original error is logged for debugging only.

---

---

# QA Prompt 3 — Error Handling & Performance

---

## Critical Issues

---

### C1 — N+1 API call pattern in `fetchCompletedOrders` — 1 order = 1+N simultaneous requests

**File:** `lib/features/orders/application/providers/orders_provider.dart:95–116`

**Severity:** CRITICAL

**Issue:** `fetchCompletedOrders()` calls `Future.wait(orders.map((order) async { await _ordersApi.getOrderRating(order.id); }))`. This fires one `getOrderRating()` HTTP request for every completed order simultaneously. A user with 30 completed orders generates 31 concurrent API requests (1 for the orders list + 30 for ratings). There is no batching, no rate limiting, and no per-request timeout.

**Code:**
```dart
final ordersWithRatings = await Future.wait(
  orders.map((order) async {
    final rating = await _ordersApi.getOrderRating(order.id); // ← 1 call per order
    if (rating != null) {
      return OrderEntity(id: order.id, ..., rating: rating);
    }
    return order;
  }),
);
```

**Impact:** On accounts with many completed orders: server overload, high mobile data consumption, slow UI (all 30 requests must complete before state updates), and potential rate-limiting 429 errors from the API. The entire "Previous" tab is blocked until all N+1 calls resolve.

**Fix Required:** Request a batch ratings endpoint from the backend (e.g. `GET /api/order/v1/ratings/?order_ids=1,2,3`). If no batch endpoint exists, limit concurrent rating fetches to a sliding window of 3–5 at a time using chunked `Future.wait`. Alternatively, fetch ratings lazily only when an order card is expanded.

---

### C2 — No pagination — `getOrders()` only fetches page 1 with no load-more

**File:** `lib/features/orders/infrastructure/data_sources/orders_api.dart:17–43`

**Severity:** CRITICAL

**Issue:** `getOrders()` only fetches `page: 1`. The API returns paginated data (`count`, `next`, `previous`, `results`) but the `next` cursor is never followed. The UI has no load-more button or infinite scroll. Users with more orders than the first page limit (typically 10–20) silently miss their older orders.

**Code:**
```dart
final response = await _apiClient.get(
  ApiEndpoints.orders,
  queryParameters: {'page': page, if (status != null) 'status': status},
);

final data = response.data as Map<String, dynamic>;
final results = data['results'] as List? ?? [];
// `data['next']` is never checked — pagination ignored entirely
return results.map(...).toList();
```

**Impact:** Deployment blocker for production: any user who has placed more orders than a single page holds will see an incomplete order history with no indication that older orders exist. The feature silently truncates the user's data.

**Fix Required:** Follow the pagination cursor in `getOrders()` (same pattern used in `CheckoutLineDataSource.fetchCheckoutLines()`), accumulating all pages. Or implement infinite scroll in `OrdersScreen` with a `page` counter and a "Load more" trigger at the list bottom.

---

## High Priority Issues

---

### H1 — Sequential `await` in reorder loop — one item added at a time

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:282–315`

**Severity:** HIGH

**Issue:** `_handleReorder()` iterates over all order lines and `await`s each `addToCart()` call sequentially. If the user is reordering a 10-item order, 10 API calls are made one-at-a-time, causing the operation to take 10× longer than necessary.

**Code:**
```dart
for (final orderLine in orderLines) {
  try {
    await checkoutLineNotifier.addToCart(    // ← sequential await
      productVariantId: orderLine.productVariantId,
      quantity: orderLine.quantity,
    );
    successCount++;
  } catch (e) {
    failedCount++;
  }
}
```

**Impact:** A 10-item reorder takes 10 sequential round-trips (approximately 5–10 seconds on a 500ms average latency connection). The snackbar "Adding items to cart..." blocks the user for the full duration with no progress indication.

**Fix Required:** Use `Future.wait()` with bounded concurrency to add all items in parallel, or at minimum in batches of 3. Track successes and failures via parallel futures. This reduces perceived latency by 5–10×.

---

### H2 — `_saveRating()` and `_submitOrderRating()` are duplicated rating paths with different implementations

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:443–471 (parent), 904–954 (child)`

**Severity:** HIGH

**Issue:** Rating submission is implemented twice in the same file: `_OrdersScreenState._submitOrderRating()` (called from `_handleWriteReview`) and `_OrderCardState._saveRating()` (called from the inline review editor). Both call `ref.read(ordersApiProvider).submitOrderRating()` directly. The two implementations differ: the card version passes `ratingId` for update support; the screen version does not. Both have independent error handling.

**Code:**
```dart
// In _OrdersScreenState (line 451):
await ref.read(ordersApiProvider).submitOrderRating(orderId: orderId, stars: stars);
// No ratingId — cannot update existing rating

// In _OrderCardState (line 917):
await ref.read(ordersApiProvider).submitOrderRating(
  orderId: widget.order.id, stars: _rating, ratingId: widget.order.rating?.id,
);
// Supports ratingId — can update
```

**Impact:** Two different behaviours for the same user action depending on which entry point is triggered. The simpler path (`_submitOrderRating`) will always create a new rating and fail with "already rated" for orders that already have one, because it never passes `ratingId`.

**Fix Required:** Delete `_OrdersScreenState._handleWriteReview()` and `_submitOrderRating()`. Use only the `_OrderCard`'s inline rating editor. Move the rating API call into `OrdersNotifier.submitRating()` so both paths converge on a single implementation.

---

### H3 — `Image.network()` in order cards without caching — re-downloads on every scroll

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:608–614`

**Severity:** HIGH

**Issue:** Product images in `_OrderCard` use `Image.network()` with no cache provider (e.g. `cached_network_image`). In a `ListView.builder`, off-screen cards are disposed and rebuilt on scroll — every time a card re-enters the viewport, its product image is re-downloaded from the network.

**Code:**
```dart
child: firstProductImage != null
    ? Image.network(
        firstProductImage,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => Icon(...),
      )
    : Icon(Icons.shopping_bag_outlined, ...),
```

**Impact:** Scrolling through order history causes repeated network image fetches for the same images. On slow connections, images appear blank momentarily on every re-entry. Wastes mobile data.

**Fix Required:** Replace `Image.network()` with `CachedNetworkImage()` from the `cached_network_image` package (already used elsewhere in the app). The package handles disk and memory caching automatically.

---

## Medium Priority Issues

---

### M1 — `_formatDate()` duplicated in two places within the same file

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:412–427 and 537–561`

**Severity:** MEDIUM

**Issue:** Date formatting logic with a hardcoded month-name array is written twice: once in `_OrdersScreenState._handleWriteReview()` (lines 412–427) and again in `_OrderCardState._formatDate()` (lines 537–561). The two implementations are not identical — one is inline, one is a method — and both maintain their own `months` array literal.

**Code:**
```dart
// In _OrdersScreenState._handleWriteReview (line 412):
final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
final formattedDate = '${deliveryDate.day} ${months[deliveryDate.month - 1]} ${deliveryDate.year}';

// In _OrderCardState._formatDate (line 538):
final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
return '$day $month $year at $hour:$minute $period';
```

**Impact:** If date format requirements change (e.g. full month name, locale-aware), two places must be updated. Divergence has already occurred — the parent version omits the time component.

**Fix Required:** Extract to a static utility function in `core/utils/date_formatter.dart`. Both usages call the shared function.

---

### M2 — `OrdersState.activeOrders`, `pendingOrders`, `completedOrders` getters are dead code

**File:** `lib/features/orders/application/providers/orders_provider.dart:38–45`

**Severity:** MEDIUM

**Issue:** `OrdersState` defines three computed list getters (`activeOrders`, `pendingOrders`, `completedOrders`) that filter the `orders` list by status. None of these getters are called anywhere in the codebase — the UI uses the raw `state.orders` list and the tab (`_isActiveTab`) controls which API call is made, not which getter is used.

**Code:**
```dart
List<OrderEntity> get activeOrders =>
    orders.where((o) => o.isActive).toList();

List<OrderEntity> get pendingOrders =>
    orders.where((o) => o.isPending).toList();

List<OrderEntity> get completedOrders =>
    orders.where((o) => o.isCompleted).toList();
```

**Impact:** Dead code that adds confusion. The `activeFilter` state field is also never used for client-side filtering — the filtering is done server-side via API parameters. The state model claims to support client-side filtering but the UI ignores it.

**Fix Required:** Remove all three computed getters and the `activeFilter` field from `OrdersState`. The API-driven tab switching already handles all filtering server-side.

---

### M3 — No timeout on individual `getOrderRating()` calls in `Future.wait`

**File:** `lib/features/orders/application/providers/orders_provider.dart:95–116`

**Severity:** MEDIUM

**Issue:** `Future.wait(orders.map((o) => _ordersApi.getOrderRating(o.id)))` has no per-call or aggregate timeout. If one rating endpoint hangs, the entire `Future.wait` blocks indefinitely until Dio's connection timeout fires (which may be 30+ seconds).

**Code:**
```dart
final ordersWithRatings = await Future.wait(
  orders.map((order) async {
    final rating = await _ordersApi.getOrderRating(order.id); // no timeout
    ...
  }),
);
```

**Impact:** A single slow rating API call blocks the entire "Previous" tab from loading. Users see an infinite spinner with no recourse.

**Fix Required:** Wrap each rating call with `.timeout(const Duration(seconds: 5), onTimeout: () => null)`. Since `getOrderRating` already returns `null` on error, a timeout can safely return `null` and the order is shown without a rating rather than blocking the list.

---

---

# QA Prompt 4 — Code Quality & Deployment Readiness

---

## Critical Issues

*No critical deployment blockers specific to this screen beyond those already identified in Prompts 1 and 3 (N+1 API pattern, missing pagination).*

---

## High Priority Issues

---

### H1 — `_navigateToCart()` uses `BottomNavigation.globalKey` — fragile global state navigation

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:353–358`

**Severity:** HIGH

**Issue:** After a successful reorder, `_navigateToCart()` calls `BottomNavigation.globalKey.currentState?.navigateToTab(3)` — the same global key anti-pattern flagged in the Cart audit. This couples the Orders screen to the specific tab index of the bottom navbar and bypasses GoRouter entirely.

**Code:**
```dart
void _navigateToCart() {
  Navigator.of(context).pop();
  BottomNavigation.globalKey.currentState?.navigateToTab(3); // tab 3 = Cart
}
```

**Impact:** If the tab order changes, the reorder flow silently navigates to the wrong tab. If GoRouter manages the navigation stack, `Navigator.of(context).pop()` may conflict with GoRouter's back-stack state. The `?.` null-safe call means navigation silently fails if the global key is not attached.

**Fix Required:** Use GoRouter: `context.go('/cart')` navigates to the cart route without depending on tab indices or global keys.

---

### H2 — AppBar back button uses `Navigator.of(context).pop()` instead of GoRouter

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:63`

**Severity:** HIGH

**Issue:** The AppBar back button calls `Navigator.of(context).pop()` directly. The rest of the app uses GoRouter for navigation. Mixing `Navigator` and GoRouter bypasses GoRouter's route stack management and can produce double-pop or orphaned routes in certain navigation paths.

**Code:**
```dart
onPressed: () => Navigator.of(context).pop(),
```

**Impact:** If the orders screen is navigated to via a deep link or GoRouter push, `Navigator.of(context).pop()` may pop an unexpected route. Consistent use of `context.pop()` (GoRouter) is required throughout.

**Fix Required:** `onPressed: () => context.pop()` using GoRouter's `pop()` method.

---

### H3 — No pagination in `OrdersScreen` — users with many orders silently miss history

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:161–175`

**Severity:** HIGH

**Issue:** `_buildBody()` renders all orders from `state.orders` in a `ListView.builder` with no load-more trigger, no pagination indicator, and no "X of Y orders shown" count. Since `getOrders()` only fetches page 1, the list is always truncated for users with more orders than the API page size.

**Code:**
```dart
return RefreshIndicator(
  onRefresh: () async => _fetchOrders(),
  child: ListView.builder(
    itemCount: state.orders.length,  // ← always ≤ page 1 count, no more
    itemBuilder: (context, index) => _OrderCard(...),
  ),
);
```

**Impact:** Users who have placed more than ~10–20 orders (the typical API page size) will see an incomplete order list. There is no visual indicator that older orders are missing. Users cannot access their full purchase history.

**Fix Required:** Track `currentPage` and `hasMore` in `OrdersState`. Attach a scroll listener or add a "Load More" button. When triggered, call `fetchOrders(page: currentPage + 1)` and append results to `state.orders`.

---

### H4 — Rating submission has two independent entry points with divergent behaviour

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:400–471 and 904–954`

**Severity:** HIGH

**Issue:** There are two separate UI paths for submitting a rating: the `Write a review` tap which opens a `ReviewBottomSheet` and calls `_submitOrderRating()`, and the inline star rating + text field in `_OrderCard` which calls `_saveRating()`. The `ReviewBottomSheet` path does NOT pass a `ratingId` for updates — it will always attempt a fresh POST, failing with "already rated" for previously rated orders.

**Code:**
```dart
// Entry 1 (_handleWriteReview, line 430): opens ReviewBottomSheet
// Calls _submitOrderRating which has no ratingId support

// Entry 2 (_OrderCard inline editor, line 838): shows star row + TextField
// Calls _saveRating which does support ratingId (update flow)
```

**Impact:** Users who tap "Write a review" (the clearly labeled action) get a broken experience if they have already rated — they see "already rated, please refresh". Users who use the star widget directly in the card work correctly. The primary CTA is the broken path.

**Fix Required:** Remove `_handleWriteReview()` and the `ReviewBottomSheet` path. The inline card editor is the correct and complete implementation. Ensure it is visually prominent for unrated orders.

---

## Medium Priority Issues

---

### M1 — `OrdersNotifier` has `fetchPendingOrders()` method that is never called

**File:** `lib/features/orders/application/providers/orders_provider.dart:77–79`

**Severity:** MEDIUM

**Issue:** `OrdersNotifier.fetchPendingOrders()` is defined and it delegates to `fetchOrders(status: 'pending')`. The UI only calls `fetchActiveOrders()` and `fetchCompletedOrders()` — `fetchPendingOrders()` is dead code. Similarly `OrdersApi.getPendingOrders()` (line 51–53) and `getActiveOrders()` (line 47–49) are wrappers never called from the app.

**Code:**
```dart
Future<void> fetchPendingOrders() async {
  await fetchOrders(status: 'pending'); // never called
}
```

**Impact:** Dead code creates maintenance noise. If "pending" orders are a real business concept, they need a UI entry point. If not, these methods mislead developers into thinking they are used.

**Fix Required:** Remove unused `fetchPendingOrders()`, `OrdersApi.getPendingOrders()`, and `OrdersApi.getActiveOrders()`. The tab UI uses `fetchActiveOrders()` and `fetchCompletedOrders()` — these are the only needed methods.

---

### M2 — Multiple sequential Snackbar messages during reorder creates jarring UX

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:255–271`

**Severity:** MEDIUM

**Issue:** `_handleReorder()` shows two sequential `AppSnackbar.info()` calls: first "Loading order items...", then immediately "Adding items to cart...". These appear one after the other in rapid succession before the user can read either.

**Code:**
```dart
AppSnackbar.info(context, 'Loading order items...');   // shown first
// ... await fetch ...
AppSnackbar.info(context, 'Adding items to cart...');  // immediately replaces it
```

**Impact:** Users see two loading messages in quick succession, which is confusing. The first message is shown for only the duration of the `getOrderLines()` call (likely sub-second for cached responses).

**Fix Required:** Show a single loading indicator (e.g. a bottom sheet or a progress dialog overlay) for the full reorder operation. Dismiss it and show the result message (success/partial/failure) once complete.

---

### M3 — `_isActiveTab` managed in `StatefulWidget` while `ordersProvider` holds the `activeFilter` — split responsibility

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:25`
**File:** `lib/features/orders/application/providers/orders_provider.dart:11`

**Severity:** MEDIUM

**Issue:** The active tab (Active vs Previous) is tracked in `_OrdersScreenState._isActiveTab` (local widget state). The `OrdersState` also has an `activeFilter` field. These are two sources of truth for the same concern. When the screen is disposed and recreated, `_isActiveTab` resets to `true` (Active) regardless of `state.activeFilter`.

**Code:**
```dart
// Widget local state:
bool _isActiveTab = true;

// Provider state:
class OrdersState {
  final String? activeFilter; // 'active', 'delivered', etc.
}
```

**Impact:** If the user navigates away and back while `ordersProvider` is still alive (not disposed), the tab indicator resets to "Active" but the displayed data may still be from the previous "Previous" fetch, creating a UI/data mismatch.

**Fix Required:** Remove `_isActiveTab` from widget state. Use `state.activeFilter` (or a derived boolean from it) as the sole source of truth for which tab is selected. The switcher calls the notifier; the notifier updates `activeFilter`; the UI derives tab selection from the provider state.

---

### M4 — `ordersProvider` keeps order data alive across navigations but never re-validates freshness

**File:** `lib/features/orders/application/providers/orders_provider.dart:132`

**Severity:** MEDIUM

**Issue:** `ordersProvider` (non-autoDispose `StateNotifierProvider`) retains its state as long as it has a listener. When the user navigates back to the orders screen, `initState` calls `_fetchOrders()` unconditionally — always re-fetching from network, discarding any previously loaded data. There is no cache freshness check or conditional fetch.

**Code:**
```dart
@override
void initState() {
  super.initState();
  Future.microtask(() => _fetchOrders()); // always re-fetches on every visit
}
```

**Impact:** The provider is not `autoDispose`, implying intent to cache state between navigations, but the screen always re-fetches on entry. This wastes bandwidth and triggers the N+1 rating calls on every visit to the Previous tab. Either the provider should be `autoDispose` (so state is discarded and refetch on re-entry is expected), or it should check whether data is already loaded before re-fetching.

**Fix Required:** In `initState`, check `ref.read(ordersProvider).hasData` before calling `_fetchOrders()`. Only fetch if the provider has no data, is in error state, or the data is stale (older than a threshold). For refresh, the pull-to-refresh `RefreshIndicator` is the correct trigger.

---

---

# QA Prompt 6 — Architecture Compliance (4-Layer Violations)

---

## Critical Issues

---

### C1 — `features/orders/domain/repositories/` is absent — no domain repository contract exists

**File:** `lib/features/orders/` (folder-level violation)

**Layer:** Domain (Rule 9 violation — domain contract missing)

**Severity:** CRITICAL

**Issue:** The entire `domain/repositories/` folder does not exist for the orders feature. There is no `OrdersRepository` abstract class defining the contract between the application and infrastructure layers. `OrdersNotifier` injects `OrdersApi` directly, and the presentation layer calls `ordersApiProvider` directly — the domain contract layer is entirely absent.

**Code:**
```
features/orders/
├── domain/
│   └── entities/          ← EXISTS
│   (missing: repositories/)  ← ABSENT
├── infrastructure/
│   └── data_sources/orders_api.dart  ← acts as both DS and repo
│   (missing: repositories/)  ← ABSENT
├── application/
│   └── providers/orders_provider.dart
└── presentation/
    └── screens/orders_screen.dart
```

**Impact:** The orders feature has no testable seam between business logic and data access. No mocking is possible, no dependency inversion is in place, and any refactoring of `OrdersApi` (e.g. adding caching) requires modifying the notifier.

**Fix Required:**
1. Create `lib/features/orders/domain/repositories/orders_repository.dart` as an `abstract class OrdersRepository` with methods: `getOrders`, `getOrderLines`, `getOrderDetails`, `getOrderRating`, `submitOrderRating`.
2. Create `lib/features/orders/infrastructure/repositories/orders_repository_impl.dart` implementing the above.
3. Update `OrdersNotifier` to inject `OrdersRepository` instead of `OrdersApi`.

---

### C2 — Presentation layer imports infrastructure `orders_api.dart` directly

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:15`

**Layer:** Presentation → Infrastructure (Rule 4 violation)

**Severity:** CRITICAL

**Issue:** `orders_screen.dart` contains `import '../../infrastructure/data_sources/orders_api.dart'` and calls `ref.read(ordersApiProvider)` directly from UI methods. The presentation layer has a hard dependency on the infrastructure file.

**Code:**
```dart
import '../../infrastructure/data_sources/orders_api.dart'; // ← infra in presentation

// Used in:
final ordersApi = ref.read(ordersApiProvider); // _handleReorder
await ref.read(ordersApiProvider).submitOrderRating(...); // _submitOrderRating
await ref.read(ordersApiProvider).submitOrderRating(...); // _saveRating
```

**Impact:** Breaks the 4-layer contract. Presentation is coupled to a specific infrastructure implementation. Any change to `OrdersApi`'s method signatures requires updating the screen file.

**Fix Required:** Remove the infrastructure import from `orders_screen.dart`. All operations (`reorder`, `submitRating`) must go through `ref.read(ordersProvider.notifier)`. The notifier is the only entry point for mutations from the presentation layer.

---

### C3 — `ordersApiProvider` defined inside the infrastructure data source file

**File:** `lib/features/orders/infrastructure/data_sources/orders_api.dart:238`

**Layer:** Infrastructure exports Application-layer constructs (Rule 5 / Rule 11 violation)

**Severity:** CRITICAL

**Issue:** The Riverpod provider `ordersApiProvider` is registered at the bottom of `orders_api.dart`. Provider definitions are application-layer constructs — infrastructure files must contain only class implementations, never provider registrations.

**Code:**
```dart
// In orders_api.dart (infrastructure):
final ordersApiProvider = Provider<OrdersApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrdersApi(apiClient);
});
```

**Impact:** Any file needing `ordersApiProvider` must import the infrastructure file, as found in `orders_screen.dart` and `orders_provider.dart`. This is the direct cause of the presentation → infrastructure coupling in C2.

**Fix Required:** Move `ordersApiProvider` to `lib/features/orders/application/providers/orders_providers.dart`. Once `OrdersRepository` exists, only `ordersRepositoryProvider` should be exported from the application layer — `ordersApiProvider` becomes an internal implementation detail.

---

## High Priority Issues

---

### H1 — `OrdersNotifier` holds `OrdersApi` (concrete infrastructure class) — breaks dependency inversion

**File:** `lib/features/orders/application/providers/orders_provider.dart:49–52`

**Layer:** Application → Infrastructure (Rule 12 violation)

**Severity:** HIGH

**Issue:** `OrdersNotifier` declares `final OrdersApi _ordersApi` — a concrete infrastructure class — rather than the abstract domain `OrdersRepository`. The application layer must depend on domain abstractions, not infrastructure implementations.

**Code:**
```dart
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersApi _ordersApi; // ← should be OrdersRepository (abstract)

  OrdersNotifier(this._ordersApi) : super(const OrdersState());
}
```

**Impact:** `OrdersNotifier` cannot be unit tested with a mock repository. Swapping to a cached repository (one that checks Hive before the API) requires modifying the notifier rather than replacing the injected dependency.

**Fix Required:** Refactor to `final OrdersRepository _repository`. After introducing `OrdersRepository` (see C1), provide it via `ordersRepositoryProvider`. The notifier calls `_repository.getOrders()` without caring whether the implementation hits Hive or the network.

---

### H2 — `fromJson()` factory constructors in domain entity classes — infrastructure concern in domain

**File:** `lib/features/orders/domain/entities/order_entity.dart:9–15, 42–89, 139–161, 189–201`

**Layer:** Domain (Rule 8 violation — domain entity knows about JSON)

**Severity:** HIGH

**Issue:** `OrderRatingEntity`, `OrderEntity`, `OrderLineEntity`, and `OrderAddressEntity` all contain `fromJson()` factory constructors. JSON parsing is an infrastructure concern — domain entities should be plain Dart objects with no knowledge of serialization formats. The domain layer currently imports nothing, but embedding `fromJson` couples entity design to the API response shape.

**Code:**
```dart
// In domain layer:
class OrderEntity {
  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    final addressJson = json['shipping_address'] ?? json['delivery_address'];
    // API-specific field name fallback logic in domain entity
    totalAmount: _parseDouble(json['total'] ?? json['total_amount']),
    ...
  }
}
```

**Impact:** Domain entity design is constrained by API response key names. If the API changes a field name (e.g. `total` → `amount`), the domain entity must be updated. The `_parseDouble` utility duplicated in both `OrderEntity` and `OrderLineEntity` is further evidence of infrastructure code leaking into the domain.

**Fix Required:** Create DTO (Data Transfer Object) classes in `infrastructure/models/` (e.g. `OrderDto`, `OrderLineDto`) that contain `fromJson` constructors and handle API-specific parsing. The infrastructure repository maps DTOs to domain entities using a `toDomain()` method. Domain entities have no JSON knowledge.

---

### H3 — `OrdersState` defined inside `application/providers/orders_provider.dart` — missing `states/` layer

**File:** `lib/features/orders/application/providers/orders_provider.dart:7–46`

**Layer:** Application layer structure (Rule 18 violation — folder structure non-compliance)

**Severity:** HIGH

**Issue:** `OrdersState` is defined at the top of `orders_provider.dart` rather than in a dedicated `application/states/` file. The required folder structure mandates `features/<name>/application/states/` for state classes.

**Code:**
```dart
// Both the state AND the notifier AND the providers are in one file:
// orders_provider.dart contains:
class OrdersState { ... }
class OrdersNotifier extends StateNotifier<OrdersState> { ... }
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>(...);
final orderDetailsProvider = FutureProvider.family<OrderEntity, String>(...);
```

**Impact:** Single-file architecture becomes unwieldy as the feature grows. States, notifiers, and provider registrations should be in separate files to support independent testing and cleaner imports.

**Fix Required:** Move `OrdersState` to `lib/features/orders/application/states/orders_state.dart`. Move `OrdersNotifier` to a separate notifier file. Keep only provider registrations in `orders_provider.dart`.

---

## Medium Priority Issues

---

### M1 — Missing `infrastructure/repositories/` folder — no concrete repository implementation

**File:** `lib/features/orders/infrastructure/` (folder-level violation)

**Layer:** Infrastructure (Rule 16 violation)

**Severity:** MEDIUM

**Issue:** The `infrastructure/repositories/` folder does not exist. `OrdersApi` serves as both the remote data source and the implicit repository. There is no class that `implements OrdersRepository` (which also doesn't exist — see C1).

**Fix Required:** Once `OrdersRepository` is introduced, create `lib/features/orders/infrastructure/repositories/orders_repository_impl.dart` with `class OrdersRepositoryImpl implements OrdersRepository`. This class holds `OrdersApi` and (eventually) an `OrdersLocalDataSource`, calling the cache before the network.

---

### M2 — Missing `infrastructure/data_sources/local/` folder — no local caching layer

**File:** `lib/features/orders/infrastructure/data_sources/` (folder-level violation)

**Layer:** Infrastructure (Rule 17 violation — no cache-before-network check)

**Severity:** MEDIUM

**Issue:** There is no `local/` subdirectory under `data_sources/`. The orders feature has no Hive data source, no local persistence, and no offline fallback. The architecture mandates that every `local/` file is the only place in the project that reads/writes Hive for its feature.

**Fix Required:** Create `lib/features/orders/infrastructure/data_sources/local/orders_local_data_source.dart`. Implement methods for caching the orders list per `(status, page)` key. The `OrdersRepositoryImpl` checks this cache before making network calls.

---

### M3 — `_OrderCard` widget defined inside `orders_screen.dart` instead of `presentation/components/`

**File:** `lib/features/orders/presentation/screens/orders_screen.dart:475–956`

**Layer:** Presentation structure (Rule 18 violation — folder structure non-compliance)

**Severity:** MEDIUM

**Issue:** The `_OrderCard` and `_OrderCardState` classes (482 lines) are defined as private classes inside `orders_screen.dart`. The architecture requires reusable UI pieces to live in `presentation/components/`. The card is large enough to warrant its own file.

**Code:**
```dart
// Both classes live in orders_screen.dart:
class _OrderCard extends ConsumerStatefulWidget { ... } // line 475
class _OrderCardState extends ConsumerState<_OrderCard> { ... } // line 494
```

**Impact:** `orders_screen.dart` is 957 lines — too large to navigate comfortably. The order card widget cannot be reused in other screens (e.g. an order tracking screen) without moving it.

**Fix Required:** Move to `lib/features/orders/presentation/components/order_card.dart` as `class OrderCard extends ConsumerStatefulWidget`. Remove the `_` private prefix since it will live in its own file.

---

### M4 — No `application/usecases/` folder — complex multi-step orchestration in notifier

**File:** `lib/features/orders/application/providers/orders_provider.dart:83–122`

**Layer:** Application (Rule 18 — structure violation; missing use case abstraction)

**Severity:** MEDIUM

**Issue:** The `fetchCompletedOrders()` method performs a multi-step orchestration (fetch orders → fetch ratings for each → merge results) that is complex enough to warrant a dedicated use case class. The architecture allows for `application/usecases/` but none exists for this feature.

**Fix Required:** Create `lib/features/orders/application/usecases/fetch_completed_orders_usecase.dart`. The use case accepts `OrdersRepository` and returns `Either<Failure, List<OrderEntity>>`. `OrdersNotifier` calls `_fetchCompletedOrdersUseCase.execute()` and maps the result to state. This allows the orchestration to be independently tested.

---
