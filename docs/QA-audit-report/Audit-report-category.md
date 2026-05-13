# Category Flow — QA Audit Report

**Feature Audited:** Category Screen (Full category browser with product grid)

**Files Reviewed:**
- `lib/features/category/presentation/screen/category_screen.dart`
- `lib/features/category/presentation/components/category_screenbody/category_screen_body.dart`
- `lib/features/category/presentation/components/product_grid/product_grid.dart`
- `lib/features/category/presentation/components/widgets/_product_card.dart`
- `lib/features/category/presentation/helpers/category_state_listener.dart`
- `lib/features/category/presentation/helpers/category_selection_manager.dart`
- `lib/features/category/presentation/helpers/socket_room_manager.dart`
- `lib/features/category/application/providers/category_providers.dart`
- `lib/features/category/application/providers/category_product_providers.dart`
- `lib/features/category/application/providers/inventory_update_notifier.dart`
- `lib/features/category/application/states/category_state.dart`
- `lib/features/category/application/states/category_product_state.dart`
- `lib/features/category/domain/entities/category.dart`
- `lib/features/category/domain/entities/category_product.dart`
- `lib/features/category/domain/repositories/category_repository.dart`
- `lib/features/category/infrastructure/repositories/category_repository_impl.dart`
- `lib/features/category/infrastructure/repositories/category_product_repository_impl.dart`
- `lib/features/category/infrastructure/data_sources/local/category_local_data_source.dart`
- `lib/features/category/infrastructure/data_sources/local/category_product_local_data_source.dart`
- `lib/features/category/infrastructure/data_sources/remote/category_remote_data_source.dart`

**Total Issues Found:** 37 (11 Critical · 13 High · 13 Medium)

---

## QA Prompt 1 — State Management

---

### Critical Issues

---

### C1 — State Mutation Inside `build()` Method

**File:** `lib/features/category/presentation/screen/category_screen.dart:157–184`

**Severity:** CRITICAL

**Issue:** `_selectionManager.selectCategory()` is called directly inside the `build()` method. This mutates the `selectedIndex` and `selectedCategoryId` fields on `_selectionManager` during the widget build phase, which is prohibited in Flutter. Mutating state during `build()` can trigger cascading rebuilds, undefined render order, and inconsistent UI frames.

**Code:**
```dart
if (widget.initialCategoryId != null &&
    categories.isNotEmpty &&
    _selectionManager.selectedCategoryId == widget.initialCategoryId &&
    _selectionManager.selectedIndex == 0) {
  final initialIndex = categories.indexWhere(
    (cat) => cat.id == widget.initialCategoryId,
  );
  if (initialIndex >= 0 &&
      initialIndex != _selectionManager.selectedIndex) {
    // Mutates mutable fields during build — CRITICAL
    _selectionManager.selectCategory(
      initialIndex,
      widget.initialCategoryId,
    );
  }
}
```

**Impact:** Unpredictable widget tree state during the build phase. Flutter's framework does not permit side-effects in `build()`. This can cause the framework to throw "setState() or markNeedsBuild() called during build" assertions in debug mode, and may cause visual inconsistencies in production.

**Fix Required:** Move this initialisation to `_scrollToInitialCategory()` which already runs via `addPostFrameCallback`. Remove the selection mutation block from `build()` entirely.

---

### C2 — Local Data Source Accessed Directly Inside Controller `build()`

**File:** `lib/features/category/application/providers/category_product_providers.dart:103–104`

**Severity:** CRITICAL

**Issue:** `CategoryProductController.build()` reads directly from `CategoryProductLocalDataSource` — bypassing the repository layer — and also runs multiple `developer.log` calls on every rebuild. Both are critical: the first violates the architectural contract (application must call domain repository, not infrastructure data source directly), and the second places heavy I/O-adjacent operations in the build method.

**Code:**
```dart
@override
CategoryProductState build(String categoryId) {
  _categoryId = categoryId;
  _disposed = false;
  ref.keepAlive();

  // ... setup ...

  // VIOLATION: Application layer reads from Infrastructure data source directly
  final localDataSource = ref.read(categoryProductLocalDataSourceProvider);
  final cached = localDataSource.read(categoryId); // bypasses repository

  // VIOLATION: developer.log inside build() runs on every rebuild
  developer.log(
    '🔧 BUILD called for category=$categoryId, ...',
    name: 'CategoryProductController',
    level: 800,
  );
  // ...
}
```

**Impact:** Tightly couples the application layer to the infrastructure implementation. If the local data source is refactored or replaced, the controller must also change. The business rule "check cache on init" is now split between repository and controller. Logging on every build adds performance overhead.

**Fix Required:** Remove the direct `localDataSource.read()` call from `build()`. The `_loadInitial()` method already calls `_repository.getCachedProducts()` — this is the correct path. Trust the repository to provide cached state asynchronously. Move all `developer.log` statements out of `build()`.

---

### High Priority Issues

---

### H1 — `AutoDisposeNotifierProviderFamily` Combined With `ref.keepAlive()` — Contradictory Lifecycle

**File:** `lib/features/category/application/providers/category_product_providers.dart:64–92`

**Severity:** HIGH

**Issue:** The provider is declared as `AutoDisposeNotifierProviderFamily` (meaning it should auto-dispose when no longer listened to), but then inside `build()` it unconditionally calls `ref.keepAlive()`. This defeats the purpose of autoDispose and permanently prevents disposal regardless of screen visibility.

