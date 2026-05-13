# Home Flow — Code Audit Report

**Scope:** Home Screen · Search Screen · Categories Screen · Categories with Sidebar Screen · Category Detail Screen

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 6

**Date:** 2026-04-30

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 2 | 3 | 2 | 7 |
| Prompt 2 — Security & Data Persistence | 2 | 2 | 2 | 6 |
| Prompt 3 — Performance & Error Handling | 2 | 3 | 3 | 8 |
| Prompt 4 — Code Quality & Deployment | 3 | 2 | 3 | 8 |
| Prompt 6 — Architecture Compliance | 3 | 3 | 2 | 8 |
| **Total** | **12** | **13** | **12** | **37** |

---

## Top Blockers Before Any Production Release

1. **Three screens are entirely unimplemented** — Categories Screen, Categories with Sidebar Screen, and Category Detail Screen all render only `Text('category')`. Every import is commented out. These are deployment blockers.
2. **Presentation imports infrastructure directly** — `home_screen.dart` imports `home_repostory_impl.dart` (infrastructure layer). Providers defined inside infrastructure files are consumed by the UI.
3. **`Hive.openBox()` called inside a data source method** — `HomeLocalDataSourceImpl.box` opens the Hive box lazily on every access with no concurrency lock.
4. **Trending product taps are a no-op** — `SearchScreen` renders trending products but the `onProductClick` callback body is an empty comment — navigation never happens.
5. **Commented-out exception handler in repository** — `HomeRepositoryImpl._handleException` is fully commented out, leaving 6 independent error-handling blocks with no shared contract.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

---

### C1 — HomeScreen directly imports the infrastructure repository implementation

**File:** `lib/features/home/presentation/screen/home_screen.dart:64`

**Severity:** CRITICAL

**Issue:** The presentation layer imports `home_repostory_impl.dart` (an infrastructure file) to access `homeRepositoryProvider`. This couples the screen directly to the infrastructure implementation rather than reading a provider from the application layer.

**Code:**
```dart
import '../../infrastructure/repositories/home_repostory_impl.dart';
// ...
final result = await ref.read(homeRepositoryProvider).getProductById(targetId);
```

**Impact:** Presentation directly depends on infrastructure. If the repository implementation changes or is swapped, the screen must be updated. GoRouter and the application state layer have no visibility of the banner-click product resolution — it runs as a raw async operation with no state tracking.

**Fix Required:** Move `homeRepositoryProvider` to the application layer (`application/providers/`). Screen imports the application-layer provider only, never the infrastructure file.

---

### C2 — Providers are defined inside the infrastructure layer files

**File:** `lib/features/home/infrastructure/repositories/home_repostory_impl.dart:430–437`
**File:** `lib/features/home/infrastructure/data_sources/remote/home_api.dart:386–391`

**Severity:** CRITICAL

**Issue:** Riverpod providers (`homeRepositoryProvider`, `homeRemoteDataSourceProvider`, `homeLocalDataSourceProvider`) are defined at the bottom of infrastructure implementation files. Infrastructure files should never export application-layer constructs (providers).

**Code:**
```dart
// In home_repostory_impl.dart
final homeRepositoryProvider = riverpod.Provider<HomeRepository>((ref) {
  final remoteDs = ref.watch(homeRemoteDataSourceProvider);
  final localDs = ref.watch(homeLocalDataSourceProvider);
  return HomeRepositoryImpl(remoteDataSource: remoteDs, localDataSource: localDs);
});

// In home_api.dart
final homeRemoteDataSourceProvider = riverpod.Provider<HomeRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeApiImpl(apiClient);
});
```

**Impact:** Presentation and application layers must import infrastructure files to access providers. This hardwires the entire architecture to specific implementations and prevents clean dependency inversion.

**Fix Required:** Move all provider definitions to `lib/features/home/application/providers/`. Infrastructure files contain only classes, not provider registrations.

---

## High Priority Issues

---

### H1 — `HomeNotifier` and `SearchNotifier` use old-style `StateNotifier` instead of Riverpod 2.x codegen

**File:** `lib/features/home/application/providers/home_provider.dart:21, 177`

**Severity:** HIGH

**Issue:** Both notifiers use `StateNotifier<T>` with manual `StateNotifierProvider` registration. The rest of the codebase uses `@riverpod` code generation (e.g. `AuthNotifier` uses `@Riverpod(keepAlive: true)`). The home feature is architecturally inconsistent.

**Code:**
```dart
class HomeNotifier extends StateNotifier<HomeState> { ... }
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) { ... });

class SearchNotifier extends StateNotifier<SearchState> { ... }
final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) { ... });
```

**Impact:** Two different state management paradigms in the same app. `StateNotifier` is deprecated in Riverpod 2.x. Developers must context-switch between styles. Codegen providers gain autoDispose, family, and ref safety features automatically.

**Fix Required:** Migrate to `@riverpod class HomeController extends _$HomeController` and `@riverpod class SearchController extends _$SearchController` following the codegen pattern used in auth.

---

### H2 — `homeProvider` is not `keepAlive` but manages persistent app-wide screen state

**File:** `lib/features/home/application/providers/home_provider.dart:253`

