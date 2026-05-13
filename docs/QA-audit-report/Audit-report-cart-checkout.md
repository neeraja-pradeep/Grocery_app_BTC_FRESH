# Cart & Checkout Flow — Code Audit Report

**Scope:** Cart Screen · Checkout Screen · Delivery Options Screen · Coupons Screen · Order Confirmed Screen · Order Failed Screen · Address Screen · Address Sheet · Payment Provider · Checkout Line Provider · Coupon Provider · Address Provider · Razorpay Service

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 6

**Date:** 2026-05-01

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 3 | 3 | 2 | 8 |
| Prompt 2 — Security & Data Persistence | 3 | 3 | 2 | 8 |
| Prompt 3 — Performance & Error Handling | 2 | 3 | 3 | 8 |
| Prompt 4 — Code Quality & Deployment | 2 | 2 | 3 | 7 |
| Prompt 6 — Architecture Compliance | 3 | 2 | 2 | 7 |
| **Total** | **13** | **13** | **12** | **38** |

---

## Top Blockers Before Any Production Release

1. **Razorpay test key hardcoded in version control** — `rzp_test_RZlZ38QcLdQOEK` in `razorpay_service.dart`. Shipping this to the Play Store means every production payment will go through the test gateway and fail or be fraudulent. This is also a credential leak in git history.
2. **Payment signatures and order IDs logged to console** — `payment_provider.dart` logs `razorpay_payment_id`, `razorpay_order_id`, `razorpay_signature`, and `razorpay_order_id` to `developer.log()` in plain text. These are sensitive financial credentials.
3. **Coupon `firstWhere` throws unguarded exception** — `checkout_order_summary.dart:178` throws an unhandled `Exception('Coupon not found')` if the coupon list has been refreshed between the user selecting a coupon and returning. This crashes the checkout flow at the payment step.
4. **`DeliveryScreen` is entirely empty** — `delivery_screen.dart` renders only `SizedBox.shrink()`. It is registered as a named route but shows nothing — a blank screen visible to users navigating to the delivery options step.
5. **`Hive.openBox()` called inside data source methods** — `checkout_line_data_source.dart:355-376` opens Hive boxes inside `getCacheMetadata()`, `saveCacheMetadata()`, and `clearCacheMetadata()`. Concurrent cart operations can attempt to open the same box simultaneously, causing HiveError crashes.
6. **`paymentControllerProvider` is not `keepAlive`** — if the user navigates away during Razorpay's payment flow (e.g. switches apps to check UPI), the `StateNotifier` disposes, all payment state is lost, and on return the provider rebuilds with `PaymentStatus.idle` — the payment verification never runs.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

---

### C1 — `PaymentController` uses deprecated `StateNotifier<PaymentState>` instead of Riverpod 2.x codegen

**File:** `lib/features/cart/application/providers/payment_provider.dart:50`

**Severity:** CRITICAL

**Issue:** `PaymentController` extends `StateNotifier<PaymentState>`, the deprecated Riverpod 1.x pattern. All other modern providers in the codebase (`CheckoutLineController`, `CouponController`, `AddressController`, `AppliedCouponController`) use `Notifier<T>`. The payment feature is architecturally inconsistent.

**Code:**
```dart
class PaymentController extends StateNotifier<PaymentState> {
  ...
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
      return PaymentController(...);
    });
```

**Impact:** `StateNotifier` is deprecated in Riverpod 2.x. The `StateNotifierProvider` pattern does not integrate with Riverpod 2.x's codegen lifecycle, autoDispose, and family features. Developers must context-switch between two patterns for the most critical feature in the app.

**Fix Required:** Migrate to:
```dart
class PaymentController extends Notifier<PaymentState> {
  @override
  PaymentState build() => const PaymentState();
  ...
}
final paymentControllerProvider =
    NotifierProvider<PaymentController, PaymentState>(PaymentController.new);
```

---

### C2 — Business logic (price totals, discount, GST) computed inside `CheckoutScreen.build()`

**File:** `lib/features/cart/presentation/screen/checkout_screen.dart:49–59`

**Severity:** CRITICAL

**Issue:** `CheckoutScreen` is a `ConsumerWidget` whose `build()` method contains full order financial calculations: item total, coupon discount, GST, delivery fee, and grand total. Every widget rebuild (scroll, state update, orientation change) re-executes all these calculations.

**Code:**
```dart
Widget build(BuildContext context, WidgetRef ref) {
  ...
  final itemTotal = _calculateTotalWithSocketPrices(cartItems, priceUpdates);

  final discount = appliedCouponState.hasCoupon
      ? ref.read(appliedCouponProvider.notifier).calculateDiscount(itemTotal)
      : 0.0;

  final gst = (itemTotal - discount) * 0.18;
  const deliveryFee = 0.0;
  final grandTotal = itemTotal - discount + gst + deliveryFee;
  ...
}
```

**Impact:** Financial calculations should live in the application layer where they can be tested, cached, and accessed without re-entering the widget lifecycle. Running them inside `build()` means a pricing bug or edge case (e.g. `double` overflow) can crash the widget mid-render rather than in a controlled error state.

**Fix Required:** Move all order total calculations to `AppliedCouponController` or a dedicated `OrderSummaryNotifier`. The screen reads a pre-computed `OrderSummary` state object. `ref.read(notifier).calculateDiscount()` inside `build()` must be replaced with `ref.watch(orderSummaryProvider).discount`.

---

### C3 — Side effect `_joinCartItemRooms()` called directly inside `build()` via `_buildCartItemsTab()`

**File:** `lib/features/cart/presentation/screen/cart_screen.dart:411`

**Severity:** CRITICAL

**Issue:** `_buildCartItemsTab()` is called from `build()` and immediately calls `_joinCartItemRooms()`. The QA rules explicitly prohibit side effects (navigation, snackbars, socket operations) inside `build()`. Socket room joins are irreversible network side effects.

**Code:**
```dart
Widget _buildCartItemsTab() {
  final checkoutState = ref.watch(checkoutLineControllerProvider);
  ...
  // Join rooms for any new cart items  ← SIDE EFFECT IN BUILD
  _joinCartItemRooms();
  ...
}
```

