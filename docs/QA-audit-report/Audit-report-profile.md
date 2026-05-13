# Profile & Account — Code Audit Report

**Scope:** Profile View (`/profile`) · Profile Edit · Contact Us

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 6

**Date:** 2026-05-02

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 1 | 2 | 1 | 4 |
| Prompt 2 — Security & Data Persistence | 2 | 1 | 1 | 4 |
| Prompt 3 — Performance & Error Handling | 1 | 2 | 2 | 5 |
| Prompt 4 — Code Quality & Deployment | 2 | 3 | 3 | 8 |
| Prompt 6 — Architecture Compliance | 2 | 3 | 2 | 7 |
| **Total** | **8** | **11** | **9** | **28** |

---

## Top Blockers Before Any Production Release

1. **Contact Us form is entirely fake** — `contact_us_screen.dart:40` — `_sendMessage()` uses `Future.delayed` as a simulation; no message is ever sent to any backend. Users are deceived into thinking their support request was submitted.
2. **No navigation after account deletion** — `profile_edit_screen.dart:421` — navigation to login screen is commented out. User is stranded on the edit screen after permanently deleting their account.
3. **Application layer breaks domain contract** — `profile_provider.dart:52–53, 81, 101` — `ProfileController` casts `ProfileRepository` to `ProfileRepositoryImpl` to call methods not on the interface. Application layer is tightly coupled to infrastructure.
4. **Hive accessed directly in application layer** — `profile_provider.dart:14` — `Hive.box()` called inside a provider, violating the infrastructure boundary.
5. **Hardcoded placeholder phone number in production** — `contact_us_screen.dart:21` — `+919876543210` is a test number committed to production code.
6. **Location field is dead UI** — `profile_edit_screen.dart:362–364` — location is collected in the edit form but never passed to `updateProfile()`.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

---

### C1 — ProfileController casts domain repository to infrastructure implementation

**File:** `lib/features/profile/application/providers/profile_provider.dart:10, 52–53, 81, 101`

**Severity:** CRITICAL

**Issue:** `ProfileController` imports `profile_repository_impl.dart` (infrastructure layer) and casts the domain-contract reference (`ProfileRepository`) to its concrete implementation (`ProfileRepositoryImpl`) in three places to call `fetchProfileWithCache()` and `refreshProfileFromApi()` — methods that are not on the domain interface. The `_repository` getter returns `ProfileRepository` but every usage immediately discards the contract with `as ProfileRepositoryImpl`.

**Code:**
```dart
// profile_provider.dart:10
import '../../infrastructure/repositories/profile_repository_impl.dart';

// profile_provider.dart:52–53
final repoImpl = _repository as ProfileRepositoryImpl;
final result = await repoImpl.fetchProfileWithCache();

// profile_provider.dart:81
final repoImpl = _repository as ProfileRepositoryImpl;
repoImpl.refreshProfileFromApi().then(...)

// profile_provider.dart:101
final repoImpl = _repository as ProfileRepositoryImpl;
final freshProfile = await repoImpl.refreshProfileFromApi();
```

**Impact:** The application layer is tightly coupled to the infrastructure implementation. If `ProfileRepositoryImpl` is swapped or mocked in tests, the cast throws a `TypeError` and the controller crashes. The domain contract (`ProfileRepository`) is rendered meaningless. `ProfileController` cannot be unit-tested with a mock repository.

**Fix Required:** Add `fetchProfileWithCache()` and `refreshProfileFromApi()` to the `ProfileRepository` abstract interface. The implementation already has them — they just need to be declared in the contract. Then remove all three casts and call through the interface:
```dart
// domain/repositories/profile_repository.dart
abstract class ProfileRepository {
  Future<ProfileFetchResult> fetchProfileWithCache();
  Future<Profile?> refreshProfileFromApi();
  // ... existing methods
}

// profile_provider.dart — no import of impl needed
final result = await _repository.fetchProfileWithCache();
```

---

## High Priority Issues

---

### H1 — Infrastructure providers missing keepAlive — recreated on disposal

**File:** `lib/features/profile/application/providers/profile_provider.dart:13–28`

**Severity:** HIGH

**Issue:** `profileLocalDsProvider`, `profileApiProvider`, and `profileRepositoryProvider` are created with plain `Provider` (autoDispose by default in generated Riverpod, or ref-counted). These are heavyweight singleton objects. If the profile feature is navigated away from and the providers are disposed, a new `ProfileLocalDs`, `ProfileApi`, and `ProfileRepositoryImpl` are constructed on next access.