**Severity:** HIGH

**Issue:** `homeProvider` uses `StateNotifierProvider` without `keepAlive: true`. The home screen is the primary screen of the app and its state (categories, deals, banners) should persist across tab switches. If the provider is disposed, all cached state is lost and data is re-fetched on every return to the home tab.

**Code:**
```dart
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  // No keepAlive — provider disposes when no listeners
  final repository = ref.watch(homeRepositoryProvider);
  ...
});
```

**Impact:** Each time the user navigates away from home and back, the entire home data set is re-fetched from API. Poor UX and unnecessary network usage.

**Fix Required:** Add `keepAlive: true` to prevent disposal while the app is running. Alternatively, use `@Riverpod(keepAlive: true)` with codegen.

---

### H3 — `ref.watch()` called conditionally inside `_buildSearchResults` in `build()`

**File:** `lib/features/home/presentation/screen/search_screen.dart:229–236`

**Severity:** HIGH

**Issue:** Inside `_buildSearchResults()` (called from `build()`), the `initial:` branch of `searchState.when()` calls `ref.watch(simpleSearchHistoryProvider)` and `ref.watch(homeProvider)`. These watches only happen in the `initial` branch, making them conditional. Riverpod requires watches to be unconditional and consistent across builds.

**Code:**
```dart
Widget _buildSearchResults(SearchState searchState) {
  return searchState.when(
    initial: () => _buildHistoryAndTrending(
      ref.watch(simpleSearchHistoryProvider), // conditional watch
      ref.watch(homeProvider).maybeMap(...),  // conditional watch
    ),
    ...
  );
}
```

**Impact:** When the state transitions from `initial` to `loaded`, the watches on `simpleSearchHistoryProvider` and `homeProvider` are dropped. If these providers update while the user is viewing results, the widget will not rebuild — stale trending data and recent searches.

**Fix Required:** Move both `ref.watch` calls to the top of `build()` unconditionally. Pass the already-watched values down to `_buildHistoryAndTrending` as parameters rather than re-watching inside the method.

---

## Medium Priority Issues

---

### M1 — `categoriesProvider` and `activeAdProvider` are `autoDispose` but derive from a `keepAlive`-equivalent parent

**File:** `lib/features/home/application/providers/home_provider.dart:278–294`

**Severity:** MEDIUM

**Issue:** `categoriesProvider` and `activeAdProvider` are marked `Provider.autoDispose`, meaning they dispose when their listeners are gone. They derive their data from `homeProvider` which does NOT auto-dispose. This creates an asymmetry — the derived selectors are ephemeral but the source is persistent.

**Code:**
```dart
final categoriesProvider = Provider.autoDispose<List<Category>>((ref) {
  final homeState = ref.watch(homeProvider);
  return homeState.maybeMap(loaded: (s) => s.categories, orElse: () => []);
});
```

**Impact:** `categoriesProvider` disposing and re-creating unnecessarily on navigation causes dependent widgets to rebuild even though the underlying `homeProvider` data has not changed. Minor performance overhead.

**Fix Required:** Remove `autoDispose` from these selector providers since the parent `homeProvider` data persists. Or convert to computed providers with keepAlive.

---

### M2 — `CategoriesWithSidebarScreen` reads `categoriesProvider` in `initState` via `addPostFrameCallback`

**File:** `lib/features/home/presentation/screen/categories_with_sidebar_screen.dart:34–49`

**Severity:** MEDIUM

**Issue:** `ref.read(categoriesProvider)` is called inside `initState` via `addPostFrameCallback`. This is a one-shot read of a value that loads asynchronously. If categories have not loaded when this fires, an empty list is returned and no category is selected.

