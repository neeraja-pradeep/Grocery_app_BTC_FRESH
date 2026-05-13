# Core Infrastructure — Code Audit Report

**Scope:** App Bootstrap (`app_bootstrap.dart`) · Env Loader (`env_loader.dart`) · App Config (`app_config.dart`) · API Client (`api_client.dart`) · Network Exceptions (`network_exceptions.dart`) · Hive Init (`hive_init.dart`) · Hive Boxes (`boxes.dart`) · Hive Keys (`keys.dart`) · Hive Adapters (`user.dart`, `address.dart`, `delivery_tracking.dart`) · Cache Config (`cache_config.dart`) · Connectivity Provider (`connectivity_provider.dart`) · Polling Manager (`polling_manager.dart`) · Polling Tab Controller (`polling_tab_controller.dart`) · Socket Service (`socket_service.dart`)

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 5 · 6

**Date:** 2026-05-02

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 0 | 1 | 1 | 2 |
| Prompt 2 — Security & Data Persistence | 3 | 3 | 1 | 7 |
| Prompt 3 — Performance & Error Handling | 1 | 3 | 2 | 6 |
| Prompt 4 — Code Quality & Deployment | 2 | 3 | 3 | 8 |
| Prompt 5 — Cache Implementation | 2 | 4 | 2 | 8 |
| Prompt 6 — Architecture Compliance | 1 | 3 | 2 | 6 |
| **Total** | **9** | **17** | **11** | **37** |

---

## Top Blockers Before Any Production Release

1. **`isProduction = false` hardcoded in source** — `app_config.dart:13` — production builds always run with the development flag set. There is no build-flavor or environment separation.
2. **API base URL is HTTP, not HTTPS** — `app_config.dart:22` — all API traffic including auth cookies, CSRF tokens, and payment data is transmitted in cleartext over HTTP.
3. **`EnvLoader.load()` is an empty stub** — `env_loader.dart:5` — the environment loading step does nothing. All config values are hardcoded.
4. **Socket events are received but silently discarded** — `socket_service.dart:95–99` — `price_update` and `inventory_update` events only `logger.i()` the payload; no Riverpod provider is notified. Real-time updates are non-functional.
5. **API timeout is 30 seconds** — `app_config.dart:57–62` — the QA Prompt 5 spec mandates 10 seconds. A 30-second hang on a bad network makes the app appear frozen.
6. **Zone error handler is silent in release builds** — `app_bootstrap.dart:38–43` — uncaught exceptions are discarded with no crash reporting in production.
7. **`CacheConfig` is missing all QA Prompt 5 required constants** — `cache_config.dart` — no `memoryCacheMaxSize`, `staleCacheThreshold`, `validCacheThreshold`, `maxRetryAttempts`, `retryBaseDelay`, or `apiTimeout`.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

*None found in this scope.*

---

## High Priority Issues

---

### H1 — `apiClientProvider` throws `UnimplementedError` by default — no safe fallback

**File:** `lib/core/network/api_client.dart:211–213`

**Severity:** HIGH

**Issue:** `apiClientProvider` is registered with a body that throws `UnimplementedError`. It relies entirely on the call-site in `main.dart` to override it via `ProviderScope`. Any code that reads this provider before the override is applied — such as during hot restart, widget tests that don't set up the full provider scope, or providers that initialize eagerly — will throw an unhandled error.

**Code:**
```dart
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('ApiClient must be overridden in main.dart');
});
```

**Impact:** Any widget test or integration test that reads a provider depending on `apiClientProvider` without overriding it in the test's `ProviderScope` crashes immediately with an `UnimplementedError`. There is no graceful "not yet initialized" state or fallback.

**Fix Required:** Use a late-initialized approach or a proper override mechanism. Document clearly that this provider must always be overridden. Add an assertion in tests:
```dart
// In test setup:
final container = ProviderContainer(
  overrides: [apiClientProvider.overrideWithValue(mockApiClient)],
);
```
Alternatively, make `ApiClient` injectable via constructor and inject it through a `ProviderScope` override at app startup as documented.

---

## Medium Priority Issues

---

### M1 — `connectivityStatusProvider` is a `FutureProvider` — does not react to network changes

**File:** `lib/core/network/connectivity_provider.dart:20–25`

**Severity:** MEDIUM

**Issue:** `connectivityStatusProvider` uses `FutureProvider`, which resolves once and never updates. If the network changes after the initial check, this provider's value is permanently stale. Developers who accidentally use this instead of the `StreamProvider` (`connectivityProvider`) will build UIs that show stale connectivity status.

**Code:**
```dart
final connectivityStatusProvider = FutureProvider<ConnectivityStatus>((ref) async {
  final connectivity = Connectivity();
  return _getConnectivityStatus(await connectivity.checkConnectivity());
});
```

**Impact:** Any widget watching `connectivityStatusProvider` will correctly show "online" on first load but will never update if the user loses connectivity mid-session. The `StreamProvider`-based `connectivityProvider` is the correct one for reactive UI.

**Fix Required:** Either remove `connectivityStatusProvider` and use `connectivityProvider.value` with a fallback, or rename it to `connectivitySnapshotProvider` and add a prominent comment warning that it does not update after the initial check. Add an `assert` or lint rule preventing watch of the `FutureProvider` variant in UI code.

---

---

# QA Prompt 2 — Security & Data Persistence Violations

---

## Critical Issues

---

### C1 — All API traffic uses HTTP — cleartext transmission of auth cookies and payment data

**File:** `lib/core/config/app_config.dart:22`

**Severity:** CRITICAL

**Issue:** `apiBaseUrl = 'http://156.67.104.149:8080'` — the app communicates with the backend over unencrypted HTTP. All session cookies (which authenticate every API request), CSRF tokens, personal data, and order information are transmitted in cleartext. This is compounded by `android:usesCleartextTraffic="true"` already flagged in the auth audit.

**Code:**
```dart
static const String apiBaseUrl = 'http://156.67.104.149:8080';
static const String webSocketUrl = apiBaseUrl;  // WebSocket also HTTP
```

**Impact:** Any attacker on the same network (coffee shop, home router, mobile hotspot) can perform a passive MITM attack to steal session cookies and hijack authenticated sessions. Payment flows, personal addresses, and order history are all exposed. This is a production-blocking security vulnerability.