**Code:**
```dart
final profileLocalDsProvider = Provider<ProfileLocalDs>((ref) {
  final box = Hive.box<dynamic>(AppHiveBoxes.profile);
  return ProfileLocalDs(box: box);
});

final profileApiProvider = Provider<ProfileApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileApi(client: apiClient);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDs = ref.watch(profileApiProvider);
  final localDs = ref.watch(profileLocalDsProvider);
  return ProfileRepositoryImpl(remoteDs: remoteDs, localDs: localDs);
});
```

**Impact:** Each navigation back to the profile screen re-opens a new data source chain. On constrained devices this adds unnecessary allocation overhead and can cause Hive box state inconsistency.

**Fix Required:**
```dart
@Riverpod(keepAlive: true)
ProfileLocalDs profileLocalDs(Ref ref) { ... }

@Riverpod(keepAlive: true)
ProfileApi profileApi(Ref ref) { ... }

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) { ... }
```
Or add `keepAlive: true` to the `Provider` constructors.

---

### H2 — Background refresh silently swallows all errors with no logging

**File:** `lib/features/profile/application/providers/profile_provider.dart:79–96`

**Severity:** HIGH

**Issue:** `_refreshInBackground()` uses `.catchError((_) {})` — an empty catch handler that swallows every exception with no log, no metric, and no user signal. If the background refresh consistently fails (bad auth token, 500 errors), there is no way to diagnose it.

**Code:**
```dart
void _refreshInBackground() {
  final repoImpl = _repository as ProfileRepositoryImpl;
  repoImpl
    .refreshProfileFromApi()
    .then((freshProfile) { ... })
    .catchError((_) {
      // Silently fail - user already has cached data
    });
}
```

**Impact:** Persistent API failures during background refresh are invisible. Stale data can be shown indefinitely without any indication to the developer or user. The comment says "user already has cached data" but gives no way to detect or act on systematic failure.

**Fix Required:**
```dart
.catchError((Object e, StackTrace st) {
  debugPrint('[ProfileController] background refresh failed: $e\n$st');
});
```

---

## Medium Priority Issues

---

### M1 — profileControllerProvider missing keepAlive — profile state lost on navigation

**File:** `lib/features/profile/application/providers/profile_provider.dart:30–31`

**Severity:** MEDIUM

**Issue:** `profileControllerProvider` is a `NotifierProvider` without `keepAlive: true`. If the profile screen is fully disposed (e.g. user navigates to a deeply nested flow and back), the controller resets to `ProfileState.initial()` and `fetchProfile()` is re-triggered on next visit — causing a brief loading flash even when the cache is warm.

**Code:**
```dart
final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);
```

**Impact:** Unnecessary API calls and loading indicators on every return to the profile screen. Minor UX regression on re-navigation.

**Fix Required:** `NotifierProvider.autoDispose` if ephemeral, or `@Riverpod(keepAlive: true)` on `ProfileController` if the profile data should survive across navigations.

---

---

# QA Prompt 2 — Security & Data Persistence Violations

---

## Critical Issues

---

### C1 — Hive accessed directly inside application-layer provider

**File:** `lib/features/profile/application/providers/profile_provider.dart:2, 14`

**Severity:** CRITICAL

**Issue:** `profile_provider.dart` (application layer) imports `hive_ce` and calls `Hive.box<dynamic>(AppHiveBoxes.profile)` directly. The application layer must never touch Hive directly — all storage access must go through `infrastructure/local/` data sources.

**Code:**
```dart
import 'package:hive_ce/hive.dart';  // line 2 — Hive in application layer

final profileLocalDsProvider = Provider<ProfileLocalDs>((ref) {
  final box = Hive.box<dynamic>(AppHiveBoxes.profile);  // direct Hive access
  return ProfileLocalDs(box: box);
});
```

**Impact:** If the box name changes, is not yet open, or throws a `HiveError`, the exception surfaces inside a provider build — crashing the widget tree. The infrastructure isolation boundary is broken; the application layer now has a direct hard dependency on Hive internals.

**Fix Required:** Move the box access into an infrastructure-layer initializer (e.g. `HiveProvider` singleton opened during app startup) and inject the opened box. The provider should receive a `Box<dynamic>` that is already opened, not call `Hive.box()` itself. Alternatively, inject the `ProfileLocalDs` as a parameter from main.dart after all boxes are opened.

---

### C2 — Hardcoded placeholder WhatsApp number in production code

**File:** `lib/features/profile/presentation/screen/contact_us_screen.dart:21`

**Severity:** CRITICAL

**Issue:** A test/demo phone number `+919876543210` is hardcoded as a `static const` in the contact screen. This number is exposed to all users in production and copied to their clipboard when they tap "Copy Number".