**Code:**
```dart
final categoryProductControllerProvider =
    AutoDisposeNotifierProviderFamily<
      CategoryProductController,
      CategoryProductState,
      String
    >(CategoryProductController.new);

class CategoryProductController
    extends AutoDisposeFamilyNotifier<CategoryProductState, String> {
  @override
  CategoryProductState build(String categoryId) {
    // ...
    ref.keepAlive(); // Always called — never actually auto-disposes
    // ...
  }
}
```

**Impact:** Every category that the user browses creates a controller instance that is permanently kept in memory. With many categories this creates unbounded memory growth. The `PollingManager` registers timers per category; those timers are also never freed. The declaration of `AutoDispose` misleads readers into thinking disposal is managed.

**Fix Required:** Either (a) change to `NotifierProviderFamily` (not autoDispose) and manage lifecycle explicitly, or (b) keep `AutoDisposeNotifierProviderFamily` and remove `ref.keepAlive()`, letting the `PollingManager` handle timer pause/resume without needing the provider alive forever.

---

### H2 — `CategoryRemoteDataSource` Instantiated Directly Without Its Own Provider

**File:** `lib/features/category/application/providers/category_providers.dart:48`

**Severity:** HIGH

**Issue:** `CategoryRemoteDataSource` is constructed inline inside `categoryRepositoryProvider` instead of having its own provider. This bypasses Riverpod's dependency injection system, making the remote data source untestable (cannot be overridden in tests) and preventing lifecycle management.

**Code:**
```dart
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  // Direct instantiation — not injectable
  final remoteDataSource = CategoryRemoteDataSource(apiClient);

  return CategoryRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});
```

**Impact:** The remote data source cannot be mocked or overridden for tests. Any future Riverpod overrides for testing the repository will still use the real network implementation.

**Fix Required:** Declare a separate `categoryRemoteDataSourceProvider` and watch it:
```dart
final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  return CategoryRemoteDataSource(ref.watch(apiClientProvider));
});
```

---

### H3 — `InventoryUpdateNotifier` Uses Legacy `StateNotifier` Pattern

**File:** `lib/features/category/application/providers/inventory_update_notifier.dart:24`

**Severity:** HIGH

**Issue:** `InventoryUpdateNotifier` extends `StateNotifier`, which is the Riverpod 1.x legacy API. The rest of the category feature uses `Notifier` and `NotifierProvider` (Riverpod 2.x). This inconsistency increases maintenance surface, and `StateNotifier` is scheduled for deprecation.

**Code:**
```dart
class InventoryUpdateNotifier extends StateNotifier<InventoryUpdateState> {
  InventoryUpdateNotifier() : super(const InventoryUpdateState());
  // ...
}

final inventoryUpdateNotifierProvider =
    StateNotifierProvider<InventoryUpdateNotifier, InventoryUpdateState>((ref) {
      return InventoryUpdateNotifier();
    });
```

**Impact:** Two different state management patterns in the same feature create inconsistency. When Riverpod formally deprecates `StateNotifier`, this will need migration under time pressure.

**Fix Required:** Migrate to `Notifier`:
```dart
class InventoryUpdateNotifier extends Notifier<InventoryUpdateState> {
  @override
  InventoryUpdateState build() => const InventoryUpdateState();
  // ...
}

final inventoryUpdateNotifierProvider =
    NotifierProvider<InventoryUpdateNotifier, InventoryUpdateState>(
      InventoryUpdateNotifier.new,
    );
```

---

### Medium Priority Issues

---

### M1 — `CategoryStateListener` Stores `BuildContext` as a Field

**File:** `lib/features/category/presentation/helpers/category_state_listener.dart:13–14`

**Severity:** MEDIUM

**Issue:** `CategoryStateListener` is created in `initState()` and stores `BuildContext context` as an immutable final field. While the class checks `context.mounted`, storing a `BuildContext` outside the widget lifecycle in a helper class is a code smell — it can lead to accessing a stale or deactivated context if the helper is reused after the widget rebuilds.

**Code:**
```dart
class CategoryStateListener {
  final WidgetRef ref;
  final BuildContext context; // Stored in initState, can become stale

  CategoryStateListener({required this.ref, required this.context});
}
```

**Impact:** If `CategoryScreen` is ever refactored to recreate `_stateListener` across rebuilds, the stored context will be stale. Subtle lifecycle bugs in complex navigation scenarios.

**Fix Required:** Pass `context` as a parameter to `listen()` rather than storing it in the constructor:
```dart
void listen({
  required BuildContext context,
  required CategorySelectionManager selectionManager,
  required void Function(void Function()) setState,
}) { ... }
```

---

## QA Prompt 2 — Security & Data Persistence

---

### Critical Issues

---

### C3 — Cache Parse Failures Swallowed Silently Without Logging

**File:** `lib/features/category/infrastructure/data_sources/local/category_local_data_source.dart:28–30`
`lib/features/category/infrastructure/data_sources/local/category_product_local_data_source.dart:27–29`

**Severity:** CRITICAL

**Issue:** Both local data sources catch ALL exceptions in `read()` and return `null` with no log entry. A `HiveError`, `FormatException`, or unexpected type cast failure is indistinguishable from a cache miss. Corrupted cache entries are never removed and will be re-read on every app start.

**Code:**
```dart
// category_local_data_source.dart
CategoryCacheDto? read() {
  try {
    final cached = _box.get(_cacheKey);
    if (cached == null) return null;
    if (cached is Map) {
      final jsonMap = Map<String, dynamic>.from(cached);
      return CategoryCacheDto.fromJson(jsonMap);
    }
    return null;
  } catch (e) {
    return null; // Swallows ALL exceptions — no log, no recovery
  }
}
```

