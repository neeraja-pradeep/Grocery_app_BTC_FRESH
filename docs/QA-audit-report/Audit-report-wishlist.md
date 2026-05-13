# Wishlist Flow — QA Audit Report

**Feature Audited:** Wishlist Screen (List of saved products)

**Files Reviewed:**
- `lib/features/wishlist/presentation/screen/wishlist_screen.dart`
- `lib/features/wishlist/application/providers/wishlist_provider.dart`
- `lib/features/wishlist/application/states/wishlist_state.dart`
- `lib/features/wishlist/application/usecases/wishlist_usecases.dart`
- `lib/features/wishlist/domain/entities/wishlist_item.dart`
- `lib/features/wishlist/domain/repositories/wishlist_repository.dart`
- `lib/features/wishlist/infrastructure/repositories/wishlist_repository_impl.dart`
- `lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart`
- `lib/features/wishlist/infrastructure/data_sources/wishlist_local_ds.dart`
- `lib/features/home/presentation/components/product_card.dart` (used in wishlist screen)

**Total Issues Found:** 36 (12 Critical · 13 High · 11 Medium)

---

## QA Prompt 1 — State Management

---

### Critical Issues

---

### C1 — `WishlistNotifier` Uses Legacy `StateNotifier` Instead of `Notifier`

**File:** `lib/features/wishlist/application/providers/wishlist_provider.dart:16`

**Severity:** CRITICAL

**Issue:** `WishlistNotifier` extends `StateNotifier`, which is the Riverpod 1.x legacy API. The entire wishlist feature is built on this deprecated pattern. In Riverpod 2.x, `StateNotifier` is replaced by `Notifier`. Using `StateNotifier` forces the class to manually receive and store a `Ref` as a field (`_ref`), bypass the lifecycle contract of `Notifier`, and call `_ref.listen` inside the constructor instead of inside `build()`.

**Code:**
```dart
class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistRepository _repository;
  final Ref _ref; // Manually stored — anti-pattern in Riverpod 2.x

  WishlistNotifier({required WishlistRepository repository, required Ref ref})
    : _repository = repository,
      _ref = ref,
      super(const WishlistState.initial()) {
    // ref.listen called in constructor — should be in build()
    _ref.listen<AuthState>(authProvider, (previous, next) { ... });
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) {
    final repository = ref.watch(wishlistRepositoryProvider);
    return WishlistNotifier(repository: repository, ref: ref);
  },
);
```

**Impact:** `StateNotifier` is scheduled for deprecation in Riverpod. Storing `Ref` as a constructor field bypasses Riverpod's lifecycle management — if the provider is rebuilt, the old `Ref` may be stale. Mixing old-style `StateNotifierProvider` with new-style `NotifierProvider` across the codebase creates inconsistency.

**Fix Required:** Migrate to `Notifier`:
```dart
class WishlistNotifier extends Notifier<WishlistState> {
  @override
  WishlistState build() {
    ref.listen<AuthState>(authProvider, (previous, next) { ... });
    return const WishlistState.initial();
  }
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, WishlistState>(WishlistNotifier.new);
```

---

### C2 — `_loadWishlist()` Not Awaited Inside `refresh()` Callback — Unawaited Future

**File:** `lib/features/wishlist/application/providers/wishlist_provider.dart:65–74`

**Severity:** CRITICAL

**Issue:** `refresh()` calls `_loadWishlist()` inside synchronous `mapOrNull` callbacks — where `await` is not possible. The `Future<void>` returned by `_loadWishlist()` is silently discarded. The `refresh()` method's own `Future` completes immediately, before the wishlist has actually been reloaded. Any caller that awaits `refresh()` will see the operation complete before the data is ready.

**Code:**
```dart
Future<void> refresh() async {
  state.mapOrNull(
    loaded: (loadedState) {
      state = WishlistState.refreshing(items: loadedState.items);
      _loadWishlist(); // ← unawaited Future — fire and forget
    },
    error: (_) => _loadWishlist(), // ← unawaited Future
  );
  // refresh() Future completes HERE — _loadWishlist() is still running
}
```

**Impact:** `ref.read(wishlistProvider.notifier).refresh()` resolves before the data is refreshed. UI code that awaits refresh and then reads state will see stale data. The error retry tap in `_WishlistErrorView` calls `refresh()` without handling its completion, which happens to work by coincidence but is architecturally fragile.

**Fix Required:** Extract the state check outside the callback and await `_loadWishlist()` directly:
```dart
Future<void> refresh() async {
  final currentState = state;
  if (currentState is WishlistLoaded) {
    state = WishlistState.refreshing(items: currentState.items);
  } else if (currentState is WishlistError) {
    // Allow retry
  } else {
    return;
  }
  await _loadWishlist();
}
```

---

### C3 — `Logger.error()` Called Inside `build()` in `_WishlistErrorView`

**File:** `lib/features/wishlist/presentation/screen/wishlist_screen.dart:303–307`

**Severity:** CRITICAL

**Issue:** `_WishlistErrorView.build()` calls `Logger.error()` as its first action. This is a side-effect — I/O-adjacent logging — executing on every widget rebuild. The error view can rebuild multiple times when the widget tree is updated (e.g., orientation changes, ancestor rebuilds). Each rebuild writes a duplicate log entry.