**Code:**
```dart
// WhatsApp number for contact
static const String whatsAppNumber = '+919876543210';
```

**Impact:** Users who try to contact support are given a fake/test number. The business's actual WhatsApp contact information is not presented. If this number is a real number belonging to an unrelated person, it constitutes an accidental harassment vector.

**Fix Required:** Replace with the actual business WhatsApp number, or load it from a remote configuration / environment variable so it can be updated without a release:
```dart
// Option: inject from app config
final whatsAppNumber = ref.watch(appConfigProvider).supportWhatsApp;
```

---

## High Priority Issues

---

### H1 — Cache corruption silently swallowed with no recovery path logged

**File:** `lib/features/profile/infrastructure/data_sources/local/profile_local_ds.dart:39–41`

**Severity:** HIGH

**Issue:** When `ProfileCacheDto.fromJson()` throws on corrupted cache data, the exception is caught by a bare `catch (_) {}` with no logging, no corruption counter, and no deletion of the corrupt entry. The corrupt data remains in Hive and will fail on every subsequent read until the user clears app data.

**Code:**
```dart
try {
  final cacheDto = ProfileCacheDto.fromJson(
    Map<String, dynamic>.from(rawData as Map),
  );
  // ...
} catch (_) {
  // If data is corrupted, return null but don't delete
  // User can still try API to recover
  return null;
}
```

**Impact:** The comment says "user can still try API to recover" but the corrupt Hive entry is never deleted. The next `getCachedProfile()` call will hit the same corrupt entry and fail again. A user with corrupted cache will always fall through to the API on every profile load.

**Fix Required:**
```dart
} catch (e, st) {
  debugPrint('[ProfileLocalDs] corrupted cache entry, deleting: $e\n$st');
  await _box.delete(_kProfileKey); // remove corrupt entry so next write is clean
  return null;
}
```

---

## Medium Priority Issues

---

### M1 — Redundant try-catch in fetchProfileWithCache that only rethrows

**File:** `lib/features/profile/infrastructure/repositories/profile_repository_impl.dart:62–65`

**Severity:** MEDIUM

**Issue:** A `try-catch` block in `fetchProfileWithCache()` catches all errors and immediately rethrows without logging or transforming the error. This adds noise and a false impression of error handling.

**Code:**
```dart
} catch (error) {
  // API failed and no cache - rethrow error
  rethrow;
}
```

**Impact:** No logging means API failures during cold-start fetch are invisible unless caught further up. The try-catch block implies handling but does nothing.

**Fix Required:** Remove the try-catch entirely (the caller already handles it), or add logging before rethrowing:
```dart
} catch (error, st) {
  debugPrint('[ProfileRepositoryImpl] cold-start fetch failed: $error\n$st');
  rethrow;
}
```

---

---

# QA Prompt 3 — Error Handling & Performance

---

## Critical Issues

---

### C1 — Contact Us "Send Message" is a fake simulation — no message is ever sent

**File:** `lib/features/profile/presentation/screen/contact_us_screen.dart:30–50`

**Severity:** CRITICAL

**Issue:** `_sendMessage()` uses a 1-second `Future.delayed` to simulate a network call and then shows a success snackbar. No API call is made, no data is submitted, no backend receives anything. The entire "Contact Us" form is non-functional.

**Code:**
```dart
Future<void> _sendMessage() async {
  final subject = _subjectController.text.trim();
  if (subject.isEmpty) {
    AppSnackbar.info(context, 'Please enter how we can help you');
    return;
  }

  setState(() => _isLoading = true);

  // Simulate sending message
  await Future.delayed(const Duration(seconds: 1));

  setState(() => _isLoading = false);

  if (mounted) {
    AppSnackbar.success(context, 'Message sent successfully!');  // lies to user
    _subjectController.clear();
    _descriptionController.clear();
  }
}
```

**Impact:** Users who fill out the support form and tap "Send message" receive a success confirmation but their message is never received by the support team. This is a critical user trust issue. Any user experiencing a problem who contacts support via this form will be ignored with no follow-up.

**Fix Required:** Integrate with an actual backend endpoint (e.g. `POST /api/support/contact/`) or a third-party service (e.g. email API, Zendesk). Until the integration is live, disable the "Send message" button and show a visible "Coming soon" banner instead of faking success.

---

## High Priority Issues

---

### H1 — Generic catch in background refresh produces zero diagnostic signal

**File:** `lib/features/profile/application/providers/profile_provider.dart:93–95`

**Severity:** HIGH

