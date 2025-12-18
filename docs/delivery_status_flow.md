# Delivery Status Bar - Flow Analysis

## Overview

The Delivery Status Bar is a floating UI component that appears on the Home screen after a successful order payment. It displays real-time delivery tracking status through 4 stages, auto-updating every 10 minutes.

---

## Architecture

### Files Involved

```
lib/
├── features/
│   ├── home/
│   │   ├── application/
│   │   │   ├── providers/
│   │   │   │   └── delivery_status_provider.dart    # StateNotifier + Providers
│   │   │   └── states/
│   │   │       ├── delivery_status_state.dart       # Freezed state class
│   │   │       └── delivery_status_state.freezed.dart # Generated code
│   │   └── presentation/
│   │       ├── components/
│   │       │   └── delivery_status_bar.dart         # UI Widget
│   │       └── screen/
│   │           └── home_screen.dart                 # Displays the status bar
│   └── cart/
│       └── presentation/
│           └── screen/
│               ├── checkout_screen.dart             # Initiates payment
│               └── confirm_order_screen.dart        # Triggers delivery tracking
└── app/
    └── router/
        └── app_router.dart                          # Navigation routes
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PAYMENT & DELIVERY FLOW                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│  CheckoutScreen  │
│                  │
│  User taps       │
│  "Place Order"   │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  _handlePlaceOrder()                                          │
│                                                               │
│  1. Validate address selected                                 │
│  2. Refresh cart to verify latest data                        │
│  3. Validate cart not empty                                   │
│  4. Validate stock availability                               │
│  5. Initiate payment via paymentControllerProvider            │
└────────┬─────────────────────────────────────────┬───────────┘
         │                                         │
         ▼ onSuccess                               ▼ onFailure
┌──────────────────────┐                 ┌──────────────────────┐
│  context.go(         │                 │  context.push(       │
│    '/order-success'  │                 │    '/order-failed'   │
│  )                   │                 │  )                   │
└────────┬─────────────┘                 └──────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  ConfirmOrderScreen                                           │
│                                                               │
│  initState() {                                                │
│    WidgetsBinding.instance.addPostFrameCallback((_) {         │
│      _startDeliveryTracking();  ◄─────────────────────────┐   │
│    });                                                    │   │
│  }                                                        │   │
│                                                           │   │
│  void _startDeliveryTracking() {                          │   │
│    final orderId = 'ORD-${DateTime.now()...}';            │   │
│    ref.read(deliveryStatusProvider.notifier)              │   │
│       .startDeliveryTracking(orderId);  ──────────────────┘   │
│  }                                                            │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  DeliveryStatusNotifier.startDeliveryTracking(orderId)        │
│                                                               │
│  1. Cancel any existing timer                                 │
│  2. Set state to DeliveryStatusState.active(                  │
│       stage: DeliveryStage.orderGettingPacked,                │
│       startedAt: DateTime.now(),                              │
│       orderId: orderId,                                       │
│     )                                                         │
│  3. Start auto-update timer (10 minutes interval)             │
└────────┬─────────────────────────────────────────────────────┘
         │
         │  User taps "Back" button
         ▼
┌──────────────────────────────────────────────────────────────┐
│  _handleBackNavigation()                                      │
│                                                               │
│  1. Show rating bottom sheet (if not shown before)            │
│  2. Submit rating to API                                      │
│  3. context.go('/home')  ─────────────────────────────────┐   │
└───────────────────────────────────────────────────────────┼───┘
                                                            │
                                                            ▼
┌──────────────────────────────────────────────────────────────┐
│  HomeScreen (via BottomNavigation)                            │
│                                                               │
│  Stack(                                                       │
│    children: [                                                │
│      SmartRefresher(...),  // Main content                    │
│      Positioned(           // Floating status bar             │
│        bottom: 8.h,                                           │
│        child: Consumer(                                       │
│          builder: (context, ref, child) {                     │
│            final state = ref.watch(deliveryStatusProvider);   │
│            return state.maybeWhen(                            │
│              active: (...) => DeliveryStatusBar(),  ◄─────┐   │
│              completed: (...) => DeliveryStatusBar(),     │   │
│              orElse: () => SizedBox.shrink(),             │   │
│            );                               Provider state│   │
│          },                                 is 'active'   │   │
│        ),                                        ─────────┘   │
│      ),                                                       │
│    ],                                                         │
│  )                                                            │
└──────────────────────────────────────────────────────────────┘
```