**Code:**
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final categories = ref.read(categoriesProvider); // snapshot — may be empty
  if (categories.isNotEmpty && selectedCategory == null) {
    setState(() => selectedCategory = categories.first);
  }
});
```

**Impact:** On first load, categories are likely still loading when the callback fires. `selectedCategory` remains null and no default selection is applied. The screen shows nothing selected until the user manually taps.

**Fix Required:** React to the categories state in `build()` — use `ref.watch(categoriesProvider)` and set the default selection when categories become non-empty for the first time, using a one-time flag.

---

---

# QA Prompt 2 — Security & Data Persistence Violations

---

## Critical Issues

---

### C1 — `Hive.openBox()` called inside a data source method — violates Hive lifecycle rules

**File:** `lib/features/home/infrastructure/data_sources/local/home_local_ds.dart:65–88`

**Severity:** CRITICAL

**Issue:** The `box` getter in `HomeLocalDataSourceImpl` calls `Hive.openBox()` lazily on first access. This violates the QA rule that `Hive.openBox()` must never be called inside repository/data source methods — it must be opened once at app startup and injected.

**Code:**
```dart
Future<Box> get box async {
  if (_box != null && _box!.isOpen) return _box!;
  if (Hive.isBoxOpen(HiveBoxes.homeBox)) {
    _box = Hive.box(HiveBoxes.homeBox);
    return _box!;
  }
  try {
    _box = await Hive.openBox(HiveBoxes.homeBox); // ← violation
    return _box!;
  } catch (e) { ... }
}
```

**Impact:** Multiple concurrent calls to `box` before the first `await` completes can attempt to open the same box simultaneously — a race condition. There is no lock or deduplication. `Hive.openBox()` called multiple times on the same box name throws a HiveError on some platforms.

**Fix Required:** Open all Hive boxes in `main.dart` before `runApp()`. Inject the already-opened `Box` into `HomeLocalDataSourceImpl` via its constructor. The constructor signature becomes `HomeLocalDataSourceImpl(this._box)` with a non-nullable `Box` instead of `Box?`.

---

### C2 — Entire `_handleException` method is commented out — no shared error-handling contract

**File:** `lib/features/home/infrastructure/repositories/home_repostory_impl.dart:28–47`

**Severity:** CRITICAL

**Issue:** The repository was written with a shared `_handleException(Object)` method that maps exceptions to typed failures. This method is entirely commented out. Every repository method now has its own independent `catch` branches in a copy-paste pattern.

**Code:**
```dart
// Converts exceptions to appropriate failures
// Failure _handleException(Object exception) {
//   if (exception is NetworkException || ...) { return NetworkFailure(...); }
//   ...
// }
```

**Impact:** Exception mapping is duplicated across 6+ repository methods. Any change to error handling (e.g. adding a new exception type) must be applied in 6 places. Copy-paste drift has already occurred — `getSelectedAddress` handles exceptions differently from `getCategories`. Dead commented code in production signals unfinished refactoring.

**Fix Required:** Uncomment and restore `_handleException`. Replace all per-method catch blocks with calls to this shared mapper, or extract it into a `NetworkExceptionMapper` utility class.

---

## High Priority Issues

---

### H1 — No concurrency lock on the Hive box getter — race condition on simultaneous cache reads

**File:** `lib/features/home/infrastructure/data_sources/local/home_local_ds.dart:65–88`

**Severity:** HIGH

**Issue:** `HomeLocalDataSourceImpl.box` is an async getter. `HomeNotifier._loadHomeData()` calls `Future.wait([...])` with 5 concurrent calls, all of which may simultaneously invoke the `box` getter before `_box` is assigned. There is no `Mutex` or `Lock` to serialize access.

**Code:**
```dart
// In _loadHomeData():
final results = await Future.wait([
  _repository.getCategories(page: 1),    // → box getter
  _repository.getSelectedAddress(),       // → box getter
  _repository.getBestDeals(limit: 10),   // → box getter
  _repository.getDiscountedProducts(...),// → box getter
  _repository.getBanners(page: 1),       // → box getter
]);
```

**Impact:** All five concurrent reads arrive at `box` simultaneously. All find `_box == null`, all attempt `Hive.openBox()` concurrently. On some Hive versions this throws `HiveError: Box already open` or silently corrupts the `_box` reference.

**Fix Required:** Open the box once at startup and inject it (see C1). If lazy opening must be kept, use the `synchronized` package: wrap the `_box = await Hive.openBox(...)` assignment in a `Lock` to serialise it.

---

### H2 — Cache parse failures silently swallowed with no logging

**File:** `lib/features/home/infrastructure/data_sources/local/home_local_ds.dart:116, 189, 261, 299`

**Severity:** HIGH

**Issue:** Every cache deserialization method has a bare `catch (e) { return null; }` block that discards errors silently.

**Code:**
```dart
// getCategories()
} catch (e) {
  // If parsing fails, return null to force fresh fetch
  return null;
}

// getDiscountedProducts()
} catch (e) {
  return null; // no log
}
```

**Impact:** Cache corruption, schema mismatches after app updates, or Hive read errors are completely invisible. There is no way to detect cache health degradation in production. The fallback to API is correct, but the root cause is undetectable.

**Fix Required:** Add logging in each catch block:
```dart
} catch (e) {
  Logger.error('Cache parse failure for ${HiveKeys.homeCategories}', error: e);
  return null;
}
```

---

## Medium Priority Issues

---

### M1 — `getSelectedAddress` in local DS casts raw Hive data unsafely

**File:** `lib/features/home/infrastructure/data_sources/local/home_local_ds.dart:361–362`

**Severity:** MEDIUM

**Issue:** Raw Hive data is cast directly to `Map<String, dynamic>` but Hive stores keys as `dynamic`, returning `Map<dynamic, dynamic>`. The hard cast will throw a `TypeError` at runtime on first read.

**Code:**
```dart
Future<UserAddress?> getSelectedAddress() async {
  final b = await box;
  final raw = b.get(HiveKeys.userSelectedAddress);
  if (raw == null) return null;
  try {
    final json = raw as Map<String, dynamic>; // ← unsafe cast
    return UserAddress.fromJson(json);
  } catch (e) {
    return null;
  }
}
```

**Impact:** `UserAddress` will never be read from local cache correctly — the cast fails silently, returns `null`, and the address is always fetched from the API. The local cache for address is functionally broken.

**Fix Required:**
```dart
final json = Map<String, dynamic>.from(raw as Map);
return UserAddress.fromJson(json);
```

---

### M2 — `saveSelectedAddress` in local DS stores address but `getSelectedAddress` in repository always fetches from API

**File:** `lib/features/home/infrastructure/repositories/home_repostory_impl.dart:342–360`
**File:** `lib/features/home/infrastructure/data_sources/local/home_local_ds.dart:369–389`

**Severity:** MEDIUM

**Issue:** `HomeLocalDataSourceImpl.saveSelectedAddress()` and `clearSelectedAddress()` are fully implemented, but `HomeRepositoryImpl.getSelectedAddress()` always calls the remote API with `// Always fetch from API - no caching for address`. The local save/clear methods exist but are never called from the repository — dead code.

