# Authentication & Guest Mode Implementation

## Overview

This document explains the authentication and guest mode flow in the BTC Fresh Grocery App. The implementation allows users to browse the app as guests or authenticate for full access.

---

## Architecture

### Core Components

1. **AuthProvider** - Manages authentication state (Authenticated, GuestMode, Unauthenticated, AuthChecking)
2. **ApiClient** - HTTP client with guest mode support and CSRF token handling
3. **AppRouter** - Route guards for guest-accessible and auth-required pages
4. **Global ProviderContainer** - Allows ApiClient to check auth state without circular dependencies

---

## Authentication States

```dart
// lib/features/auth/application/states/auth_state.dart

sealed class AuthState {
  const AuthState();
}

class Authenticated extends AuthState {
  final String userId;
  final String? name;
  final String? email;
  // ... user details
}

class GuestMode extends AuthState {
  const GuestMode();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthChecking extends AuthState {
  const AuthChecking();
}
```

---

## Flow Diagrams

### 1. App Launch Flow

```
┌─────────────────┐
│  Splash Screen  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  AuthProvider.init()    │
│  Checks stored session  │
└────────┬────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌─────┐   ┌──────┐
│Auth │   │Guest │
└──┬──┘   └───┬──┘
   │          │
   ▼          ▼
┌─────┐   ┌──────┐
│Home │   │ OTP  │
└─────┘   └──────┘
```

### 2. Guest Mode Flow

```
┌──────────────┐
│  Guest User  │
└──────┬───────┘
       │
       ├─► Browse Products ✅
       ├─► View Categories ✅
       ├─► Search ✅
       ├─► View Product Details ✅
       │
       ├─► Add to Cart ❌ → "Please login"
       ├─► Add to Wishlist ❌ → "Please login"
       ├─► Checkout ❌ → Redirect to OTP
       └─► View Profile ❌ → Redirect to OTP
```

### 3. API Request Flow

```
┌─────────────────┐
│  API Request    │
└────────┬────────┘
         │
         ▼
┌──────────────────────┐
│  Check Auth State    │
│  (via isGuestMode()) │
└────────┬─────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐  ┌───────────┐
│ Guest  │  │Authenticated│
└───┬────┘  └─────┬─────┘
    │             │
    │             ▼
    │      ┌──────────────┐
    │      │ Get CSRF     │
    │      │ from Cookies │
    │      └──────┬───────┘
    │             │
    ▼             ▼
┌────────────────────────┐
│  Add Header:           │
│  Guest: 'dev: 2'       │
│  Auth: 'X-CSRFToken'   │
└────────┬───────────────┘
         │
         ▼
┌─────────────────┐
│  Make Request   │
└─────────────────┘
```

---

## Implementation Details

### 1. Main Entry Point

**File:** `lib/main.dart`

```dart
// Global container to access ProviderContainer
late ProviderContainer _container;

Future<void> main() async {
  await AppBootstrap.run(() async {
    final api = AppBootstrap.result.apiClient;

    _container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(api.dio),
        cookieJarProvider.overrideWithValue(api.cookieJar),
        apiClientProvider.overrideWithValue(api),
      ],
    );

    // Set the guest mode check function in ApiClient
    api.isGuestMode = () {
      final authState = _container.read(authProvider);
      return authState is GuestMode;
    };

    return UncontrolledProviderScope(
      container: _container,
      child: const MyApp(),
    );
  });
}
```

**Key Points:**
- Creates global `_container` to allow ApiClient access to auth state
- Sets `isGuestMode` callback in ApiClient
- Breaks circular dependency between ApiClient and AuthProvider

---

### 2. API Client with Guest Support

**File:** `lib/core/network/api_client.dart`

```dart
class ApiClient {
  late Dio dio;
  late PersistCookieJar cookieJar;
  static const baseUrl = 'http://156.67.104.149:8080';

  // Guest mode check function - set by main.dart
  bool Function()? isGuestMode;

  Future<void> init() async {
    // ... dio initialization ...

    // Guest mode & CSRF interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Check if user is in guest mode
          final isGuest = isGuestMode?.call() ?? false;

          if (isGuest) {
            // For guest mode: Use 'dev: 2' header, skip CSRF
            options.headers['dev'] = '2';
          } else {
            // For authenticated users: Use CSRF token
            final csrf = await _getCsrfToken();
            if (csrf != null) {
              options.headers['X-CSRFToken'] = csrf;
            }
          }
          handler.next(options);
        },
      ),
    );
  }
}
```