**Issue:** `.catchError((_) {})` in `_refreshInBackground()` and a matching `catch (_) {}` block in `_saveCacheInternal()` both swallow errors with no logging. If the profile API returns a 401, 500, or the Hive write throws, it is silently discarded.

**Code:**
```dart
// profile_provider.dart:93–95
.catchError((_) {
  // Silently fail - user already has cached data
});

// profile_local_ds.dart:57–59
} catch (_) {
  // Silently fail - cache is not critical
}
```

**Impact:** Systematic failures in the background refresh path (e.g. expired auth token) are undetectable. The user will keep seeing stale data indefinitely. The stale data banner is shown but there is no log to explain why the refresh keeps failing.

**Fix Required:**
```dart
.catchError((Object e, StackTrace st) {
  debugPrint('[ProfileController] background refresh error: $e\n$st');
});
```

---

### H2 — WhatsApp bottom sheet uses deactivated context for snackbar after Navigator.pop

**File:** `lib/features/profile/presentation/screen/contact_us_screen.dart:97–101`

**Severity:** HIGH

**Issue:** Inside the bottom sheet's `builder: (context)` lambda, the `context` variable is the bottom sheet's `BuildContext`. After `Navigator.pop(context)` dismisses the sheet, `AppSnackbar.success(context, ...)` is called with the same now-deactivated context. This triggers a `ScaffoldMessenger.of(deactivated)` lookup error.

**Code:**
```dart
showModalBottomSheet(
  context: context,        // parent context
  builder: (context) =>   // 'context' is now the bottom sheet's context
    ElevatedButton(
      onPressed: () {
        Clipboard.setData(const ClipboardData(text: whatsAppNumber));
        Navigator.pop(context);          // dismisses sheet, deactivates this context
        AppSnackbar.success(
          context,                       // same deactivated context — CRASH
          'Phone number copied to clipboard',
        );
      },
```

**Impact:** Tapping "Copy Number" causes an unhandled exception. The snackbar never appears and a red error screen may flash on debug builds. On release builds the error is swallowed but the user receives no confirmation that the number was copied.

**Fix Required:** Capture the parent context before opening the sheet and use it in the callback, or check `context.mounted` and use the outer scope's `context`:
```dart
void _openWhatsApp() {
  final parentContext = context; // capture before sheet opens
  showModalBottomSheet(
    context: parentContext,
    builder: (sheetContext) => ElevatedButton(
      onPressed: () {
        Clipboard.setData(const ClipboardData(text: whatsAppNumber));
        Navigator.pop(sheetContext);
        if (parentContext.mounted) {
          AppSnackbar.success(parentContext, 'Phone number copied to clipboard');
        }
      },
    ),
  );
}
```

---

## Medium Priority Issues

---

### M1 — Hardcoded raw strokeWidth in loading indicators violates ScreenUtil rules

**File:** `lib/features/profile/presentation/screen/profile_edit_screen.dart:170–173, 201–208`

**Severity:** MEDIUM

**Issue:** Both loading spinners (Save button and Delete Account button) use hardcoded integer `2` for `strokeWidth` instead of `2.r`. The surrounding `SizedBox` dimensions correctly use `.h` and `.w` but the stroke is left as a raw pixel value.

**Code:**
```dart
// Save button spinner
SizedBox(
  height: 20.h,
  width: 20.w,
  child: const CircularProgressIndicator(
    strokeWidth: 2,  // should be 2.r
  ),
)

// Delete button spinner
SizedBox(
  height: 20.h,
  width: 20.w,
  child: const CircularProgressIndicator(
    strokeWidth: 2,   // should be 2.r
    color: Colors.red,
  ),
)
```

**Impact:** On tablets or high-DPI screens the spinner ring appears proportionally thin relative to the surrounding UI. Minor but inconsistent with the rest of the design system.

**Fix Required:** `strokeWidth: 2.r`. Remove `const` from the `CircularProgressIndicator` since `2.r` is not a compile-time constant.

---

### M2 — Magic 1-second delay used as fake network simulation

**File:** `lib/features/profile/presentation/screen/contact_us_screen.dart:41`

**Severity:** MEDIUM

**Issue:** `await Future.delayed(const Duration(seconds: 1))` is used to fake a loading state with no real asynchronous work behind it.

**Code:**
```dart
// Simulate sending message
await Future.delayed(const Duration(seconds: 1));
```

**Impact:** On slow devices users wait an extra second for nothing. The "Simulate" comment confirms this is intentional placeholder code that was never replaced with a real implementation.

**Fix Required:** Replace with an actual API call. If the feature is not yet implemented, show a "not yet available" message rather than simulating a successful send.