**Code:**
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Side effect in build() — logs on every rebuild
  Logger.error(
    'Wishlist error: ${failure.runtimeType} - ${failure.message}',
    error: failure,
  );

  return Center( ... );
}
```

**Impact:** Duplicate log entries on each rebuild pollute logs and make diagnosing the original error harder. Side effects in `build()` violate Flutter's rendering contract and can cause unexpected behaviour during hot reload and widget reconciliation.

**Fix Required:** Log the error once in the parent widget when the state transitions to error, not in the error view's `build()`. Use `ref.listen` in the parent to detect error transitions:
```dart
ref.listen<WishlistState>(wishlistProvider, (_, next) {
  next.whenOrNull(error: (f, _) => Logger.error('Wishlist error', error: f));
});
```

---

### High Priority Issues

---

### H1 — `Ref` Stored as a Field in `StateNotifier` — Lifecycle Risk

**File:** `lib/features/wishlist/application/providers/wishlist_provider.dart:18`

**Severity:** HIGH

**Issue:** `WishlistNotifier` stores `Ref _ref` as a constructor-injected field. In Riverpod 2.x, `Notifier` provides `ref` automatically as a lifecycle-bound property. Storing `Ref` manually means if the provider is ever overridden or the container is re-created, the stored `_ref` may not match the live provider container.

**Code:**
```dart
class WishlistNotifier extends StateNotifier<WishlistState> {
  final Ref _ref; // Manually held ref — bypasses Riverpod lifecycle

  WishlistNotifier({required Ref ref}) : _ref = ref, ...;

  Future<bool> addToWishlist(String productId) async {
    // ...uses _ref throughout...
  }
}
```

**Impact:** The stored `_ref` can become stale if the provider graph is rebuilt. This is particularly risky around auth state changes where providers may be invalidated.

**Fix Required:** Migrate to `Notifier` (see C1) which provides `ref` as a lifecycle-managed property with no risk of staleness.

---

### H2 — Full Wishlist Refetch After Every Mutation — N+1 State Pattern

**File:** `lib/features/wishlist/application/providers/wishlist_provider.dart:105–110`

**Severity:** HIGH

**Issue:** After a successful `addToWishlist` or `removeFromWishlist`, the notifier calls `_loadWishlist()` which triggers a full network fetch of the entire wishlist. This N+1 pattern causes two API calls per user action (the mutation + the full refetch) and results in a loading flash between the mutation and the refreshed state.

**Code:**
```dart
Future<bool> addToWishlist(String productId) async {
  final result = await _repository.addToWishlist(productId);
  return result.fold(
    (failure) { ... return false; },
    (item) {
      _loadWishlist(); // Full API refetch after every add
      return true;
    },
  );
}
```

**Impact:** Every wishlist interaction (add, remove, toggle) incurs two network round-trips. On a slow connection this creates visible UI lag and a loading state between actions. In a list of 10 items, every heart-tap triggers 11+ API calls total (1 mutation + 10 product-detail fetches from `getWishlist`).

**Fix Required:** Perform optimistic updates — immediately modify the local list state on success, then optionally sync in the background rather than refetching:
```dart
(item) {
  // Optimistic: add to current list immediately
  state.mapOrNull(loaded: (s) {
    state = WishlistState.loaded(items: [...s.items, item]);
  });
  return true;
}
```

---

### Medium Priority Issues

---

### M1 — Selector Providers (`isInWishlistProvider`, `wishlistItemsProvider`) Defined in Application-Layer Provider File

**File:** `lib/features/wishlist/application/providers/wishlist_provider.dart:202–220`

**Severity:** MEDIUM

**Issue:** Three derived selector providers (`wishlistItemsProvider`, `isInWishlistProvider`, `wishlistCountProvider`) are defined at the bottom of `wishlist_provider.dart` alongside the main notifier. Selector providers are presentation-layer conveniences and should be separated from the notifier definition.

**Impact:** The notifier file grows in scope as more selectors are added. Testing the notifier in isolation requires loading the full file with all selectors. Separation of concerns is reduced.

**Fix Required:** Extract selectors to a dedicated file: `application/providers/wishlist_selectors.dart`.

---

## QA Prompt 2 — Security & Data Persistence

---

### Critical Issues

---

### C4 — Previous User's Cache Not Cleared on Logout — Cross-User Data Contamination

**File:** `lib/features/wishlist/application/providers/wishlist_provider.dart:31–34`
`lib/features/wishlist/infrastructure/data_sources/wishlist_local_ds.dart:27`

**Severity:** CRITICAL

**Issue:** When the user logs out, `WishlistNotifier` resets state to `WishlistState.initial()` but never calls `_repository.clearCache()`. The in-memory `WishlistLocalDataSourceImpl._cachedWishlist` retains the previous user's data. If a new user logs in within 5 minutes on the same device, the cache freshness check passes and User B is served User A's wishlist data.

**Code:**
```dart
// WishlistNotifier constructor listener — logout handler
else if (next is GuestMode && previous is Authenticated) {
  state = const WishlistState.initial(); // ← State reset only
  // ← _repository.clearCache() is NEVER called
}

// WishlistLocalDataSourceImpl
CachedWishlistData? _cachedWishlist; // Persists in memory across user sessions