**Key Points:**
- All API requests automatically include proper headers
- Guest requests: `dev: 2` header (bypasses CSRF)
- Authenticated requests: `X-CSRFToken` header from cookies

---

### 3. Router Configuration

**File:** `lib/app/router/app_router.dart`

The router uses custom redirects to handle guest access:

```dart
final router = GoRouter(
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final authState = container.read(authProvider);

    // Get route configuration
    final route = state.matchedLocation;
    final isGuestAccessible = _guestAccessibleRoutes.contains(route);

    if (authState is GuestMode && !isGuestAccessible) {
      return '/otp'; // Redirect to login
    }

    return null; // Allow navigation
  },
  // ... routes ...
);
```

**Guest-Accessible Routes:**
- `/` - Splash screen
- `/otp` - OTP/Login screen
- `/home` - Home/Browse products
- `/categories` - Category listing
- `/search` - Product search
- `/product/:id` - Product details

**Auth-Required Routes:**
- `/cart` - Shopping cart
- `/checkout` - Checkout flow
- `/profile` - User profile
- `/orders` - Order history
- `/wishlist` - Saved items
- `/addresses` - Saved addresses

---

### 4. Data Cleanup on Auth State Change

**File:** `lib/features/auth/application/providers/auth_provider.dart`

When a user logs out or enters guest mode, all user-specific cached data must be cleared to prevent showing the previous user's data. This is handled automatically by the `_clearUserData()` method.

```dart
/// Clears cached data that belongs to authenticated users
/// This includes cart, wishlist, and refreshes categories
Future<void> _clearUserData() async {
  try {
    // Clear wishlist cache and refresh
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    await wishlistNotifier.clearCacheAndRefresh();

    // Clear cart cache (checkout lines need to be re-fetched for guest)
    // Cart will be empty for guests or show different data
    final checkoutLineController = ref.read(checkoutLineControllerProvider.notifier);
    await checkoutLineController.refresh();

    // Refresh category data to show guest version
    final categoryController = ref.read(categoryControllerProvider.notifier);
    await categoryController.refresh(force: true);
  } catch (e) {
    // Log error but don't fail the logout/guest mode
    // Guest mode should still work even if data clearing fails
  }
}
```

**Called from:**
1. **`logout()` method** - When user explicitly logs out
2. **`continueAsGuest()` method** - When user chooses to browse as guest

**What gets cleared:**
- **Wishlist:** Hive cache cleared, then refreshed (returns empty for guests)
- **Cart:** Refreshed to fetch guest cart state (typically empty)
- **Categories:** Force-refreshed to show guest version without user-specific data (liked products, etc.)

**Why this matters:**
- Prevents data leakage between users
- Ensures guest users see a clean slate
- Removes user-specific UI indicators (wishlist hearts, cart counts)
- Complies with privacy best practices

**Error Handling:**
- Data clearing errors are caught and logged but don't prevent logout/guest mode
- Guest mode should always succeed even if cache clearing fails
- This ensures the app remains usable in all scenarios

#### Data Refresh on Login

**File:** `lib/features/auth/application/providers/auth_provider.dart`

When a user logs in (via OTP, signup, or username/password), their user-specific data must be loaded. This is handled automatically by the `_refreshUserData()` method.

```dart
/// Refreshes user-specific data after successful login
/// This loads the authenticated user's cart, wishlist, and category preferences
Future<void> _refreshUserData() async {
  try {
    // Refresh wishlist to load user's saved items
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    await wishlistNotifier.refresh();

    // Refresh cart to load user's cart items
    final checkoutLineController = ref.read(checkoutLineControllerProvider.notifier);
    await checkoutLineController.refresh();

    // Refresh category data to show user's preferences (liked products, etc.)
    final categoryController = ref.read(categoryControllerProvider.notifier);
    await categoryController.refresh(force: true);
  } catch (e) {
    // Log error but don't fail the login
    // User should still be logged in even if data refresh fails
  }
}
```

**Called from:**
1. **`verifyOtp()` method** - After successful OTP verification
2. **`signup()` method** - After successful account creation
3. **`login()` method** - After successful username/password login