---

---

# QA Prompt 4 — Code Quality & Deployment Readiness

---

## Critical Issues

---

### C1 — No navigation after successful account deletion — user stranded on screen

**File:** `lib/features/profile/presentation/screen/profile_edit_screen.dart:416–424`

**Severity:** CRITICAL

**Issue:** After `deleteAccount()` succeeds, the navigation to the login screen is commented out. The user's account has been permanently deleted but they remain on the `ProfileEditScreen`. The profile state is reset to `ProfileState.initial()` (empty data), but the form still renders with null fallback values.

**Code:**
```dart
if (confirmed == true && mounted) {
  try {
    await ref.read(profileControllerProvider.notifier).deleteAccount();

    if (mounted) {
      AppSnackbar.success(context, 'Account deleted successfully');
      // Navigate to login screen
      // Navigator.of(context).pushReplacementNamed('/login');  // ← commented out
    }
  } catch (error) {
```

**Impact:** Deployment blocker. After successful account deletion:
- The user is shown "Account deleted successfully" but stays on the edit screen.
- Subsequent API calls (e.g. pull-to-refresh) will fail with 401 since the account no longer exists.
- Auth state is not cleared, so the user appears logged in to a deleted account.

**Fix Required:**
```dart
if (mounted) {
  AppSnackbar.success(context, 'Account deleted successfully');
  await ref.read(authProvider.notifier).logout();
  context.go('/otp');  // use GoRouter to clear the navigation stack
}
```

---

### C2 — Contact Us form is non-functional — no message is ever delivered

**File:** `lib/features/profile/presentation/screen/contact_us_screen.dart:30–50`

**Severity:** CRITICAL

**Issue:** Identical to Prompt 3 C1 — listed here because it is a hard deployment blocker. The entire Contact Us feature is a UI shell with a simulated response. No support message reaches anyone.

**Code:**
```dart
// Simulate sending message
await Future.delayed(const Duration(seconds: 1));
// ...
AppSnackbar.success(context, 'Message sent successfully!');
```

**Impact:** Any user who submits a support request through this screen will receive no response because nothing was ever sent. This directly damages user trust and blocks legitimate support requests.

**Fix Required:** Integrate with a real endpoint before shipping. Minimum viable fix: remove the button or replace the success snackbar with an honest "Feature coming soon" state.

---

## High Priority Issues

---

### H1 — Location field in profile edit form is collected but never submitted

**File:** `lib/features/profile/presentation/screen/profile_edit_screen.dart:21, 31, 146–151, 362–364`

**Severity:** HIGH

**Issue:** A `_locationController` is declared, initialised with `profile?.location`, rendered as a text field in the form, and disposed — but `_handleSave()` never passes its value to `updateProfile()`. The location field is dead UI.

**Code:**
```dart
// Declared and initialised:
late TextEditingController _locationController;
_locationController = TextEditingController(text: profile?.location ?? '');

// Rendered in the form:
_buildTextField(
  label: 'Location',
  controller: _locationController,
  maxLines: 4,
  validator: null,
),

// _handleSave() — location is never passed:
await ref.read(profileControllerProvider.notifier).updateProfile(
  fullName: _fullNameController.text.trim(),
  phoneNumber: _mobileNumberController.text.trim(),
  // _locationController.text is ignored
);
```

**Impact:** Users who update their location on the edit screen see no change when they save. The location field always returns to its previous value (or null) after save. This is a silent data loss bug — users believe they edited their location but the change is discarded.

**Fix Required:** Either add `location` as a parameter to `updateProfile()` (domain → API), or remove the location field from the edit screen if the backend does not support it. The current behaviour — showing an editable field that does nothing — is misleading.

---

### H2 — Mixed navigation paradigms — imperative Navigator alongside GoRouter

**File:** `lib/features/profile/presentation/screen/profile_screen.dart:142–149, 166–174, 185–190`

**Severity:** HIGH

**Issue:** `ProfileScreen` uses GoRouter's `context.push('/orders')` for orders but uses `Navigator.of(context).push(MaterialPageRoute(...))` for `ProfileEditScreen`, `AddressListScreen`, and `ContactUsScreen`. The same screen mixes both navigation systems, creating routing inconsistency.

**Code:**
```dart
// GoRouter — used for Orders:
onTap: () => context.push('/orders'),

// Imperative Navigator — used for ProfileEdit:
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const ProfileEditScreen()),
);

// Imperative Navigator — used for Address:
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const AddressListScreen()),
);

// Imperative Navigator — used for Contact Us:
Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen()));
```