// getWishlist() in repository — checks freshness first
if (cachedContainer != null &&
    cachedContainer.isFresh(const Duration(minutes: 5))) {
  return Right(cachedContainer.data); // User A's data returned to User B
}
```

**Impact:** User B who logs in within 5 minutes of User A logging out will see User A's wishlist items. This is a data privacy violation and directly matches QA Prompt 2 rule #12: "Login not clearing previous user's data." In a real-world grocery app, this exposes purchase intent data between users.

**Fix Required:** Clear the cache immediately on logout in the auth listener:
```dart
else if (next is GuestMode && previous is Authenticated) {
  await _repository.clearCache(); // ← must clear before state reset
  state = const WishlistState.initial();
}
```

---

### C5 — Local Cache Is In-Memory Only — No Hive Persistence

**File:** `lib/features/wishlist/infrastructure/data_sources/wishlist_local_ds.dart:25–43`

**Severity:** CRITICAL

**Issue:** `WishlistLocalDataSourceImpl` uses a plain Dart field (`CachedWishlistData? _cachedWishlist`) as its "cache." The comment explicitly acknowledges this: `// In-memory cache for now - in a real app, you'd use Hive/SharedPreferences`. This cache is lost every time the app is closed. Every cold start fetches the wishlist from the API even if data was loaded 10 seconds before the app was killed.

**Code:**
```dart
class WishlistLocalDataSourceImpl implements WishlistLocalDataSource {
  // In-memory cache for now - in a real app, you'd use Hive/SharedPreferences
  CachedWishlistData? _cachedWishlist; // Field on the class — lost on restart

  @override
  Future<CachedWishlistData?> getWishlist() async {
    return _cachedWishlist; // Always null on cold start
  }

  @override
  Future<void> saveWishlist(List<WishlistItem> items) async {
    _cachedWishlist = CachedWishlistData(data: items, cachedAt: DateTime.now());
    // Never written to disk
  }
}
```

**Impact:** Every app restart forces a full wishlist reload from the network — including the N+1 individual product-detail API calls per item. On a 20-item wishlist, cold start makes 21 API calls. The cache layer is effectively non-functional for its stated purpose of reducing network load.

**Fix Required:** Replace the in-memory implementation with Hive-backed persistence using the shared `Boxes.cache` box, following the same pattern as `CategoryLocalDataSource`. Store wishlist data as JSON under a dedicated cache key from `CacheConfig`.

---

### High Priority Issues

---

### H3 — Hardcoded API Endpoint Strings — Not Using `ApiEndpoints` Constants

**File:** `lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart:23`
`lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart:48–50`

**Severity:** HIGH

**Issue:** `WishlistApiImpl` hardcodes API endpoint strings inline instead of using the project's `ApiEndpoints` class. Other features (categories, home) use `ApiEndpoints` constants for all endpoint paths.

**Code:**
```dart
final response = await _apiClient.get('/api/order/v1/wishlist/');
// ...
final productResponse = await _apiClient.get(
  '/api/products/v1/variants/$productVariantId/',
);
```

**Impact:** Endpoint changes require searching for hardcoded strings across files rather than updating a single constant. No compile-time safety — a typo silently produces a 404. Violates the DRY principle used by every other feature in the codebase.

**Fix Required:** Add constants to `ApiEndpoints`:
```dart
static const String wishlist = '/api/order/v1/wishlist/';
static String variantDetail(String id) => '/api/products/v1/variants/$id/';
```

---

### H4 — All Exceptions Collapsed to `ServerFailure` — Loses Error Type Information

**File:** `lib/features/wishlist/infrastructure/repositories/wishlist_repository_impl.dart:51`

**Severity:** HIGH

**Issue:** The repository's `catch` blocks convert all exceptions — regardless of type — to `ServerFailure(e.toString())`. A `NetworkException`, `DioException` (timeout), or `FormatException` all become identical `ServerFailure`. The error view's `_getUserFriendlyMessage` checks for `NetworkFailure` and `TimeoutFailure` — but those types are never returned, so those branches are dead code.

**Code:**
```dart
} catch (e) {
  // 4. On Network Error: Try to return stale cache
  // ...
  return Left(ServerFailure(e.toString())); // All errors → ServerFailure
}
```

**Impact:** Users always see the "Unable to connect to server" message regardless of whether the real issue is no internet, a timeout, or a server error. The user-friendly error mapping in `_WishlistErrorView` is fully bypassed. Network failures cannot be distinguished from server failures.

**Fix Required:** Catch specific exception types and map them correctly:
```dart
} on NetworkException catch (e) {
  return Left(NetworkFailure(e.message));
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    return Left(TimeoutFailure(e.message ?? 'Timeout'));
  }
  return Left(ServerFailure(e.message ?? 'Server error', statusCode: e.response?.statusCode));
} catch (e) {
  return Left(UnknownFailure(e.toString()));
}
```

---

### Medium Priority Issues

---

### M2 — Duplicated Comment in `clearCache()` — Copy-Paste Error

**File:** `lib/features/wishlist/infrastructure/repositories/wishlist_repository_impl.dart:125–126`

**Severity:** MEDIUM

**Issue:** The same comment is pasted twice on consecutive lines inside the `catch` block of `clearCache()`, with no code between them.

**Code:**
```dart
} catch (e) {
  // Log error but don't throw - cache clearing should be non-blocking
  // Log error but don't throw - cache clearing should be non-blocking
}
```

**Impact:** Minor code quality issue indicating a copy-paste error that was not caught in code review. The intent to log is stated twice but the actual logging call is missing entirely.

**Fix Required:** Remove the duplicate comment and add the missing log call:
```dart
} catch (e) {
  Logger.error('Failed to clear wishlist cache', error: e);
}
```

---

## QA Prompt 3 — Performance & Error Handling

---

### Critical Issues

---

### C6 — Sequential N+1 API Calls in `WishlistApiImpl.getWishlist()`

**File:** `lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart:41–73`

**Severity:** CRITICAL

**Issue:** `getWishlist()` first fetches the wishlist (1 call), then for each item sequentially awaits a separate product-detail API call. With N wishlist items, this makes N+1 total API calls executed one at a time. The `for` loop uses `await` inside a synchronous iteration, blocking the entire wishlist load until every individual item's detail fetch completes.