**Impact:** Every time the cart screen rebuilds (on every scroll event, state update, or ticker), `_joinCartItemRooms()` is called. While the method guards against double-joining via `_joinedRooms`, this is fragile — it relies on a `Set` check inside what should be a pure function. Rebuilds triggered by socket updates can themselves trigger new socket room registrations.

**Fix Required:** Move `_joinCartItemRooms()` exclusively to `initState`, `addPostFrameCallback`, and `didChangeAppLifecycleState`. Remove the call from `_buildCartItemsTab()`.

---

## High Priority Issues

---

### H1 — `ref.read(appliedCouponProvider.notifier)` called inside `build()` for reactive data

**File:** `lib/features/cart/presentation/screen/checkout_screen.dart:53`

**Severity:** HIGH

**Issue:** Inside `CheckoutScreen.build()`, `ref.read()` is used to access the notifier's `calculateDiscount` method — which computes a value from the current state. The QA rules require `ref.watch()` inside `build()` for any state that should trigger rebuilds. Using `ref.read()` means changes to `appliedCouponProvider` won't trigger a checkout rebuild.

**Code:**
```dart
final discount = appliedCouponState.hasCoupon
    ? ref.read(appliedCouponProvider.notifier).calculateDiscount(itemTotal)
    : 0.0;
```

**Impact:** If the coupon is removed or changed externally (e.g. polling invalidates the coupon), the checkout screen will NOT rebuild to show the updated discount. The stale discount is displayed until the next unrelated rebuild.

**Fix Required:** Compute the discount purely from state without calling the notifier:
```dart
final discount = appliedCouponState.hasCoupon
    ? appliedCouponState.calculateDiscount(itemTotal)
    : 0.0;
```
Move `calculateDiscount` from the notifier to `AppliedCouponState` as a plain method.

---

### H2 — `paymentControllerProvider` has no `keepAlive` — payment state lost if user switches apps mid-payment

**File:** `lib/features/cart/application/providers/payment_provider.dart:241–247`

**Severity:** HIGH

**Issue:** `paymentControllerProvider` is a `StateNotifierProvider` with no `keepAlive`. During a Razorpay payment, the user is typically redirected to a UPI app (PhonePe, GPay) or bank app. When they return, if no widget is watching the provider, Riverpod disposes it. The payment verification callback (`_verifyPayment`) never fires — the order is in an unknown state.

**Code:**
```dart
final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
      return PaymentController(           // No keepAlive — disposed on nav away
        orderDataSource: ref.watch(orderDataSourceProvider),
        razorpayService: ref.watch(razorpayServiceProvider),
      );
    });
```

**Impact:** Users who switch apps during UPI payment return to a cart screen with no payment result. The Razorpay callback fires to a disposed notifier. The order may be charged on the backend but the app shows no confirmation — a financial reliability defect.

**Fix Required:** After migrating to `Notifier` (see C1), call `ref.keepAlive()` inside `build()`:
```dart
@override
PaymentState build() {
  ref.keepAlive();
  ...
  return const PaymentState();
}
```

---

### H3 — `_initialized` flag in `CheckoutLineController.build()` is never reset on provider rebuild

**File:** `lib/features/cart/application/providers/checkout_line_provider.dart:36–73`

**Severity:** HIGH

**Issue:** `build()` has three critical reset lines commented out. When the `checkoutLineControllerProvider` is rebuilt (e.g. due to a `checkoutLineDataSourceProvider` dependency change), `_initialized` remains `true`, so `_initialize()` returns early and the cart never reloads. This is a silent data-freshness bug.

**Code:**
```dart
@override
CheckoutLineState build() {
  final dataSource = ref.watch(checkoutLineDataSourceProvider);
  _dataSource = dataSource;
  //_disposed = false;
  //_initialized = false; // Reset on rebuild to ensure initialization runs ← COMMENTED OUT
  //_pollingTimer?.cancel();
  //_pollingTimer = null;
  ...
}
```

**Impact:** If the auth token or API client changes (e.g. token refresh), `checkoutLineDataSourceProvider` rebuilds, `build()` is called, but `_initialized = true` prevents re-loading the cart. The user sees stale cart data from the previous auth session.

**Fix Required:** Uncomment the reset lines or refactor to remove the mutable `_initialized` flag by leveraging `build()` as the single point of truth for initialization.

---

## Medium Priority Issues

---

### M1 — Infrastructure providers for coupon data sources defined inside the application layer file

**File:** `lib/features/cart/application/providers/coupon_providers.dart:15–35`

**Severity:** MEDIUM

**Issue:** `couponLocalDataSourceProvider`, `couponRemoteDataSourceProvider`, and `couponRepositoryProvider` are defined in the application providers file alongside `CouponController`. Infrastructure-layer provider registrations must not live in application-layer files.

**Code:**
```dart
// In coupon_providers.dart (application layer):
final couponLocalDataSourceProvider = Provider<CouponLocalDataSource>((ref) { ... });
final couponRemoteDataSourceProvider = Provider<CouponRemoteDataSource>((ref) { ... });
final couponRepositoryProvider = Provider<CouponRepository>((ref) { ... });
```

**Impact:** Any file importing `coupon_providers.dart` is importing infrastructure provider registrations through an application layer path. The application layer is now an implicit conduit for infrastructure dependencies.

**Fix Required:** Move infrastructure provider registrations to `infrastructure/repositories/coupon_repository_provider.dart` or a dedicated `application/providers/coupon_infrastructure_providers.dart`.

---

### M2 — Infrastructure providers for address data sources defined inside the application layer file

**File:** `lib/features/cart/application/providers/address_providers.dart:59–81`

**Severity:** MEDIUM

**Issue:** Same pattern as M1 — `addressLocalDataSourceProvider`, `addressRemoteDataSourceProvider`, and `addressRepositoryProvider` are all defined in the application layer alongside `AddressController`.

**Code:**
```dart
// In address_providers.dart (application layer):
final addressLocalDataSourceProvider = Provider<AddressLocalDataSource>((ref) { ... });
final addressRemoteDataSourceProvider = Provider<AddressRemoteDataSource>((ref) { ... });
final addressRepositoryProvider = Provider<AddressRepository>((ref) { ... });
```