---

## State Management

### DeliveryStatusState (Freezed Union Type)

```dart
@freezed
class DeliveryStatusState with _$DeliveryStatusState {
  // Initial state - bar is hidden
  const factory DeliveryStatusState.hidden() = _Hidden;

  // Active delivery tracking
  const factory DeliveryStatusState.active({
    required DeliveryStage stage,
    required DateTime startedAt,
    required String orderId,
  }) = _Active;

  // Order delivered
  const factory DeliveryStatusState.completed({
    required String orderId,
  }) = _Completed;
}
```

### DeliveryStage Enum

```dart
enum DeliveryStage {
  orderGettingPacked,  // "Order is getting packed!" - 30 mins
  orderPacked,         // "Order is packed!"         - 20 mins
  outForDelivery,      // "Out for delivery"         - 10 mins
  orderCompleted,      // "Order completed"          - Delivered
}
```

### Stage Progression (Auto-update every 10 minutes)

```
┌───────────────────────┐     10 min     ┌─────────────────┐
│  orderGettingPacked   │ ─────────────► │   orderPacked   │
│  "Getting packed!"    │                │   "Packed!"     │
└───────────────────────┘                └────────┬────────┘
                                                  │ 10 min
                                                  ▼
┌───────────────────────┐     10 min     ┌─────────────────┐
│    orderCompleted     │ ◄───────────── │  outForDelivery │
│    "Completed"        │                │  "Out for..."   │
└───────────┬───────────┘                └─────────────────┘
            │ 5 sec
            ▼
┌───────────────────────┐
│        hidden         │  (Bar disappears)
└───────────────────────┘
```

---

## Providers

### 1. deliveryStatusProvider (Main State)

```dart
final deliveryStatusProvider =
    StateNotifierProvider<DeliveryStatusNotifier, DeliveryStatusState>((ref) {
      return DeliveryStatusNotifier();
    });
```

**Usage:**
- `ref.read(deliveryStatusProvider)` - Get current state
- `ref.watch(deliveryStatusProvider)` - Watch for changes
- `ref.read(deliveryStatusProvider.notifier).startDeliveryTracking(orderId)` - Start tracking

### 2. isDeliveryActiveProvider (Derived/Selector)

```dart
final isDeliveryActiveProvider = Provider<bool>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.map(
    hidden: (_) => false,
    active: (_) => true,
    completed: (_) => true,
  );
});
```

**Usage:** Quick boolean check for visibility

### 3. currentDeliveryStageProvider (Derived/Selector)

```dart
final currentDeliveryStageProvider = Provider<DeliveryStage?>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.mapOrNull(active: (s) => s.stage);
});
```

**Usage:** Get current stage without full state

---

## Navigation Flow (go_router)

### Routes Defined in app_router.dart

```dart
GoRoute(
  path: '/order-success',
  builder: (_, state) => const ConfirmOrderScreen(),
),
GoRoute(
  path: '/order-failed',
  builder: (_, state) => const FailedOrderScreen(),
),
GoRoute(
  path: '/home',
  builder: (_, state) => BottomNavigation(key: BottomNavigation.globalKey),
),
```

### Navigation Methods Used

| Action | Method | Reason |
|--------|--------|--------|
| Payment Success | `context.go('/order-success')` | Replace stack, prevent back to checkout |
| Payment Failed | `context.push('/order-failed')` | Push on stack, allow back to cart |
| Back to Home | `context.go('/home')` | Replace stack, clean navigation |
| Go to Cart | `context.go('/cart')` | Replace stack |