**What gets refreshed:**
- **Wishlist:** Fetches user's saved/wishlisted products from server
- **Cart:** Fetches user's cart items and quantities from server
- **Categories:** Force-refreshed to show user-specific data (liked products, wishlist indicators)

**Why this matters:**
- User sees their data immediately after login (no manual refresh needed)
- Seamless transition from guest mode to authenticated mode
- Prevents showing stale guest data to authenticated users
- Improves user experience with instant data visibility

**Error Handling:**
- Data refresh errors are caught and logged but don't prevent login
- User authentication succeeds even if data refresh fails
- User can manually refresh if automatic refresh fails

---

### 5. UI Components with Guest Protection

#### Product Cards

**Files:**
- `lib/features/home/presentation/components/product_card.dart` (Best Deals)
- `lib/features/category/presentation/components/widgets/_product_card.dart` (Category)

```dart
// Add to Cart Button
GestureDetector(
  onTap: () async {
    // Block guests from adding to cart
    final authState = ref.read(authProvider);
    final isGuest = authState is GuestMode;

    if (isGuest) {
      AppSnackbar.info(context, 'Please login to add items to cart');
      return;
    }

    // Proceed with add to cart
    await ref.read(checkoutLineControllerProvider.notifier)
        .addToCart(productVariantId: product.id, quantity: 1);
  },
  child: Icon(Icons.add),
)

// Wishlist Heart Icon
GestureDetector(
  onTap: () async {
    // Block guests from adding to wishlist
    final authState = ref.read(authProvider);
    final isGuest = authState is GuestMode;

    if (isGuest) {
      AppSnackbar.info(context, 'Please login to add items to wishlist');
      return;
    }

    // Proceed with wishlist toggle
    await ref.read(wishlistProvider.notifier)
        .toggleWishlist(product.id.toString());
  },
  child: Icon(isInWishlist ? Icons.favorite : Icons.favorite_border),
)
```

#### Product Details

**File:** `lib/features/product_details/presentation/components/product_info/product_info.dart`

```dart
// Wishlist Toggle with Guest Check
GestureDetector(
  onTap: () async {
    final success = await widget.onWishlistToggle();
    if (context.mounted && !success) {
      AppSnackbar.info(context, 'Please login to add items to wishlist');
    }
  },
  child: Icon(
    widget.isInWishlist ? Icons.favorite : Icons.favorite_border,
  ),
)
```

**File:** `lib/features/product_details/application/providers/product_detail_providers.dart`

```dart
/// Toggle wishlist status
Future<bool> toggleWishlist() async {
  // Block guests from adding to wishlist
  final authState = ref.read(authProvider);
  final isGuest = authState is GuestMode;

  if (isGuest) {
    state = state.copyWith(
      errorMessage: 'Please login to add items to wishlist'
    );
    return false;
  }

  try {
    if (state.isInWishlist) {
      await _repository.removeFromWishlist(_variantId);
      state = state.copyWith(isInWishlist: false);
    } else {
      await _repository.addToWishlist(_variantId);
      state = state.copyWith(isInWishlist: true);
    }
    return true;
  } catch (e) {
    state = state.copyWith(errorMessage: 'Failed to update wishlist: $e');
    return false;
  }
}
```

---

## API Endpoint Overrides

### Guest Mode Header Override

**All API requests** automatically receive the appropriate header based on auth state:

| Auth State | Header Added | Value | Purpose |
|------------|-------------|-------|---------|
| GuestMode | `dev` | `2` | Bypass authentication for browse-only access |
| Authenticated | `X-CSRFToken` | `<csrf_from_cookies>` | Standard Django CSRF protection |

### Endpoints Accessible in Guest Mode

The following endpoints work with `dev: 2` header:

#### Product Endpoints
- `GET /api/products/` - List products
- `GET /api/products/{id}/` - Product details
- `GET /api/products/variants/` - Product variants
- `GET /api/products/variants/{id}/` - Variant details
- `GET /api/products/search/` - Search products

#### Category Endpoints
- `GET /api/categories/` - List categories
- `GET /api/categories/{id}/` - Category details
- `GET /api/categories/{id}/products/` - Products in category

#### Other Browse Endpoints
- `GET /api/banners/` - Home banners
- `GET /api/offers/` - Special offers