**Code:**
```dart
// Repository always goes to network:
@override
Future<Either<Failure, UserAddress?>> getSelectedAddress() async {
  // Always fetch from API - no caching for address
  final address = await _remoteDataSource.getSelectedAddress();
  ...
}

// Local DS has address save/clear that are never called:
@override
Future<void> saveSelectedAddress(UserAddress address) async { ... }
@override
Future<void> clearSelectedAddress() async { ... }
```

**Impact:** Address is always fetched fresh from the API on every home screen load, adding latency and wasting bandwidth. The local data source has dead methods that add confusion.

**Fix Required:** Either implement address caching end-to-end (call `saveSelectedAddress` after API fetch, read from cache first), or remove `saveSelectedAddress`/`clearSelectedAddress` from the local DS to reduce dead code.

---

---

# QA Prompt 3 — Error Handling & Performance

---

## Critical Issues

---

### C1 — `GridView.builder` with `shrinkWrap: true` inside a sliver — defeats lazy loading

**File:** `lib/features/home/presentation/screen/home_screen.dart:700–721`

**Severity:** CRITICAL

**Issue:** `_buildBestDealsGrid()` uses `GridView.builder` with `shrinkWrap: true` and `NeverScrollableScrollPhysics()` inside a `CustomScrollView` (sliver context). `shrinkWrap: true` forces Flutter to lay out ALL items eagerly upfront to measure the total height — the lazy `builder` pattern provides no benefit and all products are rendered immediately.

**Code:**
```dart
return GridView.builder(
  shrinkWrap: true,                          // forces full layout
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: productsPerRow,
    ...
  ),
  itemCount: displayProducts.length,
  itemBuilder: (context, index) {
    return ProductCard(product: displayProducts[index], ...);
  },
);
```

**Impact:** When "See All" is expanded to show all best deals, every product card is rendered at once regardless of viewport visibility. This can cause significant frame drops on large product lists and negates the performance benefit of using a builder.

**Fix Required:** Replace with `SliverGrid` inside the existing `CustomScrollView`, which integrates with the sliver protocol and provides true lazy rendering:
```dart
SliverGrid(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(...),
  delegate: SliverChildBuilderDelegate(
    (context, index) => ProductCard(product: displayProducts[index], ...),
    childCount: displayProducts.length,
  ),
),
```

---

### C2 — `Logger.info()` with data computation called on every `loaded` state build

**File:** `lib/features/home/presentation/screen/home_screen.dart:231–250`

**Severity:** CRITICAL

**Issue:** Inside the `loaded:` callback of `homeState.when()` in `build()`, a `Logger.info()` call executes with computed data (`.length` lookups) on every widget rebuild. `build()` is called many times — on scroll position changes, tab switches, state updates — causing repeated analytics logging.

**Code:**
```dart
loaded: (categories, address, deals, discounts, ad, catLoad, dealLoad, discLoad) {
  Logger.info(
    'Home screen loaded successfully',
    data: {
      'categories_count': categories.length,
      'deals_count': deals.length,
      'discount_groups_count': discounts.length,
      ...
    },
  );
  return _buildScrollContent(...);
},
```

**Impact:** This generates thousands of redundant log entries per session. If the Logger writes to disk or sends to a remote service, it is a performance and cost issue. Log noise makes debugging harder.

**Fix Required:** Move analytics tracking to a one-shot location — use `ref.listen` outside the `when()` block, or track it in `HomeNotifier` when the state transitions to `loaded` for the first time. Use a `_hasLoggedLoad` flag in state to ensure it fires once.

---

## High Priority Issues

---

### H1 — `Future.wait` on all 5 home data requests has no per-request timeout

**File:** `lib/features/home/application/providers/home_provider.dart:44–53`

**Severity:** HIGH

**Issue:** `_loadHomeData()` fires all 5 API calls concurrently with `Future.wait`. If any single request hangs (e.g. the address API is unresponsive), the entire `Future.wait` hangs until the Dio connection timeout fires — which may be 30+ seconds.

**Code:**
```dart
final results = await Future.wait([
  _repository.getCategories(page: 1),
  _repository.getSelectedAddress(),          // no individual timeout
  _repository.getBestDeals(limit: 10),
  _repository.getDiscountedProducts(...),
  _repository.getBanners(page: 1),
]);
```

**Impact:** A slow address API can hold the entire home screen in loading state for 30+ seconds. The user sees only a spinner with no feedback or partial content.

**Fix Required:** Wrap non-critical requests with a timeout:
```dart
_repository.getSelectedAddress().timeout(
  const Duration(seconds: 10),
  onTimeout: () => const Right(null),
),
```
Only categories are marked as critical — all others should degrade gracefully on timeout.