**Fix Required:** Migrate the backend to HTTPS immediately. Replace `http://` with `https://`. Remove `android:usesCleartextTraffic="true"` from the main manifest (retain only in `src/debug/AndroidManifest.xml`). For the WebSocket URL, use `wss://` instead of `ws://`.

---

### C2 — `isProduction = false` hardcoded — production builds use dev configuration

**File:** `lib/core/config/app_config.dart:13–14`

**Severity:** CRITICAL

**Issue:** `isProduction` and `isDevelopment` are hardcoded `const bool` values in source. They are never set differently for release builds. There is no build-flavor, `--dart-define`, or `EnvLoader` mechanism to switch them. A production APK will have `isProduction = false` and `isDevelopment = true` permanently.

**Code:**
```dart
static const bool isProduction = false;
static const bool isDevelopment = true;
```

**Impact:** If any code gates behaviour on `AppConfig.isProduction` (logging verbosity, debug overlays, test data, mock responses), those gates will never activate in production. Any feature intended to be disabled in production remains enabled. The app has no distinction between dev and prod builds.

**Fix Required:** Replace with `--dart-define`-based configuration:
```dart
static const bool isProduction =
    bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);
```
In CI/CD, pass `--dart-define=IS_PRODUCTION=true` for release builds.

---

### C3 — `EnvLoader.load()` is an empty stub — no environment loading occurs

**File:** `lib/app/bootstrap/env_loader.dart:5`

**Severity:** CRITICAL

**Issue:** `EnvLoader.load()` does nothing. It is called during `AppBootstrap.run()` but since the body is empty, no `.env` file is read, no `--dart-define` values are validated, and no environment-specific configuration is applied. All config values are hardcoded in `AppConfig`.

**Code:**
```dart
class EnvLoader {
  static Future<void> load() async {}  // empty stub — does nothing
}
```

**Impact:** The app has no environment injection mechanism. Hardcoded values (`apiBaseUrl`, `isProduction`, credentials) cannot be changed at build time without editing source files. This makes it impossible to maintain separate dev/staging/prod configurations from the same codebase.

**Fix Required:** Implement actual environment loading. Minimum viable approach using `--dart-define`:
```dart
class EnvLoader {
  static const _apiUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://156.67.104.149:8080');

  static Future<void> load() async {
    // Validate required environment variables
    assert(_apiUrl.isNotEmpty, 'API_BASE_URL must be defined');
  }
}
```

---

## High Priority Issues

---

### H1 — `LogInterceptor` logs full request/response bodies in debug mode — cookies and tokens exposed

**File:** `lib/core/network/api_client.dart:52–61`

**Severity:** HIGH

**Issue:** `LogInterceptor` is configured with `requestBody: true, responseBody: true, requestHeader: true`. This logs the full HTTP request — including `Cookie` headers containing session tokens and CSRF tokens — to the console in debug builds. On Android, these logs are accessible to other apps with `READ_LOGS` permission on Android 4.x or via `adb logcat` on unrooted devices.

**Code:**
```dart
if (kDebugMode) {
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,      // logs full request body including passwords
      responseBody: true,     // logs full response body including tokens
      requestHeader: true,    // logs Cookie header — session tokens exposed
      responseHeader: false,
    ),
  );
}
```

**Impact:** On a developer's device or in a CI environment with `adb logcat` access, auth session cookies, CSRF tokens, and response payloads including user PII are logged in plaintext. For debug builds shared with testers (e.g. via Firebase App Distribution), this constitutes a credential exposure risk.

**Fix Required:** Remove `requestHeader: true` to avoid logging cookies. Redact the `Cookie` and `Set-Cookie` headers from request logs:
```dart
LogInterceptor(
  requestBody: kDebugMode,
  responseBody: kDebugMode,
  requestHeader: false,       // never log headers — contains session cookies
  responseHeader: false,
),
```

---

### H2 — Zone error handler in `AppBootstrap` silently discards crashes in release builds

**File:** `lib/app/bootstrap/app_bootstrap.dart:38–43`

**Severity:** HIGH

**Issue:** The `runZonedGuarded` error handler only logs in `kDebugMode`. In release builds, uncaught exceptions that escape the zone are completely silently discarded with no crash report, no analytics event, and no user feedback.

**Code:**
```dart
(error, stack) {
  if (kDebugMode) {
    log('Uncaught zone error: $error\n$stack');
  }
  // In release: nothing happens — crash is swallowed
},
```

**Impact:** Fatal production crashes produce no signal. Crash rates cannot be monitored. Users experience silent app freezes or blank screens with no error state and no actionable path to recovery.

**Fix Required:** Integrate a crash reporting service (Firebase Crashlytics, Sentry) and record all uncaught errors regardless of build mode:
```dart
(error, stack) {
  if (kDebugMode) {
    log('Uncaught zone error: $error\n$stack');
  } else {
    // e.g. FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  }
},
```

---

### H3 — `Boxes.openHiveBoxes()` does not open `homeBox`, `catalogBox`, `userPrefsBox` — dead constants

**File:** `lib/core/storage/hive/boxes.dart:12–16, 24–31`

**Severity:** HIGH

**Issue:** Three box name constants (`homeBox`, `catalogBox`, `userPrefsBox`) are declared in `Boxes` but never opened in `openHiveBoxes()`. If any code attempts `Hive.box(Boxes.homeBox)` without it being open, a `HiveError` is thrown at runtime.

**Code:**
```dart
// Declared constants (lines 12–16):
static const String homeBox = 'homeBox';
static const String catalogBox = 'catalogBox';
static const String userPrefsBox = 'userPrefsBox';

// Never opened in openHiveBoxes() (lines 24–31):
static Future<void> openHiveBoxes() async {
  userBox = await Hive.openBox(HiveKeys.userbox);
  addressBox = await Hive.openBox(HiveKeys.addressBox);
  cacheBox = await Hive.openBox(cache);
  profileBox = await Hive.openBox(profile);
  deliveryTrackingBox = await Hive.openBox(deliveryTracking);
  // homeBox, catalogBox, userPrefsBox never opened
}
```

