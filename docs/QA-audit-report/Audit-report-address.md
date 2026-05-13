# Address Management — Code Audit Report

**Scope:** Address List (`/address-list`) · Address Form (add/edit) · Location Selection (from home)

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 6

**Date:** 2026-05-02

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 2 | 2 | 2 | 6 |
| Prompt 2 — Security & Data Persistence | 0 | 2 | 2 | 4 |
| Prompt 3 — Performance & Error Handling | 1 | 1 | 2 | 4 |
| Prompt 4 — Code Quality & Deployment | 1 | 2 | 4 | 7 |
| Prompt 6 — Architecture Compliance | 2 | 2 | 3 | 7 |
| **Total** | **6** | **9** | **13** | **28** |

---

## Top Blockers Before Any Production Release

1. **Application layer casts domain interface to concrete infrastructure class** — `address_provider.dart:63,119` — completely breaks dependency inversion and the domain contract.
2. **Three parallel address implementations with manual cross-provider sync** — no single source of truth for address selection; user A's `localSelectedAddressId` can bleed into user B's session.
3. **Sequential geocoding loop in `_searchLocation()`** — up to 5 blocking API calls in series make location search 2–5 seconds slower than necessary.
4. **`AddressModel` Hive adapter in `core/` imports auth feature domain entity** — creates an illegal cross-feature dependency in the shared core layer.
5. **`Navigator.push()` used instead of GoRouter** across all address screens, bypassing deep-link guards and redirect logic.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

---

### C1 — `ProfileAddressController` casts domain interface to concrete infrastructure class

**File:** `lib/features/address/application/providers/address_provider.dart:63, 119`

**Severity:** CRITICAL

**Issue:** `ProfileAddressController` stores the repository as `AddressRepository` (domain contract), then downcasts it to `AddressRepositoryImpl` at call sites to access infrastructure-only methods (`fetchAddressesWithCache`, `refreshAddressesFromApi`). These two methods do not exist on the domain `AddressRepository` interface. The application layer is tightly coupled to a concrete infrastructure class, completely breaking dependency inversion.

**Code:**
```dart
// fetchAddresses() — line 63
final repoImpl = _repository as AddressRepositoryImpl;
final result = await repoImpl.fetchAddressesWithCache();

// refreshAddresses() — line 119
final repoImpl = _repository as AddressRepositoryImpl;
final freshAddresses = await repoImpl.refreshAddressesFromApi();
```

**Impact:** The application layer cannot be tested with a mock repository because only `AddressRepositoryImpl` exposes these methods. Swapping the infrastructure implementation breaks the notifier at runtime with a `CastError`. The domain contract (`AddressRepository`) is effectively meaningless.

**Fix Required:** Promote `fetchAddressesWithCache()` and `refreshAddressesFromApi()` to the `AddressRepository` interface (or introduce a `CacheableAddressRepository` sub-interface), then have the notifier call only interface methods.

```dart
// In AddressRepository (domain):
Future<AddressFetchResult> fetchAddressesWithCache();
Future<List<Address>?> refreshAddressesFromApi();

// In ProfileAddressController:
AddressRepository get _repository => ref.read(profileAddressRepositoryProvider);
final result = await _repository.fetchAddressesWithCache(); // no cast needed
```

---

### C2 — Business logic and cross-provider synchronisation inside a widget event handler

**File:** `lib/features/address/presentation/screens/address_list_screen.dart:351–395`

**Severity:** CRITICAL

**Issue:** `_handleSelectAddress()` manually performs entity conversion (`Address` → `UserAddress`), then calls three separate providers to synchronise state (`profileAddressControllerProvider`, `homeProvider`, `addressControllerProvider`). This is business logic — cross-domain coordination — placed inside a widget method, violating Rule 6 (business logic in widget build methods) and Rule 11 (navigation/UI side effects orchestrated outside providers).

**Code:**
```dart
Future<void> _handleSelectAddress(String id) async {
    final selectedAddress = await ref
        .read(profileAddressControllerProvider.notifier)
        .selectAddress(id);

    // Entity conversion done in widget
    final userAddress = UserAddress(
        id: int.tryParse(selectedAddress.id) ?? 0,
        firstName: selectedAddress.firstName,
        // ...
    );

    // Three separate providers manually synced from widget
    ref.read(homeProvider.notifier).updateAddressInState(userAddress);
    final addressId = int.tryParse(selectedAddress.id);
    if (addressId != null) {
        ref.read(addressControllerProvider.notifier).selectAddress(addressId);
    }
}
```