---

### H2 — Trending product taps in Search Screen are non-functional

**File:** `lib/features/home/presentation/screen/search_screen.dart:362–368`

**Severity:** HIGH

**Issue:** The `onProductClick` callback for trending products in the search screen is an empty comment. No navigation occurs when a trending product is tapped.

**Code:**
```dart
ProductHorizontalList(
  products: trendingProducts,
  onProductClick: (product) {
    // Navigate to product detail
  },
)
```

**Impact:** Tapping any trending product on the search screen does nothing. This is a broken user-facing feature — trending products are visible but entirely non-interactive.

**Fix Required:**
```dart
onProductClick: (product) {
  context.push('/product-details/${product.id}');
},
```

---

### H3 — `_onScroll` listener uses modulo arithmetic to throttle analytics — fragile pattern

**File:** `lib/features/home/presentation/screen/home_screen.dart:115–130`

**Severity:** HIGH

**Issue:** The scroll listener fires on every scroll event. Analytics are throttled by checking `scrollPosition.pixels % 1000 < 50`, which only fires if the pixel value is within the first 50px of every 1000px band. This is a brittle, undocumented pattern that will miss many scroll events or double-fire on fast flings.

**Code:**
```dart
void _onScroll() {
  final scrollPosition = _scrollController.position;
  if (scrollPosition.pixels > 0 && scrollPosition.pixels % 1000 < 50) {
    Logger.debug('User scrolled', data: { ... });
  }
}
```

**Impact:** On fast flings, the scroll position jumps from 950px to 1100px — the 1000px band is entirely skipped. On slow scrolling, the event fires 50 times per band. Analytics data is unreliable and misleading.

**Fix Required:** Use a proper throttle mechanism — track the last logged pixel value and only log when the difference exceeds 1000px:
```dart
double _lastLoggedScrollPixels = 0;
void _onScroll() {
  final px = _scrollController.position.pixels;
  if ((px - _lastLoggedScrollPixels).abs() >= 1000) {
    _lastLoggedScrollPixels = px;
    Logger.debug('User scrolled', data: { ... });
  }
}
```

---

## Medium Priority Issues

---

### M1 — `Future.delayed` magic number for scroll-to-category in CategoryScreen

**File:** `lib/features/category/presentation/screen/category_screen.dart:128`

**Severity:** MEDIUM

**Issue:** A 300ms hardcoded delay is used before scrolling to the initially selected category.

**Code:**
```dart
Future.delayed(const Duration(milliseconds: 300), () {
  if (!mounted) return;
  _bodyKey.currentState?.scrollToCategory(initialIndex);
});
```

**Impact:** On fast devices 300ms is unnecessary overhead; on slow devices 300ms may be insufficient. The same fragile pattern flagged in auth (`otp_screen.dart`) recurs here.

**Fix Required:** Use `WidgetsBinding.instance.addPostFrameCallback` chained to ensure the body widget is fully rendered before scrolling, rather than relying on an arbitrary delay.

---

### M2 — Commented-out navigation method left in production code

**File:** `lib/features/home/presentation/screen/home_screen.dart:650–655`

**Severity:** MEDIUM

**Issue:** An entire navigation method is commented out in a production file.

**Code:**
```dart
// void _navigateToSearchResults() {
//   Navigator.push(
//     context,
//     MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
//   );
// }
```

**Impact:** Dead commented code signals unfinished work. The `SearchResultsScreen` import is also absent, suggesting this feature was partially removed. Confuses future developers.

**Fix Required:** Remove the commented block entirely. If `SearchResultsScreen` is a planned feature, track it in the backlog — not in a comment in production code.

---

### M3 — Search hint text contains a hardcoded product-specific example

**File:** `lib/features/home/presentation/screen/search_screen.dart:178`

**Severity:** MEDIUM

**Issue:** The search field hint is hardcoded to a specific product name.

**Code:**
```dart
hintText: "Search For 'Cooker'",
```

**Impact:** A grocery delivery app hardcoding "Cooker" as the search example is limiting and potentially inaccurate. If the product catalogue doesn't include cookers, this misleads users about available products.

**Fix Required:** Use a generic hint text (`"Search products..."`) or pull from a rotating list of actual top-search terms fetched from the backend.

---

---

# QA Prompt 4 — Code Quality & Deployment Readiness

---

## Critical Issues

---

### C1 — CategoriesScreen is entirely unimplemented — deployment blocker

**File:** `lib/features/home/presentation/screen/categories_screen.dart`

**Severity:** CRITICAL

**Issue:** The Categories Screen body is a single `Text('category')` widget. All meaningful imports are commented out. This screen is registered in the bottom navigation bar and is reachable by users.

**Code:**
```dart
// ignore_for_file: prefer_const_constructors
// import 'package:grocery_app/features/home/application/providers/home_provider.dart';
// import 'package:grocery_app/features/home/domain/entities/category.dart';
// import 'package:grocery_app/features/home/presentation/screen/category_detail_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: const Center(child: Text('category'))); // placeholder
  }
}
```

**Impact:** Any user who navigates to the Categories tab sees a blank white screen with the word "category". This is a shipped, user-visible, broken feature.