**Impact:** Any feature that attempts to use `Boxes.homeBox`, `Boxes.catalogBox`, or `Boxes.userPrefsBox` will crash with `HiveError: Box not found.`. These constants are either dead code (should be deleted) or represent boxes that were intended to be opened but were forgotten.

**Fix Required:** If these boxes are not used, delete the three constants. If they are used, add them to `openHiveBoxes()` and add corresponding `late Box` fields and close/clear calls to maintain consistency.

---

## Medium Priority Issues

---

### M1 — Hive `TypeAdapter` registrations not verified against all `@HiveType` classes — silent registration gap risk

**File:** `lib/app/bootstrap/hive_init.dart:20–23`

**Severity:** MEDIUM

**Issue:** `HiveInit.initialize()` manually registers 4 adapters. There is no automated check ensuring every `@HiveType` class in the project has its adapter registered before boxes are opened. Adding a new `@HiveType` without updating `hive_init.dart` silently fails: data is written as raw maps and read back incorrectly, causing data corruption without a startup crash.

**Code:**
```dart
Hive.registerAdapter(AddressModelAdapter());
Hive.registerAdapter(UserModelAdapter());
Hive.registerAdapter(AddressTypeAdapter());
Hive.registerAdapter(DeliveryTrackingDataAdapter());
// Any new @HiveType class must be manually added here
```

**Impact:** A new Hive model added to the project will work correctly in tests (since tests open fresh boxes) but corrupt existing user data silently in production if its adapter is missing.

**Fix Required:** Add a build-time check (or at least an integration test) that enumerates all `@HiveType` classes in the project and confirms each has a corresponding registered adapter before any box is opened. Until automated, add a comment listing all registered adapters and their `typeId`s as a manual checklist.

---

---

# QA Prompt 3 — Error Handling & Performance

---

## Critical Issues

---

### C1 — API connect/receive/send timeouts are 30 seconds — UI hangs for 30s on bad network

**File:** `lib/core/config/app_config.dart:57–62`

**Severity:** CRITICAL

**Issue:** All three timeout values (`connectTimeout`, `receiveTimeout`, `sendTimeout`) are set to 30 seconds. The QA Prompt 5 specification mandates a 10-second API timeout. A 30-second hang before an error is shown makes the app appear frozen and causes users to force-quit.

**Code:**
```dart
static const Duration connectTimeout = Duration(seconds: 30);
static const Duration receiveTimeout = Duration(seconds: 30);
static const Duration sendTimeout = Duration(seconds: 30);
```

**Impact:** Any API call on a degraded network (weak 3G, congested Wi-Fi) causes a 30-second wait before the timeout error is shown. During this window, loading indicators spin indefinitely with no user-actionable feedback. Checkout and payment flows are particularly affected since payment API hangs block the user from knowing if an order was placed.

**Fix Required:**
```dart
static const Duration connectTimeout = Duration(seconds: 10);
static const Duration receiveTimeout = Duration(seconds: 10);
static const Duration sendTimeout = Duration(seconds: 10);
```

---

## High Priority Issues

---

### H1 — Socket events received but silently discarded — real-time features non-functional

**File:** `lib/core/network/socket_service.dart:94–118`

**Severity:** HIGH

**Issue:** `_setupEventListeners()` registers handlers for `price_update`, `inventory_update`, and `delivery_location_update` socket events. Every handler body is `logger.i(...)` — the received data is only logged. No Riverpod provider is notified, no state is updated, and no UI reacts to these events. Real-time price and inventory updates are infrastructure that does nothing.

**Code:**
```dart
socket.on('price_update', (data) {
  logger.i('🔥 Price Update Received: $data');
  // No provider.invalidate(), no state update, no UI notification
});

socket.on('inventory_update', (data) {
  logger.i('📦 Inventory Update Received: $data');
  // Nothing
});

socket.on('delivery_location_update', (data) {
  logger.i('📍 Delivery Location Update: $data');
  // Nothing
});
```

**Impact:** The socket infrastructure connects, joins rooms, and receives data — but the data never reaches the UI. Products can go out of stock, prices can change, and delivery locations can update, but users see stale data. The investment in Socket.IO is entirely wasted until this is wired up.

**Fix Required:** Inject a `Ref` or callback into `SocketService` so it can notify providers on received events:
```dart
SocketService({required this.onPriceUpdate, required this.onInventoryUpdate, ...});

socket.on('price_update', (data) {
  onPriceUpdate(data as Map<String, dynamic>);
});
```
Or expose a `StreamController` per event type and have Riverpod `StreamProvider`s subscribe to them.

---

### H2 — `SocketService` is a plain class, not a singleton or Riverpod provider — multiple instances possible

**File:** `lib/core/network/socket_service.dart:11–217`

**Severity:** HIGH

**Issue:** `SocketService` is a plain Dart class with no singleton enforcement and no Riverpod provider registration in this file. Nothing prevents multiple `SocketService` instances from being created, each establishing their own socket connection. The `_listenersRegistered` guard prevents duplicate listeners on a single instance, but cannot prevent two instances from both connecting.

**Code:**
```dart
class SocketService {
  late IO.Socket socket;  // not a singleton, no provider
  bool _isConnected = false;
  // ...
}
```

**Impact:** If `SocketService` is instantiated by multiple providers or screens, each instance opens its own WebSocket connection to the server — multiplying connection load and causing duplicate event handling.

**Fix Required:** Either register `SocketService` as a `keepAlive` Riverpod provider:
```dart
@Riverpod(keepAlive: true)
SocketService socketService(Ref ref) {
  final service = SocketService();
  ref.onDispose(service.dispose);
  return service;
}
```
Or apply the singleton pattern with `SocketService._instance`.

---

### H3 — `PollingManager` global singleton holds strong references to `VoidCallback` — potential memory leaks

**File:** `lib/core/polling/polling_manager.dart:43–44`

**Severity:** HIGH

**Issue:** `PollingManager._pollers` is a `Map<String, _PollerInfo>` where each `_PollerInfo` holds `onResume` and `onPause` `VoidCallback`s. If a notifier that registered a poller is disposed without calling `unregisterPoller`, the `PollingManager` singleton retains the callbacks, preventing garbage collection of the notifier and all objects it references.