**Code:**
```dart
for (var item in responseList) {
  // ...
  if (productVariantId != null) {
    try {
      // Sequential await — each call waits for the previous
      final productResponse = await _apiClient.get(
        '/api/products/v1/variants/$productVariantId/',
      );
      // ...
    }
  }
}
```

**Impact:** On a wishlist with 10 items, cold start makes 11 sequential API calls. If each call takes 300ms, the wishlist loads in 3+ seconds minimum. On a slow connection this easily exceeds 10 seconds. This directly causes the `loading` state to persist for an unacceptably long time, producing a poor user experience.

**Fix Required:** Use `Future.wait()` to run all product-detail fetches in parallel:
```dart
final futures = responseList.map((item) async {
  final wishlistData = item as Map<String, dynamic>;
  final productVariantId = wishlistData['product_variant']?.toString();
  if (productVariantId == null) return WishlistItem.fromJson(wishlistData);
  try {
    final resp = await _apiClient.get('/api/products/v1/variants/$productVariantId/');
    return WishlistItem.fromProductVariantResponse(
      wishlistId: wishlistData['id'] ?? 0,
      productData: resp.data as Map<String, dynamic>,
    );
  } catch (_) {
    return WishlistItem.fromJson(wishlistData);
  }
});
final wishlistItems = await Future.wait(futures);
```

---

### High Priority Issues

---

### H5 — All Exceptions in `WishlistApiImpl` Wrapped as Generic `Exception` — Loses Type

**File:** `lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart:79–82`

**Severity:** HIGH

**Issue:** `WishlistApiImpl.getWishlist()` wraps all errors in `Exception('Error loading wishlist: $e')`, discarding the original exception type. A `DioException` (network failure, timeout, 401) becomes an untyped `Exception`. The repository's catch blocks cannot identify the real failure and therefore cannot map to the correct `Failure` subtype.

**Code:**
```dart
} catch (e) {
  throw Exception('Error loading wishlist: $e'); // Discards original type
}
```

**Impact:** Combined with H4 (all errors mapped to `ServerFailure`), users can never receive a meaningful network-specific error message. Auth failures (401) are invisible — the app cannot detect that the session has expired and prompt re-login.

**Fix Required:** Let typed exceptions propagate naturally. Only catch to rethrow as typed domain exceptions:
```dart
} on DioException catch (e) {
  throw NetworkException.fromDio(e);
} on FormatException catch (e) {
  throw DataParsingException(e.message);
}
// Do not catch the general Exception — let it propagate
```

---

### H6 — No Retry Logic for Failed Network Operations

**File:** `lib/features/wishlist/infrastructure/repositories/wishlist_repository_impl.dart`

**Severity:** HIGH

**Issue:** `getWishlist()`, `addToWishlist()`, and `removeFromWishlist()` all have a single try-catch with no retry. A transient network hiccup permanently results in an error state until the user manually taps "Try Again." Per QA Prompt 5, critical operations must retry with exponential backoff (4 attempts, 2s/4s/8s delays, skipping retry on 4xx errors).

**Impact:** On spotty connections (elevators, tunnels, weak mobile signal) a single failed request leaves the wishlist broken until the user actively retries. Mutation operations (add/remove) that fail silently leave the UI out of sync with the server state.

**Fix Required:** Implement a `RetryPolicy` class that handles `pow(2, attempt-1) * 2` second delays for up to 4 attempts, skipping retry on HTTP 4xx responses.

---

### Medium Priority Issues

---

### M3 — Data Transformation (`toProductVariant()`) in Widget Build Chain

**File:** `lib/features/wishlist/presentation/screen/wishlist_screen.dart:138`

**Severity:** MEDIUM

**Issue:** `_buildContent()` runs `items.map((item) => item.toProductVariant()).toList()` on every rebuild. This transformation — converting `WishlistItem` list to `ProductVariant` list — is a business-logic mapping that belongs in the application or infrastructure layer, not inside the widget build call chain.

**Code:**
```dart
Widget _buildContent(BuildContext context, WidgetRef ref, List<WishlistItem> items) {
  if (items.isEmpty) return _buildEmptyState(context, ref);

  // Data transformation during every rebuild
  final products = items.map((item) => item.toProductVariant()).toList();
  // ...
}
```

**Impact:** The conversion runs on every state rebuild, even when items haven't changed. `toProductVariant()` does non-trivial string parsing and URL processing per item. On a 20-item wishlist, this is 20 object constructions per rebuild.

**Fix Required:** Move the transformation into the provider layer (a selector provider). The derived `ProductVariant` list can be cached and only recomputed when `wishlistState.items` actually changes.

---

## QA Prompt 4 — Code Quality & Deployment

---

### High Priority Issues

---

### H7 — Entire `wishlist_usecases.dart` File Is Commented-Out Dead Code

**File:** `lib/features/wishlist/application/usecases/wishlist_usecases.dart:1–55`

**Severity:** HIGH

**Issue:** The entire contents of `wishlist_usecases.dart` — five complete use case classes — are wrapped in a block comment. The file ships as part of the production codebase but contributes nothing. It also references a non-existent import path (`package:grocery_app/features/home/domain/repositories/wishlist_repository.dart`) that would cause a compile error if uncommented.

**Code:**
```dart
// // lib/features/wishlist/application/usecases/wishlist_usecases.dart

// import 'package:grocery_app/features/wishlist/domain/entities/wishlist_item.dart';
// import 'package:grocery_app/features/home/domain/repositories/wishlist_repository.dart';

// class GetWishlistUseCase { ... }
// class AddToWishlistUseCase { ... }
// class RemoveFromWishlistUseCase { ... }
// class GetWishlistItemUseCase { ... }
// class UpdateWishlistItemUseCase { ... }
```