**Impact:** Deep links, back-button behaviour, and GoRouter redirect guards do not apply to screens pushed imperatively. The profile feature cannot be tested with integration test driver that relies on GoRouter state. Inconsistent back-stack behaviour for users using the Android system back button.

**Fix Required:** Register all three screens as GoRouter routes (`/profile/edit`, `/profile/contact`) and navigate with `context.push('/profile/edit')`. The existing `go_router` import in `profile_screen.dart` is already present.

---

### H3 — Hardcoded test WhatsApp number in production code

**File:** `lib/features/profile/presentation/screen/contact_us_screen.dart:21`

**Severity:** HIGH

**Issue:** The WhatsApp support number is a static compile-time constant with an obviously placeholder value. This is a duplicate of Prompt 2 C2 — listed again as a deployment blocker under code quality.

**Code:**
```dart
static const String whatsAppNumber = '+919876543210';
```

**Impact:** Every user who taps "Contact us on WhatsApp" copies or sees a placeholder test number that is not the business's actual contact. This ships in the production build.

**Fix Required:** Replace with the actual support WhatsApp number. Move to a remote-config or build-time environment variable so it can be changed without a new app release.

---

## Medium Priority Issues

---

### M1 — Misleading comment about optimistic updates in address navigation

**File:** `lib/features/profile/presentation/screen/profile_screen.dart:172–174`

**Severity:** MEDIUM

**Issue:** A comment inside the `AddressListScreen` navigation callback states "No need to clear cache — optimistic updates are already applied", but the address list is navigated imperatively and there is no observable optimistic update logic in this file.

**Code:**
```dart
onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AddressListScreen()),
  );
  // Note: Address updates are handled optimistically
  // No need to clear cache - optimistic updates are already applied
},
```

**Impact:** Future developers will be misled into believing the address cache is updated proactively when it is not obvious that this is happening here. The comment belongs in the address feature, not in a navigation handler.

**Fix Required:** Remove the comment from the navigation handler.

---

### M2 — CircularProgressIndicator strokeWidth uses raw integer instead of ScreenUtil

**File:** `lib/features/profile/presentation/screen/profile_edit_screen.dart:170, 204`

**Severity:** MEDIUM

**Issue:** Both loading spinners use `strokeWidth: 2` (raw int). This is a repeat of Prompt 3 M1 — listed under code quality as a dart format / ScreenUtil compliance issue.

**Code:**
```dart
child: const CircularProgressIndicator(strokeWidth: 2)
```

**Fix Required:** `strokeWidth: 2.r` — remove `const`.

---

### M3 — Zero test coverage for profile feature

**File:** `lib/features/profile/` (entire directory)

**Severity:** MEDIUM

**Issue:** There are no unit, widget, or integration tests for any file in the profile feature. `ProfileController` state transitions (fetch, update, delete, logout), `ProfileRepositoryImpl` cache-first logic, and all three screens are completely untested.

**Impact:** Regressions in profile fetch, update, or account deletion silently reach production. The CI pipeline cannot catch any breakage in this feature.

**Fix Required:** At minimum, add:
- Unit tests for `ProfileController`: `fetchProfile()` (cold start, warm cache, stale), `updateProfile()` (success + error), `deleteAccount()` (success + error).
- Unit test for `ProfileRepositoryImpl.fetchProfileWithCache()`: cache-hit path, API-fallback path.
- Widget test for `ProfileEditScreen`: form validation, save button state (loading vs idle), delete account confirmation dialog.

---

---

# QA Prompt 6 — Architecture Compliance (4-Layer Violations)

---

## Critical Issues

---

### C1 — Application layer imports from and casts to infrastructure implementation

**File:** `lib/features/profile/application/providers/profile_provider.dart:10, 52–53, 81, 101`

**Layer:** Application → Infrastructure (Rules 5 and 12 violation)

**Severity:** CRITICAL

**Issue:** `profile_provider.dart` (application layer) imports `profile_repository_impl.dart` (infrastructure layer) and performs three explicit downcasts of the `ProfileRepository` domain interface to `ProfileRepositoryImpl`. This is the exact violation described in Rule 5 ("Application layer imports from `infrastructure/`") and Rule 12 ("StateNotifier holds reference to infrastructure implementation").

**Code:**
```dart
// Line 10 — infrastructure import in application layer:
import '../../infrastructure/repositories/profile_repository_impl.dart';

// Lines 52–53, 81, 101 — downcast in application logic:
final repoImpl = _repository as ProfileRepositoryImpl;
```