### Endpoints Blocked for Guests

These endpoints require authentication (no `dev: 2` header support):

#### Cart Endpoints
- `POST /api/cart/add/` - Add to cart
- `GET /api/cart/` - View cart
- `PUT /api/cart/update/` - Update cart
- `DELETE /api/cart/remove/` - Remove from cart

#### Wishlist Endpoints
- `POST /api/wishlist/add/` - Add to wishlist
- `GET /api/wishlist/` - View wishlist
- `DELETE /api/wishlist/remove/` - Remove from wishlist

#### User Endpoints
- `GET /api/user/profile/` - User profile
- `PUT /api/user/profile/` - Update profile
- `GET /api/user/orders/` - Order history
- `GET /api/user/addresses/` - Saved addresses

#### Checkout Endpoints
- `POST /api/checkout/` - Create order
- `GET /api/checkout/{id}/` - Order details
- `POST /api/payment/` - Process payment

---

## User Experience Flow

### Guest User Journey

1. **Launch App**
   - Splash screen shows
   - No stored session found
   - Navigate to OTP screen

2. **Browse as Guest**
   - User taps "Continue as Guest" on OTP screen
   - AuthProvider sets state to `GuestMode()`
   - **Automatic data cleanup:**
     - Wishlist cache cleared and refreshed (empty for guests)
     - Cart data refreshed (empty for guests)
     - Category data force-refreshed (shows guest version without user-specific data)
   - Navigate to Home screen

3. **Browse Products**
   - All product browsing works normally
   - Can view categories, search, see details
   - API requests include `dev: 2` header
   - No user-specific data visible (clean slate)

4. **Attempt to Add to Cart**
   - User taps add button
   - Guest check triggers
   - Shows snackbar: "Please login to add items to cart"
   - No navigation (stays on current page)

5. **Attempt to Add to Wishlist**
   - User taps heart icon
   - Guest check triggers
   - Shows snackbar: "Please login to add items to wishlist"
   - No navigation

6. **Navigate to Cart/Profile**
   - User taps cart or profile icon
   - Router redirect triggers
   - Navigate to OTP screen for login

7. **Login**
   - User completes OTP verification
   - AuthProvider sets state to `Authenticated()`
   - **Automatic data refresh:**
     - Wishlist refreshed to load user's saved items
     - Cart refreshed to load user's cart items
     - Categories refreshed to show user's preferences (liked products)
   - API requests now include CSRF token
   - Full app access granted with user's data visible immediately

### Authenticated User Journey

1. **Launch App**
   - Splash screen shows
   - Stored session found (cookies exist)
   - AuthProvider sets state to `Authenticated()`
   - Navigate directly to Home

2. **Full Access**
   - All features available
   - Add to cart works
   - Wishlist works
   - Can access profile, orders, checkout

3. **Logout**
   - User taps logout
   - AuthProvider calls `logout()` method
   - Cookies cleared via repository
   - AuthProvider sets state to `GuestMode()`
   - **Automatic data cleanup:**
     - Wishlist cache cleared and refreshed (empty)
     - Cart data refreshed (empty)
     - Category data force-refreshed (guest version)
   - User can continue browsing as guest or login again
   - Navigate to OTP screen

---

## Developer Guidelines

### Adding a New Guest-Accessible Page

1. **Add route to router** (`lib/app/router/app_router.dart`)
   ```dart
   GoRoute(
     path: '/new-page',
     builder: (context, state) => const NewPage(),
   ),
   ```

2. **Mark as guest-accessible**
   ```dart
   static final _guestAccessibleRoutes = {
     '/',
     '/otp',
     '/home',
     '/new-page', // Add here
   };
   ```

### Adding Guest Protection to a Feature

1. **Read auth state**
   ```dart
   final authState = ref.read(authProvider);
   final isGuest = authState is GuestMode;
   ```

2. **Block action with message**
   ```dart
   if (isGuest) {
     AppSnackbar.info(context, 'Please login to access this feature');
     return;
   }
   ```

3. **Optionally return status**
   ```dart
   Future<bool> myAction() async {
     if (isGuest) return false;
     // ... perform action
     return true;
   }
   ```

### Testing Guest Mode