**Impact:** Same as M1 — application layer imports carry infrastructure-level concerns, violating the 4-layer boundary.

**Fix Required:** Move to `infrastructure/repositories/address_repository_provider.dart`.

---

---

# QA Prompt 2 — Security & Data Persistence Violations

---

## Critical Issues

---

### C1 — Razorpay test key hardcoded directly in source code

**File:** `lib/features/cart/infrastructure/services/razorpay_service.dart:8`

**Severity:** CRITICAL

**Issue:** The Razorpay test API key is hardcoded as a string constant in the service class. It is committed to version control and will be included in every production build.

**Code:**
```dart
class RazorpayConfig {
  static const String keyId = 'rzp_test_RZlZ38QcLdQOEK';
  // Note: Key secret should NOT be used in client-side code
}
```

**Impact:** The `rzp_test_` prefix confirms this is a sandbox key. Any production release with this key will process all payments through the Razorpay test environment — payments appear to succeed to the user but no real money moves. Any bad actor who reads the APK can extract the key. The test key is also now in git history.

**Fix Required:** Move to environment variables loaded at build time via `--dart-define` or `flutter_dotenv`. Use `const String.fromEnvironment('RAZORPAY_KEY_ID')`. Separate test and production keys via CI build flavours. Rotate the current key immediately since it is in version control.

---

### C2 — `Hive.openBox()` called inside data source methods — race condition on concurrent cart operations

**File:** `lib/features/cart/infrastructure/data_sources/remote/checkout_line_data_source.dart:355–376`

**Severity:** CRITICAL

**Issue:** `getCacheMetadata()`, `saveCacheMetadata()`, and `clearCacheMetadata()` all call `Hive.openBox<String>(_cacheBoxName)` on every invocation. The cart triggers multiple concurrent operations (fetch, save, clear after mutation) which can call `openBox()` simultaneously.

**Code:**
```dart
Future<Map<String, String?>> getCacheMetadata() async {
  final box = await Hive.openBox<String>(_cacheBoxName); // ← called on every read
  return { 'lastModified': box.get(_lastModifiedKey), 'etag': box.get(_etagKey) };
}

Future<void> saveCacheMetadata({String? lastModified, String? etag}) async {
  final box = await Hive.openBox<String>(_cacheBoxName); // ← called on every write
  ...
}
```

**Impact:** When `_loadInitial()` runs and calls `saveCacheMetadata()` concurrently with polling calling `getCacheMetadata()`, multiple `Hive.openBox()` calls fire simultaneously. On some Hive versions this throws `HiveError: Box '...' is already open and cannot be opened again`, crashing the cart feature.

**Fix Required:** Open the Hive box once at app startup in `main.dart` and inject the opened `Box<String>` into the data source via its constructor. Remove all `Hive.openBox()` calls from data source methods.

---

### C3 — Payment signatures and financial credentials logged in plain text via `developer.log()`

**File:** `lib/features/cart/application/providers/payment_provider.dart:111–116, 175–179`

**Severity:** CRITICAL

**Issue:** Both `initiatePayment()` and `_verifyPayment()` log sensitive payment credentials to the developer console in plain text — including the Razorpay order ID, payment ID, signature, and amount.

**Code:**
```dart
// In initiatePayment():
developer.log('========== RAZORPAY CHECKOUT DEBUG ==========');
developer.log('Razorpay Order ID: ${checkoutResponse.razorpayOrderId}');
developer.log('Amount (in paise): ${checkoutResponse.amount}');
developer.log('App Order ID: ${checkoutResponse.orderId}');

// In _verifyPayment():
developer.log('razorpay_payment_id: $razorpayPaymentId');
developer.log('razorpay_order_id: $razorpayOrderId');
developer.log('razorpay_signature: $razorpaySignature');  // ← HMAC signature in logs
```

**Impact:** The `razorpay_signature` is an HMAC-SHA256 value that proves payment authenticity. Logging it enables replay attacks on the verification endpoint if logs are captured. On Android, any app with `READ_LOGS` permission or via ADB can read these logs. PCI-DSS and Razorpay's own guidelines prohibit logging payment credentials.

**Fix Required:** Remove all `developer.log()` calls that contain payment IDs, signatures, or order amounts. For audit purposes, log only non-sensitive identifiers: `'Payment initiated for order: [REDACTED]'`. Replace debug blocks in `razorpay_service.dart:120-129` similarly.

---

## High Priority Issues

---

### H1 — Full Razorpay payment options (including API key) logged to console

**File:** `lib/features/cart/infrastructure/services/razorpay_service.dart:119–130`

**Severity:** HIGH

**Issue:** `openCheckout()` logs the complete Razorpay options dict including the API key, customer name, email, phone number, and the full `options` map — all in one `developer.log()` call.

**Code:**
```dart
developer.log('Key: ${RazorpayConfig.keyId}');
developer.log('Customer Name: $customerName');
developer.log('Customer Email: $customerEmail');
developer.log('Customer Phone (original): $customerPhone');
developer.log('Customer Phone (formatted): $formattedPhone');
developer.log('Full Options: $options');
```

**Impact:** Customer PII (name, email, phone) is logged every time a payment is opened. In combination with crash reporting tools (Firebase Crashlytics, Sentry), these logs may be shipped to external servers. This is a GDPR/data protection violation.

**Fix Required:** Remove all payment-related `developer.log()` debug blocks entirely. Use the project's `Logger` utility at `debug` level for non-PII operational logs only (e.g. `Logger.debug('Payment checkout opened')`).

---

### H2 — `Hive.openBox()` called inside `CouponLocalDataSourceImpl._box` getter

**File:** `lib/features/cart/infrastructure/data_sources/local/coupon_local_data_source.dart:24–29`

**Severity:** HIGH

**Issue:** The `_box` getter lazily calls `Hive.openBox()` if the box is not open. During coupon polling (every 30 seconds), multiple concurrent cache reads and writes can invoke this getter before the box assignment completes.

**Code:**
```dart
Future<Box> get _box async {
  if (!Hive.isBoxOpen(CacheConfig.hiveBoxName)) {
    return await Hive.openBox(CacheConfig.hiveBoxName); // ← called on concurrent access
  }
  return Hive.box(CacheConfig.hiveBoxName);
}
```

