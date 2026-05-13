# Dashboard & Navigation Shell — Code Audit Report

**Scope:** Bottom Navigation Bar (`bottom_navbar.dart`) · App Router (`app_router.dart`) · Auth Guard (`auth_guard.dart`)

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 6

**Date:** 2026-05-02

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 1 | 2 | 1 | 4 |
| Prompt 2 — Security & Data Persistence | 0 | 1 | 1 | 2 |
| Prompt 3 — Performance & Error Handling | 0 | 2 | 2 | 4 |
| Prompt 4 — Code Quality & Deployment | 2 | 3 | 2 | 7 |
| Prompt 6 — Architecture Compliance | 1 | 2 | 2 | 5 |
| **Total** | **4** | **10** | **8** | **22** |

---

## Top Blockers Before Any Production Release

1. **Dead redirect target in `/address` route guard** — `app_router.dart:157` — `AuthGuard` redirects to `/number` which does not exist anywhere in the router; any unauthenticated access to `/address` causes a GoRouter 404.
2. **`_pages` getter recreates all 4 tab widgets on every `build()`** — `bottom_navbar.dart:60–72` — new widget instances are constructed on every `setState`, invalidating `IndexedStack` diffing and causing unnecessary subtree rebuilds.
3. **Polling feature names are intentionally reversed** — `bottom_navbar.dart:85–91` — Tab 0 (HomeScreen) is mapped to `'category_products'` and Tab 1 (CategoryScreen) is mapped to `'home'`, which activates the wrong pollers when switching tabs.
4. **`/cart` route renders `CartScreen` outside `BottomNavigation`** — `app_router.dart:169` — a standalone `/cart` route exists alongside the embedded cart tab, causing inconsistent back-stack and double rendering.
5. **OTP route transition is 2 seconds** — `app_router.dart:143–150` — the most frequently visited auth route has a 2-second fade animation, appearing frozen to the user.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

---

### C1 — Static GlobalKey exposes BottomNavigationState globally — mutable global state antipattern

**File:** `lib/features/bottomnavbar/bottom_navbar.dart:23–24`

**Severity:** CRITICAL

**Issue:** `BottomNavigation.globalKey` is a `static final GlobalKey<BottomNavigationState>` on the widget class. This allows any code anywhere in the app to call `BottomNavigation.globalKey.currentState?.navigateToTab(index)` or `navigateToCategories(category)`, creating an untracked imperative mutation path that bypasses Riverpod entirely.

**Code:**
```dart
class BottomNavigation extends ConsumerStatefulWidget {
  const BottomNavigation({super.key});

  /// Global key to access BottomNavigation state from anywhere
  static final GlobalKey<BottomNavigationState> globalKey =
      GlobalKey<BottomNavigationState>();
```

**Impact:** Any screen can mutate navigation state without going through a provider. Tab changes made via the global key do not emit Riverpod state, so any provider that watches current tab index will not see the change. This is unmockable in tests and makes navigation flow untraceable.

**Fix Required:** Replace with a Riverpod `StateNotifier` or `Notifier` that holds the current tab index and exposes `navigateTo(int)` and `navigateToCategory(Category)`. The `BottomNavigation` widget watches the notifier instead of holding its own mutable int. Remove the `GlobalKey` entirely.

---

## High Priority Issues

---

### H1 — `_pages` getter reconstructs all 4 tab widgets on every build

**File:** `lib/features/bottomnavbar/bottom_navbar.dart:60–72`

**Severity:** HIGH

**Issue:** `_pages` is a getter that creates a new `List<Widget>` containing new instances of `HomeScreen`, `CategoryScreen`, `WishlistScreen`, and `CartScreen` on every invocation. Since it is called inside `build()` via `IndexedStack(children: _pages)`, a new list is built on every `setState` — including every tab tap and every back-press.

**Code:**
```dart
List<Widget> get _pages {
  return [
    HomeScreen(onCategoryNavigate: navigateToCategories),
    CategoryScreen(
      key: ValueKey(_selectedCategoryId),
      initialCategoryId: _selectedCategoryId?.toString(),
    ),
    const WishlistScreen(),
    const CartScreen(),
  ];
}

// Called in build():
IndexedStack(index: _currentIndex, children: _pages)
```