**Impact:** Commented-out code is a deployment readiness concern per QA Prompt 4. The incorrect import path suggests this was scaffolded and never completed. The file creates false confidence that use cases exist when they do not. If uncommented by mistake, it will not compile.

**Fix Required:** Delete the file entirely. If use cases are needed in the future, create them fresh with correct imports.

---

### H8 — Commented-Out `print` Statements in Production Files

**File:** `lib/features/wishlist/domain/entities/wishlist_item.dart:25–27`
`lib/features/wishlist/domain/entities/wishlist_item.dart:164–168`
`lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart:65`

**Severity:** HIGH

**Issue:** Multiple `print()` calls are commented out across production files. Commented-out debug code indicates these were not removed during development and signals a gap in code review hygiene. If uncommented, `print()` statements would expose wishlist item data including prices and product names to the device console.

**Code:**
```dart
// Debug: Print the raw JSON to see what we're getting
// print('WishlistItem.fromJson - Raw JSON: $json');
// print('WishlistItem.fromJson - Image URL: $imageUrl');

// print('WishlistItem.toProductVariant - Original imageUrl: $imageUrl');
// print('WishlistItem.toProductVariant - Processed imageUrl: $processedImageUrl');

// print('Error fetching product details for $productVariantId: $e');
```

**Impact:** Commented-out `print` statements in domain entities and data sources indicate unfinished debugging cleanup. Exposing wishlist item data in logs (if uncommented) would be a security risk.

**Fix Required:** Delete all commented-out `print` statements. Any logging needed during development should use the project `Logger` with appropriate levels, gated by `kDebugMode`.

---

### Medium Priority Issues

---

### M4 — Magic Hex Colour `0xFFcaf5ac` Hardcoded in Screen

**File:** `lib/features/wishlist/presentation/screen/wishlist_screen.dart:97`

**Severity:** MEDIUM

**Issue:** The status bar colour is hardcoded as `Color(0xFFcaf5ac)` in the `AnnotatedRegion`. This value should come from `AppColors` so that theme changes propagate consistently.

**Code:**
```dart
value: const SystemUiOverlayStyle(
  statusBarColor: Color(0xFFcaf5ac), // Magic hex — should be AppColors.green10 or equivalent
  statusBarIconBrightness: Brightness.dark,
),
```

**Impact:** If the app colour scheme changes, this hardcoded value will be missed and the wishlist screen will display an inconsistent status bar colour.

**Fix Required:** Replace with `AppColors.green10` (or the matching named constant) to keep the colour consistent with the rest of the app.

---

### M5 — Hardcoded `SizedBox(height: 220)` Without ScreenUtil

**File:** `lib/features/wishlist/presentation/screen/wishlist_screen.dart:149`

**Severity:** MEDIUM

**Issue:** The horizontal product list container has a hardcoded height of `220` with no ScreenUtil suffix (`.h`). All other sizing in the screen uses ScreenUtil. This one value is fixed-pixel and will not scale on different screen densities.

**Code:**
```dart
SizedBox(
  height: 220, // Should be 220.h
  child: ListView.builder( ... ),
),
```

**Impact:** On small-screen devices, the product card list may clip or overflow. On large-screen devices, cards will appear proportionally small. The inconsistency with ScreenUtil usage elsewhere makes the UI layout unpredictable.

**Fix Required:** Change to `height: 220.h`.

---

### M6 — `ProductCard` Width Passed as Raw `double` Without ScreenUtil

**File:** `lib/features/wishlist/presentation/screen/wishlist_screen.dart:162`

**Severity:** MEDIUM

**Issue:** `ProductCard` receives `width: 140` as a raw double. Inside `ProductCard`, this width is applied as `widget.width.w` (with ScreenUtil), but the value `140` passed from `WishlistScreen` is a plain number without any ScreenUtil-awareness at the call site. The inconsistency means the intent (140 logical pixels) may not match the actual rendering.

**Code:**
```dart
ProductCard(
  product: product,
  onTap: () => _handleProductTap(context, product),
  width: 140, // Raw double — width.w applied inside ProductCard
),
```

**Impact:** Minor visual inconsistency. The actual width rendered is `140.w`, which is correct, but the intent expressed at the call site is ambiguous.

**Fix Required:** Pass `140.w` at the call site and accept a `double` already in logical pixels inside `ProductCard`, removing the internal `.w` application to avoid double-scaling.

---

## QA Prompt 5 — Caching

---

### Critical Issues

---

### C7 — No Persistent Cache — In-Memory Only, No Hive Backing

**File:** `lib/features/wishlist/infrastructure/data_sources/wishlist_local_ds.dart:25–43`

**Severity:** CRITICAL

**Issue:** The wishlist cache implementation uses a class field (`_cachedWishlist`) as its storage. This violates QA Prompt 5 Scenario 1 (Cold Start) requirements: every cold start is a cache miss, triggering 11+ API calls regardless of when the data was last fetched. There is no L2 Hive layer and no L1 memory layer — only a transient Dart object.

**Impact:** The cache is effectively decorative. It provides TTL freshness checking but never survives an app restart. Every launch makes the full N+1 API call sequence, making the wishlist one of the slowest-loading screens in the app.

**Fix Required:** Implement Hive-backed persistence. Store wishlist data as JSON under a `CacheConfig.wishlistKey` constant in `Boxes.cache`. Follow the pattern established by `CategoryLocalDataSource.save()` and `read()`.