**Fix Required:** Implement the screen or add an explicit "Coming soon" UI with a back button. Do not ship a placeholder `Text('category')` as a navigation destination.

---

### C2 — CategoriesWithSidebarScreen is entirely unimplemented — deployment blocker

**File:** `lib/features/home/presentation/screen/categories_with_sidebar_screen.dart`

**Severity:** CRITICAL

**Issue:** The Categories with Sidebar Screen body is `SafeArea(child: const Center(child: Text('category')))`. All sidebar, product grid, and wishlist imports are commented out. This is the route `/category-products` linked from the home screen's category grid.

**Code:**
```dart
// import '../../components/category_sidebar.dart';
// import '../../components/product_card.dart';
// import 'package:grocery_app/features/wishlist/application/providers/wishlist_provider.dart';

child: SafeArea(child: const Center(child: Text('category'))),
```

**Impact:** Tapping any category on the home screen navigates to this screen, which shows only the word "category". The core product browsing flow is broken.

**Fix Required:** Implement the sidebar + product grid layout. The `CategoryScreen` in `lib/features/category/presentation/screen/category_screen.dart` appears to have the full implementation — verify if this is the intended implementation and wire it to the route instead.

---

### C3 — CategoryDetailScreen is entirely unimplemented — deployment blocker

**File:** `lib/features/home/presentation/screen/category_detail_screen.dart`

**Severity:** CRITICAL

**Issue:** The Category Detail Screen has no implementation beyond a placeholder widget.

**Code:**
```dart
class CategoryDetailScreen extends StatelessWidget {
  final Category category;
  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(...),
      child: Scaffold(body: Center(child: Text('category'))),
    );
  }
}
```

**Impact:** Any deep link or navigation to a category detail shows only the word "category". This screen is part of the core product discovery flow.

**Fix Required:** Wire to `CategoryScreen` or implement category-specific product listing here using `categoryControllerProvider`.

---

## High Priority Issues

---

### H1 — `_navigateToAddressSelection` uses `Navigator.push` instead of GoRouter

**File:** `lib/features/home/presentation/screen/home_screen.dart:738–745`

**Severity:** HIGH

**Issue:** Address navigation uses the old `Navigator.push` / `MaterialPageRoute` pattern while the rest of the app uses GoRouter. Mixing navigation paradigms breaks GoRouter's state tracking and deep link handling.

**Code:**
```dart
void _navigateToAddressSelection() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddressListScreen()),
  );
}
```

**Impact:** GoRouter's `redirect` logic, route guards, and back-stack management are bypassed. Deep links and back navigation from the address screen will behave incorrectly.

**Fix Required:** `context.push('/address-list');` — use GoRouter consistently.

---

### H2 — `dart:developer` used for logging in CategoryScreen instead of the project's Logger utility

**File:** `lib/features/category/presentation/screen/category_screen.dart:2, 45–58`

**Severity:** HIGH

**Issue:** `CategoryScreen` uses `dart:developer`'s `log()` function extensively for debug output, while the rest of the codebase uses the project's own `Logger` utility from `core/utils/logger.dart`.

**Code:**
```dart
import 'dart:developer' as developer;
// ...
developer.log(
  'CategoryScreen initState: initialCategoryId = "${widget.initialCategoryId}"',
  name: 'CategoryScreen_Init',
);
```

**Impact:** Debug logs from `CategoryScreen` are invisible to the project's centralized log monitoring and cannot be filtered, levelled, or routed to crash reporting alongside other logs. In release builds, `dart:developer` logs may not be stripped if not configured correctly.

**Fix Required:** Replace all `developer.log(...)` calls with `Logger.debug(...)` / `Logger.info(...)` from the project's Logger utility. Remove the `dart:developer` import.

---

## Medium Priority Issues

---

### M1 — `HomeNotifier.reloadAddress()` failure silently discards errors with no feedback

**File:** `lib/features/home/application/providers/home_provider.dart:156–170`

**Severity:** MEDIUM

**Issue:** `reloadAddress()` folds on failure with an empty left branch and a comment suggesting a SnackBar — but no SnackBar or state update is emitted.

**Code:**
```dart
result.fold(
  (failure) {
    // Keep current address on error, maybe show a snackbar in UI
  },
  (address) {
    updateAddressInState(address);
  },
);
```

**Impact:** If address reload fails (e.g. after returning from address selection), the displayed address may be stale with no indication to the user. The comment signals this was known but left unimplemented.

**Fix Required:** Emit an `AddressReloadError` sub-state or emit the failure through a separate stream/event that the UI can listen to for showing a SnackBar.

---

### M2 — `_showAllCategories` and `_showAllBestDeals` toggling causes full page rebuild

**File:** `lib/features/home/presentation/screen/home_screen.dart:657–689`

**Severity:** MEDIUM

**Issue:** Toggling "See All" / "Show Less" calls `setState`, which rebuilds the entire `HomeScreen` widget tree — including re-evaluating `homeState.when(...)`, recomputing discount groups, and re-laying out every sliver.