**Impact:** Cache corruption goes completely undetected. A device with a corrupted cache will silently fall through to the API on every cold start but will never self-heal (the corrupted entry is never deleted). Debugging cache issues in production is impossible.

**Fix Required:**
```dart
CategoryCacheDto? read() {
  try {
    final cached = _box.get(_cacheKey);
    if (cached == null) return null;
    if (cached is Map) {
      final jsonMap = Map<String, dynamic>.from(cached);
      return CategoryCacheDto.fromJson(jsonMap);
    }
    return null;
  } on HiveError catch (e) {
    Logger.error('Hive error reading category cache', error: e);
    _box.delete(_cacheKey); // Remove corrupted entry
    return null;
  } catch (e) {
    Logger.error('Unexpected error reading category cache', error: e);
    return null;
  }
}
```

---

### High Priority Issues

---

### H4 — Cache Save Methods Use `rethrow` but Callers Lack Error Handling

**File:** `lib/features/category/infrastructure/data_sources/local/category_local_data_source.dart:37–40`

**Severity:** HIGH

**Issue:** `CategoryLocalDataSource.save()` and `updateLastSyncedAt()` both `rethrow` on error. The repository methods that call these (`syncCategories`) do not wrap these calls in try-catch, meaning a Hive write failure during a successful API response will propagate as an unhandled exception and show an error screen — even though the API data was valid.

**Code:**
```dart
Future<void> save(CategoryCacheDto dto) async {
  try {
    await _box.put(_cacheKey, dto.toJson());
  } catch (e) {
    rethrow; // Propagates Hive write error to repository and then to controller
  }
}
```

**Impact:** A transient Hive write failure (e.g., disk full, box corruption) causes the entire data-load flow to fail with an error state, even though the API returned valid data. Users see an error screen when the data was successfully fetched.

**Fix Required:** Cache write failures should be logged silently and not rethrown:
```dart
Future<void> save(CategoryCacheDto dto) async {
  try {
    await _box.put(_cacheKey, dto.toJson());
  } on HiveError catch (e) {
    Logger.error('Failed to save category cache', error: e);
    // Do not rethrow — cache write failure should not block UI
  } catch (e) {
    Logger.error('Unexpected error saving category cache', error: e);
  }
}
```

---

### Medium Priority Issues

---

### M2 — No Cache Corruption Recovery — Corrupted Entries Persist Indefinitely

**File:** `lib/features/category/infrastructure/data_sources/local/category_local_data_source.dart`
`lib/features/category/infrastructure/data_sources/local/category_product_local_data_source.dart`

**Severity:** MEDIUM

**Issue:** When `read()` encounters a parse error it returns `null` but leaves the corrupted Hive entry in place. On the next app start the corrupted entry is re-read and fails again. Per QA Prompt 5, the same cache key corrupted 3+ times within 1 hour should be blacklisted from caching for 5 minutes.

**Impact:** Devices with corrupted cache entries will always make network calls on startup (cache is effectively broken) but will never self-heal.

**Fix Required:** Delete the corrupted key when a parse fails, and add a corruption counter to temporarily suppress caching for repeat offenders.

---

## QA Prompt 3 — Performance & Error Handling

---

### Critical Issues

---

### C4 — `developer.log` Calls Inside `build()` Methods

**File:** `lib/features/category/application/providers/category_product_providers.dart:106–113`
`lib/features/category/presentation/components/product_grid/product_grid.dart:299–307`

**Severity:** CRITICAL

**Issue:** Multiple `developer.log` statements execute inside `build()` methods that run on every widget rebuild. In `CategoryProductController.build()` log calls execute on every provider rebuild. In `_CategoryProductsSliver.build()` a log fires on every state change when products are present. With 30-second polling across multiple categories, these logs execute at high frequency.

**Code:**
```dart
// category_product_providers.dart — runs on every provider rebuild
developer.log(
  '🔧 BUILD called for category=$categoryId, '
  'initialized=$_initialized, ...',
  name: 'CategoryProductController',
  level: 800,
);

// product_grid.dart — runs on every widget rebuild when products exist
if (productState.hasData && productState.products.isNotEmpty) {
  final firstProduct = productState.products.first;
  developer.log(
    'ProductGrid REBUILD: category=$categoryId, ...',
    name: 'ProductGrid',
  );
}
```

**Impact:** Significant performance overhead in production builds. `developer.log` has a non-trivial cost. With polling every 30 seconds across N categories, this produces constant I/O noise and may contribute to janky scrolling on lower-end devices.

**Fix Required:** Remove all `developer.log` calls from `build()` methods entirely. Use conditional logging only in event handlers and lifecycle methods, gated by a debug flag:
```dart
// In build() — remove logs
// In event handlers — use Logger if needed:
if (kDebugMode) Logger.debug('...');
```

---

### High Priority Issues

---

### H5 — No Retry Logic After Network Failure in `CategoryController`

**File:** `lib/features/category/application/providers/category_providers.dart:152–164`

**Severity:** HIGH

**Issue:** When `syncCategories()` throws a `NetworkException`, the controller sets error state and stops. There is no exponential backoff, no retry counter, and no automatic recovery when connectivity is restored. Per QA Prompt 5, critical operations must retry up to 4 times with delays of +2s/+4s/+8s.

**Code:**
```dart
} catch (error) {
  final message = _mapError(error);
  if (!hasData) {
    state = state.copyWith(
      status: CategoryStatus.error,
      isRefreshing: false,
      errorMessage: message, // Sets error state, no retry
    );
  } else {
    state = state.copyWith(isRefreshing: false, errorMessage: message);
  }
}
```