**Impact:** Every tab switch calls `setState`, which calls `build()`, which calls `_pages`, creating 4 new widget instances. `IndexedStack` receives new child references and must reconcile the entire subtree. `HomeScreen` also receives a new `onCategoryNavigate` closure instance on every build, which can trigger unnecessary rebuilds in descendants that compare callbacks.

**Fix Required:** Move `_pages` to a `late final` field initialised in `initState()`. The `CategoryScreen` key updates can be handled by rebuilding only the category page slot when `_selectedCategoryId` changes:
```dart
late final List<Widget> _pages;

@override
void initState() {
  super.initState();
  _pages = [
    HomeScreen(onCategoryNavigate: navigateToCategories),
    CategoryScreen(initialCategoryId: _selectedCategoryId?.toString()),
    const WishlistScreen(),
    const CartScreen(),
  ];
}
```

---

### H2 — Polling feature name mapping is inverted between tabs

**File:** `lib/features/bottomnavbar/bottom_navbar.dart:85–91`

**Severity:** HIGH

**Issue:** The `PollingTabController` maps Tab 0 (renders `HomeScreen`) to `'category_products'` and Tab 1 (renders `CategoryScreen`) to `'home'`. The comment acknowledges this mismatch ("Matches CategoryProductController registration") but the inversion means that when the user is on the Home tab, the polling manager believes `'category_products'` is active — resuming category product pollers when no category screen is visible.

**Code:**
```dart
_pollingController = PollingTabController(
  tabToFeature: {
    0: 'category_products', // Home screen
    1: 'home', // Category screen - Matches CategoryProductController registration
    2: 'wishlist',
    3: 'cart',
  },
);
```

**Impact:** Pollers that should only run on the Category tab will fire on the Home tab and vice versa. This wastes network calls (polling product data while user is on Home) and may fail to poll the correct data when the user is actually on the Category tab. The inverted labels will confuse every developer who works on polling integration.

**Fix Required:** Rename the feature strings to match what each tab actually renders. If the `CategoryProductController` registers itself under `'category_products'`, that notifier should be on Tab 1 (CategoryScreen), not Tab 0. Align either the tab mapping or the notifier registration string — but not leave them contradictory:
```dart
tabToFeature: {
  0: 'home',               // HomeScreen pollers
  1: 'category_products',  // CategoryScreen pollers
  2: 'wishlist',
  3: 'cart',
},
```

---

## Medium Priority Issues

---

### M1 — Tab history tracks duplicates, allowing back-press to revisit the same tab

**File:** `lib/features/bottomnavbar/bottom_navbar.dart:75, 126–129`

**Severity:** MEDIUM

**Issue:** `_tabHistory` appends the current tab index even when it equals the previous entry. Tapping the same tab twice results in `[0, 0]`. Pressing back then navigates to the same tab rather than exiting the app, because `_tabHistory.length > 1`.

**Code:**
```dart
final List<int> _tabHistory = [0];
// ...
if (index != _currentIndex) {
  _tabHistory.add(index);
}
```

**Impact:** The guard `if (index != _currentIndex)` prevents duplicates from `_onTabSelected`, but `navigateToCategories` and `navigateToTab` both append unconditionally when `_currentIndex != 1/index`. A rapid double-tap can produce `[0, 1, 1]`, making the first back-press a no-op.

**Fix Required:** Guard all three append sites with `if (_tabHistory.isEmpty || _tabHistory.last != index)` to prevent consecutive duplicates:
```dart
if (_tabHistory.isEmpty || _tabHistory.last != tabIndex) {
  _tabHistory.add(tabIndex);
}
```

---

---

# QA Prompt 2 — Security & Data Persistence Violations

---

## Critical Issues

*None found in this scope.*

---

## High Priority Issues

---

### H1 — `state.extra` cast on `/forgot-password-otp` route has no null guard — runtime crash on deep link