**Code:**
```dart
void _toggleCategoryView() {
  setState(() {
    _showAllCategories = !_showAllCategories; // triggers full rebuild
  });
}
```

**Impact:** On a home screen with many discount groups and product cards, toggling category visibility causes a measurable UI stutter on mid-range devices.

**Fix Required:** Extract `CategoryGrid` and `BestDealsGrid` into separate `ConsumerWidget` or `StatefulWidget` components that manage their own expand/collapse state locally. The parent `HomeScreen` does not need to rebuild when a section is expanded.

---

### M3 — Search result load-more indicator renders a bare `CircularProgressIndicator` with hardcoded padding

**File:** `lib/features/home/presentation/screen/search_screen.dart:382–387`

**Severity:** MEDIUM

**Issue:** The "load more" indicator at the bottom of search results uses hardcoded `EdgeInsets.all(16.0)` instead of ScreenUtil responsive units.

**Code:**
```dart
return const Padding(
  padding: EdgeInsets.all(16.0), // hardcoded, not 16.r
  child: Center(child: CircularProgressIndicator()),
);
```

**Impact:** Minor inconsistency with the rest of the UI that uses ScreenUtil. On tablets, this padding will appear proportionally small.

**Fix Required:** `Padding(padding: EdgeInsets.all(16.r), ...)`. Remove `const`.

---

---

# QA Prompt 6 — Architecture Compliance (4-Layer Violations)

---

## Critical Issues

---

### C1 — Presentation imports infrastructure implementation directly

**File:** `lib/features/home/presentation/screen/home_screen.dart:64`

**Layer:** Presentation → Infrastructure (Rule 4 violation)

**Severity:** CRITICAL

**Issue:** `HomeScreen` imports `home_repostory_impl.dart` to access `homeRepositoryProvider`. Presentation must never import infrastructure implementation files.

**Code:**
```dart
import '../../infrastructure/repositories/home_repostory_impl.dart';
// Used as:
final result = await ref.read(homeRepositoryProvider).getProductById(targetId);
```

**Impact:** Breaks the 4-layer boundary. Presentation is coupled to a specific infrastructure implementation. Any refactoring of the repository requires changes in the UI.

**Fix Required:** Move `homeRepositoryProvider` to `application/providers/home_repository_provider.dart`. Screen imports only the application-layer provider file.

---

### C2 — Riverpod providers defined inside infrastructure layer files

**File:** `lib/features/home/infrastructure/repositories/home_repostory_impl.dart:430–437`
**File:** `lib/features/home/infrastructure/data_sources/remote/home_api.dart:386–391`
**File:** `lib/features/home/infrastructure/data_sources/local/home_local_ds.dart:405–408`

**Layer:** Infrastructure exports Application-layer constructs (Rule 5 violation)

**Severity:** CRITICAL

**Issue:** Riverpod provider objects — which belong to the application layer — are defined and exported from infrastructure files. Any file that needs these providers must import infrastructure implementation files.

**Code:**
```dart
// home_repostory_impl.dart
final homeRepositoryProvider = riverpod.Provider<HomeRepository>((ref) { ... });

// home_api.dart
final homeRemoteDataSourceProvider = riverpod.Provider<HomeRemoteDataSource>((ref) { ... });

// home_local_ds.dart
final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) { ... });
```

**Impact:** The application and presentation layers are forced to import infrastructure files, collapsing the 4-layer boundary everywhere providers are needed.

**Fix Required:** Create `lib/features/home/application/providers/home_repository_provider.dart` and `home_datasource_providers.dart`. Move all provider definitions there. Infrastructure files contain only class definitions.

---

### C3 — `PaginatedResult<T>` and `DiscountedProductsResult` defined in the domain repository file

**File:** `lib/features/home/domain/repositories/home_repository.dart:16–40`

**Layer:** Domain (data-shape concerns belong in infrastructure)

**Severity:** CRITICAL

**Issue:** `PaginatedResult<T>` is an API pagination wrapper — it represents the shape of a backend response. `DiscountedProductsResult` is a data-transport bundle derived from the API response structure. Both are defined in the domain repository file, which should contain only abstract contracts and domain entity references.

**Code:**
```dart
class PaginatedResult<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;
  ...
}

class DiscountedProductsResult {
  final List<ProductVariant> variants;
  final Map<int, int> productCategoryMap;
  ...
}
```

**Impact:** The domain layer gains knowledge of API pagination conventions (`count`, `next`, `previous`). A change to the API pagination format (e.g. moving from cursor-based to offset-based) requires a domain entity change — a violation of domain purity.

**Fix Required:** Move `PaginatedResult` and `DiscountedProductsResult` to the infrastructure layer (e.g. `infrastructure/models/paginated_result.dart`). The domain repository contract returns only domain entities: `Future<Either<Failure, List<Category>>>` instead of `Future<Either<Failure, PaginatedResult<Category>>>`.

---

## High Priority Issues

---

### H1 — `HomeNotifier` imports infrastructure repository implementation file

**File:** `lib/features/home/application/providers/home_provider.dart:12`

**Layer:** Application → Infrastructure (Rule 5 violation)

**Severity:** HIGH