**Impact:** While the check `Hive.isBoxOpen()` reduces the risk, two concurrent callers can both pass the `!isBoxOpen` check before either completes the `await openBox()`, causing a double-open. This is the same race condition as C2 in a different file.

**Fix Required:** Open the global `CacheConfig.hiveBoxName` box at app startup. Use `Hive.box()` (synchronous) throughout the data source — never `openBox()`.

---

### H3 — Placeholder garbage data (`firstName: '.'`, `lastName: '.'`) sent to server for unauthenticated saves

**File:** `lib/features/cart/presentation/screen/address_screen.dart:62–68`

**Severity:** HIGH

**Issue:** When the auth state is not `Authenticated` (e.g. token expired mid-session), `_saveAddress()` defaults `firstName` and `lastName` to `'.'` — a single period — and sends this to the address creation API.

**Code:**
```dart
String firstName = '.';  // ← garbage placeholder
String lastName = '.';

if (authState is Authenticated) {
  firstName = authState.user.firstName;
  lastName = authState.user.lastName;
}
// save proceeds regardless — '.' is sent to API
```

**Impact:** Users who save an address when their session has expired silently create an address with `firstName: '.'` and `lastName: '.'` in the database. This corrupts the address record, shows as `'. .'` in the delivery address section, and may fail backend validation on orders. The user receives no error feedback.

**Fix Required:** Guard the save: if `authState is! Authenticated`, show an error snackbar and return before saving. The save should not proceed with garbage placeholder data.

---

## Medium Priority Issues

---

### M1 — No auth state validation before initiating payment — guest users could attempt checkout

**File:** `lib/features/cart/presentation/screen/checkout_screen.dart:363–488`

**Severity:** MEDIUM

**Issue:** `_handlePlaceOrder()` validates address selection but does NOT verify that the current user is authenticated before initiating payment. An unauthenticated user who somehow bypasses the guest guard can trigger `initiatePayment()`, which will fail at the API level without a user-facing explanation.

**Code:**
```dart
Future<void> _handlePlaceOrder(BuildContext context, WidgetRef ref) async {
  final selectedAddress = addressState.selectedAddress;
  if (selectedAddress == null) { ... } // only validates address
  // No auth check before payment
  ref.read(paymentControllerProvider.notifier).initiatePayment(...);
}
```

**Impact:** Guest users or users with expired sessions see the payment gateway open, fail at the API, and receive a cryptic error message rather than a clear "Please log in to continue".

**Fix Required:** Add an auth check at the start of `_handlePlaceOrder`:
```dart
final authState = ref.read(authProvider);
if (authState is! Authenticated) {
  AppSnackbar.warning(context, 'Please log in to place an order');
  return;
}
```

---

### M2 — Auth state transition details logged via `developer.log()` — not using project Logger

**File:** `lib/features/cart/application/providers/checkout_line_provider.dart:51–64`

**Severity:** MEDIUM

**Issue:** Auth state transitions (login, logout, guest mode) are logged using `developer.log()` instead of the project's `Logger` utility. This bypasses the project's log-level filtering and crash reporting integration.

**Code:**
```dart
developer.log(
  'Auth state changed to Authenticated - reloading cart',
  name: 'CheckoutLineController',
);
developer.log(
  'Auth state changed from Authenticated to Guest - clearing cart',
  name: 'CheckoutLineController',
);
```

**Impact:** These logs are invisible to the project's centralized observability. In release builds, `developer.log` may not be suppressed unless explicitly configured, leaking internal state machine details to ADB.

**Fix Required:** Replace with `Logger.debug('Cart reloaded on auth state change')` and `Logger.debug('Cart cleared on logout')`.

---

---

# QA Prompt 3 — Error Handling & Performance

---

## Critical Issues

---

### C1 — Unguarded `firstWhere(..., orElse: throw)` crashes checkout when coupon not found

**File:** `lib/features/cart/presentation/components/checkout_order_summary.dart:176–180`

**Severity:** CRITICAL

**Issue:** After navigating from the CouponsScreen back to the CheckoutOrderSummary, the selected coupon code is looked up in `couponState.coupons` using `firstWhere` with an `orElse` that throws an unguarded exception. If the coupon list was refreshed (30-second poll) between the user tapping a coupon and returning, the coupon may no longer be in the list.

**Code:**
```dart
final selectedCoupon = couponState.coupons.firstWhere(
  (c) => c.name == selectedCouponCode,
  orElse: () => throw Exception('Coupon not found'), // ← unguarded throw
);
```

**Impact:** An `Exception('Coupon not found')` propagates uncaught through `_navigateToCoupons()` (an async method with no try-catch). This crashes the entire checkout screen at the payment step — the worst possible moment for an unhandled exception.

**Fix Required:**
```dart
final matchingCoupons = couponState.coupons.where((c) => c.name == selectedCouponCode);
if (matchingCoupons.isEmpty) {
  AppSnackbar.warning(context, 'Coupon no longer available');
  return;
}
ref.read(appliedCouponProvider.notifier).applyCoupon(matchingCoupons.first, currentItemTotal);
```

---

### C2 — `ListView.builder` with `shrinkWrap: true` inside `SingleChildScrollView` — defeats lazy loading

**File:** `lib/features/cart/presentation/screen/cart_screen.dart:453–511`

**Severity:** CRITICAL

**Issue:** `_buildCartItemsTab()` uses `ListView.builder` with `shrinkWrap: true` and `NeverScrollableScrollPhysics()` inside a `SingleChildScrollView`. `shrinkWrap: true` forces Flutter to lay out ALL cart items upfront to measure total height — the lazy builder pattern provides no benefit.

**Code:**
```dart
return SingleChildScrollView(
  child: Column(
    children: [
      ListView.builder(
        shrinkWrap: true,                          // forces full layout
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cartItems.length,
        itemBuilder: (context, index) { ... },
      ),
    ],
  ),
);
```

**Impact:** All cart item cards are rendered at once regardless of viewport visibility. For users with large carts (10+ items), every rebuild (scroll, socket price update, polling) re-renders all items. Causes measurable frame drops on mid-range devices.

**Fix Required:** Replace with a single `ListView.builder` that contains all content as items (minimum order warning, product cards, suggested products link). No `shrinkWrap` needed — the `ListView` itself provides the scroll.