**Code:**
```dart
final Map<String, _PollerInfo> _pollers = {};

// If unregisterPoller is not called on notifier dispose,
// _pollers retains closures capturing the notifier's state
```

**Impact:** Each leaked notifier keeps the full provider state, Hive data sources, and API client references alive. Navigating to a product detail screen 20+ times (as called out in QA Prompt 4 memory-leak test) accumulates leaked product notifiers in `PollingManager._pollers`.

**Fix Required:** Add a contract that every `registerPoller` call must be paired with `unregisterPoller` in the notifier's `dispose()` method. Add a debug assertion in `registerPoller` that warns if the key already exists:
```dart
assert(!_pollers.containsKey(key),
  'Poller $key registered twice without unregistering. Call unregisterPoller first.');
```
Add this to the architecture docs and code review checklist.

---

## Medium Priority Issues

---

### M1 — `network_exceptions.dart` has two separate error-mapping functions doing the same job

**File:** `lib/core/network/network_exceptions.dart:37–107, 139–227`

**Severity:** MEDIUM

**Issue:** The file contains both `NetworkException.fromDio(DioException)` (a factory constructor on the exception class) and a free function `mapDioError(Object e)` that performs nearly identical `DioException` mapping. Both exist, each used by different parts of the codebase, leading to inconsistent error messages for the same HTTP status codes.

**Code:**
```dart
// Two different places doing the same thing:
factory NetworkException.fromDio(DioException error) { ... }  // lines 37–107
Failure mapDioError(Object e) { ... }  // lines 139–227
```

**Impact:** A 401 error may produce "Unauthorized. Please log in." via `mapDioError` but `"Request failed (401). Please check your input."` via `NetworkException.fromDio`. Users see different messages for the same error depending on which codepath was used. The divergence will grow as only one is updated while the other is forgotten.

**Fix Required:** Remove `mapDioError`. All Dio errors are caught in `ApiClient` and rethrown as `NetworkException`. Any code that called `mapDioError` should catch `NetworkException` instead and map to `AppFailure` via a single shared utility.

---

### M2 — `AppConfig.convertToCdnUrl()` is business logic inside a config class

**File:** `lib/core/config/app_config.dart:71–96`

**Severity:** MEDIUM

**Issue:** `AppConfig` contains `convertToCdnUrl(String url)` and `ensureHttps(String url)` instance methods. A config class should hold only constants; business logic (URL transformation) does not belong here.

**Code:**
```dart
class AppConfig {
  // ...
  static String convertToCdnUrl(String url) {
    // URL manipulation logic — not config
    if (url.startsWith(cdnBaseUrl)) return url;
    if (url.startsWith(internalServerBase)) {
      return url.replaceFirst(internalServerBase, cdnBaseUrl);
    }
    ...
  }
}
```

**Impact:** `AppConfig` becomes a grab-bag utility class. URL conversion logic cannot be unit-tested independently of config values. If the CDN URL strategy changes, both the constant and the transformation logic must be edited in the same file.

**Fix Required:** Move `convertToCdnUrl()` and `ensureHttps()` to a `UrlUtils` or `MediaUrlHelper` utility class in `core/utils/`. `AppConfig` retains only constants.

---

---

# QA Prompt 4 — Code Quality & Deployment Readiness

---

## Critical Issues

---

### C1 — Production build uses dev configuration — `isProduction` hardcoded false (deployment blocker)

**File:** `lib/core/config/app_config.dart:13`

**Severity:** CRITICAL

**Issue:** Repeated from Prompt 2 C2 — listed here as a deployment blocker. Every production APK released will have `AppConfig.isProduction == false` and `AppConfig.isDevelopment == true` at compile time.

**Code:**
```dart
static const bool isProduction = false;
static const bool isDevelopment = true;
```

**Impact:** Any feature gate, log suppression, analytics toggle, or mock data switch that relies on `isProduction` will never activate. The app ships in a permanent "development" mode.

**Fix Required:** Use `--dart-define=IS_PRODUCTION=true` with a `bool.fromEnvironment` constant. Automate this in the release CI/CD pipeline.

---

### C2 — `EnvLoader` is an empty no-op — environment configuration never loaded (deployment blocker)

**File:** `lib/app/bootstrap/env_loader.dart:5`

**Severity:** CRITICAL

**Issue:** Repeated from Prompt 2 C3 — listed here as a deployment blocker. There is no separation between dev, staging, and production configurations. All config is hardcoded, including the backend IP address.

**Code:**
```dart
static Future<void> load() async {}
```

**Impact:** The same hardcoded IP address, the same development flags, and the same timeout values are used in every build. Changing the API server requires editing source code and cutting a new release.

**Fix Required:** Implement `--dart-define`-based configuration. The release pipeline passes production values; debug builds use defaults.

---

## High Priority Issues

---

### H1 — No retry logic for network failures on any API call

**File:** `lib/core/network/api_client.dart:100–208`

**Severity:** HIGH

**Issue:** `ApiClient` catches `DioException` and rethrows as `NetworkException` for every HTTP verb with no retry logic. A single transient network failure (dropped packet, brief disconnection) immediately surfaces as an error to the user. Per QA Prompt 5, the retry strategy must be: 4 attempts, exponential backoff (`+2s/+4s/+8s`), 4xx errors not retried.

**Code:**
```dart
Future<Response<T>> get<T>(...) async {
  try {
    final response = await dio.get<T>(...);
    return response;
  } on DioException catch (error) {
    throw NetworkException.fromDio(error);  // immediate throw, no retry
  }
}
```

**Impact:** Transient network errors that would self-resolve in 1–2 seconds immediately show error states. On mobile networks (3G handoff, brief signal loss), this causes unnecessary error screens. Critical flows like checkout payment are particularly affected.

**Fix Required:** Add a `RetryInterceptor` to Dio using the `dio_smart_retry` package or a custom implementation:
```dart
// Exponential backoff: attempts 1-4, delays 2s/4s/8s, skip 4xx
dio.interceptors.add(RetryInterceptor(
  dio: dio,
  retries: 4,
  retryDelays: [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)],
  retryEvaluator: (error, attempt) =>
      error.type != DioExceptionType.badResponse ||
      (error.response?.statusCode ?? 0) >= 500,
));
```