**Impact:** A single transient network failure permanently puts the screen into error state until the user manually retries. On spotty connections this creates a poor experience.

**Fix Required:** Implement a retry policy with exponential backoff (4 attempts, 2s/4s/8s delays, skip retry on 4xx errors).

---

### H6 — No Retry Logic in `CategoryProductController._refreshInternal`

**File:** `lib/features/category/application/providers/category_product_providers.dart:251–273`

**Severity:** HIGH

**Issue:** Same issue as H5 — `_refreshInternal` catches errors and sets error state without any retry. For a screen that is a core navigation destination and has 30-second polling already wired, the lack of retry makes brief outages cause permanent error states until the next polling cycle.

**Code:**
```dart
} catch (error) {
  developer.log(
    'Category $_categoryId: HTTP Error - $error',
    name: 'CategoryProductController',
    level: 1000,
  );
  final message = _mapError(error);
  if (!hasData) {
    _safeSetState(state.copyWith(
      status: CategoryProductStatus.error,
      isRefreshing: false,
      errorMessage: message, // No retry
    ));
  }
}
```

**Impact:** First-load network failure on any category tab shows a permanent error until the 30-second polling interval fires again. On a slow connection this feels broken.

**Fix Required:** Add a retry policy (same as H5 recommendation). 4xx errors should not be retried; 5xx and network errors should retry with exponential backoff.

---

### Medium Priority Issues

---

### M3 — Generic `catch` Blocks Without Logging in Local Data Sources

**File:** `lib/features/category/infrastructure/data_sources/local/category_product_local_data_source.dart:27–29`

**Severity:** MEDIUM

**Issue:** The `read()` method catches all exceptions and returns `null` with no log entry. This is the only place where Hive read failures can be diagnosed, and silencing them makes production debugging impossible.

**Code:**
```dart
} catch (e) {
  return null; // Generic silent catch
}
```

**Impact:** Cache corruption, type mismatches, or Hive box access errors are indistinguishable from cache misses. No visibility into why devices fall back to the network.

**Fix Required:** Use typed catches with logging as shown in the fix for C3.

---

## QA Prompt 4 — Code Quality & Deployment

---

### High Priority Issues

---

### H7 — `dart:developer` Used Instead of Project Logger Throughout Category Feature

**File:** `lib/features/category/presentation/screen/category_screen.dart:2`
`lib/features/category/application/providers/category_product_providers.dart:2`
`lib/features/category/presentation/components/product_grid/product_grid.dart:1`

**Severity:** HIGH

**Issue:** The entire category feature uses `dart:developer` (`developer.log`) instead of the project's shared `Logger` utility. The auth and home features use `Logger`. This inconsistency means category logs cannot be centrally controlled, filtered, or disabled in production via the Logger configuration.

**Code:**
```dart
import 'dart:developer' as developer;
// ...
developer.log(
  'CategoryScreen mounted — ensuring category_products polling is active',
  name: 'CategoryScreen',
  level: 700,
);
```

**Impact:** Category feature logs cannot be silenced in production builds via the Logger's level controls. Maintaining two logging systems across the codebase increases developer confusion and makes log filtering unreliable.

**Fix Required:** Replace all `dart:developer` imports and `developer.log()` calls with the project's `Logger` utility (`Logger.debug()`, `Logger.info()`, `Logger.error()`). The `socket_room_manager.dart` already demonstrates correct usage of `logger.i()`.

---

### H8 — `PollingManager.instance.setActiveFeature()` Called Without Corresponding Cleanup in `dispose()`

**File:** `lib/features/category/presentation/screen/category_screen.dart:73–76`

**Severity:** HIGH

**Issue:** `CategoryScreen.initState()` calls `PollingManager.instance.setActiveFeature('category_products')` via a `postFrameCallback`, but `CategoryScreen.dispose()` does not call any corresponding cleanup on `PollingManager`. If the user navigates away before the callback fires, or if the screen is disposed while the feature is marked active, the polling manager retains stale state.

**Code:**
```dart
// initState
WidgetsBinding.instance.addPostFrameCallback((_) {
  final currentFeature = PollingManager.instance.activeFeature;
  if (currentFeature == null || currentFeature == 'category_products') {
    PollingManager.instance.setActiveFeature('category_products');
  }
});

// dispose — no PollingManager cleanup
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
```

**Impact:** If the user navigates away before `postFrameCallback` fires, the `setActiveFeature` call may execute on a disposed widget. On low-end devices with slow frames, this timing issue can cause memory leaks through the polling system.

**Fix Required:** Add cleanup in `dispose()`:
```dart
@override
void dispose() {
  PollingManager.instance.clearActiveFeature(); // or equivalent
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
```

---

### Medium Priority Issues

---

### M4 — Magic Number `300ms` Hardcoded Delay

**File:** `lib/features/category/presentation/screen/category_screen.dart:128`

**Severity:** MEDIUM

**Issue:** `_scrollToInitialCategory()` uses `Future.delayed(const Duration(milliseconds: 300), ...)` with no documented justification. This is a timing hack that can break on slower devices where 300ms is insufficient for the widget tree to be fully built.

**Code:**
```dart
Future.delayed(const Duration(milliseconds: 300), () {
  if (!mounted) return;
  _bodyKey.currentState?.scrollToCategory(initialIndex);
});
```

**Impact:** On slow devices the scroll fires before the target widget is rendered. On fast devices 300ms is unnecessarily long. Magic delays are fragile and tend to create race conditions.