**File:** `lib/app/router/app_router.dart:208–210`

**Severity:** HIGH

**Issue:** The `/forgot-password-otp` route casts `state.extra` directly to `String` with no null check. If the route is accessed via deep link, browser restoration, or a GoRouter redirect that doesn't carry `extra`, the cast throws a `TypeError` at runtime.

**Code:**
```dart
GoRoute(
  path: '/forgot-password-otp',
  builder: (context, state) {
    final mobileNumber = state.extra as String;  // unchecked cast
    return ForgotPasswordOtpScreen(mobileNumber: mobileNumber);
  },
),
```

**Impact:** Any navigation to `/forgot-password-otp` without `extra` (deep link, back-navigation restore, unit test) throws `TypeError: Null is not a String`. The screen crashes before rendering.

**Fix Required:**
```dart
builder: (context, state) {
  final mobileNumber = state.extra as String? ?? '';
  if (mobileNumber.isEmpty) return const ForgotPasswordScreen();
  return ForgotPasswordOtpScreen(mobileNumber: mobileNumber);
},
```

---

## Medium Priority Issues

---

### M1 — `/address` route guard's `redirectTo: '/number'` references a non-existent route (security boundary hole)

**File:** `lib/app/router/app_router.dart:153–163`

**Severity:** MEDIUM

**Issue:** The `/address` route uses `AuthGuard` with `redirectTo: '/number'`. The route `/number` does not exist in the route table. An unauthenticated deep link to `/address` attempts to redirect to `/number`, which GoRouter cannot resolve.

**Code:**
```dart
GoRoute(
  path: '/address',
  redirect: (context, state) {
    final guard = AuthGuard(ref);
    return guard.protect(redirectTo: '/number');  // /number not registered
  },
  ...
),
```

**Impact:** An unauthenticated user accessing `/address` causes a GoRouter `GoException` or silent navigation failure instead of being redirected to the login/OTP screen. The auth guard intended to protect this route effectively fails open on unauthenticated access.

**Fix Required:** Change `redirectTo: '/otp'` to point to the app's actual auth entry route. Verify there is no intended `/number` alias.

---

---

# QA Prompt 3 — Error Handling & Performance

---

## Critical Issues

*None found in this scope.*

---

## High Priority Issues

---

### H1 — OTP route transition duration is 2 seconds — blocks the most common auth entry point

**File:** `lib/app/router/app_router.dart:143–150`

**Severity:** HIGH

**Issue:** The `/otp` route's `CustomTransitionPage` uses `transitionDuration: const Duration(seconds: 2)`. Every user who opens the app on a cold start, logs out, or starts the forgot-password flow waits 2 full seconds for a fade animation before they can interact with the OTP screen.

**Code:**
```dart
GoRoute(
  path: '/otp',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const OTPScreen(),
    transitionDuration: const Duration(seconds: 2), // 10× too slow
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
),
```

**Impact:** On every app cold start, the OTP screen (the primary auth screen) takes 2 seconds to appear. This reads as the app being frozen, particularly on low-end devices. Standard Flutter transition durations are 250–400ms.

**Fix Required:** `transitionDuration: const Duration(milliseconds: 350)`.

---

### H2 — `/cart` GoRoute duplicates CartScreen outside BottomNavigation — inconsistent back-stack

**File:** `lib/app/router/app_router.dart:169`

**Severity:** HIGH

**Issue:** A standalone `/cart` route renders `CartScreen` directly, bypassing `BottomNavigation`. The same `CartScreen` is also embedded as tab index 3 inside `BottomNavigation`. Navigating to `/cart` via a deep link or `context.go('/cart')` shows the cart without the bottom nav bar, while tapping the cart tab shows it within the nav.

**Code:**
```dart
GoRoute(path: '/cart', builder: (_, state) => const CartScreen()),
// Also inside BottomNavigation._pages:
const CartScreen(),  // tab index 3
```

