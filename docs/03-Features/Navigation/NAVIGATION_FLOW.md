# Navigation Flow - Complete Documentation

## Overview

The Navigation Flow manages how users move through the app, including bottom navigation tabs, back button handling, deep linking, and screen transitions. The app uses GoRouter for routing and a custom BottomNavigation with IndexedStack for tab management.

---

## Architecture

### Files Involved

```
lib/
├── app/
│   └── router/
│       ├── app_router.dart              # GoRouter configuration
│       └── auth_guard.dart              # Route protection
├── features/
│   └── bottomnavbar/
│       └── bottom_navbar.dart           # Bottom navigation + tabs
├── core/
│   └── polling/
│       ├── polling_manager.dart         # Screen-aware polling
│       └── polling_tab_controller.dart  # Tab-based polling control
```

---

## Navigation Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         NAVIGATION STRUCTURE                                 │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                           APP ROUTES                                         │
└──────────────────────────────────────────────────────────────────────────────┘

/splash ──────► Auth Check ──────┬──► /home (authenticated/guest)
                                 └──► /login (if needs auth action)

/home ─────────► BottomNavigation with IndexedStack
                 │
                 ├── Tab 0: HomeScreen
                 ├── Tab 1: CategoryScreen
                 ├── Tab 2: WishlistScreen (auth required)
                 └── Tab 3: CartScreen (auth required)

/product-details/:variantId ──► ProductDetailsScreen

/cart ─────────► CartScreen (standalone, for deep links)
/orders ───────► OrdersScreen
/profile ──────► ProfileScreen
/address-list ─► AddressListScreen

/login ────────► LoginScreen
/signup ───────► SignupScreen
/otp ──────────► OTPScreen (phone verification)

/checkout ─────► CheckoutScreen
/order-success ► ConfirmOrderScreen
/order-failed ─► FailedOrderScreen

/category-products ► CategoriesWithSidebarScreen
```

---

## Bottom Navigation

### Tab Structure

```dart
class BottomNavigation extends ConsumerStatefulWidget {
  static final GlobalKey<BottomNavigationState> globalKey =
      GlobalKey<BottomNavigationState>();
}

class BottomNavigationState extends ConsumerState<BottomNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),           // Tab 0: Home
    CategoryScreen(categoryId: selectedCategoryId),  // Tab 1: Categories
    const WishlistScreen(),       // Tab 2: Wishlist
    const CartScreen(),           // Tab 3: Cart
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('$cartCount'),
              child: Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
```

### Tab Selection with Auth Check

```dart
void _onTabSelected(int index) {
  final authState = ref.read(authProvider);
  final isGuest = authState is GuestMode;

  // Block wishlist and cart for guests
  if (isGuest && (index == 2 || index == 3)) {
    final featureName = index == 2 ? 'Wishlist' : 'Cart';
    AppSnackbar.info(context, 'Please login to access $featureName');
    context.go('/otp');
    return;
  }

  setState(() => _currentIndex = index);
  _pollingController.selectTab(index);
}
```

### Programmatic Tab Navigation

```dart
// Navigate to specific tab from anywhere in the app
BottomNavigation.globalKey.currentState?.navigateToTab(3);  // Go to Cart

// Navigate to categories with specific category selected
BottomNavigation.globalKey.currentState?.navigateToCategories(category);
```

---

## Back Button Handling

### Android Back Button with PopScope

```dart
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: _currentIndex == 0,  // Only allow exit from Home tab
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;  // Already exiting app

      // Navigate back to Home tab instead of exiting
      setState(() => _currentIndex = 0);
      _pollingController.selectTab(0);
    },
    child: Scaffold(
      body: IndexedStack(...),
      bottomNavigationBar: BottomNavigationBar(...),
    ),
  );
}
```

### Back Button Behavior

| Current Screen | Back Button Action |
|----------------|-------------------|
| Home Tab (0) | Exit app |
| Categories Tab (1) | Go to Home Tab |
| Wishlist Tab (2) | Go to Home Tab |
| Cart Tab (3) | Go to Home Tab |
| Product Details | Pop to previous screen |
| Checkout | Pop to Cart |
| Order Success | Navigate to Home (replace stack) |
| Order Failed | Pop to Checkout |

---

## GoRouter Configuration

### Route Definitions

```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref),  // Auth state listener
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      // Protected routes
      final protectedRoutes = ['/cart', '/checkout', '/profile', '/orders'];
      final isProtected = protectedRoutes.any((r) => location.startsWith(r));

      // Redirect unauthenticated users to OTP
      if (!isAuthenticated && isProtected) {
        return '/otp';
      }

      // Redirect authenticated users away from auth screens
      final authRoutes = ['/login', '/signup', '/otp'];
      if (isAuthenticated && authRoutes.contains(location)) {
        return '/home';
      }

      return null;  // No redirect
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
      GoRoute(path: '/home', builder: (_, __) => BottomNavigation()),
      GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
      GoRoute(path: '/otp', builder: (_, __) => OTPScreen()),
      GoRoute(
        path: '/product-details/:variantId',
        builder: (_, state) => ProductDetailsScreen(
          variantId: state.pathParameters['variantId']!,
        ),
      ),
      GoRoute(path: '/cart', builder: (_, __) => CartScreen()),
      GoRoute(path: '/orders', builder: (_, __) => OrdersScreen()),
      GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
      GoRoute(path: '/order-success', builder: (_, __) => ConfirmOrderScreen()),
      GoRoute(
        path: '/order-failed',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FailedOrderScreen(
            errorMessage: extra?['error'],
            isReservationExpired: extra?['isReservationExpired'] ?? false,
          );
        },
      ),
    ],
  );
});
```

---

## Navigation Methods

### Push vs Go

| Method | Behavior | Use Case |
|--------|----------|----------|
| `context.push('/path')` | Add to stack | Product details, modals |
| `context.go('/path')` | Replace stack | Post-login, post-payment |
| `context.pop()` | Go back | Close screen |
| `Navigator.push()` | Standard Flutter | Within same feature |

### Examples

```dart
// Add to navigation stack (can go back)
context.push('/product-details/123');