**Fix Required:** Use `WidgetsBinding.instance.addPostFrameCallback` chained with the scroll call instead of a time-based delay. If timing is truly needed, extract the constant to `CacheConfig` or a dedicated UI constants file.

---

### M5 — Debug Logging Left in Production Code Inside `build()`

**File:** `lib/features/category/application/providers/category_product_providers.dart:106–113`
`lib/features/category/presentation/components/product_grid/product_grid.dart:298–307`

**Severity:** MEDIUM

**Issue:** Commented labels like `// Debug: Log when products are rebuilt` and emoji-prefixed logs (`'🔧 BUILD called'`, `'✅ Returning CACHED state'`) indicate these are development-only debugging statements that were not removed before the code was committed to the feature branch.

**Code:**
```dart
// Debug: Log when products are rebuilt
if (productState.hasData && productState.products.isNotEmpty) {
  final firstProduct = productState.products.first;
  developer.log(
    'ProductGrid REBUILD: ...',
    name: 'ProductGrid',
  );
}
```

**Impact:** Increases log noise in production, adds minor performance overhead on every rebuild, and indicates missing code-review hygiene before deployment.

**Fix Required:** Remove all debug logs from `build()` methods. Use `kDebugMode` guards for any logs that must remain during development.

---

### M6 — Dead `onAddToCart` Callback Always Passed as Empty Lambda

**File:** `lib/features/category/presentation/components/category_screenbody/category_screen_body.dart:143`

**Severity:** MEDIUM

**Issue:** `ProductGrid` receives `onAddToCart: (product) {}` — an empty lambda that silently discards the callback. The actual cart addition is handled inside `ProductCard._handleAddToCart()` directly via `checkoutLineControllerProvider`. The `onAddToCart` parameter on `ProductGrid` and `CategoryScreenBody` is dead code.

**Code:**
```dart
ProductGrid(
  key: _productGridKey,
  categories: categories,
  selectedCategoryIndex: widget.selectedCategoryIndex,
  onCategoryInViewChanged: widget.onCategorySelected,
  onAddToCart: (product) {}, // Dead — actual cart logic is inside ProductCard
),
```

**Impact:** Dead callback creates confusion — developers reading the code assume `onAddToCart` does something meaningful at the `CategoryScreenBody` level. This misleads future contributors.

**Fix Required:** Remove the `onAddToCart` parameter from `ProductGrid` and `CategoryScreenBody` entirely, since the cart behaviour is fully self-contained in `ProductCard`.

---

## QA Prompt 5 — Caching

---

### Critical Issues

---

### C5 — No L1 In-Memory Cache — Only Hive (L2) + Network (L3)

**File:** `lib/features/category/infrastructure/data_sources/local/category_local_data_source.dart`
`lib/features/category/infrastructure/data_sources/local/category_product_local_data_source.dart`

**Severity:** CRITICAL

**Issue:** The category feature implements only 2 layers: Hive disk cache and Network. There is no L1 in-memory cache. Navigating between categories triggers a Hive read on every visit. Per QA Prompt 5 Scenario 4, navigation between screens should hit memory in 1–5ms with no API call. Current implementation reads from disk on every navigation return.

**Code:**
```dart
// Every category tab switch reads from Hive disk cache
Box<dynamic> get _box => Hive.box<dynamic>(Boxes.cache);

CategoryProductCacheDto? read(String categoryId) {
  try {
    final key = '$_cacheKeyPrefix$categoryId';
    final cached = _box.get(key); // Disk I/O on every call
    // ...
  }
}
```

**Impact:** Navigating between category tabs causes disk reads on every switch. On devices with slow storage this can cause visible lag (50–200ms). The polling system refreshes every 30 seconds — without an L1 cache, every poll result causes a Hive read cycle.

**Fix Required:** Add an in-memory `Map<String, CategoryProductCacheDto>` layer in `CategoryProductLocalDataSource` that is populated on the first Hive read and invalidated on write. Reads check memory first, fall through to Hive on miss.

---

### C6 — No Request Deduplication Pool

**File:** `lib/features/category/infrastructure/data_sources/remote/category_remote_data_source.dart`
`lib/features/category/application/providers/category_product_providers.dart`

**Severity:** CRITICAL

**Issue:** There is no request deduplication pool. If two `CategoryProductController` instances for the same `categoryId` are created simultaneously (e.g., during rapid tab switching), two independent API requests are made to the same endpoint. Per QA Prompt 5 Scenario 7, concurrent requests to the same endpoint must share a single in-flight `Future`.

**Code:**
```dart
// No deduplication — each controller instance makes its own request
Future<CategoryRemoteResponse?> fetchCategories({...}) async {
  final response = await _apiClient.get<dynamic>(
    ApiEndpoints.categories,
    headers: <String, String>{...},
  );
  // ...
}
```

**Impact:** On rapid navigation between categories, the same category endpoint can be called multiple times. Each duplicate request wastes bandwidth and increases server load. Race conditions may cause older responses to overwrite newer ones.

**Fix Required:** Implement a `RequestPool` using `Map<String, Completer>` keyed by cache key. Return the existing `Future` if a request is in-flight for the same key.

---

### High Priority Issues

---

### H9 — No Exponential Backoff Retry Strategy

**File:** `lib/features/category/application/providers/category_providers.dart:152–164`
`lib/features/category/application/providers/category_product_providers.dart:251–273`

**Severity:** HIGH

**Issue:** Network failures immediately set error state with no retry. Per QA Prompt 5 Scenario 5, the required strategy is 4 attempts with delays of 2s/4s/8s, with 4xx errors excluded from retry.