**Impact:** The 4-layer boundary is broken. The application layer has a compile-time dependency on the infrastructure implementation. Mocking the repository in tests breaks because the cast throws `TypeError`. Any refactoring of `ProfileRepositoryImpl` risks breaking `ProfileController` without type-system warning.

**Fix Required:** Promote `fetchProfileWithCache()` and `refreshProfileFromApi()` to the `ProfileRepository` abstract interface. Remove the import and all three casts. See Prompt 1 C1 for the full fix.

---

### C2 — Hive box accessed directly in application layer — boundary violation

**File:** `lib/features/profile/application/providers/profile_provider.dart:2, 13–16`

**Layer:** Application → Storage (Rule 11 violation)

**Severity:** CRITICAL

**Issue:** `profile_provider.dart` imports `hive_ce` and calls `Hive.box<dynamic>()` inside the application-layer provider body. Per Rule 11, Hive reads and writes must exist exclusively inside `infrastructure/local/` files. No other layer may import or call Hive directly.

**Code:**
```dart
import 'package:hive_ce/hive.dart';  // Hive in application layer

final profileLocalDsProvider = Provider<ProfileLocalDs>((ref) {
  final box = Hive.box<dynamic>(AppHiveBoxes.profile);  // direct Hive call
  return ProfileLocalDs(box: box);
});
```

**Impact:** If the box is not open at the point this provider builds, `Hive.box()` throws an unhandled `HiveError`. The application layer now knows about Hive box names and the timing of box initialisation. Any refactoring of how boxes are opened in `main.dart` can silently break this provider.

**Fix Required:** Open all Hive boxes during app startup in `main.dart` and inject the already-opened `Box<dynamic>` as a `ProviderScope` override, or through a dedicated `HiveProvider` singleton:
```dart
// main.dart
await Hive.openBox<dynamic>(AppHiveBoxes.profile);
// ...
runApp(ProviderScope(
  overrides: [
    profileLocalDsProvider.overrideWithValue(
      ProfileLocalDs(box: Hive.box<dynamic>(AppHiveBoxes.profile)),
    ),
  ],
  child: const App(),
));
```

---

## High Priority Issues

---

### H1 — Domain entity missing copyWith() — mutable update pattern unavailable

**File:** `lib/features/profile/domain/entities/profile.dart`

**Layer:** Domain (Rule 20 violation)

**Severity:** HIGH

**Issue:** `Profile` domain entity has no `copyWith()` method. Per the architecture rules, domain entities must be immutable value objects with a safe update path. Without `copyWith()`, every update to a profile (e.g. after an edit) requires manually constructing a full new instance from all 6 fields.

**Code:**
```dart
class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.location,
    this.profileImageUrl,
  });

  final String id;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? location;
  final String? profileImageUrl;
  // No copyWith()
}
```

**Impact:** Any partial update to a `Profile` requires the caller to supply all 6 fields. Error-prone and verbose. As the `Profile` entity grows, this becomes increasingly fragile.

**Fix Required:**
```dart
Profile copyWith({
  String? id,
  String? fullName,
  String? mobileNumber,
  String? email,
  String? location,
  String? profileImageUrl,
}) => Profile(
  id: id ?? this.id,
  fullName: fullName ?? this.fullName,
  mobileNumber: mobileNumber ?? this.mobileNumber,
  email: email ?? this.email,
  location: location ?? this.location,
  profileImageUrl: profileImageUrl ?? this.profileImageUrl,
);
```

---

### H2 — Infrastructure DTO contains business logic method (splitFullName)

**File:** `lib/features/profile/infrastructure/models/profile_dto.dart:87–92`

**Layer:** Infrastructure (Rule 10 violation)

**Severity:** HIGH

**Issue:** `ProfileDto` contains a `static splitFullName(String fullName)` method that implements name-splitting logic. Utility and business logic must not live in infrastructure DTOs — the DTO's sole responsibility is serialisation/deserialisation.

**Code:**
```dart
/// Helper method to get fullName for API requests
static Map<String, String> splitFullName(String fullName) {
  final parts = fullName.trim().split(' ');
  if (parts.length == 1) {
    return {'first_name': parts[0], 'last_name': ''};
  }
  return {'first_name': parts.first, 'last_name': parts.sublist(1).join(' ')};
}
```

**Impact:** The name-splitting logic is coupled to the infrastructure DTO, meaning it cannot be used or tested independently of the DTO. If `ProfileCacheDto` also needs to split names (and it does — line 46 of `profile_cache_dto.dart` calls `ProfileDto.splitFullName()`), the cross-DTO dependency creates a subtle coupling between two infrastructure files.