// Replace entire stack (can't go back)
context.go('/order-success');

// Pop current screen
context.pop();
// or
Navigator.pop(context);

// Navigate with data
context.push('/order-failed', extra: {
  'error': 'Payment failed',
  'isReservationExpired': true,
});

// Navigate to tab
BottomNavigation.globalKey.currentState?.navigateToTab(3);
```

---

## Screen-Aware Polling Integration

### Polling Tab Controller

```dart
class BottomNavigationState extends ConsumerState<BottomNavigation> {
  late final PollingTabController _pollingController;

  @override
  void initState() {
    super.initState();

    _pollingController = PollingTabController(
      tabToFeature: {
        0: 'category_products',  // Home
        1: 'home',               // Categories
        2: 'wishlist',
        3: 'cart',
      },
    );

    // Activate initial tab
    _pollingController.selectTab(0);
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    _pollingController.selectTab(index);  // Update polling
  }
}
```

### App Lifecycle Handling

```dart
class BottomNavigationState extends ConsumerState<BottomNavigation>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - resume polling
      PollingManager.instance.resumeActiveFeaturePolling();
    } else if (state == AppLifecycleState.paused) {
      // App went to background - pause all polling
      PollingManager.instance.pauseAllPolling();
    }
  }
}
```

---

## Auth Guard

### Protecting Routes

```dart
class AuthGuard {
  final Ref ref;
  AuthGuard(this.ref);

  String? protect({String? redirectTo}) {
    final authState = ref.read(authProvider);

    if (authState is! Authenticated) {
      return redirectTo ?? '/otp';
    }

    return null;  // Allow access
  }
}

// Usage in route
GoRoute(
  path: '/address',
  redirect: (context, state) {
    final guard = AuthGuard(ref);
    return guard.protect(redirectTo: '/otp');
  },
  builder: (_, state) => AddressScreen(user: state.extra as UserEntity),
),
```

---

## Deep Linking

### Supported Deep Links

| Link | Destination |
|------|-------------|
| `btcgrocery://home` | Home Screen |
| `btcgrocery://product/{id}` | Product Details |
| `btcgrocery://cart` | Cart Screen |
| `btcgrocery://orders` | Orders Screen |

### Configuration

```yaml
# android/app/src/main/AndroidManifest.xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="btcgrocery"/>
</intent-filter>
```

---

## Navigation Patterns

### After Login

```dart
void _onLoginSuccess() {
  // Check if there's a redirect URL
  final redirectPath = widget.redirectTo;

  if (redirectPath != null) {
    context.go(redirectPath);
  } else {
    context.go('/home');
  }
}
```

### After Payment

```dart
// Success - replace stack to prevent back navigation
context.go('/order-success');

// Failure - push so user can go back to cart
context.push('/order-failed', extra: {'error': 'Payment failed'});
```

### Modal Bottom Sheets

```dart
// Show address selection
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => AddressSheet(),
);

// Close after selection
Navigator.pop(context);
```

---

## Common Navigation Helpers

```dart
// In app_router.dart

void goToHome(BuildContext context) {
  context.go('/home');
}

void goToLogin(BuildContext context, {String? redirectTo}) {
  final uri = redirectTo != null ? '/login?redirect=$redirectTo' : '/login';
  context.push(uri);
}

void goToProductDetails(BuildContext context, String variantId) {
  context.push('/product-details/$variantId');
}

void goToOrders(BuildContext context) {
  context.push('/orders');
}

void goToCart(BuildContext context) {
  // Use bottom nav for cart to preserve state
  BottomNavigation.globalKey.currentState?.navigateToTab(3);
}
```

---

## IndexedStack Benefits

The app uses `IndexedStack` for bottom navigation tabs:

**Advantages:**
- Preserves state of inactive tabs
- No rebuild when switching tabs
- Scroll position maintained
- Form data preserved

**Considerations:**
- All tabs are built on first load
- Memory usage higher than PageView
- Must manually control polling per tab

---

## Related Documentation

- [Auth & Guest Mode](../Authentication/AUTH_GUEST_MODE.md) - Authentication flow
- [Screen-Aware Polling](../../02-Architecture/Performance/SCREEN_AWARE_POLLING_GUIDE.md) - Polling optimization
- [Cart Flow](../Cart/CART_FLOW.md) - Cart navigation
- [Payment Flow](../../payment_flow.md) - Post-payment navigation

---

**Last Updated:** 2025-12-25