---

### C8 — Previous User's Wishlist Cache Not Cleared on Logout

**File:** `lib/features/wishlist/application/providers/wishlist_provider.dart:31–34`

**Severity:** CRITICAL

**Issue:** On logout, only the Riverpod state is reset. The local data source's in-memory cache (`_cachedWishlist`) is not cleared. For the in-memory-only implementation this is a User A/User B contamination risk (as detailed in C4). Once Hive persistence is added (C7 fix), this becomes even more severe — User A's wishlist would persist to disk and be served to User B on their first login.

**Impact:** Directly violates QA Prompt 5 Scenario 9 (Cache Corruption Recovery) and QA Prompt 2's requirement that login must clear previous user's data. The fix for C5/C7 makes this a must-fix prerequisite before shipping Hive persistence.

**Fix Required:** Add `await _repository.clearCache()` to the auth state listener before setting state to `initial`. Also invalidate the `wishlistProvider` to force a fresh provider instantiation for the new user.

---

### High Priority Issues

---

### H9 — Cache TTL Hardcoded as `Duration(minutes: 5)` — Not Using `CacheConfig`

**File:** `lib/features/wishlist/infrastructure/repositories/wishlist_repository_impl.dart:28`

**Severity:** HIGH

**Issue:** The cache freshness check uses a hardcoded 5-minute TTL. Per QA Prompt 5, all cache constants must be centralised in `CacheConfig`. There is no `CacheConfig.wishlistCacheTtl` constant, and this 5-minute value is inconsistent with the 10-minute TTL used in category and home features.

**Code:**
```dart
if (cachedContainer != null &&
    cachedContainer.isFresh(const Duration(minutes: 5))) {
  return Right(cachedContainer.data);
}
```

**Impact:** Changing the wishlist cache TTL requires finding and updating this literal value rather than changing a single `CacheConfig` constant. The inconsistency with other features' TTLs (10 minutes) suggests this was set arbitrarily.

**Fix Required:** Add `static const Duration wishlistCacheTtl = Duration(minutes: 10)` to `CacheConfig` and reference it here.

---

### H10 — No HTTP Conditional Request Headers (If-Modified-Since)

**File:** `lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart:21–82`

**Severity:** HIGH

**Issue:** The wishlist API fetches always make full requests with no `If-Modified-Since` or `ETag` headers. Per QA Prompt 5 Scenario 6, cached data should be validated with conditional headers to allow the server to return `304 Not Modified` when the wishlist is unchanged — saving bandwidth and the N+1 product detail fetches.

**Impact:** Every wishlist refresh (including the 5-minute TTL expiry) re-fetches all data even if nothing changed. Combined with the sequential N+1 pattern, this means every non-trivial session causes dozens of API calls for unchanged data.

**Fix Required:** Store the `Last-Modified` header from the wishlist response. Send `If-Modified-Since` on subsequent requests. On `304`, return cached data without triggering the N+1 product detail fetches.

---

### H11 — No Stale Cache Indicator for Outdated Wishlist Data

**File:** `lib/features/wishlist/presentation/screen/wishlist_screen.dart`

**Severity:** HIGH

**Issue:** The wishlist shows cached data without any visual indicator when the cache is stale (data older than the defined threshold). Per QA Prompt 5 Scenario 5, stale data must show an amber warning: "Data from X ago • Tap to refresh." No such indicator exists.

**Impact:** Users may be browsing wishlist prices that are hours or days out of date with no indication that the data may not be current. In a grocery app, price staleness directly affects purchasing decisions.

**Fix Required:** Add a stale data banner to `WishlistScreen` that checks `lastSyncedAt` against `CacheConfig.staleCacheThreshold` and surfaces a "Tap to refresh" affordance when exceeded.

---

### Medium Priority Issues

---

### M7 — No Per-Entry Cache Metadata: `accessCount`, `lastAccessed`, `size`

**File:** `lib/features/wishlist/infrastructure/data_sources/wishlist_local_ds.dart:8–17`

**Severity:** MEDIUM

**Issue:** `CachedWishlistData` tracks only `data` and `cachedAt`. Per QA Prompt 5, cache entries must also track `accessCount`, `lastAccessed`, and `size` for LRU eviction and the Hive size monitor.

**Code:**
```dart
class CachedWishlistData {
  final List<WishlistItem> data;
  final DateTime cachedAt;
  // Missing: accessCount, lastAccessed, size
}
```

**Impact:** Without `lastAccessed` and `accessCount`, the LRU eviction policy cannot include wishlist data in its calculations. Without `size`, the Hive size monitor cannot account for wishlist cache contribution.

**Fix Required:** Add `int accessCount`, `DateTime lastAccessed`, and `int sizeBytes` to `CachedWishlistData`. Increment `accessCount` and update `lastAccessed` on every read.

---

### M8 — No Request Deduplication — Concurrent Wishlist Fetches Make Duplicate Calls

**File:** `lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart`

**Severity:** MEDIUM

**Issue:** If `getWishlist()` is triggered twice simultaneously (e.g., from `_loadWishlist()` called in the auth listener and from the UI refresh), two full N+1 request sequences run in parallel. There is no in-flight request deduplication pool.

**Impact:** Race conditions between concurrent requests can cause the UI to briefly show the result of the slower request, overwriting the fresher result. Combined with the N+1 pattern, duplicate fetches can make 22+ API calls in a short window.

**Fix Required:** Implement a `Completer`-based in-flight deduplication pool in `WishlistApiImpl`, returning the existing `Future` for any duplicate request while one is in flight.