---

## High Priority Issues

---

### H1 — No timeout on `initiatePayment()` and `verifyPayment()` API calls

**File:** `lib/features/cart/application/providers/payment_provider.dart:107, 181`

**Severity:** HIGH

**Issue:** Both `_orderDataSource.initiatePayment()` and `_orderDataSource.verifyPayment()` have no per-call timeout. If the payment API server is slow or unresponsive, the `PaymentStatus.creatingOrder` or `PaymentStatus.verifyingPayment` spinner stays forever with no feedback or retry option.

**Code:**
```dart
final checkoutResponse = await _orderDataSource.initiatePayment(
  addressId: addressId,
); // no timeout

final verifyResponse = await _orderDataSource.verifyPayment(
  razorpayPaymentId: razorpayPaymentId,
  razorpayOrderId: razorpayOrderId,
  razorpaySignature: razorpaySignature,
); // no timeout
```

**Impact:** A hung payment initiation freezes the checkout screen indefinitely. Payment verification that hangs leaves the order in a charged-but-unconfirmed state with no retry path.

**Fix Required:**
```dart
final checkoutResponse = await _orderDataSource.initiatePayment(addressId: addressId)
    .timeout(const Duration(seconds: 15), onTimeout: () => throw TimeoutException('Payment initiation timed out'));
```
Show a user-facing error with a retry button on timeout.

---

### H2 — `_showApplyingBottomSheet` uses `Future.delayed(3 seconds)` — fake coupon application with no real validation

**File:** `lib/features/cart/presentation/screen/coupons_screen.dart:44–92`

**Severity:** HIGH

**Issue:** The "applying coupon" bottom sheet auto-closes after a hardcoded 3-second delay with no actual coupon validation, no API call, and no error handling. It creates a false impression of processing.

**Code:**
```dart
Future.delayed(const Duration(seconds: 3), () { // ← magic number
  if (bottomSheetContext.mounted) {
    Navigator.pop(bottomSheetContext); // Close bottom sheet
  }
});
```

**Impact:** The 3-second animation implies the coupon is being validated against the user's cart. In reality, no validation occurs here — the actual coupon application happens later via `_orderDataSource.applyCoupon()`. If a coupon is invalid for the user's cart (e.g. minimum order not met), the 3-second "success" animation fires before the eventual payment-time failure. This is deceptive UX and will cause user confusion.

**Fix Required:** Remove the fake delay entirely. Either validate the coupon at selection time via the API and show a real success/failure state, or remove the bottom sheet and return the coupon code directly to the parent screen. Do not simulate progress.

---

### H3 — `ConfirmOrderScreen._fetchLatestOrderAndStartTracking()` makes sequential API calls without timeout

**File:** `lib/features/cart/presentation/screen/confirm_order_screen.dart:33–69`

**Severity:** HIGH

**Issue:** On the order success screen, two sequential API calls are made (`fetchActiveOrders` then `fetchPendingOrders` as a fallback) without any timeout. If the orders API hangs, delivery tracking never starts and the order confirmation screen is stuck in an untracked state.

**Code:**
```dart
await ref.read(ordersProvider.notifier).fetchActiveOrders(); // no timeout
...
await ref.read(ordersProvider.notifier).fetchPendingOrders(); // no timeout fallback
```

**Impact:** The order success screen shows successfully, but delivery tracking never initializes. When the user navigates to check their order, no tracking data is available. The error is caught generically at line 67 but only logs — no user feedback that tracking failed to start.

**Fix Required:** Add a timeout to each call and surface a recoverable error state with a "Retry" option if tracking fails to start:
```dart
await ref.read(ordersProvider.notifier).fetchActiveOrders()
    .timeout(const Duration(seconds: 10), onTimeout: () { throw TimeoutException(''); });
```

---

## Medium Priority Issues

---

### M1 — "View suggested products" is permanently broken — snackbar stub in production

**File:** `lib/features/cart/presentation/screen/cart_screen.dart:617–619`

**Severity:** MEDIUM

**Issue:** The "View suggested products" link is visible to all users on the cart screen but tapping it only shows a snackbar: `'Suggested products coming soon'`.

**Code:**
```dart
void _handleViewSuggestedProducts() {
  AppSnackbar.info(context, 'Suggested products coming soon');
}
```

**Impact:** Users see a navigation-style affordance (`View suggested products →`) that does nothing. This creates a broken user expectation and reduces trust in the cart screen. "Coming soon" messages in production code are deployment blockers.

**Fix Required:** Hide the "View suggested products" row entirely until the feature is implemented. Do not ship visible UI stubs with hardcoded "coming soon" messages.

---

### M2 — Minimum order value `150.0` hardcoded in widget — not configurable

**File:** `lib/features/cart/presentation/screen/cart_screen.dart:42`

**Severity:** MEDIUM

**Issue:** The minimum order value is a magic number hardcoded in the widget state.

**Code:**
```dart
final double _minimumOrderValue = 150.0;
```

**Impact:** Changing the minimum order value requires a code change and app release. In production, minimum order values typically vary by location, time slot, or promotion. Hardcoding this in the widget means any backend-driven change is impossible without a release.

**Fix Required:** Load from `CacheConfig` or a remote config provider. At minimum, define as a named constant in a central configuration file.

---

### M3 — GST rate hardcoded at 18% — not loaded from backend or config

**File:** `lib/features/cart/presentation/screen/checkout_screen.dart:57`

**Severity:** MEDIUM

**Issue:** The GST calculation uses a hardcoded 18% rate.

**Code:**
```dart
final gst = (itemTotal - discount) * 0.18; // hardcoded GST rate
```

**Impact:** GST rates for grocery items vary by product category (0%, 5%, 12%, 18%) under Indian GST rules. Applying 18% to all grocery items is incorrect for most product categories (most food items are 0% or 5%). This will show incorrect tax amounts to customers and may constitute a misrepresentation of prices.

**Fix Required:** GST must be calculated per product variant based on the HSN code and category returned from the API. The backend should return per-line tax amounts in the checkout response. Remove the client-side hardcoded rate.

---

---

# QA Prompt 4 — Code Quality & Deployment Readiness

---

## Critical Issues