**Impact:** A single failed request permanently blocks the screen in error state until the user manually retries or the 30-second polling cycle fires. See also H5 and H6.

**Fix Required:** Implement a `RetryPolicy` class with `pow(2, attempt-1) * 2` second delays, max 4 attempts, skipping retry on HTTP 4xx errors.

---

### H10 — No Stale Cache Visual Indicator When Data Is Older Than 24 Hours

**File:** `lib/features/category/presentation/components/category_screenbody/category_screen_body.dart`

**Severity:** HIGH

**Issue:** The caching system tracks `lastSyncedAt` and `isRefreshing`, but the UI never shows an amber warning when cached data is more than 24 hours old. Per QA Prompt 5 Scenario 5, stale data must display: `"Data from X ago • Tap to refresh"`.

**Impact:** Users may browse stale product information without any indication. In a grocery app, stale prices or inventory data directly affects purchasing decisions.

**Fix Required:** Add a stale data banner in `CategoryScreenBody` that checks `categoryState.lastSyncedAt` against a 24-hour threshold and surfaces an amber "Tap to refresh" affordance.

---

### H11 — No Persistent Offline Indicator in App Bar

**File:** `lib/features/category/presentation/components/header/_header.dart`
`lib/features/category/presentation/screen/category_screen.dart`

**Severity:** HIGH

**Issue:** When the device is offline, the app shows error state but provides no persistent offline indicator in the app bar. Per QA Prompt 5 Scenario 3, the offline state must be visually persistent and the app must listen to `ConnectivityPlus` to auto-retry on reconnection rather than polling continuously.

**Impact:** Users do not know if the error is a server issue or their own connectivity. The app continues attempting background polls that fail silently, wasting battery and processing.

**Fix Required:** Subscribe to `ConnectivityPlus` stream; show an offline banner in the app bar; suppress polling retries while offline; trigger a single retry on reconnection.

---

### Medium Priority Issues

---

### M7 — Cache TTL Hardcoded in Repository Constructor Instead of `CacheConfig`

**File:** `lib/features/category/infrastructure/repositories/category_repository_impl.dart:14`
`lib/features/category/infrastructure/repositories/category_product_repository_impl.dart:14`

**Severity:** MEDIUM

**Issue:** Both repositories default `cacheTtl = const Duration(minutes: 10)` in their constructors. Per QA Prompt 5, cache constants must be centralized in `CacheConfig`. If `CacheConfig.staleCacheThreshold` is changed, these 10-minute defaults remain inconsistent.

**Code:**
```dart
CategoryRepositoryImpl({
  required CategoryLocalDataSource localDataSource,
  required CategoryRemoteDataSource remoteDataSource,
  Duration cacheTtl = const Duration(minutes: 10), // Hardcoded
})
```

**Impact:** Cache TTL is fragmented across files. When tuning cache behaviour, developers must update multiple constructor defaults rather than a single `CacheConfig` constant.

**Fix Required:** Remove the default value and read from `CacheConfig.validCacheThreshold` at the point of instantiation in the provider.

---

### M8 — No Per-Entry Metadata: `accessCount`, `lastAccessed`, `size`

**File:** `lib/features/category/infrastructure/data_sources/local/category_cache_dto.dart`
`lib/features/category/infrastructure/data_sources/local/category_product_cache_dto.dart`

**Severity:** MEDIUM

**Issue:** Cache DTOs track `lastSyncedAt` and `lastModified` but not `accessCount`, `lastAccessed`, or entry `size`. Per QA Prompt 5, these fields are required for LRU eviction and the Hive size monitor.

**Impact:** Without `lastAccessed` and `accessCount`, LRU eviction (deleting oldest 20% when Hive exceeds 180MB) cannot be implemented correctly. Without `size`, the Hive size monitor cannot track per-entry contribution to total storage.

**Fix Required:** Add `accessCount`, `lastAccessed`, and `size` (bytes) to both cache DTOs and update `read()` to increment `accessCount` and `lastAccessed` on every successful read.

---

### M9 — Cache Parse Exceptions in `read()` Swallowed Without Logging

**File:** `lib/features/category/infrastructure/data_sources/local/category_local_data_source.dart:28`

**Severity:** MEDIUM

**Issue:** See C3 for the primary report. Additionally, even in non-corruption scenarios (e.g., app was updated and JSON schema changed), the silent catch means upgraded users silently fall back to the network with no log trace. This is a separate concern from corruption recovery.

**Impact:** Schema migrations between app versions are invisible. When a `CategoryCacheDto.fromJson()` fails due to a missing field after an upgrade, there is no signal that the migration path needs to be handled.

**Fix Required:** Log at minimum a warning when `fromJson` parsing fails, including the exception message.

---

## QA Prompt 6 — Architecture Compliance

---

### Critical Issues

---

### C7 — Application Layer Directly Imports Infrastructure Layer

**File:** `lib/features/category/application/providers/category_providers.dart:7–9`

**Severity:** CRITICAL

**Issue:** `category_providers.dart` (Application layer) imports three Infrastructure files directly: the local data source, the remote data source, and the repository implementation. This is a fundamental layer boundary violation. The Application layer must only import Domain contracts — it must never know about infrastructure details.

**Code:**
```dart
// Application layer importing Infrastructure — CRITICAL violation
import '../../infrastructure/data_sources/local/category_local_data_source.dart';
import '../../infrastructure/data_sources/remote/category_remote_data_source.dart';
import '../../infrastructure/repositories/category_repository_impl.dart';
```