1. **Clear app data** to remove stored cookies
2. **Launch app** - should show OTP screen
3. **Tap "Continue as Guest"**
4. **Verify:**
   - Can browse products
   - Add to cart shows "Please login" message
   - Wishlist shows "Please login" message
   - Cart/Profile navigation redirects to OTP
   - API requests include `dev: 2` header (check logs)

### Testing Authenticated Mode

1. **Login with OTP**
2. **Verify:**
   - Can add to cart
   - Can add to wishlist
   - Can access all pages
   - API requests include `X-CSRFToken` header (check logs)

---

## Common Issues & Solutions

### Issue: Guest can access auth-required page

**Solution:** Add route to auth-required list in router redirect logic

### Issue: Authenticated user sees "Please login" message

**Solution:** Check that auth state is properly set after login. Verify CSRF token extraction from cookies.

### Issue: API returns 403 Forbidden

**Solution:**
- Guest: Ensure `dev: 2` header is being sent
- Authenticated: Verify CSRF token is valid and not expired

### Issue: Guest redirects to OTP when browsing

**Solution:** Ensure route is in `_guestAccessibleRoutes` set

---

## Security Considerations

1. **Guest Mode Limitations**
   - Guests cannot modify data (cart, wishlist, profile)
   - Guests cannot checkout or place orders
   - Guest sessions don't persist user-specific data

2. **CSRF Protection**
   - All authenticated requests require valid CSRF token
   - Tokens are automatically extracted from cookies
   - Tokens must match server-side session

3. **Header Security**
   - `dev: 2` header only enables read-only access
   - Server must validate this header and restrict write operations
   - Never expose sensitive data to guest users

4. **Session Management**
   - Cookies persist login state
   - Clearing cookies logs user out
   - No manual token storage (security best practice)

5. **Data Privacy**
   - User-specific data automatically cleared on logout
   - Guest mode triggers complete cache refresh
   - No data leakage between user sessions
   - Previous user's wishlist/cart never visible to guests

---

## File Reference

### Core Files
- `lib/main.dart` - Global container setup
- `lib/core/network/api_client.dart` - HTTP client with guest support
- `lib/app/router/app_router.dart` - Route guards

### Auth Feature
- `lib/features/auth/application/providers/auth_provider.dart` - Auth state management
- `lib/features/auth/application/states/auth_state.dart` - Auth state definitions
- `lib/features/auth/presentation/screen/splash_screen.dart` - App entry point

### Guest Protection Points
- `lib/features/home/presentation/components/product_card.dart` - Best deals cards
- `lib/features/category/presentation/components/widgets/_product_card.dart` - Category cards
- `lib/features/product_details/application/providers/product_detail_providers.dart` - Product detail logic
- `lib/features/product_details/presentation/components/product_info/product_info.dart` - Product info UI

### Data Providers (for cleanup)
- `lib/features/wishlist/application/providers/wishlist_provider.dart` - Wishlist state management
- `lib/features/cart/application/providers/checkout_line_provider.dart` - Cart state management
- `lib/features/category/application/providers/category_providers.dart` - Category state management

### Utilities
- `lib/core/widgets/app_snackbar.dart` - User feedback messages

---

## Changelog

### v1.1 - Automatic Data Management on Auth State Changes (Current)
- **NEW:** Automatic data cleanup when entering guest mode or logging out
  - Wishlist cache cleared and refreshed on logout
  - Cart data refreshed to show guest state
  - Categories force-refreshed to remove user-specific data
  - `_clearUserData()` method in AuthProvider
- **NEW:** Automatic data refresh when logging in
  - Wishlist refreshed to load user's saved items
  - Cart refreshed to load user's cart items
  - Categories refreshed to show user's preferences
  - `_refreshUserData()` method in AuthProvider
- **IMPROVED:** No data leakage between user sessions
- **IMPROVED:** Guest users always see clean slate after logout
- **IMPROVED:** Authenticated users see their data immediately after login (no manual refresh needed)
- **IMPROVED:** Seamless transitions between guest mode and authenticated mode

### v1.0 - Initial Implementation
- Guest mode support with `dev: 2` header
- Route guards for auth-required pages
- UI protection for cart and wishlist actions
- CSRF token handling for authenticated users
- Animated splash screen with guest mode flow

---

## Contact

For questions or issues regarding authentication and guest mode:
- Review this documentation
- Check the specific file implementations
- Test both guest and authenticated flows
- Verify API headers in network logs