**Impact:** Any change to the address selection flow (e.g., adding a fourth provider) requires editing widget code. The home header and cart can fall out of sync if one of the three calls fails after the first has already succeeded. There is no transactional guarantee across the three mutations.

**Fix Required:** Move all cross-provider coordination into `ProfileAddressController.selectAddress()`. The notifier already holds `ref` and can read `homeProvider` and `addressControllerProvider` internally. The widget should only call `selectAddress(id)` and observe the result state.

---

## High Priority Issues

---

### H1 — `locationProvider` uses deprecated `StateNotifier` / `StateNotifierProvider`

**File:** `lib/core/location/location_provider.dart:32, 134`

**Severity:** HIGH

**Issue:** `LocationNotifier extends StateNotifier<LocationState>` and `locationProvider = StateNotifierProvider<LocationNotifier, LocationState>` use the Riverpod 1.x legacy API. Riverpod 2+ replaced this with `Notifier` / `NotifierProvider`. The legacy API does not support `ref` inside the notifier body without passing it via the constructor.

**Code:**
```dart
class LocationNotifier extends StateNotifier<LocationState> {
    final LocationService _locationService;

    LocationNotifier({LocationService? locationService})
        : _locationService = locationService ?? LocationService.instance,
          super(const LocationState.initial());
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
    (ref) => LocationNotifier(),
);
```

**Impact:** `LocationNotifier` cannot access `ref` to watch other providers (e.g., connectivity). It also uses a hardcoded `LocationService.instance` singleton instead of receiving it via provider injection, making the notifier untestable.

**Fix Required:** Migrate to `Notifier<LocationState>` / `NotifierProvider`. Pass `LocationService` through `ref.read(locationServiceProvider)` inside `build()`.

---

### H2 — `ref.watch(profileControllerProvider)` watched but result never used

**File:** `lib/features/address/presentation/screens/address_form_screen.dart:89`

**Severity:** HIGH

**Issue:** `ref.watch(profileControllerProvider)` is called inside `build()` and its result is silently discarded. The comment acknowledges this: `// Profile state watched for reactivity, not directly used`. Watching a provider only to trigger a rebuild is an anti-pattern — it causes the entire `AddressFormScreen` to rebuild on every `ProfileState` change, even unrelated ones (profile photo update, name change, etc.).

**Code:**
```dart
@override
Widget build(BuildContext context) {
    final addressState = ref.watch(profileAddressControllerProvider);
    // Profile state watched for reactivity, not directly used
    ref.watch(profileControllerProvider);
```

**Impact:** Any profile state change (even unrelated mutations like updating the avatar) rebuilds the entire address form, discarding in-progress text field focus state and potentially resetting the UI.

**Fix Required:** Remove `ref.watch(profileControllerProvider)` from `build()`. In `_handleSave()`, use `ref.read(profileControllerProvider)` (already correct — line 342) to get the profile data at save time. No rebuild is needed for profile state changes on this screen.

---

## Medium Priority Issues

---

### M1 — `profileAddressControllerProvider` missing `autoDispose`

**File:** `lib/features/address/application/providers/address_provider.dart:38–41`

**Severity:** MEDIUM

**Issue:** The provider is a non-global, screen-scoped controller (used only by profile address screens), yet it is not `autoDispose`. The address list data, error messages, and `localSelectedAddressId` all persist in memory indefinitely after the user navigates away from the address section.

**Code:**
```dart
final profileAddressControllerProvider =
    NotifierProvider<ProfileAddressController, AddressState>(
      ProfileAddressController.new,
    );
```

**Impact:** `localSelectedAddressId` accumulated in one user session will survive indefinitely and can incorrectly override the backend's selection state on future visits. Memory is also consumed by a cached address list that is no longer displayed.

**Fix Required:** Change to `NotifierProvider.autoDispose<ProfileAddressController, AddressState>(...)`. If address selection state must survive navigation within a session, scope the provider to the relevant `ProviderScope` subtree rather than keeping it alive globally.

---

### M2 — `AddressState` missing `==` and `hashCode` — causes unnecessary widget rebuilds

**File:** `lib/features/address/application/states/address_state.dart`

**Severity:** MEDIUM

**Issue:** `AddressState` is a plain Dart class with no `==` override. Riverpod uses `==` to decide whether to notify listeners. Without it, even `copyWith()` calls that produce logically identical state will trigger rebuilds on all `ref.watch(profileAddressControllerProvider)` callers.

**Code:**
```dart
class AddressState {
    const AddressState({
        required this.status,
        // ...
    });
    // No == override
    // No hashCode override
}
```

**Impact:** Every `state = state.copyWith(...)` call triggers a full widget rebuild even if all field values are unchanged. This causes visible jitter on screens with complex build trees.