---

### C1 — Razorpay test key (`rzp_test_*`) will be shipped in production APK

**File:** `lib/features/cart/infrastructure/services/razorpay_service.dart:8`

**Severity:** CRITICAL

**Issue:** *(See Prompt 2, C1 for full details.)* The `rzp_test_RZlZ38QcLdQOEK` key is a Razorpay sandbox key. Any build submitted to the Play Store with this key routes all payments to the test environment — no real payments can be processed. Additionally, `rzp_test_` keys are easily identified by attackers scanning APKs and can be used to flood the app's test account with fake transactions.

**Code:**
```dart
static const String keyId = 'rzp_test_RZlZ38QcLdQOEK';
```

**Impact:** Hard blocker for production release. All real user payments will fail silently (from the user's perspective) or be processed against the sandbox — no revenue generated.

**Fix Required:** Replace with `const String.fromEnvironment('RAZORPAY_KEY_ID')` and configure the production key in CI/CD secrets. Never hardcode payment gateway credentials.

---

### C2 — `DeliveryScreen` is entirely empty — deployed as a blank screen

**File:** `lib/features/cart/presentation/screen/delivery_screen.dart:5–15`

**Severity:** CRITICAL

**Issue:** `DeliveryScreen` renders nothing — only `SizedBox.shrink()`. It is registered as a route and reachable by users in the checkout flow.

**Code:**
```dart
class DeliveryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: const SizedBox.shrink(), // ← completely empty
    );
  }
}
```

**Impact:** Users navigating to the delivery options step see a completely blank white screen with no title, no content, and no way to continue. This is identical to the unimplemented categories screens flagged in the Home audit. It is a user-visible, shipped, broken screen.

**Fix Required:** Either implement the delivery options flow or explicitly block navigation to this route and remove it from the router until it is ready. Do not ship a blank placeholder screen.

---

## High Priority Issues

---

### H1 — `developer.log()` used throughout the payment and cart providers instead of project Logger

**File:** `lib/features/cart/application/providers/payment_provider.dart:94,101,111–129,151`
**File:** `lib/features/cart/application/providers/checkout_line_provider.dart` (numerous)
**File:** `lib/features/cart/application/providers/address_providers.dart` (numerous)
**File:** `lib/features/cart/application/providers/coupon_providers.dart` (numerous)

**Severity:** HIGH

**Issue:** Every provider in the cart feature uses `dart:developer`'s `developer.log()` for debug output, while the rest of the codebase uses `core/utils/logger.dart`. In addition to the inconsistency, `developer.log()` in release builds is not stripped unless explicitly configured, and it does not integrate with crash reporting.

**Code:**
```dart
import 'dart:developer' as developer;
...
developer.log('Payment Error: $e');
developer.log('PATCH REQUEST:\nURL: /api/order/...\nData: {...}');
```

**Impact:** Payment errors are invisible to crash reporting (Firebase Crashlytics, Sentry). Debug logs from the most critical flow in the app are inconsistently filtered and can leak to ADB in production builds.

**Fix Required:** Replace all `developer.log(...)` calls with the project's `Logger.debug(...)` / `Logger.error(...)` / `Logger.warning(...)`. Remove the `import 'dart:developer' as developer;` import from all cart providers.

---

### H2 — `Navigator.push/pop/popUntil` used instead of GoRouter throughout the entire cart flow

**File:** `lib/features/cart/presentation/screen/coupons_screen.dart:41`
**File:** `lib/features/cart/presentation/screen/address_screen.dart:107, 175`
**File:** `lib/features/cart/presentation/components/checkout_order_summary.dart:170`
**File:** `lib/features/cart/presentation/components/address_sheet.dart:91, 229, 317, 321`
**File:** `lib/features/cart/presentation/screen/failed_order_screen.dart:86`

**Severity:** HIGH

**Issue:** The entire cart and checkout flow uses `Navigator.push()`, `Navigator.pop()`, and `Navigator.popUntil()` for navigation, bypassing GoRouter. The rest of the app uses GoRouter (`context.push()`, `context.go()`, `context.pop()`).

**Code:**
```dart
// checkout_order_summary.dart:170 — push without GoRouter
final selectedCouponCode = await Navigator.push<String>(
  context,
  MaterialPageRoute(builder: (context) => const CouponsScreen()),
);

// failed_order_screen.dart:86 — popUntil bypasses GoRouter stack
Navigator.of(context).popUntil((route) => route.isFirst);

// address_sheet.dart:91
Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressScreen()));
```

**Impact:** GoRouter's redirect guards, deep link handling, and back-stack management are completely bypassed in the checkout flow. Back navigation from the failed order screen may pop the wrong route. Deep links to `/order-failed` or `/order-success` may behave incorrectly when `Navigator.pop` is mixed with GoRouter's route stack. The checkout tab within `CartScreen` (a `TabBarView`) uses mixing `Navigator` context which is different from GoRouter's shell route context.

**Fix Required:** Replace all `Navigator.push/pop` with `context.push()` / `context.pop()` / `context.go()`. For the CouponsScreen result, use a shared provider (`appliedCouponProvider`) instead of returning values through navigation.

---

## Medium Priority Issues

---

### M1 — Coupon discount calculated against API-priced `totalAmount` — incorrect when socket prices differ

**File:** `lib/features/cart/presentation/components/checkout_order_summary.dart:184–190`

**Severity:** MEDIUM

**Issue:** When the coupon is applied from `CheckoutOrderSummary`, the discount is calculated against `checkoutState.totalAmount` — the API-fetched total — rather than the socket-adjusted `itemTotal` computed from real-time prices.

**Code:**
```dart
// checkout_order_summary.dart:184-190
final checkoutState = ref.read(checkoutLineControllerProvider);
final currentItemTotal = checkoutState.totalAmount; // ← uses API price, not socket price

ref.read(appliedCouponProvider.notifier).applyCoupon(selectedCoupon, currentItemTotal);
```

**Impact:** If a product's price changed via socket (e.g. dropped from ₹100 to ₹80), the cart total visible to the user includes the socket price, but the coupon discount is calculated on the API total (₹100). The discount is wrong — either over- or under-discounting. The order summary shown to the user is inconsistent.

**Fix Required:** Pass the socket-adjusted `itemTotal` (already computed in `CheckoutScreen.build()`) down to `CheckoutOrderSummary` as a parameter, or read it from a dedicated `orderSummaryProvider` that is the single source of truth for the calculated total.

---

### M2 — Address form only collects two fields — no city, state, postcode, or country

**File:** `lib/features/cart/presentation/screen/address_screen.dart:234–285`

**Severity:** MEDIUM

**Issue:** The address creation/edit form only exposes `House / Flat / Block No.` and `Apartment / Road / Area` input fields. City, state, postal code, and country are passed as `null` to the API.

**Code:**
```dart
await ref.read(addressControllerProvider.notifier).createAddress(
  ...
  streetAddress1: _houseController.text.trim(),
  streetAddress2: _apartmentController.text.trim().isEmpty ? null : ...,
  latitude: null,
  longitude: null,
  // city: null, state: null, postalCode: null, country: null — never collected
);
```

**Impact:** Addresses stored without city, state, and postal code are incomplete for delivery routing. Delivery partners cannot use pincode-based routing. Order validation on the backend may fail silently or deliver to incorrect locations.

**Fix Required:** Add form fields for City, State, Postal Code, and Country. All address fields required by the API should have corresponding input fields in the form.

---

### M3 — `_isSaving` managed in `StatefulWidget` local state instead of Riverpod for a data-level operation

**File:** `lib/features/cart/presentation/screen/address_screen.dart:31, 70–71`

**Severity:** MEDIUM

**Issue:** The `_isSaving` flag tracks an ongoing API call (save address), which is a data-level concern. The QA rule states `StatefulWidget` is for purely visual/local state only (show/hide, open/close) — not for tracking API operation status.

**Code:**
```dart
bool _isSaving = false; // data-level state in StatefulWidget

Future<void> _saveAddress() async {
  setState(() => _isSaving = true);
  try { ... } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}
```

**Impact:** If the widget is disposed while the save is in flight, the `setState` in `finally` is guarded by `mounted`, but the underlying API call continues. The state cannot be observed from other widgets. If the user navigates away during save, no feedback is given on return.

**Fix Required:** Add a `savingAddress` boolean to `AddressState` in the `AddressController`. Let `AddressController.createAddress/updateAddress` set `state = state.copyWith(isSaving: true/false)`. The screen reads `ref.watch(addressControllerProvider).isSaving`.

---

---

# QA Prompt 6 — Architecture Compliance (4-Layer Violations)

---

## Critical Issues

---

### C1 — `CheckoutLineDataSource` mixes remote HTTP calls with Hive cache operations in one class

**File:** `lib/features/cart/infrastructure/data_sources/remote/checkout_line_data_source.dart:353–377`

**Layer:** Infrastructure — Remote/Local separation violated

**Severity:** CRITICAL

**Issue:** `CheckoutLineDataSource` lives under `infrastructure/data_sources/remote/` but contains three Hive cache methods: `getCacheMetadata()`, `saveCacheMetadata()`, and `clearCacheMetadata()`. A `remote/` data source must only make HTTP calls and convert JSON responses. All Hive operations must live exclusively in `local/` data sources.

**Code:**
```dart
// In remote/checkout_line_data_source.dart:
Future<Map<String, String?>> getCacheMetadata() async {
  final box = await Hive.openBox<String>(_cacheBoxName); // ← Hive in a remote class
  return { 'lastModified': box.get(_lastModifiedKey), ... };
}
```

**Impact:** The remote data source is now coupled to Hive. It cannot be tested without a real Hive instance. Swapping the caching mechanism (e.g. from Hive to SQLite) requires modifying the HTTP data source. The separation of concerns mandated by the 4-layer architecture is broken for the most important data source in the app.

**Fix Required:** Move `getCacheMetadata()`, `saveCacheMetadata()`, and `clearCacheMetadata()` to a new `CheckoutLineLocalDataSource` in `infrastructure/data_sources/local/`. Inject both into `CheckoutLineController` separately. The remote data source has only HTTP methods.

---

### C2 — Application layer imports infrastructure implementation files directly

**File:** `lib/features/cart/application/providers/coupon_providers.dart:11`
**File:** `lib/features/cart/application/providers/address_providers.dart:13`

**Layer:** Application → Infrastructure (Rule 5 violation)

**Severity:** CRITICAL

**Issue:** Both application layer provider files import infrastructure implementation files directly. The application layer must only depend on domain abstractions, never on infrastructure implementations.

**Code:**
```dart
// coupon_providers.dart:11
import '../../infrastructure/repositories/coupon_repository_impl.dart';

// address_providers.dart:13
import '../../infrastructure/repositories/address_repository_impl.dart';
```

**Impact:** The application layer is directly coupled to specific infrastructure implementations. Swapping the implementation (e.g. for testing or switching data sources) requires editing the application layer. Dependency inversion is violated — the application depends on the infrastructure, not the other way around.

**Fix Required:** Move the repository provider registrations to infrastructure layer provider files. Application layer imports only `coupon_repository.dart` (domain abstract). Infrastructure layer imports `coupon_repository_impl.dart` to register the provider.

---

### C3 — `AddressSheet` (presentation) imports cross-feature domain and application layers

**File:** `lib/features/cart/presentation/components/address_sheet.dart:8–9`

**Layer:** Presentation → Cross-feature violation (Rules 4 and 12)

**Severity:** CRITICAL

**Issue:** `AddressSheet` imports from the `home` feature's application and domain layers (`home_provider.dart` and `user_address.dart`) and from the `address` feature's application layer (`address_provider.dart`) — three cross-feature imports in a presentation component.

**Code:**
```dart
import '../../../address/application/providers/address_provider.dart';
import '../../../home/application/providers/home_provider.dart';
import '../../../home/domain/entities/user_address.dart';
```

**Impact:** The cart feature's address selection sheet is now tightly coupled to the home feature's provider and domain entity. Any change to `HomeNotifier.updateAddressInState()` or `UserAddress` requires updating the cart's address sheet. Cross-feature presentation imports signal that the selected address state should be in a shared/core provider, not duplicated across features.

**Fix Required:** Move selected address state to a shared `core/providers/selected_address_provider.dart` or make `AddressController.setLocalSelectedAddress()` the single source of truth. Remove direct imports of `home_provider.dart` and `user_address.dart` from the cart presentation layer.

---

## High Priority Issues

---

### H1 — `PaymentController` (application layer) directly depends on `OrderDataSource` and `RazorpayService` (infrastructure)

**File:** `lib/features/cart/application/providers/payment_provider.dart:50–58`

**Layer:** Application → Infrastructure (Rule 12 — should depend on domain contract)

**Severity:** HIGH

**Issue:** `PaymentController` constructor accepts `OrderDataSource` and `RazorpayService` — both infrastructure-layer classes — as direct dependencies. The controller should depend on a domain-level `PaymentRepository` abstract interface, not the concrete infrastructure implementations.

**Code:**
```dart
class PaymentController extends StateNotifier<PaymentState> {
  final OrderDataSource _orderDataSource;       // ← infrastructure, not domain
  final RazorpayService _razorpayService;       // ← infrastructure, not domain

  PaymentController({
    required OrderDataSource orderDataSource,
    required RazorpayService razorpayService,
  }) ...
}
```

**Impact:** `PaymentController` cannot be unit tested without a real `OrderDataSource` (HTTP) and `RazorpayService` (native Razorpay). There is no domain repository interface for payment — the entire payment flow is an untestable infrastructure dependency.

**Fix Required:** Create a `PaymentRepository` abstract class in `domain/repositories/payment_repository.dart`. Create `PaymentRepositoryImpl` in infrastructure that wraps `OrderDataSource` and `RazorpayService`. `PaymentController` constructor accepts `PaymentRepository`.

---

### H2 — `CouponsScreen._applyCoupon()` uses navigation return value as inter-screen communication

**File:** `lib/features/cart/presentation/screen/coupons_screen.dart:37–42`
**File:** `lib/features/cart/presentation/components/checkout_order_summary.dart:168–192`

**Layer:** Presentation (anti-pattern — using navigation as a data bus)

**Severity:** HIGH

**Issue:** The coupon selection result is communicated from `CouponsScreen` back to `CheckoutOrderSummary` via `Navigator.pop(context, code)` / `Navigator.push<String>(...)`. Using navigation as a callback mechanism is an architectural anti-pattern. Data flow should go through providers, not navigation return values.

**Code:**
```dart
// CouponsScreen — returns coupon code via nav pop
Future<void> _applyCoupon(String code) async {
  await _showApplyingBottomSheet(code);
  if (mounted) {
    Navigator.pop(context, code); // ← data returned via navigation
  }
}

// CheckoutOrderSummary — receives coupon via push return value
final selectedCouponCode = await Navigator.push<String>(
  context,
  MaterialPageRoute(builder: (context) => const CouponsScreen()),
);
```

**Impact:** The coupon selection is tied to the `Navigator` call stack. Using GoRouter (as required elsewhere) breaks this pattern entirely — GoRouter does not support `push<T>()` return values in the same way. The current implementation is incompatible with the GoRouter migration flagged in Prompt 4 H2.

**Fix Required:** `CouponsScreen` writes directly to `appliedCouponProvider` when the user taps Apply. `CheckoutOrderSummary` watches `appliedCouponProvider` reactively. No return-via-navigation needed. The coupon screen navigates back with `context.pop()` and the summary auto-updates from the provider.

---

## Medium Priority Issues

---

### M1 — `AddressScreen._saveAddress()` contains business logic for name extraction from auth state

**File:** `lib/features/cart/presentation/screen/address_screen.dart:61–68`

**Layer:** Presentation (Rule 6 — business logic in widget method)

**Severity:** MEDIUM

**Issue:** The presentation layer reads auth state and extracts `firstName`/`lastName` to compose API parameters. Deriving user data from auth state for an API call is business logic that belongs in the application layer notifier.

**Code:**
```dart
Future<void> _saveAddress() async {
  // Business logic in presentation:
  final authState = ref.read(authProvider);
  String firstName = '.';
  String lastName = '.';
  if (authState is Authenticated) {
    firstName = authState.user.firstName;
    lastName = authState.user.lastName;
  }
  // ... pass to notifier
}
```

**Impact:** The auth state dependency for address creation is invisible to `AddressController` — if the auth API changes (e.g. different user fields), the fix must be made in the presentation layer rather than the application layer where it belongs.

**Fix Required:** `AddressController.createAddress()` should read the user's name from `authProvider` internally, not accept `firstName`/`lastName` from the presentation layer. The screen calls `notifier.createAddress(streetAddress1: ..., addressType: ...)` only.

---

### M2 — `PaymentState` is a plain Dart class with mutable state pattern, not an immutable state with `copyWith`

**File:** `lib/features/cart/application/providers/payment_provider.dart:20–47`

**Layer:** Application (Rule 13 — mutable State fields)

**Severity:** MEDIUM

**Issue:** `PaymentState` is a plain class. The QA rule requires all `State` classes to have only `final` fields and a `copyWith()` method. `PaymentState` has `final` fields but `errorMessage` is nullable and its null handling in `copyWith()` is non-standard — `null` can be passed as `errorMessage` to `copyWith()` but the current implementation uses `errorMessage: errorMessage` (passes null) which clears the error. This is unintuitive and differs from the `null`-safety pattern used in other state classes.

**Code:**
```dart
PaymentState copyWith({
  PaymentStatus? status,
  String? errorMessage,   // ← null can be passed but semantics unclear
  String? orderId,
}) {
  return PaymentState(
    status: status ?? this.status,
    errorMessage: errorMessage,   // ← intentionally null-clears on success states
    orderId: orderId ?? this.orderId,
  );
}
```

**Impact:** `state.copyWith(status: PaymentStatus.creatingOrder)` silently clears any existing `errorMessage` because `errorMessage` is not guarded with `?? this.errorMessage`. If a status update fires mid-error display, the error message is lost.

**Fix Required:** Use a sentinel pattern or explicit clear flag:
```dart
PaymentState copyWith({
  PaymentStatus? status,
  String? errorMessage,
  bool clearError = false,
  String? orderId,
}) {
  return PaymentState(
    status: status ?? this.status,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    orderId: orderId ?? this.orderId,
  );
}
```

---