---

## QA Prompt 6 — Architecture Compliance

---

### Critical Issues

---

### C9 — Presentation Layer Imports Infrastructure Directly

**File:** `lib/features/wishlist/presentation/screen/wishlist_screen.dart:18`

**Severity:** CRITICAL

**Issue:** `WishlistScreen` (Presentation layer) imports `home_repostory_impl.dart` (Infrastructure layer) directly to access `homeRepositoryProvider`. This is used to call `ref.read(homeRepositoryProvider).getProductById(targetId)` inside the banner "Shop Now" handler. Presentation must never import from `infrastructure/`.

**Code:**
```dart
// Presentation layer importing Infrastructure directly — CRITICAL
import '../../../home/infrastructure/repositories/home_repostory_impl.dart';

// Used in _handleShopNowClick:
final result = await ref
    .read(homeRepositoryProvider) // Provider from infrastructure file
    .getProductById(targetId);
```

**Impact:** Tightly couples the wishlist screen to the home feature's infrastructure implementation. Refactoring `HomeRepositoryImpl` or moving `homeRepositoryProvider` will require changes to the wishlist presentation layer. The dependency inversion principle is broken.

**Fix Required:** Move `homeRepositoryProvider` to `home/application/providers/` and import it from there, or create a dedicated use case / application provider for banner navigation that the wishlist screen can consume without knowing about the home repository.

---

### C10 — Application Layer Imports Infrastructure Layer

**File:** `lib/features/wishlist/application/providers/wishlist_provider.dart:7`

**Severity:** CRITICAL

**Issue:** `wishlist_provider.dart` (Application layer) imports `wishlist_repository_impl.dart` (Infrastructure layer) to access `wishlistRepositoryProvider`. The application layer must only import domain contracts — never infrastructure implementations.

**Code:**
```dart
// Application layer importing Infrastructure — CRITICAL
import '../../infrastructure/repositories/wishlist_repository_impl.dart';

// Used in provider definition:
final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) {
    final repository = ref.watch(wishlistRepositoryProvider); // from infra
    return WishlistNotifier(repository: repository, ref: ref);
  },
);
```

**Impact:** The application layer is now coupled to `WishlistRepositoryImpl`. Testing `WishlistNotifier` with a mock repository requires mocking the infrastructure class or overriding the infrastructure provider — not the domain contract.

**Fix Required:** Move `wishlistRepositoryProvider` to `application/providers/wishlist_repository_provider.dart`. The provider definition may reference the infrastructure class, but it belongs in the application layer.

---

### C11 — Domain Entity Contains Factory Methods With HTTP Response Parsing Logic

**File:** `lib/features/wishlist/domain/entities/wishlist_item.dart:24–181`

**Severity:** CRITICAL

**Issue:** `WishlistItem` (a domain entity) contains three factory constructors that perform infrastructure-level operations: JSON parsing (`fromJson`), HTTP response mapping (`fromProductVariantResponse`), and cross-entity conversion (`fromProductVariant`). Domain entities must be plain value objects — they must not know about JSON, HTTP responses, or other entities' structures. This is a fundamental domain purity violation.

**Code:**
```dart
@freezed
class WishlistItem with _$WishlistItem {
  // ...
  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    // HTTP response parsing — belongs in infrastructure DTO
    String imageUrl = json['image']?.toString() ?? '';
    // ...URL validation logic...
    return WishlistItem(...);
  }

  factory WishlistItem.fromProductVariantResponse({
    required int wishlistId,
    required Map<String, dynamic> productData, // HTTP response map in domain
  }) { ... }
}

extension WishlistItemX on WishlistItem {
  ProductVariant toProductVariant() { ... } // Cross-entity conversion in domain
}
```

**Impact:** The domain layer now depends on the structure of HTTP responses. If the API response format changes, the domain entity must be modified — violating the open/closed principle. The domain entity cannot be reused in a context where JSON is not involved.

**Fix Required:** Create a `WishlistItemDto` in `infrastructure/models/` that handles all JSON parsing and HTTP response mapping. The DTO's `toDomain()` method produces a clean `WishlistItem`. Move `toProductVariant()` to the infrastructure or application layer as an adapter/mapper.

---

### C12 — `wishlistRepositoryProvider` Defined in Infrastructure Layer

**File:** `lib/features/wishlist/infrastructure/repositories/wishlist_repository_impl.dart:141–148`

**Severity:** CRITICAL

**Issue:** The Riverpod provider for the wishlist repository is defined at the bottom of the infrastructure implementation file, forcing any layer that needs the repository to import the infrastructure file. Provider definitions belong in the application layer (`application/providers/`).

**Code:**
```dart
// Infrastructure file — wrong place for a provider definition
final wishlistRepositoryProvider = riverpod.Provider<WishlistRepository>((ref) {
  final remoteDs = ref.watch(wishlistRemoteDataSourceProvider);
  final localDs = ref.watch(wishlistLocalDataSourceProvider);
  return WishlistRepositoryImpl(
    remoteDataSource: remoteDs,
    localDataSource: localDs,
  );
});
```

**Impact:** Same as C10 — forces application and presentation layers to import the infrastructure file just to access `wishlistRepositoryProvider`. This is the root cause of the import violation in C10.

**Fix Required:** Move the provider definition to `application/providers/wishlist_repository_provider.dart`. The infrastructure file should contain only `WishlistRepositoryImpl` with no Riverpod code.

---

### High Priority Issues

---

### H12 — `WishlistItem` Domain Entity Imports From Another Feature's Domain