---

### H2 — `Boxes.closeHiveBoxes()` and `clearAllData()` exist but are never called

**File:** `lib/core/storage/hive/boxes.dart:35–58`

**Severity:** HIGH

**Issue:** `Boxes.closeHiveBoxes()` and `Boxes.clearAllData()` are defined but never called from `AppBootstrap`, any lifecycle handler, or logout flow. Boxes are opened at startup and never explicitly closed. On logout, the individual feature repositories call their own box `.clear()` — not the centralized `clearAllData()`.

**Code:**
```dart
static Future<void> closeHiveBoxes() async {
  await userBox.close();
  await addressBox.close();
  await cacheBox.close();
  await profileBox.close();
  await deliveryTrackingBox.close();
  // Never called anywhere
}

static Future<void> clearAllData() async {
  await userBox.clear();
  // ...
  // Never called anywhere
}
```

**Impact:** Hive boxes are never properly closed when the app terminates. On some platforms this can cause write-queue corruption if the app is force-killed mid-write. The `clearAllData()` method exists but the logout flow does not use it — each feature clears its own box independently, risking that a new feature's box is cleared in the feature but not in `clearAllData()`.

**Fix Required:** Call `Boxes.clearAllData()` from the auth notifier's `logout()` method to centralise cache clearing. Register `Boxes.closeHiveBoxes()` in `AppBootstrap` via a lifecycle observer or the app's `dispose()` path.

---

### H3 — `PollingTabController.dispose()` does not pause active pollers

**File:** `lib/core/polling/polling_tab_controller.dart:121–127`

**Severity:** HIGH

**Issue:** `PollingTabController.dispose()` only logs a message. It does not call `PollingManager.instance.pauseActive()` or `pauseAllPolling()`. When `BottomNavigation` is disposed (e.g. on logout, when GoRouter navigates away from `/home`), all tab pollers continue running via the singleton `PollingManager`.

**Code:**
```dart
void dispose() {
  developer.log(
    'PollingTabController disposed',
    name: 'PollingTabController',
    level: 500,
  );
  // No pause or unregister calls
}
```

**Impact:** After logout, pollers that were running for cart, wishlist, and home continue firing API calls against the now-unauthenticated session. These calls return 401 errors that are silently swallowed by the polling catch blocks, but they consume battery and network bandwidth.

**Fix Required:**
```dart
void dispose() {
  PollingManager.instance.pauseAllPolling();
  developer.log('PollingTabController disposed', name: 'PollingTabController', level: 500);
}
```

---

## Medium Priority Issues

---

### M1 — `AppBootstrap` embeds fire-and-forget emoji comments in production code

**File:** `lib/app/bootstrap/app_bootstrap.dart:33, 47, 49, 53`

**Severity:** MEDIUM

**Issue:** The bootstrap file contains emoji-adorned comments (`// 🔥 COMBINED INITIALIZATION`, `// --- THEIR Hive init ---`, `// --- YOUR API client init ---`) that appear to be collaboration scaffolding left from a merge. These are informal and do not describe production intent.

**Code:**
```dart
// 🔥 COMBINED INITIALIZATION (theirs + yours)
result = await _initialize();
// ...
// --- THEIR Hive init ---
await HiveInit.initialize();
// --- YOUR API client init ---
final apiClient = ApiClient();
```

**Impact:** Suggests the bootstrap is in an unfinished state. "THEIR" and "YOUR" imply multiple authors who have not yet aligned on a single ownership model for initialization. Future developers cannot tell which parts are stable.

**Fix Required:** Remove emoji comments, remove ownership annotations ("theirs/yours"), and rewrite with intent-based comments if any are needed at all.

---

### M2 — `HiveKeys` contains duplicate box-name key for `addressBox`

**File:** `lib/core/storage/hive/keys.dart:6` vs `lib/core/storage/hive/boxes.dart:11`

**Severity:** MEDIUM

**Issue:** `HiveKeys.addressBox = 'address_box'` and `Boxes.address = 'address_box'` both define the same box name as separate constants in separate files. `HiveInit` uses `HiveKeys.addressBox` while `Boxes.openHiveBoxes()` uses `HiveKeys.addressBox` — but `Boxes.address` constant is redundant.

**Code:**
```dart
// keys.dart:6
static const addressBox = 'address_box';

// boxes.dart:11
static const String address = 'address_box'; // same value, different name
```

**Impact:** Minor — but if one is updated without the other, the box name changes for part of the codebase while the rest uses the old name, opening different physical Hive boxes and losing data.

**Fix Required:** Remove `Boxes.address` and use only `HiveKeys.addressBox`. Or consolidate all box name constants into a single source of truth (`Boxes`) and remove `HiveKeys`.

---

### M3 — Excessive `developer.log` calls throughout `PollingManager` — performance noise in release builds

**File:** `lib/core/polling/polling_manager.dart:83–96, 107–109, 119–120, 141–145, 165–172, 185–189, 206–210, 241–248, 261–272`

**Severity:** MEDIUM

**Issue:** `PollingManager` makes `developer.log()` calls on every poller start, stop, register, unregister, feature change, and lifecycle event. These are gated at log levels 500–800 but not behind `kDebugMode`. Every tab switch, background/foreground transition, and polling tick emits multiple log entries in both debug and release builds.

**Code:**
```dart
developer.log(
  'Setting active feature: $featureName (was: $_activeFeature)',
  name: 'PollingManager',
  level: 800,
);
```

**Impact:** In release builds, `developer.log` at level 800 still writes to the system log buffer on Android. For a heavy user who switches tabs dozens of times per session, this fills the log buffer with polling noise, making it harder to identify meaningful log entries from crash reports or support sessions.

**Fix Required:** Wrap all `developer.log` calls in `if (kDebugMode)` guards, or replace with the project's existing `logger` utility (used in `SocketService`) which already handles release suppression.

---

---

# QA Prompt 5 — Cache Implementation

---

## Critical Issues

---

### C1 — `CacheConfig` is missing the majority of QA Prompt 5 required constants

**File:** `lib/core/storage/cache_config.dart`

**Severity:** CRITICAL