**Impact:** Users navigating from a notification or external link to `/cart` see no bottom bar and cannot return to other tabs without pressing the system back button. Two separate `CartScreen` instances can coexist in the widget tree simultaneously if the user has both the nav and a pushed `/cart` route active.

**Fix Required:** Remove the standalone `/cart` GoRoute. All cart navigation should use `context.go('/home')` then programmatically switch to tab 3 via the tab notifier, or — if a standalone cart page is needed — give it a distinct route like `/cart-standalone` that is explicitly used only in specific flows.

---

## Medium Priority Issues

---

### M1 — Bottom nav icons and cart badge use hardcoded raw pixel values — ScreenUtil not applied

**File:** `lib/features/bottomnavbar/bottom_navbar.dart:219–272, 309–321`

**Severity:** MEDIUM

**Issue:** All nav bar icon sizes and the cart badge dimensions use raw integer literals (`height: 20, width: 20`, `padding: EdgeInsets.all(4)`, `minWidth: 16, minHeight: 16`, `fontSize: 10`) instead of ScreenUtil-responsive units.

**Code:**
```dart
// Nav icons (lines 219–272):
height: 20,   // should be 20.h / 20.w
width: 20,    // should be 20.w

// Cart badge (lines 309–316):
padding: const EdgeInsets.all(4),             // should be EdgeInsets.all(4.r)
constraints: const BoxConstraints(minWidth: 16, minHeight: 16), // 16.w / 16.h
style: const TextStyle(fontSize: 10, ...),    // should be 10.sp
```

**Impact:** Nav icons and the cart badge do not scale on tablets or high-DPI displays. On a 12-inch tablet the 20px icons look tiny compared to the ScreenUtil-scaled content they border.

**Fix Required:** Replace all raw pixel values with ScreenUtil equivalents (`20.w`, `20.h`, `4.r`, `10.sp`). Remove all `const` qualifiers from the affected widgets.

---

### M2 — `GoRouterRefreshStream` holds a `Ref` beyond its intended lifecycle

**File:** `lib/app/router/app_router.dart:30–36`

**Severity:** MEDIUM

**Issue:** `GoRouterRefreshStream` stores `Ref ref` implicitly via the `ref.listen` closure captured during construction. The `ChangeNotifier` is created once and stored inside the `GoRouter`. If the `goRouterProvider` is ever invalidated and rebuilt, the old `GoRouterRefreshStream` with its stale `Ref` continues to live inside the already-disposed `GoRouter` instance.

**Code:**
```dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authProvider, (prev, next) {
      notifyListeners();
    });
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshStream(ref);
  // refreshNotifier is never disposed — ChangeNotifier leak
  return GoRouter(refreshListenable: refreshNotifier, ...);
});
```

**Impact:** Minor memory leak if `goRouterProvider` is ever invalidated. The `ChangeNotifier` is never disposed, leaking its listener registration. In practice, `goRouterProvider` is `keepAlive` (default for plain `Provider`), so the risk is low — but the pattern is non-idiomatic.

**Fix Required:**
```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshStream(ref);
  ref.onDispose(refreshNotifier.dispose);
  return GoRouter(refreshListenable: refreshNotifier, ...);
});
```

---

---

# QA Prompt 4 — Code Quality & Deployment Readiness

---

## Critical Issues

---

### C1 — `/address` route guard redirects to `/number` — unauthenticated users hit a 404 (deployment blocker)

**File:** `lib/app/router/app_router.dart:153–163`

**Severity:** CRITICAL

**Issue:** Repeated from Prompt 2 M1 — listed as CRITICAL here because it is a confirmed deployment blocker. The `/address` route is used during new-user onboarding. If the guard fires (unauthenticated deep link), users are sent to a route that does not exist.

**Code:**
```dart
return guard.protect(redirectTo: '/number'); // /number is not in the route table
```

**Impact:** New-user onboarding from a deep link is broken. Any CI test that navigates to `/address` without auth will crash the test runner.

**Fix Required:** Change to `redirectTo: '/otp'`.

---

### C2 — Global redirect reads auth state with `ref.read` — stale state possible during auth transitions