**File:** `lib/features/wishlist/domain/entities/wishlist_item.dart:5–6`

**Severity:** HIGH

**Issue:** The `wishlist` domain entity imports `ProductVariant` and `ProductMedia` from the `home` feature's domain layer. This creates a cross-feature dependency at the domain level — the wishlist domain is coupled to the home domain's entity structure.

**Code:**
```dart
// Domain entity importing from another feature's domain
import '../../../home/domain/entities/product_media.dart';
import '../../../home/domain/entities/product_variant.dart';
```

**Impact:** Changes to `ProductVariant` or `ProductMedia` in the home feature directly break the wishlist domain entity. Features cannot be developed or refactored independently. The wishlist cannot be extracted into a separate package without bringing the home domain along.

**Fix Required:** Remove the cross-feature domain dependency. Create a `WishlistProduct` value object in the wishlist domain that contains only the fields the wishlist needs (price, image URL, name). The `toProductVariant()` conversion belongs in an application-layer mapper, not in the domain.

---

### H13 — `WishlistApiImpl.getWishlist()` Contains Business Logic — Enriching Items With Product Data

**File:** `lib/features/wishlist/infrastructure/data_sources/wishlist_api.dart:38–75`

**Severity:** HIGH

**Issue:** The remote data source class `WishlistApiImpl` decides to enrich each wishlist item with full product details by making additional API calls. This decision (fetch enriched data vs. use basic data) is business logic — it belongs in the repository or a use case, not in a data source class. Per QA Prompt 6 Rule 10, a `remote/` API class must only make the HTTP call and convert JSON to domain entity.

**Code:**
```dart
// Business logic inside remote data source — decides to enrich data
for (var item in responseList) {
  if (productVariantId != null) {
    try {
      final productResponse = await _apiClient.get(
        '/api/products/v1/variants/$productVariantId/',
      );
      wishlistItems.add(WishlistItem.fromProductVariantResponse(...));
    } catch (e) {
      wishlistItems.add(WishlistItem.fromJson(wishlistData)); // Fallback
    }
  }
}
```

**Impact:** The data source layer now makes decisions about data enrichment strategy. If the enrichment strategy changes (e.g., batch endpoint becomes available), the data source must be modified. The N+1 pattern (C6) is embedded in a layer that should have no business logic.

**Fix Required:** `WishlistApiImpl.getWishlist()` should only fetch and parse the wishlist endpoint, returning basic `WishlistItemDto` objects. Move the enrichment decision to the repository layer, where it can be optimised (e.g., parallel fetches, batch API if available) without violating layer boundaries.

---

### Medium Priority Issues

---

### M9 — No `presentation/components/` Subfolder — Single Monolithic Screen File

**File:** `lib/features/wishlist/presentation/screen/wishlist_screen.dart`

**Severity:** MEDIUM

**Issue:** The wishlist presentation layer has no `components/` subfolder. All UI code — the main screen, the error view, and the empty state — is in a single 387-line file. The `_WishlistErrorView` is defined in the same file as the screen. Per QA Prompt 6, the folder structure requires a `presentation/components/` directory for reusable UI pieces.

**Impact:** As the wishlist screen grows (adding remove buttons, quantity selectors, sorting), the file will become increasingly difficult to maintain. The error view and empty state widgets cannot be reused by other screens without importing the entire `wishlist_screen.dart`.

**Fix Required:** Extract `_WishlistErrorView` to `presentation/components/wishlist_error_view.dart` and the empty state to `presentation/components/wishlist_empty_view.dart`. Create the `components/` folder.

---

### M10 — `wishlist_usecases.dart` Is an Entirely Commented-Out Stub Layer

**File:** `lib/features/wishlist/application/usecases/wishlist_usecases.dart`

**Severity:** MEDIUM

**Issue:** The use cases layer stub exists as a file but contributes nothing. The feature bypasses use cases entirely — the notifier calls the repository directly. This is not a violation in itself (use cases are optional), but the dead file creates a misleading impression of architectural completeness.

**Impact:** New developers reading the codebase may assume use cases are implemented and look to this file for business rules — finding only commented-out scaffolding. See also H7.

**Fix Required:** Delete the file. If use cases are introduced in the future, create them fresh.

---

### M11 — `WishlistItemX.toProductVariant()` Performs Cross-Entity Mapping in Domain Layer

**File:** `lib/features/wishlist/domain/entities/wishlist_item.dart:200–241`

**Severity:** MEDIUM

**Issue:** The extension `WishlistItemX.toProductVariant()` constructs a full `ProductVariant` object from a `WishlistItem` — including creating `ProductMedia` objects, parsing SKUs, and constructing fake `currentQuantity` strings. This is a mapping operation that belongs in the application or infrastructure layer, not in a domain entity extension.

**Code:**
```dart
extension WishlistItemX on WishlistItem {
  ProductVariant toProductVariant() {
    return ProductVariant(
      sku: 'wishlist-$productId', // Fake SKU construction in domain
      currentQuantity: '1',       // Hardcoded value in domain
      // ...
    );
  }
}
```

**Impact:** The domain layer now contains mapping logic that must stay in sync with both `WishlistItem` and `ProductVariant` schemas. The fake `sku` and `currentQuantity` values are workarounds that hide the underlying data gap — these should be surfaced and handled at a higher layer.

**Fix Required:** Move `toProductVariant()` to an application-layer mapper class (`WishlistItemMapper`) or to the infrastructure layer. The domain entity should only contain `final` value fields.

---

*End of Wishlist Flow Audit Report — 36 Issues Total: 12 Critical · 13 High · 11 Medium*