**Issue:** Per QA Prompt 5, `CacheConfig` must define a specific set of constants. The current implementation is missing 7 of the 8 required constants. Only `pollingInterval` (as an approximate equivalent) exists; the rest are absent entirely.

**Code:**
```dart
class CacheConfig {
  static const Duration pollingInterval = Duration(seconds: 30); // ≈ polling only

  // MISSING required constants:
  // memoryCacheMaxSize = 50MB          ← absent
  // memoryCacheMaxEntries = 500        ← absent
  // hiveCacheMaxSize = 200MB           ← absent
  // staleCacheThreshold = 24h          ← absent
  // validCacheThreshold = 12h          ← absent
  // apiTimeout = 10s                   ← absent (set to 30s in AppConfig)
  // maxRetryAttempts = 4               ← absent
  // retryBaseDelay = 2s                ← absent
}
```

**Impact:** Every feature that should use standardized cache constants (`validCacheThreshold`, `staleCacheThreshold`) instead uses feature-specific hardcoded values. For example, `ProfileLocalDs._kCacheValidityHours = 24` is independent of `CacheConfig`. When the cache policy changes, all features must be updated individually.

**Fix Required:**
```dart
class CacheConfig {
  // Memory cache limits
  static const int memoryCacheMaxEntries = 500;
  static const int memoryCacheMaxSizeBytes = 50 * 1024 * 1024; // 50MB

  // Hive cache limits
  static const int hiveCacheMaxSizeBytes = 200 * 1024 * 1024; // 200MB

  // Cache validity thresholds
  static const Duration validCacheThreshold = Duration(hours: 12);
  static const Duration staleCacheThreshold = Duration(hours: 24);

  // Network timeouts
  static const Duration apiTimeout = Duration(seconds: 10);

  // Retry policy
  static const int maxRetryAttempts = 4;
  static const Duration retryBaseDelay = Duration(seconds: 2);
}
```

---

### C2 — No memory cache (L1) layer — every navigation re-fetches from Hive or API

**File:** All feature local data sources (`profile_local_ds.dart`, category, home, product_details)

**Severity:** CRITICAL

**Issue:** Per QA Prompt 5, the app must implement a 3-layer cache (L1 Memory → L2 Hive → L3 Network). No feature implements an in-memory cache layer. Every navigation to a previously visited screen triggers a Hive read (I/O operation) rather than returning the already-decoded Dart object from memory.

**Code:**
```dart
// Typical pattern across all features — no memory cache:
Future<CachedProfileResult?> getCachedProfile() async {
  final rawData = _box.get(_kProfileKey);  // always reads Hive, never memory
  // ...
}
```

**Impact:** Screen transitions between visited tabs incur unnecessary Hive read overhead. For the `IndexedStack` navigation pattern used in `BottomNavigation`, the same data is decoded from Hive on every tab switch even though it was already in memory seconds ago. Per QA Prompt 5 Scenario 4, a memory hit should return in 1–5ms with no I/O.

**Fix Required:** Add a `Map<String, dynamic>` in-memory cache (bounded by `CacheConfig.memoryCacheMaxEntries`) to each local data source. Check the in-memory map first on every get; only fall through to Hive on a cache miss.

---

## High Priority Issues

---

### H1 — No request deduplication — simultaneous calls to same endpoint make multiple network requests

**File:** `lib/core/network/api_client.dart`

**Severity:** HIGH

**Issue:** Per QA Prompt 5 Scenario 7, simultaneous calls to the same endpoint must return the same `Future` (deduplication pool / `RequestPool`). `ApiClient` has no `RequestPool`. If two providers both fetch `/api/auth/v1/profile/` on startup, two separate HTTP calls are made.

**Code:**
```dart
// No RequestPool — every call is independent:
Future<Response<T>> get<T>(String path, ...) async {
  final response = await dio.get<T>(path, ...);
  return response;
}
```

**Impact:** On app startup, multiple providers (profile, home, categories) all initialize simultaneously. Without deduplication, identical API calls are duplicated, inflating API server load and wasting bandwidth.

**Fix Required:** Add a `Map<String, Completer<Response>>` request pool to `ApiClient`. On a cache key match, return the existing `Completer.future`; remove the entry on completion or error.

---

### H2 — `CacheConfig.pollingInterval` is 30 seconds but spec requires exponential backoff with max 4 retries

**File:** `lib/core/storage/cache_config.dart:44`

**Severity:** HIGH

**Issue:** `pollingInterval` is a fixed 30-second interval. Per QA Prompt 5, network retries must use exponential backoff (4 attempts, +2s/+4s/+8s delays, max total 15s, 4xx errors not retried). The current implementation retries uniformly on a 30-second timer with no backoff, no attempt limit, and no 4xx error detection.

**Code:**
```dart
static const Duration pollingInterval = Duration(seconds: 30);
// No retryBaseDelay, no maxRetryAttempts, no backoff strategy
```

**Impact:** When a 4xx error occurs (e.g. session expired, invalid request), the polling continues indefinitely at 30-second intervals, sending invalid requests to the server every 30 seconds for the lifetime of the app session.

**Fix Required:** Add `maxRetryAttempts = 4` and `retryBaseDelay = Duration(seconds: 2)` to `CacheConfig`. Update all polling notifiers to use exponential backoff and stop retrying on 4xx errors.

---

### H3 — HTTP 304 Not Modified handling is inconsistent across features

**File:** `lib/features/profile/infrastructure/data_sources/remote/profile_api.dart:43–45` · `lib/features/category/infrastructure/` · `lib/features/product_details/infrastructure/`

**Severity:** HIGH

**Issue:** Per QA Prompt 5 Scenario 6, when a 304 is received: cached data must be returned, the access timestamp updated, and the `Last-Modified` value must NOT be changed. Profile API handles 304 by returning a `ProfileFetchResponse.notModified()` wrapper. However, the `Last-Modified` header from the original 200 response is never stored — `ProfileLocalDs` caches only `cachedAt`, not `lastModified`. This means `If-Modified-Since` can never be sent on subsequent requests because there is no stored `Last-Modified` value.