**File:** `lib/app/router/app_router.dart:51`

**Severity:** CRITICAL

**Issue:** The GoRouter global `redirect` callback reads auth state with `ref.read(authProvider)`. `ref.read` captures the current state synchronously at the time the redirect fires. During `AuthChecking` (the brief window between app start and session restore), if `refreshListenable` fires before `AuthChecking` transitions to `Authenticated` or `GuestMode`, `ref.read` returns the intermediate state and the redirect fires prematurely.

**Code:**
```dart
redirect: (context, state) {
  final location = state.matchedLocation;
  final authState = ref.read(authProvider);  // snapshot at redirect time
  final isAuthenticated = authState is Authenticated;
  final isCheckingAuth = authState is AuthChecking;

  if (isCheckingAuth && location == '/splash') {
    return null;  // only guards splash — all other routes unguarded during AuthChecking
  }
  ...
```

**Impact:** If `refreshListenable` notifies during `AuthChecking` while the user is on any route other than `/splash` (e.g. a deep link), `isCheckingAuth` is `true` but the early-return only applies to `/splash`. For other locations the redirect falls through to the `!isAuthenticated && !isCheckingAuth` check, which is `false` during `AuthChecking`, so protected routes are not redirected. An unauthenticated user briefly has access to protected routes during the auth-check window.

**Fix Required:** Extend the `AuthChecking` guard to all routes, not just `/splash`:
```dart
if (isCheckingAuth) return null; // hold all redirects while checking
```
Pair this with a loading overlay on all protected routes that shows until `isCheckingAuth` resolves.

---

## High Priority Issues

---

### H1 — `/address` route casts `state.extra` without null-check — crashes on bad navigation

**File:** `lib/app/router/app_router.dart:160`

**Severity:** HIGH

**Issue:** The address route builder does `final user = state.extra as UserEntity` with no null guard. If reached via the broken `/number` redirect or a direct deep link without `extra`, the cast throws immediately.

**Code:**
```dart
builder: (context, state) {
  final user = state.extra as UserEntity;  // unchecked — throws if null
  return AddressScreen(user: user);
},
```

**Impact:** Combined with the broken `/number` redirect, this route can never be reached safely in the current state. Even after fixing the redirect, a stale navigation entry without `extra` will crash.

**Fix Required:**
```dart
builder: (context, state) {
  final user = state.extra;
  if (user is! UserEntity) return const OTPScreen();
  return AddressScreen(user: user);
},
```

---

### H2 — `GoRouterRefreshStream` is never disposed — ChangeNotifier leak

**File:** `lib/app/router/app_router.dart:38–39`

**Severity:** HIGH

**Issue:** Repeated from Prompt 3 M2 — listed at HIGH here because listener leaks in `ChangeNotifier` can cause `setState` after dispose errors in edge cases.

**Code:**
```dart
final refreshNotifier = GoRouterRefreshStream(ref);
// ref.onDispose never called for refreshNotifier
```

**Fix Required:** `ref.onDispose(refreshNotifier.dispose);`

---

### H3 — Zero tests for routing and navigation guard logic

**File:** `lib/app/router/app_router.dart`, `lib/app/router/auth_guard.dart`

**Severity:** HIGH

**Issue:** There are no tests for any routing logic — no tests for `AuthGuard.protect()`, no tests for the global `redirect` callback, and no tests for any `GoRoute` builder. The routing layer is the single highest-risk component in the entire app: a broken redirect or missing route affects every user on every screen.

**Impact:** Any change to the route table or redirect logic silently ships with no regression detection. The confirmed `/number` redirect bug exists because there is no test that exercises this path.

**Fix Required:** At minimum, add unit tests for:
- `AuthGuard.protect()` — authenticated and unauthenticated states.
- Global `redirect` — authenticated on auth route, unauthenticated on protected route, `AuthChecking` state.
- Route `extra` null-safety guards on `/sign-pass`, `/address`, `/forgot-password-otp`, `/reset-password`.

---

## Medium Priority Issues

---