**Issue:** The notifier's file imports `home_repostory_impl.dart` to access the provider. The application layer must depend on the domain abstract `HomeRepository`, resolved via a provider — not directly on the infrastructure file.

**Code:**
```dart
import '../../infrastructure/repositories/home_repostory_impl.dart';
// Accessed via:
final repository = ref.watch(homeRepositoryProvider);
```

**Impact:** Application layer is coupled to the infrastructure implementation. Swapping implementations (e.g. for testing) requires changing the notifier file.

**Fix Required:** Once `homeRepositoryProvider` is moved to the application layer (see C1), this import is replaced with `import '../providers/home_repository_provider.dart';`.

---

### H2 — `CategoriesWithSidebarScreen` uses `StatefulWidget` local state for domain-level selection

**File:** `lib/features/home/presentation/screen/categories_with_sidebar_screen.dart:27–29`

**Layer:** Presentation (Rule 15 violation — StatefulWidget for data state)

**Severity:** HIGH

**Issue:** `selectedCategory` (which category is currently selected) and `searchQuery` are managed as `StatefulWidget` local state. The selected category is a user-session-level concern that should be in Riverpod state so it can be shared with child widgets without prop drilling.

**Code:**
```dart
class _CategoriesWithSidebarScreenState extends ConsumerState<CategoriesWithSidebarScreen> {
  Category? selectedCategory; // domain state in widget
  String searchQuery = '';    // filter state in widget
```

**Impact:** Child components that need to know the selected category (sidebar, product grid) must receive it through constructor parameters. State cannot be shared reactively. If a child widget updates the selection, it must propagate back via callbacks.

**Fix Required:** Introduce a `selectedCategoryProvider` (StateProvider or NotifierProvider) in the application layer to hold the selection. Both the sidebar and product grid can watch it directly.

---

### H3 — `CategoryScreen` uses `PollingManager.instance` singleton directly — infrastructure concern in presentation

**File:** `lib/features/category/presentation/screen/category_screen.dart:73–76`

**Layer:** Presentation accessing Infrastructure singleton (Rule 4 violation)

**Severity:** HIGH

**Issue:** `CategoryScreen` directly accesses `PollingManager.instance` (a global singleton) to set the active polling feature. Polling lifecycle management is an infrastructure concern and should be controlled by the application layer (notifier), not the presentation layer (screen).

**Code:**
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final currentFeature = PollingManager.instance.activeFeature;
  if (currentFeature == null || currentFeature == 'category_products') {
    PollingManager.instance.setActiveFeature('category_products');
  }
});
```

**Impact:** Screens directly control infrastructure-level polling behaviour. If the polling strategy changes, every screen that calls `PollingManager.instance` must be updated. This is infrastructure logic that has leaked into presentation.

**Fix Required:** Add a `setActiveFeature(String)` method to `CategoryControllerNotifier`. The notifier calls `PollingManager` internally. The screen only calls `ref.read(categoryControllerProvider.notifier).activatePolling()`.

---

## Medium Priority Issues

---

### M1 — `CategoryScreen` state mutation inside `build()` without using Riverpod

**File:** `lib/features/category/presentation/screen/category_screen.dart:157–184`

**Layer:** Presentation (Rule 6 — business logic in build)

**Severity:** MEDIUM

**Issue:** Inside `build()`, a category index search and `_selectionManager.selectCategory()` call are made synchronously. Mutating selection manager state inside `build()` is incorrect — `build()` must be a pure function.

**Code:**
```dart
Widget build(BuildContext context) {
  ...
  if (widget.initialCategoryId != null && categories.isNotEmpty && ...) {
    final initialIndex = categories.indexWhere(...);
    if (initialIndex >= 0 && initialIndex != _selectionManager.selectedIndex) {
      _selectionManager.selectCategory(initialIndex, widget.initialCategoryId); // mutation in build
    }
  }
```

**Impact:** If `build()` is called multiple times (which Flutter guarantees), `selectCategory` is called multiple times unnecessarily. Side effects in `build()` cause unpredictable behaviour and can trigger additional rebuilds.

**Fix Required:** Move initial category selection logic to `initState` or a `didUpdateWidget` override. Use a one-time flag to ensure it runs only once.

---

### M2 — `HomeScreen.build()` watches both `homeProvider` and `authProvider` — any auth state change rebuilds the entire home screen

**File:** `lib/features/home/presentation/screen/home_screen.dart:157–161`

**Layer:** Presentation (excessive rebuild scope)

**Severity:** MEDIUM

**Issue:** `build()` watches the full `authProvider` state to derive `isGuest`. Any auth state change (OTP sending, session check, guest mode change) triggers a full rebuild of `HomeScreen` including all sliver sections.

**Code:**
```dart
final homeState = ref.watch(homeProvider);
final authState = ref.watch(authProvider);
final isGuest = authState is GuestMode;
```

**Impact:** Any auth state transition (even transient ones like `AuthLoading`) causes an unnecessary and expensive full rebuild of the home screen with all its sliver content.

**Fix Required:** Create a selector provider: `final isGuestProvider = Provider<bool>((ref) => ref.watch(authProvider) is GuestMode);`. Then use `ref.watch(isGuestProvider)` — only rebuilds when the boolean actually changes.

---