**Impact:** Tightly couples business logic to the concrete implementations. Replacing `CategoryRemoteDataSource` with a different HTTP implementation requires modifying the application-layer provider. The dependency inversion principle is broken. Testing requires the real infrastructure classes.

**Fix Required:** Move infrastructure provider registrations (`categoryLocalDataSourceProvider`, `categoryRemoteDataSourceProvider`, `categoryRepositoryProvider`) to the infrastructure layer. The application-layer `category_providers.dart` should import only `CategoryRepository` (domain contract) and `CategoryState`/`CategoryController` (application classes).

---

### C8 — Application Layer Directly Imports Infrastructure Layer (Category Products)

**File:** `lib/features/category/application/providers/category_product_providers.dart:12–14`

**Severity:** CRITICAL

**Issue:** Same violation as C7 — `category_product_providers.dart` (Application layer) imports the local data source, remote data source, and repository implementation directly.

**Code:**
```dart
// Application layer importing Infrastructure — CRITICAL violation
import '../../infrastructure/data_sources/local/category_product_local_data_source.dart';
import '../../infrastructure/data_sources/remote/category_product_remote_data_source.dart';
import '../../infrastructure/repositories/category_product_repository_impl.dart';
```

**Impact:** Same as C7. Additionally, the direct import enables the anti-pattern in C2 where the controller reads from the local data source directly in `build()`.

**Fix Required:** Same as C7 — move infrastructure providers to the infrastructure layer.

---

### C9 — Riverpod Providers Defined in Presentation Layer Helper

**File:** `lib/features/category/presentation/helpers/socket_room_manager.dart:53–96`

**Severity:** CRITICAL

**Issue:** `socket_room_manager.dart` lives in `presentation/helpers/` but defines 5 Riverpod providers (`socketRoomManagerProvider`, `joinVariantRoomsProvider`, `variantPriceProvider`, `variantQuantityProvider`, `variantInStockProvider`). Provider definitions belong in the Application layer (`application/providers/`). Presentation layer must only consume providers, never define them.

**Code:**
```dart
// In presentation/helpers/ — WRONG LAYER
final socketRoomManagerProvider = Provider((ref) { ... });
final joinVariantRoomsProvider = FutureProvider.family<void, List<int>>((ref, variantIds) async { ... });
final variantPriceProvider = Provider.family<double?, int>((ref, variantId) { ... });
final variantQuantityProvider = Provider.family<int?, int>((ref, variantId) { ... });
final variantInStockProvider = Provider.family<bool, int>((ref, variantId) { ... });
```

**Impact:** Provider definitions in the presentation layer make them impossible to access from the application layer without creating circular imports. It violates the data flow direction. Any other feature that needs real-time price/inventory providers must import from a presentation-layer file.

**Fix Required:** Move all provider definitions from `socket_room_manager.dart` to `application/providers/socket_providers.dart`. Keep `SocketRoomManager` as a plain helper class; instantiate it inside the provider definition.

---

### C10 — Domain Layer Contains Infrastructure Concept (`CategoryDataSource` Enum)

**File:** `lib/features/category/domain/repositories/category_repository.dart:7–13`

**Severity:** CRITICAL

**Issue:** `CategoryDataSource` enum (`cache`, `remote`) is defined in the domain layer. This enum represents WHERE data came from — a concern that belongs in the infrastructure layer. The domain must remain pure; it must not know about `cache` vs `remote` data sources.

**Code:**
```dart
// In domain/repositories/ — WRONG LAYER
enum CategoryDataSource {
  cache, // Infrastructure-level concept
  remote, // Infrastructure-level concept
}

class CategoryRepositoryResult {
  final CategoryDataSource source; // Leaks infrastructure knowledge into domain
  // ...
}
```

**Impact:** The domain layer now has a dependency on an infrastructure concept. If the data source strategy changes (e.g., adding a new CDN layer), the domain contract must be modified. This breaks domain purity.

**Fix Required:** Move `CategoryDataSource` enum and the `source` field to the infrastructure layer. `CategoryRepositoryResult` in the domain should contain only `categories`, `lastSyncedAt`, `isStale`, pagination, and `lastModified`. The infrastructure layer can extend or wrap this result for its internal routing.

---

### C11 — Application Controller Bypasses Repository to Read Local Data Source Directly

**File:** `lib/features/category/application/providers/category_product_providers.dart:103–104`

**Severity:** CRITICAL

**Issue:** `CategoryProductController.build()` reads from `CategoryProductLocalDataSource` directly, circumventing the repository contract. The repository is the designated single entry point for data access — bypassing it creates two paths that can produce inconsistent state (controller's in-`build` read vs. repository's async read in `_loadInitial`).

**Code:**
```dart
@override
CategoryProductState build(String categoryId) {
  // ...
  // VIOLATION: Bypasses CategoryProductRepository
  final localDataSource = ref.read(categoryProductLocalDataSourceProvider);
  final cached = localDataSource.read(categoryId); // Should go via repository
```

**Impact:** Business logic (cache-then-API pattern) is now split between the controller and the repository. The controller can read stale data that the repository would have invalidated. Adding cache metadata (e.g., encryption, access logging) to the repository is bypassed.

**Fix Required:** Remove the direct data source read from `build()`. If synchronous initial state from cache is needed, add a `getCachedProductsSync()` method to the repository interface that returns a synchronous result from an in-memory L1 cache (see C5).

---

### High Priority Issues

---

### H12 — `PollingManager.instance` Singleton Accessed Directly from Presentation Layer