**Fix Required:** Move `splitFullName` to a utility function in the application layer (e.g. `ProfileUtils.splitFullName()`), or place it in a domain value object if name-splitting is a domain concern. The DTO calls the utility; it doesn't own it.

---

### H3 — ContactUsScreen uses StatefulWidget with raw state booleans instead of Riverpod

**File:** `lib/features/profile/presentation/screen/contact_us_screen.dart:8–18`

**Layer:** Presentation (Rule 15 violation)

**Severity:** HIGH

**Issue:** `ContactUsScreen` extends `StatefulWidget` and uses a raw `bool _isLoading` to manage the loading state for what is intended to be an API operation. Per Rule 15, `StatefulWidget` is reserved for purely visual/local state (e.g. show/hide, dropdown open/close). API call state — even a fake one — must be managed through Riverpod.

**Code:**
```dart
class ContactUsScreen extends StatefulWidget { ... }

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  // ...
  setState(() => _isLoading = true);
  await Future.delayed(const Duration(seconds: 1));
  setState(() => _isLoading = false);
}
```

**Impact:** When the Contact Us form eventually calls a real API, the loading state and error handling will need to be completely rearchitected. Currently, there is no way to test the loading state via Riverpod, no way to share state with other screens, and no structured error propagation.

**Fix Required:** Convert to `ConsumerStatefulWidget` with a `ContactController` (or `AsyncNotifier`) that exposes an `AsyncValue` for the submit operation. The form fields' `TextEditingController` can stay in `StatefulWidget` state (they are purely local UI state).

---

## Medium Priority Issues

---

### M1 — Presentation screens use imperative Navigator instead of GoRouter

**File:** `lib/features/profile/presentation/screen/profile_screen.dart:142–149, 166–174, 185–190`

**Layer:** Presentation (Rule 21 — inconsistent routing)

**Severity:** MEDIUM

**Issue:** Three navigation calls in `ProfileScreen` use `Navigator.push(MaterialPageRoute(...))` while the same screen uses `context.push('/orders')` for the orders flow. The architecture requires GoRouter to be the single navigation authority so redirect guards and deep-link routing apply uniformly.

**Code:**
```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => const ProfileEditScreen()),
);
```

**Impact:** Screens pushed imperatively bypass GoRouter's `redirect` guards. Deep links to `/profile/edit` will not resolve. The Android back-stack is managed by two separate systems simultaneously.

**Fix Required:** Add `GoRoute` entries for `/profile/edit` and `/contact` in `app_router.dart`. Replace all three `Navigator.push` calls with `context.push('/profile/edit')` etc.

---

### M2 — ProfileCacheDto is a separate model mirroring ProfileDto — redundant layer

**File:** `lib/features/profile/infrastructure/data_sources/local/profile_cache_dto.dart`

**Layer:** Infrastructure

**Severity:** MEDIUM

**Issue:** `ProfileCacheDto` duplicates most of `ProfileDto`'s fields (`id`, `fullName`/`firstName`/`lastName`, `mobileNumber`, `email`, `profileImageUrl`) with a different field naming convention. The round-trip `ProfileDto → ProfileCacheDto → ProfileDto` via `toDto()` / `fromDto()` introduces two JSON serialisation steps and a name-split round-trip that can silently change data (e.g. a name with three words splits differently on rebuild).

**Code:**
```dart
// ProfileCacheDto.toDto() calls splitFullName, which re-splits the cached fullName:
factory ProfileCacheDto.fromDto(ProfileDto dto) {
  return ProfileCacheDto(
    fullName: '${dto.firstName} ${dto.lastName}',  // joins name
    ...
  );
}

ProfileDto toDto() {
  final nameParts = ProfileDto.splitFullName(fullName);  // re-splits name
  return ProfileDto(
    firstName: nameParts['first_name']!,  // may differ from original
    lastName: nameParts['last_name']!,
    ...
  );
}
```

**Impact:** A user with a three-word name (e.g. "Mary Anne Smith") will have `firstName = "Mary"` and `lastName = "Anne Smith"` from the API. The cache stores `fullName = "Mary Anne Smith"`. On cache read, `splitFullName` produces `firstName = "Mary"`, `lastName = "Anne Smith"` — this happens to match, but is fragile for names with prefixes/suffixes. More importantly, having two cache models for the same entity adds maintenance burden.

**Fix Required:** Cache `ProfileDto` directly (serialised with `toJson()`) and add `cachedAt` as a top-level wrapper field. This eliminates `ProfileCacheDto` and the double-serialisation round-trip:
```dart
class ProfileCacheEntry {
  final ProfileDto profile;
  final DateTime cachedAt;
}
```