---

## UI Component: DeliveryStatusBar

### Widget Structure

```
DeliveryStatusBar (ConsumerWidget)
│
└── Container (White card with shadow)
    │
    └── Material + InkWell (Tap handler)
        │
        └── Row
            ├── _buildTimeBadge()      # Green gradient pill with time
            ├── _buildStatusText()      # "Order is getting packed!"
            └── _buildArrowButton()     # Teal circle with arrow
```

### Positioning in HomeScreen

```dart
Stack(
  children: [
    SmartRefresher(...),  // Takes full available space
    Positioned(
      left: 0,
      right: 0,
      bottom: 8.h,        // Floating above bottom nav
      child: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(deliveryStatusProvider);
          return state.maybeWhen(
            active: (...) => const DeliveryStatusBar(),
            completed: (...) => const DeliveryStatusBar(),
            orElse: () => const SizedBox.shrink(),
          );
        },
      ),
    ),
  ],
)
```

---

## Key Implementation Details

### 1. Why Riverpod StateNotifierProvider?

- **Global State**: Persists across navigation (go_router route changes)
- **Auto-dispose**: False by default, state survives widget rebuilds
- **Timer Management**: StateNotifier handles timer lifecycle in `dispose()`

### 2. Why `addPostFrameCallback` in ConfirmOrderScreen?

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _startDeliveryTracking();
});
```

Ensures the widget tree is fully built before modifying provider state, preventing build-phase state modification errors.

### 3. Why `maybeWhen` instead of `map`?

```dart
// Safe with orElse fallback
state.maybeWhen(
  active: (...) => DeliveryStatusBar(),
  completed: (...) => DeliveryStatusBar(),
  orElse: () => SizedBox.shrink(),
);
```

Provides a safe fallback for unexpected states.

### 4. Provider State Persistence

When navigating with `context.go('/home')`:
1. go_router rebuilds the widget tree (new BottomNavigation instance)
2. Riverpod providers are **not** disposed (global scope)
3. HomeScreen's `Consumer` watches provider and gets the **existing** active state
4. DeliveryStatusBar renders with correct stage

---

## Testing the Flow

### Manual Test Steps

1. Add items to cart
2. Go to checkout
3. Select delivery address
4. Tap "Place Order"
5. Complete payment (mock success)
6. Observe: Navigated to ConfirmOrderScreen
7. Check logs: "Delivery tracking started for order: ORD-..."
8. Tap "Back" button
9. Observe: Rating sheet appears (optional)
10. After rating: Navigated to HomeScreen
11. **Verify**: Delivery status bar visible at bottom
12. **Verify**: Shows "Order is getting packed!"
13. Tap the status bar → advances to next stage (demo behavior)

### Debug Logging

Add temporary logging to verify state:

```dart
// In home_screen.dart
Logger.info('DeliveryStatusBar visibility check', data: {
  'state': deliveryState.toString(),
});

// In confirm_order_screen.dart
Logger.info('Delivery tracking started for order: $orderId');
```

---

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Bar not showing | Freezed file not generated | Run `dart run build_runner build` |
| Bar not showing | State is 'hidden' | Verify `startDeliveryTracking()` is called |
| Bar hidden behind content | Z-index/Stack order | Ensure Positioned is after main content in Stack |
| Navigation error | Mixing Navigator with go_router | Use only `context.go()` / `context.push()` |
| State lost on navigation | Provider disposed | Ensure provider is not `.autoDispose` |

---

## Future Enhancements

1. **Backend Integration**: Replace mock timer with real order status polling
2. **Push Notifications**: Trigger stage updates from server
3. **Order Details**: Navigate to order tracking screen on tap
4. **Multiple Orders**: Support tracking multiple concurrent orders
5. **Persistence**: Save delivery state to local storage for app restarts