**File:** `lib/features/category/presentation/screen/category_screen.dart:73–76`

**Severity:** HIGH

**Issue:** `CategoryScreen` (Presentation) calls `PollingManager.instance.activeFeature` and `PollingManager.instance.setActiveFeature()` directly. `PollingManager` is an infrastructure-level singleton managing background timers. Presentation should interact with it only through the application layer (a provider or controller method).

**Code:**
```dart
// Presentation layer accessing infrastructure singleton directly
final currentFeature = PollingManager.instance.activeFeature;
if (currentFeature == null || currentFeature == 'category_products') {
  PollingManager.instance.setActiveFeature('category_products');
}
```

**Impact:** Presentation now has a hard dependency on `PollingManager`'s internal state shape. This also makes it impossible to test `CategoryScreen` without a real `PollingManager` instance. If the polling strategy changes, all presentation files that access the singleton must be updated.

**Fix Required:** Expose polling lifecycle through the `CategoryController`:
```dart
// In CategoryController
void activatePolling() => PollingManager.instance.setActiveFeature('category_products');
```
Then in `CategoryScreen.initState`:
```dart
ref.read(categoryControllerProvider.notifier).activatePolling();
```

---

### H13 — `CategorySelectionManager` Has Mutable Non-Final Fields

**File:** `lib/features/category/presentation/helpers/category_selection_manager.dart:5–6`

**Severity:** HIGH

**Issue:** `CategorySelectionManager.selectedIndex` and `selectedCategoryId` are non-final mutable fields. Per QA Prompt 6, state classes must use `final` fields and produce new instances via `copyWith()`. Mutable state in a shared helper makes it harder to track what changed and when.

**Code:**
```dart
class CategorySelectionManager {
  int selectedIndex;          // Mutable — should be final
  String? selectedCategoryId; // Mutable — should be final
  // ...
  void selectCategory(int index, String? categoryId) {
    selectedIndex = index;         // Direct field mutation
    selectedCategoryId = categoryId;
  }
}
```

**Impact:** `_selectionManager` is shared between `_CategoryScreenState` and `CategoryStateListener`. Mutations in one place are immediately visible in the other. Because mutations happen outside `setState()`, they can cause silent UI inconsistencies.

**Fix Required:** Make fields `final` and use `copyWith()`. The owning widget (`_CategoryScreenState`) should replace `_selectionManager` with the new instance and call `setState()`:
```dart
setState(() {
  _selectionManager = _selectionManager.copyWith(selectedIndex: index, selectedCategoryId: categoryId);
});
```

---

### Medium Priority Issues

---

### M10 — Hardcoded Pixel Values Without ScreenUtil in `_product_card.dart`

**File:** `lib/features/category/presentation/components/widgets/_product_card.dart:217`
`lib/features/category/presentation/components/widgets/_product_card.dart:255`

**Severity:** MEDIUM

**Issue:** Several pixel values are hardcoded without ScreenUtil equivalents. Per QA Prompt 6, all sizes must use `.h`, `.w`, `.sp`, `.r` from `flutter_screenutil`.

**Code:**
```dart
// Hardcoded — not responsive
child: Padding(
  padding: const EdgeInsets.all(8.0), // Should be 8.r
  child: _ProductImage(image: image),
),

// Icon size without .sp
child: const Icon(
  Icons.sync,
  color: Colors.white,
  size: 12, // Should be 12.sp or 12.r
),
```

**Impact:** Product card layout breaks on tablets and large-screen devices. The image padding and sync icon are fixed-pixel and will not scale with screen density.

**Fix Required:** Replace `const EdgeInsets.all(8.0)` with `EdgeInsets.all(8.r)` and `size: 12` with `size: 12.sp`.

---

### M11 — `CategoryState` and `CategoryProductState` Are Plain Classes Without `freezed`

**File:** `lib/features/category/application/states/category_state.dart`
`lib/features/category/application/states/category_product_state.dart`

**Severity:** MEDIUM

**Issue:** Both state classes are manually written plain Dart classes with `copyWith()`. The home feature uses `freezed`-generated state classes. Manual `copyWith()` implementations are error-prone: forgetting to include a field in `copyWith()` causes silent data loss. `freezed` generates `copyWith()`, equality, and `toString()` automatically.

**Impact:** Manual `copyWith()` in `CategoryState` (11 fields) and `CategoryProductState` (11 fields) must be kept in sync as new fields are added. Missing a field in `copyWith()` — a common oversight — causes state resets that are difficult to diagnose.

**Fix Required:** Migrate both state classes to `freezed`. Annotate with `@freezed`, define fields in the factory constructor, and let `build_runner` generate `copyWith()`.

---

### M12 — `socket_room_manager.dart` in Wrong Layer Contains Both Logic and Providers

**File:** `lib/features/category/presentation/helpers/socket_room_manager.dart`

**Severity:** MEDIUM

**Issue:** Beyond the critical violation (C9) of providers in the presentation layer, this file conflates two responsibilities: `SocketRoomManager` (socket room join/leave logic) and provider definitions (`socketRoomManagerProvider`, `variantPriceProvider`, etc.). These are separate concerns.

**Impact:** Presentation helpers that contain provider definitions and socket logic are difficult to test, reuse across features, or replace independently.

**Fix Required:** Split into: (a) `core/network/socket_room_manager.dart` for the `SocketRoomManager` class, and (b) `application/providers/socket_providers.dart` for all Riverpod provider definitions.

---

*End of Category Flow Audit Report — 37 Issues Total: 11 Critical · 13 High · 13 Medium*