**Code:**
```dart
// profile_api.dart — Last-Modified extracted but never stored:
final lastModified = response.headers.value('last-modified') ...;
return ProfileFetchResponse(profile: ProfileDto.fromJson(data), lastModified: lastModified);

// profile_local_ds.dart — CacheDto has no lastModified field:
class ProfileCacheDto {
  final DateTime cachedAt;  // only tracks when we cached, not server's Last-Modified
  // no lastModified field
}
```

**Impact:** `If-Modified-Since` conditional requests cannot be used for profile fetches because the `Last-Modified` value is never persisted. Every background refresh makes a full unconditioned GET request regardless of whether the data changed. The bandwidth savings of 304 are lost.

**Fix Required:** Add `lastModified` to `ProfileCacheDto` and persist the value from the API response. Use it in `ProfileApi.fetchProfile({String? ifModifiedSince})` by passing the stored `lastModified` on background refreshes.

---

### H4 — No offline indicator shown when network is unavailable

**File:** `lib/core/network/connectivity_provider.dart` · All feature screens

**Severity:** HIGH

**Issue:** Per QA Prompt 5 Scenario 3, an offline mode must show a persistent offline indicator in the app bar when the network is unavailable. `ConnectivityProvider` correctly exposes a `StreamProvider` for connectivity status, but no screen or global widget subscribes to it to show an offline banner. The `network_status_banner.dart` widget exists in `core/widgets/` but is not mounted anywhere in the widget tree.

**Code:**
```dart
// connectivity_provider.dart — correctly implemented:
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) async* { ... });

// network_status_banner.dart — exists but is never used:
class NetworkStatusBanner extends ConsumerWidget { ... }

// No screen or shell widget mounts NetworkStatusBanner
```

**Impact:** Users who lose connectivity receive cryptic "Connection timeout" errors on next API call, with no proactive indication that they are offline. Per QA spec, the banner must appear immediately when connectivity is lost.

**Fix Required:** Mount `NetworkStatusBanner` in `BottomNavigation`'s `Scaffold` body wrapper so it appears on all four tabs when offline:
```dart
body: Column(
  children: [
    const NetworkStatusBanner(),
    Expanded(child: IndexedStack(index: _currentIndex, children: _pages)),
  ],
),
```

---

## Medium Priority Issues

---

### M1 — `CacheConfig.cacheTTL` (1 hour) conflicts with per-feature cache validity values

**File:** `lib/core/storage/cache_config.dart:54` vs `lib/features/profile/infrastructure/data_sources/local/profile_local_ds.dart:21`

**Severity:** MEDIUM

**Issue:** `CacheConfig.cacheTTL = 1 hour` is the global conditional-request metadata TTL. However, `ProfileLocalDs._kCacheValidityHours = 24` uses a different validity window. These two constants serve related but different purposes and there is no comment clarifying the distinction. A developer could easily use the wrong constant when adding a new feature.

**Code:**
```dart
// cache_config.dart:
static const Duration cacheTTL = Duration(hours: 1);

// profile_local_ds.dart:
static const int _kCacheValidityHours = 24;  // different threshold, no shared constant
```

**Impact:** Cache validity semantics are fragmented across files. Adding a new feature requires choosing between the two values with no documentation to guide the decision. The QA spec mandates a `validCacheThreshold = 12h` — neither of these matches.

**Fix Required:** Add `validCacheThreshold = 12h` and `staleCacheThreshold = 24h` to `CacheConfig` as specified. Replace `_kCacheValidityHours` in `ProfileLocalDs` with `CacheConfig.staleCacheThreshold.inHours`.

---

### M2 — No cache eviction policy — Hive can grow unbounded

**File:** `lib/core/storage/cache_config.dart`, all local data sources

**Severity:** MEDIUM

**Issue:** Per QA Prompt 5 Scenario 8, a Hive size monitor must run every 5 minutes and evict the oldest 20% of LRU entries when Hive exceeds 90% capacity (180MB of 200MB limit). There is no size monitoring, no LRU tracking, and no eviction logic anywhere in the codebase. Cached product metadata, category lists, and profile data accumulate indefinitely.

**Code:**
```dart
// No cache eviction anywhere
// CacheConfig has no hiveCacheMaxSize constant
// No size monitoring timer exists
```

**Impact:** On devices used heavily over weeks or months, the Hive cache grows without bound. Eventually the device runs low on storage, causing `HiveError` write failures that are silently swallowed. The user experiences degraded app performance with no actionable error.

**Fix Required:** Implement the Scenario 8 eviction policy: add `size` and `lastAccessed` fields to cache entries, add a periodic timer (every 5 minutes) in `AppBootstrap` that measures total Hive box sizes and triggers LRU eviction when over 180MB.

---

---

# QA Prompt 6 — Architecture Compliance (4-Layer Violations)

---

## Critical Issues

---

### C1 — `AppConfig` is a cross-layer god class — config, URLs, business logic, and CDN utilities mixed

**File:** `lib/core/config/app_config.dart`

**Layer:** Cross-layer

**Severity:** CRITICAL

**Issue:** `AppConfig` mixes four distinct responsibilities: environment flags (`isProduction`), network configuration (`apiBaseUrl`, timeouts), CDN URL transformation logic (`convertToCdnUrl`), and URL normalization utilities (`ensureHttps`, `getApiUrl`). Any layer that imports `AppConfig` gains a dependency on all of these.

**Code:**
```dart
class AppConfig {
  static const bool isProduction = false;        // environment config
  static const String apiBaseUrl = '...';         // network config
  static const Duration connectTimeout = ...;     // network config
  static String convertToCdnUrl(String url) { }  // business logic
  static String ensureHttps(String url) { }       // utility
  static String getApiUrl(String path) { }        // utility
}
```

**Impact:** Domain entities and infrastructure repositories that only need to call `AppConfig.convertToCdnUrl()` also gain a dependency on `apiBaseUrl` and `isProduction`. If `AppConfig` is mocked in tests, all of these concerns are mocked together. Violates single-responsibility and makes testing more complex.

**Fix Required:** Split into:
- `EnvironmentConfig` — `isProduction`, `isDevelopment` (build-flavor constants)
- `NetworkConfig` — `apiBaseUrl`, timeouts (network-layer only)
- `MediaUrlHelper` — `convertToCdnUrl()`, `ensureHttps()` (utility in `core/utils/`)