### M1 — OTP transition duration is 2 seconds — repeated from Prompt 3 H1

**File:** `lib/app/router/app_router.dart:147`

**Severity:** MEDIUM

**Issue:** Listed again under deployment readiness. This is the most user-visible performance issue in the router.

**Fix Required:** `transitionDuration: const Duration(milliseconds: 350)`.

---

### M2 — Inline `List<int>` for `protectedRoutes` and `authRoutes` should be constants

**File:** `lib/app/router/app_router.dart:61–84`

**Severity:** MEDIUM

**Issue:** `protectedRoutes` and `authRoutes` are inline `List<String>` literals created on every `redirect` call. The redirect fires on every navigation event. Allocating two lists on every redirect is an unnecessary allocation in a hot path.

**Code:**
```dart
final protectedRoutes = [
  '/cart',
  '/checkout',
  '/profile',
  '/orders',
  '/account',
];

final authRoutes = [
  '/login',
  '/signup',
  '/otp',
  ...
];
```

**Impact:** Minor allocation pressure — negligible on its own but indicative of non-production-hardened code in the most frequently executed callback in the app.

**Fix Required:** Extract to top-level `const Set<String>`. Use `const` `Set` for O(1) `contains` instead of O(n) list `.any()`:
```dart
const _protectedRoutes = {'/cart', '/checkout', '/profile', '/orders', '/account'};
const _authRoutes = {'/login', '/signup', '/otp', '/sign-pass', ...};
```

---

---

# QA Prompt 6 — Architecture Compliance (4-Layer Violations)

---

## Critical Issues

---

### C1 — `BottomNavigation` imports screens from multiple feature domains — breaks feature isolation

**File:** `lib/features/bottomnavbar/bottom_navbar.dart:10–18`

**Severity:** CRITICAL

**Issue:** `bottom_navbar.dart` imports presentation screens from `cart`, `category`, `home`, `wishlist`, and `auth` directly. It also imports a domain entity (`Category`) from `home/domain/entities/`. A navigation shell should only compose screens; it must not import domain entities directly.

**Code:**
```dart
import '../auth/application/providers/auth_provider.dart';
import '../auth/application/states/auth_state.dart';
import '../cart/application/providers/checkout_line_provider.dart';
import '../category/presentation/screen/category_screen.dart';
import '../cart/presentation/screen/cart_screen.dart';
import '../category/presentation/components/widgets/review_bottom_sheet.dart';
import '../home/presentation/screen/home_screen.dart';
import '../wishlist/presentation/screen/wishlist_screen.dart';
import '../home/domain/entities/category.dart';  // domain entity in navigation shell
```

**Impact:** The navigation shell couples to the domain layer of the `home` feature. If `Category` is renamed or moved, `bottom_navbar.dart` must be updated. The `navigateToCategories(Category category)` method on the public state class leaks a domain type into the navigation layer.

**Fix Required:** Replace `navigateToCategories(Category category)` with `navigateToCategories(int categoryId)` — pass only the primitive ID, not the domain entity. Remove the `home/domain/entities/category.dart` import from the navigation shell.

---

## High Priority Issues

---

### H1 — `AuthGuard` reads auth state via `ref.read` — does not re-evaluate on state change

**File:** `lib/app/router/auth_guard.dart:11–13`

**Severity:** HIGH

**Issue:** `AuthGuard.isAuthenticated` uses `ref.read(authProvider)`. `ref.read` is correct for one-shot checks inside callbacks, but the `AuthGuard` is instantiated fresh on every `redirect` call (`AuthGuard(ref)`) and only exists for that single synchronous check. While this is technically correct per the Riverpod contract, the `AuthGuard` class is designed as a reusable object but is always discarded after a single call — it has no value as a class.

**Code:**
```dart
class AuthGuard {
  final Ref ref;
  AuthGuard(this.ref);

  bool get isAuthenticated {
    final state = ref.read(authProvider);
    return state is Authenticated;
  }

  String? protect({String redirectTo = '/login'}) {
    return isAuthenticated ? null : redirectTo;
  }
}
```