**Fix Required:** Add `==` and `hashCode` overrides, or use `package:equatable` / `package:freezed` to generate them automatically.

---

---

# QA Prompt 2 — Security & Data Persistence

---

## High Priority Issues

---

### SEC-H1 — `localSelectedAddressId` persists in-memory after logout; survives user switching

**File:** `lib/features/address/application/providers/address_provider.dart:38–41, 312–336`

**Severity:** HIGH

**Issue:** `profileAddressControllerProvider` is not `autoDispose` and not explicitly invalidated during the logout flow. The `logout()` method on the notifier resets state to `AddressState.initial()` — but only if something calls `ref.read(profileAddressControllerProvider.notifier).logout()`. If the auth logout flow does not invoke this, `localSelectedAddressId` (the local override that bypasses the backend's `selected` flag) persists in memory. User B logging in on the same device will see the wrong address pre-selected.

**Code:**
```dart
/// Track locally selected address to override buggy API during refresh
final String? localSelectedAddressId;
```

**Impact:** User B sees User A's selected delivery address. Incorrect address shown in cart and home header. This is a data isolation failure between user sessions (Prompt 2 Rule 12).

**Fix Required:** Either mark the provider `autoDispose`, or ensure the auth logout notifier calls `ref.invalidate(profileAddressControllerProvider)` so the state is fully reset on logout.

---

### SEC-H2 — `AddressModel` Hive adapter in `core/` imports auth feature's domain entity

**File:** `lib/core/storage/hive/adapters/address.dart:4`

**Severity:** HIGH

**Issue:** The shared core Hive adapter imports directly from a specific feature's domain layer:

**Code:**
```dart
import '../../../../features/auth/domain/entities/address.dart';
```

The `core/` layer is a shared infrastructure utility. It must not depend on any feature's domain entities. This creates a circular coupling: `auth` feature → `core/hive/adapters` → `auth` feature domain entity. If the `auth` feature's `AddressEntity` is refactored or removed, the shared adapter breaks.

Furthermore, `AddressModel` converts to/from `AddressEntity` (auth), yet the address management feature uses a completely different entity `Address` (address feature domain) — the adapter is effectively unused by the address management screens, making this dead code with dangerous import side-effects.

**Impact:** Core layer is polluted by feature-specific knowledge. Any renaming or restructuring of `AddressEntity` breaks Hive adapter compilation. The `AddressTypeAdapter` (typeId = 2) and `AddressModelAdapter` (typeId = 1) are registered globally but not used by the address feature screens — wasted TypeAdapter registrations.

**Fix Required:** Move `AddressModel` and its adapter into `lib/features/auth/infrastructure/local/` where it belongs. Core adapters should only contain truly shared, feature-agnostic models. Update `hive_registrar.g.dart` accordingly.

---

## Medium Priority Issues

---

### SEC-M1 — Silent `catch (_)` in `getCachedAddresses()` hides programming errors

**File:** `lib/features/address/infrastructure/data_sources/local/address_local_ds.dart:49–53`

**Severity:** MEDIUM

**Issue:** The entire JSON deserialization block is wrapped in a catch-all that discards the exception type, message, and stack trace. Any programming error (bad type cast, null dereference, missing key) is treated identically to a genuine Hive corruption, and returns `null` silently.

**Code:**
```dart
} catch (_) {
    // If data is corrupted, return null but don't delete
    return null;
}
```

**Impact:** Bugs in `AddressCacheDto.fromJson()` or the cache map structure are invisible during development and testing. The symptom is "always fetches from API" with no log trace to explain why.

**Fix Required:** At minimum, log the exception before swallowing it:

```dart
} catch (e, stack) {
    debugPrint('[AddressLocalDs] Cache read failed: $e\n$stack');
    return null;
}
```

---

### SEC-M2 — Debug method `fetchSelectedAddress()` left in production `AddressApi`

**File:** `lib/features/address/infrastructure/data_sources/remote/address_api.dart:148–167`

**Severity:** MEDIUM

**Issue:** A method explicitly annotated as `// DEBUG: Used to verify backend behavior` remains in the production API class. It is not called from any provider or notifier, but it exists in the build.

**Code:**
```dart
/// Fetches the selected address using ?selected=true filter
/// DEBUG: Used to verify backend behavior
Future<AddressDto?> fetchSelectedAddress() async {
```

**Impact:** Dead code in infrastructure layer. Increases APK size marginally and creates confusion about whether the endpoint is actually used. Risk of accidentally wiring it to a UI element in future.

**Fix Required:** Remove the method entirely, or move it to a separate `AddressApiDebug` class excluded from release builds.

---

---

# QA Prompt 3 — Performance & Error Handling

---

## Critical Issues

---

### PERF-C1 — Sequential geocoding loop in `_searchLocation()` — up to 5 blocking API calls in series

**File:** `lib/features/home/presentation/components/location_selection_screen.dart:254–285`

**Severity:** CRITICAL

**Issue:** After calling `locationFromAddress(query)`, the code iterates through the first 5 results and calls `placemarkFromCoordinates()` for each one **sequentially** inside an `await` loop. Each geocoding call can take 100–500 ms over a network connection. For 5 results, this can block the search response for 2.5 seconds or more.

**Code:**
```dart
for (final location in locations.take(5)) {
    try {
        final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
        );
```

**Impact:** Location search feels sluggish or unresponsive on slow network connections. Users may abandon address entry. The loading spinner runs for the entire sequential duration.

**Fix Required:** Run all reverse geocoding calls in parallel with `Future.wait()`:

```dart
final futures = locations.take(5).map((location) async {
    try {
        final placemarks = await placemarkFromCoordinates(
            location.latitude, location.longitude,
        );
        if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            return _SearchResult(
                title: place.locality ?? place.name ?? query,
                subtitle: _formatAddress(place),
                position: LatLng(location.latitude, location.longitude),
            );
        }
    } catch (_) {
        return _SearchResult(
            title: query,
            subtitle: '${location.latitude.toStringAsFixed(4)}, ...',
            position: LatLng(location.latitude, location.longitude),
        );
    }
    return null;
});
final results = (await Future.wait(futures)).whereType<_SearchResult>().toList();
```

---

## High Priority Issues

---

### PERF-H1 — `rethrow` in `refreshAddresses()` propagates unhandled exception through `RefreshIndicator`

**File:** `lib/features/address/application/providers/address_provider.dart:158–164`

**Severity:** HIGH

**Issue:** `refreshAddresses()` catches the error, updates state, then re-throws. The widget calls this from `RefreshIndicator.onRefresh`:

```dart
// address_list_screen.dart:93-97
onRefresh: () async {
    await ref
        .read(profileAddressControllerProvider.notifier)
        .refreshAddresses();
},
```

`RefreshIndicator.onRefresh` is an async callback. If the returned Future completes with an error, Flutter's `RefreshIndicator` will call `FlutterError.onError`. Depending on the error handler, this silently dismisses the indicator with no user feedback beyond the `errorMessage` already set in state — but the `errorMessage` is only displayed when `!addressState.hasData`, so users who already have data never see the error from a failed pull-to-refresh.

**Code:**
```dart
} catch (error) {
    final message = _mapError(error);
    state = state.copyWith(errorMessage: message);
    rethrow; // propagated to RefreshIndicator
}
```

**Impact:** Pull-to-refresh failures are silently swallowed for users who already have a loaded address list. The refresh spinner dismisses with no indication of failure.

**Fix Required:** Either remove the `rethrow` and show the error via `AppSnackbar` in the notifier (violation — see Prompt 6), or catch the exception explicitly in the `onRefresh` callback and display a snackbar from the widget:

```dart
onRefresh: () async {
    try {
        await ref.read(profileAddressControllerProvider.notifier).refreshAddresses();
    } catch (_) {
        if (mounted) AppSnackbar.error(context, 'Failed to refresh addresses');
    }
},
```

---

## Medium Priority Issues

---

### PERF-M1 — `ListView` with eager `.map()` instead of `ListView.builder`

**File:** `lib/features/address/presentation/screens/address_list_screen.dart:101–305`

**Severity:** MEDIUM

**Issue:** The address list is built with `ListView(children: [...addressState.addresses.map(...)])`. All address tiles are constructed eagerly in memory regardless of how many are off-screen.

**Code:**
```dart
ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: EdgeInsets.all(16.w),
    children: [
        if (addressState.isStale) ...[/* stale banner */],
        if (addressState.addresses.isEmpty) ...[/* empty state */]
        else ...addressState.addresses.map(
            (address) => GestureDetector(...)
        ),
    ],
)
```

**Impact:** Low risk today (typical users have 2–5 addresses), but the pattern does not scale. If the app supports business accounts with many delivery addresses, this will cause jank on initial render.

**Fix Required:** Use `ListView.builder` for the address items. The stale banner and empty state can be handled with a `SliverList` + `SliverToBoxAdapter` in a `CustomScrollView`, or simply by inserting them as index 0 in the builder.

---

### PERF-M2 — No client-side validation for latitude/longitude values in `AddressFormScreen`

**File:** `lib/features/address/presentation/screens/address_form_screen.dart:362–373`

**Severity:** MEDIUM

**Issue:** When no map location has been picked and `locationProvider` is not loaded, `latitude` and `longitude` remain `null`. The address is saved to the backend without coordinates. No user message is shown. Additionally, there is no validation that the string precision matches the backend constraint (`max_digits=9, decimal_places=6`).

**Code:**
```dart
if (latitude == null || longitude == null) {
    final locationState = ref.read(locationProvider);
    locationState.mapOrNull(
        loaded: (state) {
            latitude = state.location.latitude.toStringAsFixed(6);
            longitude = state.location.longitude.toStringAsFixed(6);
        },
    );
    // If still null here — silently saved without coordinates
}
```

**Impact:** Addresses saved without coordinates may not be usable for route calculation or delivery tracking. Users do not know their location data is missing.

**Fix Required:** After attempting to populate coordinates, check if they are still null and either (a) show an inline warning but allow saving, or (b) prompt the user to enable location services or use the map picker.

---

---

# QA Prompt 4 — Code Quality & Deployment

---

## Critical Issues

---

### QUAL-C1 — Three parallel address implementations with manual, fragile cross-provider synchronisation

**File:** `lib/features/auth/...` · `lib/features/address/...` · `lib/features/cart/...`

**Severity:** CRITICAL

**Issue:** Three entirely separate address feature stacks exist side by side with no shared domain:

| Layer | Auth address | Profile address | Cart address |
|---|---|---|---|
| Entity | `AddressEntity` (int id, `AddressType` enum) | `Address` (String id, String? addressType) | `Address` (separate class) |
| Repository | `AuthRepository.addAddress()` | `AddressRepository` | `CartAddressRepository` |
| State | `AddressState` (sealed class) | `AddressState` (enum-based) | `AddressState` (separate) |
| Controller | `AddressEntry` | `ProfileAddressController` | `AddressController` |

Address selection made in the profile screen requires the widget (`_handleSelectAddress`) to manually call three different providers: `profileAddressControllerProvider`, `homeProvider`, and `addressControllerProvider`. There is no single source of truth for which address is the user's active delivery address.

**Code:**
```dart
// Three separate syncs from a single widget handler:
ref.read(homeProvider.notifier).updateAddressInState(userAddress);
ref.read(addressControllerProvider.notifier).selectAddress(addressId);
// + the original selectAddress call on profileAddressControllerProvider
```

**Impact:** Any one of the three calls can fail independently, leaving providers in inconsistent state. Bug fixes must be applied in three places. Testing any address flow requires mocking three different provider stacks.

**Fix Required:** Consolidate into a single shared `AddressRepository` and `Address` entity in a common domain or shared feature. The `homeProvider` and `addressControllerProvider` should observe a single `selectedAddressProvider` rather than requiring explicit `updateAddressInState()` calls.

---

## High Priority Issues

---

### QUAL-H1 — `int.tryParse()` failure silently skips cart address synchronisation

**File:** `lib/features/address/presentation/screens/address_list_screen.dart:383–385`

**Severity:** HIGH

**Issue:** If `selectedAddress.id` is not a valid integer string (e.g., a UUID or a malformed backend response), `int.tryParse()` returns `null` and the entire cart address provider sync is silently skipped. No error is surfaced to the user.

**Code:**
```dart
final addressId = int.tryParse(selectedAddress.id);
if (addressId != null) {
    ref.read(addressControllerProvider.notifier).selectAddress(addressId);
}
// If addressId is null: cart address is not updated, no feedback
```

**Impact:** After selecting an address in the profile screen, the cart checkout will silently use the old (or no) address. The bug only appears when the user proceeds to checkout, making it very hard to trace back to the address selection step.

**Fix Required:** Add a fallback and user-visible error if the ID cannot be parsed. Alternatively, the ID type mismatch between the three address systems (`String` in profile, `int` in cart) should be eliminated by using a consistent type.

---

### QUAL-H2 — All address screen navigation uses imperative `Navigator.push()` instead of GoRouter

**File:** `lib/features/address/presentation/screens/address_list_screen.dart:238–248, 314–323` · `lib/features/home/presentation/components/location_selection_screen.dart:360–367`

**Severity:** HIGH

**Issue:** GoRouter is configured as the app's routing system (with auth guards and deep-link support), but all address-related navigation uses direct `Navigator.push()` with `MaterialPageRoute`. This bypasses:
- GoRouter's authentication redirect guards
- Deep-linking (external URIs cannot navigate to `/address-list`)
- Analytics route tracking

**Code:**
```dart
// address_list_screen.dart:238
final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
        builder: (_) => AddressFormScreen(address: address),
    ),
);

// location_selection_screen.dart:361
final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute<bool>(
        builder: (context) => AddressFormScreen(selectedLocation: selectedLocation),
    ),
);
```

**Impact:** `AddressFormScreen` and `LocationSelectionScreen` are invisible to GoRouter. If a user is unauthenticated and somehow reaches this route, the auth guard does not fire. Analytics cannot observe these transitions.

**Fix Required:** Add named routes to `app_router.dart` for `AddressFormScreen` and `LocationSelectionScreen` and navigate with `context.push('/address-form')` / `context.push('/location-selection')`, passing parameters via `extra` or path params.

---

## Medium Priority Issues

---

### QUAL-M1 — `developer.log()` polling statements left in production code

**File:** `lib/features/cart/application/providers/address_providers.dart:189–192, 200–203`

**Severity:** MEDIUM

**Issue:** Multiple `developer.log()` calls output internal polling state to the console in production builds. While `developer.log()` is more controlled than `print()`, it still exposes polling cadence and server response codes in release logs.

**Code:**
```dart
developer.log(
    'Polling addresses: 304 Not Modified (no UI update)',
    name: 'AddressController',
);
developer.log(
    'Polling addresses: 200 OK (UI updated)',
    name: 'AddressController',
);
```

**Impact:** Internal implementation details are visible in release builds. On some platforms, `developer.log()` output can appear in system logs accessible to other apps.

**Fix Required:** Wrap in `kDebugMode` check or use a centralised logger that strips output in release builds.

---

### QUAL-M2 — Magic numbers for FAB positioning in `LocationSelectionScreen`

**File:** `lib/features/home/presentation/components/location_selection_screen.dart:535–539`

**Severity:** MEDIUM

**Issue:** The current location button and zoom controls are positioned using hardcoded `200.h` and `270.h` values that are tightly coupled to the height of the bottom confirmation sheet. If the sheet height changes, the buttons will either overlap the sheet or float too high.

**Code:**
```dart
Positioned(right: 16.w, bottom: 200.h, child: _buildCurrentLocationButton()),
Positioned(right: 16.w, bottom: 270.h, child: _buildZoomControls()),
```

**Impact:** UI breaks if the bottom sheet content grows (e.g., adding a second line of address info). Cannot respond dynamically to different device sizes or text scale.

**Fix Required:** Calculate the button positions relative to the actual bottom sheet height, or use a `Stack` with `LayoutBuilder` to measure the sheet height at runtime.

---

### QUAL-M3 — No user feedback when coordinates are unavailable at address save time

**File:** `lib/features/address/presentation/screens/address_form_screen.dart:358–373`

**Severity:** MEDIUM

**Issue:** If location permission is denied and no map location was selected, `latitude` and `longitude` silently remain `null` when the user taps "Done". The address is saved to the backend without geolocation data and the user receives no indication that their address is missing coordinates.

**Code:**
```dart
String? latitude = _selectedLatitude;
String? longitude = _selectedLongitude;

if (latitude == null || longitude == null) {
    final locationState = ref.read(locationProvider);
    locationState.mapOrNull(
        loaded: (state) {
            latitude = state.location.latitude.toStringAsFixed(6);
            longitude = state.location.longitude.toStringAsFixed(6);
        },
    );
}
// latitude/longitude may still be null — no user warning
```

**Impact:** Delivery tracking and routing may fail for addresses without coordinates. Users may discover the problem only at the point of ordering.

**Fix Required:** After the null-check, display a non-blocking warning if coordinates are unavailable: `"Location not pinned — delivery accuracy may be lower"`. Optionally block save and direct the user to pick a location on the map.

---

### QUAL-M4 — Hardcoded colour constants in `LocationSelectionScreen` bypass app theme

**File:** `lib/features/home/presentation/components/location_selection_screen.dart:84–85`

**Severity:** MEDIUM

**Issue:** Two colour constants are hardcoded inside the widget class rather than referencing `AppColors`:

**Code:**
```dart
static const Color _primaryGreen = Color(0xFF0b6866);
static const Color _lightGreen = Color(0xFFcaf5ac);
```

**Impact:** If the brand colour changes, this screen will not update automatically. The duplication also risks the two green values drifting apart from the design system over time.

**Fix Required:** Replace with `AppColors.green` and `AppColors.green10` (or whatever the equivalent light green token is in the existing `AppColors` class).

---

---

# QA Prompt 6 — Architecture Compliance

---

## Critical Issues

---

### ARCH-C1 — Application layer accesses infrastructure-only methods via downcast (same as State-C1, repeated for arch context)

**File:** `lib/features/address/application/providers/address_provider.dart:63, 119`

**Layer:** Application → Infrastructure (direct boundary violation)

**Severity:** CRITICAL

**Rule Violated:** Rule 5 — Application layer imports/calls infrastructure directly; Rule 12 — StateNotifier holds reference to implementation not domain contract.

**Issue:** `ProfileAddressController` calls `_repository as AddressRepositoryImpl` to reach `fetchAddressesWithCache()` and `refreshAddressesFromApi()` which are not part of the domain `AddressRepository` interface. This is a hard Application → Infrastructure boundary violation.

**Code:**
```dart
final repoImpl = _repository as AddressRepositoryImpl;
final result = await repoImpl.fetchAddressesWithCache();
```

**Fix Required:** Add these two methods to `AddressRepository` (domain interface) so the controller calls only the contract. See C1 in Prompt 1 for the full fix.

---

### ARCH-C2 — `AddressModel` in `core/hive/adapters/` imports auth feature domain entity

**File:** `lib/core/storage/hive/adapters/address.dart:4`

**Layer:** Core → Feature domain (illegal upward dependency)

**Severity:** CRITICAL

**Rule Violated:** Rule 6 — Domain layer (or here, core) must not import from feature-specific infrastructure or application layers.

**Issue:** The shared `core/` Hive adapter directly imports `AddressEntity` from `lib/features/auth/domain/entities/address.dart`. Core utilities must be dependency-free from all feature domains.

**Code:**
```dart
import '../../../../features/auth/domain/entities/address.dart';

@HiveType(typeId: 1)
class AddressModel {
    // ...
    factory AddressModel.fromEntity(AddressEntity e) { ... }
    AddressEntity toEntity() { ... }
}
```

**Impact:** A change to `AddressEntity` in the auth domain breaks the core Hive adapter. The `core/` layer cannot be reused in other projects without dragging the auth feature along.

**Fix Required:** Move `AddressModel` and `AddressTypeAdapter` to `lib/features/auth/infrastructure/data_sources/local/` alongside the auth local data source that actually uses them.

---

## High Priority Issues

---

### ARCH-H1 — Three parallel `Address` domain entities with no shared definition

**File:** `lib/features/auth/domain/entities/address.dart` · `lib/features/address/domain/entities/address.dart` · `lib/features/cart/domain/entities/address.dart`

**Layer:** Cross-feature domain

**Severity:** HIGH

**Rule Violated:** Rule 18 — Feature folder does not follow the 4-layer structure (implied: shared domain concepts should not be duplicated).

**Issue:** The same real-world concept (a user delivery address) is modelled three times with inconsistent field types:
- Auth `AddressEntity`: `int id`, `AddressType` enum, no `postalCode`, no `country`
- Address `Address`: `String id`, `String? addressType`, full fields including `postalCode` and `country`
- Cart `Address`: separate class, `int id`, different field set

**Impact:** Any feature interaction requires manual entity conversion at the widget layer (as seen in `_handleSelectAddress`). The three definitions are guaranteed to diverge over time as each feature team adds fields independently.

**Fix Required:** Define a single `Address` domain entity in a shared package (`lib/shared/domain/entities/address.dart`) and import it from all three features. Use feature-specific DTOs for API mapping only.

---

### ARCH-H2 — `logout()` method on `AddressRepository` is an auth concern, not an address concern

**File:** `lib/features/address/domain/repositories/address_repository.dart:51`

**Layer:** Domain

**Severity:** HIGH

**Rule Violated:** Rule 9 — Abstract domain repository contains implementation-level concerns inside its contract.

**Issue:** The `AddressRepository` domain interface declares `logout()` — a session management operation — as part of the address domain contract. Domain contracts should only describe business operations on the aggregate they own.

**Code:**
```dart
abstract class AddressRepository {
    // ...
    /// Clears all cached addresses on logout
    Future<void> logout();
}
```

**Impact:** Any implementation of `AddressRepository` is forced to know about session lifecycle. A future read-only address repository (e.g., for a guest browsing mode) must still implement `logout()` even if it has no cache to clear.

**Fix Required:** Remove `logout()` from `AddressRepository`. Handle cache clearing on logout via the `Boxes.clearUserDataOnly()` utility that already exists, called from the auth logout notifier directly.

---

## Medium Priority Issues

---

### ARCH-M1 — Domain entity `Address` contains presentation-layer formatting methods

**File:** `lib/features/address/domain/entities/address.dart:36–53`

**Layer:** Domain

**Severity:** MEDIUM

**Rule Violated:** Rule 8 — Domain entity contains UI logic.

**Issue:** The `Address` entity exposes three computed getters that perform string formatting for UI display: `fullName`, `fullAddress`, and `addressTypeLabel`. The `addressTypeLabel` getter specifically capitalises a string for display purposes — a pure UI concern.

**Code:**
```dart
String get fullName => '$firstName $lastName';

String get fullAddress {
    final parts = <String>[...];
    return parts.join(', ');
}

String get addressTypeLabel {
    if (addressType == null || addressType!.isEmpty) return 'Other';
    return addressType![0].toUpperCase() + addressType!.substring(1);
}
```

**Impact:** UI formatting logic is coupled into the domain. If the display format changes (e.g., showing state before city), the domain entity must be edited.

**Fix Required:** Move display formatting to a presentation-layer extension or a separate `AddressFormatter` utility class. The domain entity should only expose raw data fields.

---

### ARCH-M2 — `LocationSelectionScreen` (home feature) directly imports `AddressFormScreen` (address feature)

**File:** `lib/features/home/presentation/components/location_selection_screen.dart:11`

**Layer:** Cross-feature Presentation

**Severity:** MEDIUM

**Rule Violated:** Rule 4 — Presentation layer accesses another feature's presentation directly.

**Issue:** A component in the `home` feature's presentation layer directly imports and instantiates a screen from the `address` feature's presentation layer.

**Code:**
```dart
import '../../../address/presentation/screens/address_form_screen.dart';

// ...
final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute<bool>(
        builder: (context) => AddressFormScreen(selectedLocation: selectedLocation),
    ),
);
```

**Impact:** The `home` feature cannot be developed or tested independently of the `address` feature. Adding `AddressFormScreen` constructor parameters requires changing `LocationSelectionScreen` in a different feature.

**Fix Required:** Navigate using a named GoRouter route (`context.push('/address-form', extra: selectedLocation)`) instead of directly constructing the screen. The `home` feature should only know the route name, not the widget class.

---

### ARCH-M3 — `AddressListScreen` reads providers from two foreign features inside the presentation layer

**File:** `lib/features/address/presentation/screens/address_list_screen.dart:8–10`

**Layer:** Cross-feature Presentation → Application

**Severity:** MEDIUM

**Rule Violated:** Rule 4 — Presentation layer accesses infrastructure of other features.

**Issue:** `AddressListScreen` (address feature presentation) directly reads and mutates `homeProvider` (home feature application) and `addressControllerProvider` (cart feature application). Cross-feature provider reads from the presentation layer should go through a mediating use case or a shared event bus, not direct `ref.read()` into another feature's notifier.

**Code:**
```dart
import '../../../cart/application/providers/address_providers.dart';
import '../../../home/application/providers/home_provider.dart';
import '../../../home/domain/entities/user_address.dart';

// In widget:
ref.read(homeProvider.notifier).updateAddressInState(userAddress);
ref.read(addressControllerProvider.notifier).selectAddress(addressId);
```

**Impact:** The address feature is now coupled to both the home and cart features at the widget level. Testing `AddressListScreen` requires mocking providers from three different features.

**Fix Required:** Extract cross-feature coordination into a `SelectAddressUseCase` or a shared `SelectedAddressNotifier` that the home and cart providers observe reactively. The widget only calls `selectedAddressProvider.notifier.select(id)` and the downstream providers react automatically.

---

---

## Architecture Health Report

| Layer | Files Audited | Critical | High | Medium | Status |
|-------|---------------|----------|------|--------|--------|
| Domain | 2 | 0 | 1 | 2 | FAIL |
| Infrastructure | 4 | 1 | 1 | 1 | FAIL |
| Application | 2 | 1 | 2 | 2 | FAIL |
| Presentation | 3 | 1 | 2 | 3 | FAIL |
| Cross-layer boundaries | — | 2 | 2 | 2 | FAIL |
| Hive model integrity | 2 | 1 | 1 | 0 | FAIL |

---

## Technical Debt Score: 4 / 10

**Justification:**
- The 4-layer folder structure is present and named correctly — infrastructure is recognisable.
- Individual layers are mostly internally clean (state uses `copyWith`, entities have `final` fields, Hive is accessed via pre-opened boxes).
- However, the downcast from domain interface to infrastructure concrete class (C1) is a fundamental breach of the architecture that makes the domain contract meaningless.
- Three parallel address domain entities with manual widget-level synchronisation mean every address-related bug must be tracked through three separate stacks.
- `LocationSelectionScreen` mixes home and address feature concerns at the presentation layer, creating a web of imports that make individual feature testing impossible.
- GoRouter is bypassed for all address navigation, removing deep-link support and auth guard enforcement for these screens.