---

## High Priority Issues

---

### H1 — `ApiClient` is initialized imperatively in `AppBootstrap` and injected via `ProviderScope` override — not a Riverpod-native pattern

**File:** `lib/app/bootstrap/app_bootstrap.dart:52–55`

**Layer:** Application → Infrastructure boundary

**Severity:** HIGH

**Issue:** `ApiClient` requires async initialization (`await apiClient.init()`) before it can be used. It is constructed imperatively in `AppBootstrap._initialize()` and then injected via `ProviderScope.overrides` (implied, based on `apiClientProvider` throwing `UnimplementedError` if not overridden). This is not a standard Riverpod async initialization pattern and makes the initialization contract implicit.

**Code:**
```dart
static Future<AppBootstrapResult> _initialize() async {
  await HiveInit.initialize();
  final apiClient = ApiClient();
  await apiClient.init();  // must be awaited before use
  return AppBootstrapResult(apiClient: apiClient);
}
```

**Impact:** Any provider that reads `apiClientProvider` before the `ProviderScope` override is applied gets the `UnimplementedError`. The async initialization order is enforced by `AppBootstrap` convention, not by the type system.

**Fix Required:** Use a Riverpod `FutureProvider` for `ApiClient` initialization that properly handles the async lifecycle, or document the override contract explicitly with a `late` validator.

---

### H2 — `SocketService` is not connected to any Riverpod provider tree — lifecycle unmanaged

**File:** `lib/core/network/socket_service.dart`

**Layer:** Infrastructure (cross-layer)

**Severity:** HIGH

**Issue:** `SocketService` has no associated Riverpod provider. It must be instantiated, connected, and disposed outside the provider system. There is no evidence in `AppBootstrap` that `SocketService.connect()` is ever called. The socket infrastructure may never be connected in the running app.

**Code:**
```dart
class SocketService {
  // No associated Provider/Notifier
  // No call to .connect() visible in AppBootstrap or main.dart
}
```

**Impact:** If `SocketService.connect()` is never called, all socket functionality (real-time price/inventory/delivery updates) is silently inactive. The missing Riverpod registration means there is no lifecycle management — the socket is never disposed when the app goes to background or the user logs out.

**Fix Required:** Register `SocketService` as a `keepAlive` Riverpod provider. Call `connect()` inside the provider body and register `ref.onDispose(service.dispose)`. Wire `connect()` to fire after auth success via `ref.listen(authProvider, ...)`.

---

### H3 — `PollingManager` is a global singleton, not a Riverpod provider — bypasses the provider graph

**File:** `lib/core/polling/polling_manager.dart:31–43`

**Layer:** Application (singleton antipattern)

**Severity:** HIGH

**Issue:** `PollingManager` is implemented as a Dart singleton (`static final _instance`). Any code that calls `PollingManager.instance` bypasses Riverpod entirely. This makes it impossible to reset the polling manager between tests, inject a mock, or scope its lifecycle to the user's session.

**Code:**
```dart
class PollingManager {
  static final PollingManager _instance = PollingManager._internal();

  factory PollingManager() => _instance;

  static PollingManager get instance => _instance;
}

// Used directly throughout the app:
PollingManager.instance.setActiveFeature(featureName);
PollingManager.instance.pauseAllPolling();
```

**Impact:** Integration tests that involve tab switching cannot reset `PollingManager` state between tests — pollers from one test bleed into the next. The singleton persists across logout, retaining stale poller registrations for the previous user's session.

**Fix Required:** Convert to a `keepAlive` Riverpod `Notifier`:
```dart
@Riverpod(keepAlive: true)
PollingManager pollingManager(Ref ref) {
  final manager = PollingManager();
  ref.onDispose(manager.pauseAllPolling);
  return manager;
}
```
Replace all `PollingManager.instance` calls with `ref.read(pollingManagerProvider)`.

---

## Medium Priority Issues

---

### M1 — `HiveInit` is a static utility class — initialization state tracked with a static bool

**File:** `lib/app/bootstrap/hive_init.dart:11–29`

**Layer:** Infrastructure bootstrap

**Severity:** MEDIUM

**Issue:** `HiveInit._initialized` is a `static bool` that guards against double-initialization. While effective, this pattern means `HiveInit` state persists for the entire process lifetime. In integration tests, resetting Hive between test runs is impossible without process restart because `_initialized = true` persists and the second `HiveInit.initialize()` call returns early without reopening boxes.

**Code:**
```dart
class HiveInit {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;  // guard prevents re-init in tests
    // ...
    _initialized = true;
  }
}
```

**Impact:** Integration tests that need a fresh Hive state for each test scenario cannot use `HiveInit.initialize()` — they must manage Hive lifecycle manually, duplicating the initialization logic and risking divergence.

**Fix Required:** Add a `static Future<void> reset()` method (only call in tests) that sets `_initialized = false` and closes all boxes. Or convert to a Riverpod provider with `keepAlive: true` whose lifecycle is managed by the provider container.

---

### M2 — `Boxes` class uses `late` static fields — no compile-time safety on uninitialized access

**File:** `lib/core/storage/hive/boxes.dart:17–21`

**Layer:** Infrastructure

**Severity:** MEDIUM

**Issue:** Five box references are declared as `static late Box`. Accessing any of them before `Boxes.openHiveBoxes()` completes throws a `LateInitializationError`. The `late` pattern provides no compile-time safety and the error message is not user-friendly.

**Code:**
```dart
static late Box userBox;
static late Box addressBox;
static late Box cacheBox;
static late Box profileBox;
static late Box deliveryTrackingBox;
```

**Impact:** If any provider reads a box during startup before `HiveInit.initialize()` completes (due to async ordering issues), the error is `LateInitializationError: Field 'userBox' has not been initialized` — opaque and hard to trace in crash reports.

**Fix Required:** Replace `late` statics with nullable `Box?` statics with an explicit "not yet initialized" assertion, or gate all box accesses through `HiveInit._initialized`:
```dart
static Box get userBox {
  assert(HiveInit.isInitialized, 'Hive not yet initialized. Call HiveInit.initialize() first.');
  return _userBox!;
}
static Box? _userBox;
```