**Impact:** The default `redirectTo: '/login'` in `protect()` is never used — every call site overrides it with a different value (and currently an invalid one). The class has one use site and wraps a single `ref.read` check — it is over-engineered for its purpose and masks the broken `/number` default.

**Fix Required:** Either inline the guard logic directly in the route's `redirect` callback (it's one line), or keep the class but change its default to `'/otp'` and add a check that the target route actually exists.

---

### H2 — Navigation shell has no Riverpod-managed state for current tab — violates state management rules

**File:** `lib/features/bottomnavbar/bottom_navbar.dart:74, 130–132`

**Severity:** HIGH

**Issue:** `_currentIndex` and `_tabHistory` are `StatefulWidget` local state managed with raw `setState()`. Per architecture rules (QA Prompt 6 Rule 15), `StatefulWidget` is for purely visual/local state only. Tab selection represents app-wide navigation state that other screens need to read (e.g. to programmatically switch tabs). Storing it as widget-local state makes it inaccessible to the rest of the app except through the `GlobalKey` antipattern.

**Code:**
```dart
int _currentIndex = 0;
final List<int> _tabHistory = [0];
// ...
setState(() => _currentIndex = index);
```

**Impact:** Any screen needing to know the current tab must use `BottomNavigation.globalKey.currentState?._currentIndex` — bypassing Riverpod entirely. This is the root cause of the `GlobalKey` antipattern flagged in Prompt 1 C1.

**Fix Required:** Create a `NavigationNotifier` (or `TabNotifier`) that holds `currentIndex` and `tabHistory`. `BottomNavigation` watches it and delegates all tab changes through it. Other screens call `ref.read(tabProvider.notifier).selectTab(index)`.

---

## Medium Priority Issues

---

### M1 — `GoRoute` builders for data-carrying routes do not validate `state.extra` type before casting

**File:** `lib/app/router/app_router.dart:117–134, 160, 208–210, 216–228`

**Layer:** Presentation (routing)

**Severity:** MEDIUM

**Issue:** Multiple routes cast `state.extra` without confirming the type first. The `/sign-pass` route correctly checks `rawData is! Map` before proceeding, but `/address`, `/forgot-password-otp`, and `/reset-password` do not follow this pattern consistently.

**Code:**
```dart
// /address — no check:
final user = state.extra as UserEntity;

// /forgot-password-otp — no check:
final mobileNumber = state.extra as String;

// /reset-password — partial check (null/Map checked, but not String keys):
final data = rawData as Map<String, dynamic>; // still can throw on type mismatch
```

**Impact:** Any route accessed without its expected `extra` (deep link, state restoration, test) throws a `TypeError`.

**Fix Required:** Apply the same guard pattern used in `/sign-pass` to every data-carrying route. Prefer `is` type checks over `as` casts.

---

### M2 — `app_router.dart` navigation helper functions bypass the provider — use `BuildContext` directly

**File:** `lib/app/router/app_router.dart:241–331`

**Severity:** MEDIUM

**Issue:** Navigation helper functions (`goToHome`, `goToOTP`, `goToAddress`, etc.) take a raw `BuildContext` and call `context.go()`. These functions exist outside any provider or widget, making them untestable global functions that capture `BuildContext` at call time.

**Code:**
```dart
void goToHome(BuildContext context) {
  context.go('/home');
}

void goToAddress(BuildContext context, UserEntity user) {
  context.go('/address', extra: user);
}
```

**Impact:** These functions cannot be called from inside providers (no `BuildContext` available), cannot be intercepted in tests, and duplicate the routing logic. They also carry `UserEntity` as a raw `extra` parameter, perpetuating the unguarded cast vulnerability.

**Fix Required:** Replace with a `NavigationService` provider that holds a `GoRouter` reference and exposes typed navigation methods:
```dart
class NavigationService {
  NavigationService(GoRouter router) : _router = router;
  final GoRouter _router;
  void goHome() => _router.go('/home');
  void goAddress(UserEntity user) => _router.go('/address', extra: user);
}
```
