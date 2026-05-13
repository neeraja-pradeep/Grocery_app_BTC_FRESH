# Auth Flow — Code Audit Report

**Scope:** Splash · Login · Signup · Sign-Pass · OTP · Address · Forgot Password · Forgot Password OTP · Reset Password · Password Changed

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 6

**Date:** 2026-04-30

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 3 | 2 | 1 | 6 |
| Prompt 2 — Security & Data Persistence | 4 | 3 | 1 | 8 |
| Prompt 3 — Performance & Error Handling | 1 | 2 | 3 | 6 |
| Prompt 4 — Code Quality & Deployment | 2 | 3 | 4 | 9 |
| Prompt 6 — Architecture Compliance | 3 | 3 | 2 | 8 |
| **Total** | **13** | **13** | **11** | **37** |

---

## Top Blockers Before Any Production Release

1. **Broken OTP new-user navigation** — `otp_screen.dart:534` — users who sign up via OTP never reach address setup.
2. **Hardcoded Google Maps API key** — `AndroidManifest.xml:52` — rotate immediately and move to build-time injection.
3. **Cleartext HTTP permitted** — `AndroidManifest.xml:17` — session cookies can be intercepted over HTTP.
4. **Entire forgot-password flow bypasses application layer** — 3 screens call infrastructure directly with no Riverpod state.
5. **Errors shown as success** — `forgot_password_otp_screen.dart:195` — failures display with green success banners.
6. **Reset password sends no OTP token to backend** — server cannot verify proof of OTP before allowing password change.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

---

### C1 — ForgotPasswordScreen directly accesses infrastructure data source

**File:** `lib/features/auth/presentation/screen/forgot_password_screen.dart:9, 43`

**Severity:** CRITICAL

**Issue:** `ForgotPasswordScreen` imports `auth_api.dart` (infrastructure/remote layer) and calls `ref.read(authApiProvider)` directly inside `_handleSendCode()`. No StateNotifier is involved. Presentation layer is tightly coupled to infrastructure — no auth state is emitted, GoRouter redirect logic does not fire, loading states are unmanaged, and errors cannot be handled via `AuthState`.

**Code:**
```dart
import '../../infrastructure/data_sources/remote/auth_api.dart';
// ...
final authApi = ref.read(authApiProvider);
final message = await authApi.sendOtp(phoneNumber: phoneWithCountryCode);
```

**Impact:** Complete bypass of the application layer. If the user successfully requests a password OTP, the global `AuthState` remains unchanged. GoRouter has no knowledge of this action, so no redirect guards apply.

**Fix Required:** Create a `ForgotPasswordNotifier` (or add `sendForgotPasswordOtp()` to `AuthNotifier`) exposed via a provider. The screen calls the notifier and listens to state via `ref.listen`.

---

### C2 — ForgotPasswordOtpScreen directly accesses infrastructure data source

**File:** `lib/features/auth/presentation/screen/forgot_password_otp_screen.dart:12, 113, 167`

**Severity:** CRITICAL

**Issue:** Both `sendOtp()` and `verifyOtpOnly()` are called on `authApiProvider` directly from `ConsumerStatefulWidget`. The entire forgot-password-OTP verification flow is invisible to the application state layer and GoRouter.

**Code:**
```dart
import '../../infrastructure/data_sources/remote/auth_api.dart';
// ...
final authApi = ref.read(authApiProvider);
final message = await authApi.verifyOtpOnly(
  phoneNumber: widget.mobileNumber,
  otp: otp,
);
```

**Impact:** Same as C1. OTP verification result is never reflected in any Riverpod provider. Loading state is managed by a raw `_isLoading` bool.

**Fix Required:** Move OTP send/verify logic into a notifier. Screen calls `ref.read(forgotPasswordProvider.notifier).verifyOtp(...)` and listens via `ref.listen`.

---

### C3 — ResetPasswordScreen calls the repository directly, bypassing the StateNotifier

**File:** `lib/features/auth/presentation/screen/reset_password_screen.dart:9, 67–74`

**Severity:** CRITICAL

**Issue:** The screen imports `auth_repository_provider.dart` and calls `repo.resetPassword(...)` directly. The application layer (notifier) is completely skipped.

**Code:**
```dart
import '../../application/providers/auth_repository_provider.dart';
// ...
final repo = ref.read(authRepositoryProvider);
final result = await repo.resetPassword(newPassword: password);
```

**Impact:** No `AuthState` is emitted on password reset success or failure. Loading, error, and success are managed by a local `_isLoading` bool. There is no way to globally guard or invalidate state after a password reset.

**Fix Required:** Add `resetPassword()` to `AuthNotifier`. Screen: `ref.read(authProvider.notifier).resetPassword(password)` + `ref.listen` for state changes.

---

## High Priority Issues

---

### H1 — `authRepositoryProvider` is not keepAlive

**File:** `lib/features/auth/application/providers/auth_repository_provider.dart:12–17`

**Severity:** HIGH

**Issue:** The repository provider uses `@riverpod` without `keepAlive: true`. A new `AuthRepositoryImpl` is created each time the provider is re-read after disposal, cascading to new `AuthApi` and `AuthLocalDs` instances as well.

**Code:**
```dart
@riverpod
AuthRepository authRepository(Ref ref) {
  final api = ref.watch(authApiProvider);
  final local = ref.watch(authLocalDsProvider);
  return AuthRepositoryImpl(local: local, remote: api);
}
```

**Impact:** The repository is a core singleton dependency. Re-creating it between screen transitions can cause shared cookie state context to be lost.

**Fix Required:** Change to `@Riverpod(keepAlive: true)` to make the repository a true singleton.

---

### H2 — Auth notifier directly couples to wishlist, cart, and category providers

**File:** `lib/features/auth/application/providers/auth_provider.dart:229–245`

**Severity:** HIGH

**Issue:** `_clearUserData()` uses `ref.read()` to reach into wishlist, checkout, and category notifiers directly from the auth notifier. Auth domain now has hard knowledge of cart/wishlist domains.

**Code:**
```dart
final wishlistNotifier = ref.read(wishlistProvider.notifier);
await wishlistNotifier.clearCacheAndRefresh();

final checkoutLineController = ref.read(checkoutLineControllerProvider.notifier);
await checkoutLineController.refresh();
```

**Impact:** Violates single responsibility. Auth notifier cannot be tested in isolation. Adding a new feature that needs clearing on logout requires editing the auth notifier.

**Fix Required:** Use `ref.invalidate()` for cross-domain providers, or introduce a `UserSessionService` provider that coordinates clearing across domains independently.

---

## Medium Priority Issues

---

### M1 — `this.state` assignment inconsistency in AddressEntry notifier

**File:** `lib/features/auth/application/providers/address_provider.dart:32–33`

**Severity:** MEDIUM

**Issue:** Uses `this.state = AddressSaving()` instead of `state = AddressSaving()`. Functionally identical in Riverpod but inconsistent with the pattern used everywhere else in the codebase.

**Code:**
```dart
this.state = AddressSaving();
// ...
this.state = AddressError(failure);
```

**Impact:** Minor readability inconsistency. Developers familiar with the rest of the codebase will need to do a double-take.

**Fix Required:** Remove `this.` prefix — use `state = AddressSaving();` throughout the notifier.

---

---

# QA Prompt 2 — Security & Data Persistence Violations

---

## Critical Issues

---

### C1 — Hardcoded Google Maps API key in AndroidManifest

**File:** `android/app/src/main/AndroidManifest.xml:52`

**Severity:** CRITICAL

**Issue:** The Google Maps API key is committed directly into `AndroidManifest.xml` in plain text, making it visible to anyone with repository access.

**Code:**
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBuOyJfzRHyMJghiOPJlOQoiKi82XNxWyc"/>
```

**Impact:** The key can be extracted from the APK or the repo and abused for billing charges, quota exhaustion, or map data scraping.

**Fix Required:** Move the key to `local.properties`. In `app/build.gradle.kts`, read it with `val mapsKey = localProperties.getProperty("MAPS_API_KEY", "")` and inject via `manifestPlaceholders["MAPS_API_KEY"] = mapsKey`. In the manifest use `android:value="${MAPS_API_KEY}"`. Rotate the current key immediately.

---

### C2 — Cleartext HTTP traffic is permitted globally

**File:** `android/app/src/main/AndroidManifest.xml:17`

**Severity:** CRITICAL

**Issue:** `android:usesCleartextTraffic="true"` is set on the `<application>` tag, allowing the app to communicate over unencrypted HTTP on any network.

**Code:**
```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

**Impact:** Session cookies, auth tokens, and user credentials can be transmitted in plaintext. Any device on the same network (coffee shop Wi-Fi, shared LAN) can intercept them via a passive MITM attack.

**Fix Required:** Remove `android:usesCleartextTraffic="true"` from the main manifest. If the dev/staging server uses HTTP, add the flag only to `src/debug/AndroidManifest.xml` so it never reaches a production build.

---

### C3 — Reset password API sends no OTP token — server cannot verify identity

**File:** `lib/features/auth/infrastructure/data_sources/remote/auth_api.dart:155–170`

**Severity:** CRITICAL

**Issue:** `resetPassword()` sends only `new_password`. The OTP that was verified on the client is never forwarded to the backend. The backend has no cryptographic proof that the caller actually verified the OTP.

**Code:**
```dart
Future<String> resetPassword({required String newPassword}) async {
  final res = await _dio.post(
    ApiEndpoints.resetPassword,
    data: {'new_password': newPassword}, // OTP/token missing
  );
```

**Impact:** If the reset-password endpoint does not maintain its own server-side verified session, any caller who knows the endpoint URL can reset any account's password without OTP proof. This is a password-takeover vulnerability.

**Fix Required:** The backend must issue a short-lived `reset_token` upon successful OTP verification. The client must store this token and send `{'new_password': password, 'reset_token': token}`. Update `goToResetPassword` to pass the token, and update `resetPassword()` to include it.

---

### C4 — Error cases use success-style snackbar in ForgotPasswordOtpScreen

**File:** `lib/features/auth/presentation/screen/forgot_password_otp_screen.dart:195–197`

**Severity:** CRITICAL

**Issue:** A single `_showSnack()` helper always calls `AppSnackbar.success()`. It is reused for both success messages and catch-block error messages.

**Code:**
```dart
void _showSnack(String msg) {
  AppSnackbar.success(context, msg); // always green, even for errors
}

// Called on error paths:
} catch (e) {
  _showSnack(e.toString()); // shows green banner for a failure
}
```

**Impact:** Network failures, invalid OTPs, and server errors are displayed with a green success banner. Users believe the action succeeded when it actually failed, leading to confusion and incorrect retry behaviour.

**Fix Required:** Split into `_showSuccess(String msg)` → `AppSnackbar.success(...)` and `_showError(String msg)` → `AppSnackbar.error(...)`. Replace all error-path `_showSnack` calls with `_showError`.

---

## High Priority Issues

---

### H1 — Auto-login validates session client-side only, no server-side verification

**File:** `lib/features/auth/application/providers/auth_provider.dart:37–63`

**Severity:** HIGH

**Issue:** The session is considered valid if the cookie name contains `session`, has a non-empty value, and has not passed its local expiry. There is no call to the server to confirm the session is still active.

**Code:**
```dart
final session = await _repository.getCurrentSession();
if (session != null) {
  final user = await _repository.getSavedUser();
  if (user != null) {
    state = Authenticated(user: user, isNewUser: false); // no server check
  }
}
```

**Impact:** A server-side logout (password change on another device, admin revocation, session expiry policy change) is not detected. The user is auto-logged-in with a dead session and will receive silent 401 errors on every API call until they try a protected action.

**Fix Required:** After loading the cached session, make a lightweight `GET /api/auth/me` call. If it returns 401, call `local.clearAllUserData()` and set `state = const GuestMode()`.

---

### H2 — Logout does not call a server-side logout endpoint

**File:** `lib/features/auth/infrastructure/repositories/auth_repository_impl.dart:234–238`

**Severity:** HIGH

**Issue:** Logout only clears local cookies and Hive data. No request is sent to the server to invalidate the session.

**Code:**
```dart
@override
Future<void> logout() async {
  await local.clearAllUserData(); // only local cleanup
}
```

**Impact:** The server-side session remains active indefinitely after logout. Intercepted cookies remain usable until they naturally expire on the server.

**Fix Required:** Send `POST /api/auth/logout` before clearing local data. Wrap in try-catch — if the server call fails, still clear local data so the user is not stuck logged in on-device.

---

### H3 — No OTP resend cooldown timer on the signup/login OTP screen

**File:** `lib/features/auth/presentation/screen/otp_screen.dart`

**Severity:** HIGH

**Issue:** The `Resend OTP` button is available immediately with no cooldown. `ForgotPasswordOtpScreen` correctly implements a 60-second countdown; this screen does not.

**Code:**
```dart
Widget _buildResendOption(AuthState authState) {
  final isResending = authState is OtpSending;
  return GestureDetector(
    onTap: isResending ? null : _handleResendOtp, // no timer guard
    ...
  );
}
```

**Impact:** Users can spam OTP requests, abusing the SMS gateway and potentially locking out accounts through rate-limit exhaustion on the backend.

**Fix Required:** Add the same `Timer` + `_canResend` + `_timerSeconds` pattern used in `ForgotPasswordOtpScreen`. Start the timer after a successful OTP send and disable the resend button until it reaches zero.

---

## Medium Priority Issues

---

### M1 — Login does not clear previous user's cached data before saving the new user

**File:** `lib/features/auth/infrastructure/repositories/auth_repository_impl.dart:24–42`

**Severity:** MEDIUM

**Issue:** On login, `local.saveUser(user)` overwrites the user record but does not clear other cached data boxes (address, cart) that may belong to the previously logged-in user.

**Code:**
```dart
final user = await remote.login(username: username, password: password);
await local.saveUser(user); // overwrites user but not other boxes
```

**Impact:** If User A logs in after User B without a reinstall, User A may momentarily see User B's stale address or cart data until individual features refresh.

**Fix Required:** Call `await local.clearAllUserData()` before `saveUser()` on successful login, mirroring the pattern used in logout.

---

---

# QA Prompt 3 — Error Handling & Performance

---

## Critical Issues

---

### C1 — New-user address navigation is commented out in OTP screen

**File:** `lib/features/auth/presentation/screen/otp_screen.dart:533–538`

**Severity:** CRITICAL

**Issue:** When `verifyOtp()` succeeds for a new user (`state.isNewUser == true`), the navigation to the address screen is disabled with a comment. The `else` branch navigates to home, but the `if` branch is a no-op.

**Code:**
```dart
if (state is Authenticated) {
  setState(() => _isSubmitting = false);
  if (state.isNewUser) {
    // goToAddress(context,);  // ← commented out — nothing happens
  } else {
    goToHome(context);
  }
}
```

**Impact:** New users who register and verify via OTP are silently dropped onto the home screen without completing address setup. User profiles remain incomplete. This is a live regression in the new-user onboarding flow.

**Fix Required:**
```dart
if (state.isNewUser) {
  goToAddress(context, state.user); // pass the UserEntity
} else {
  goToHome(context);
}
```

---

## High Priority Issues

---

### H1 — FocusNode created inside build() on every rebuild — memory leak

**File:** `lib/features/auth/presentation/screen/otp_screen.dart:295–309`

**Severity:** HIGH

**Issue:** `KeyboardListener` is given an inline `FocusNode()` created on every call to `_buildOtpInputFields()`, which is called from `build()`. These are never disposed.

**Code:**
```dart
child: KeyboardListener(
  focusNode: FocusNode(), // new FocusNode on every rebuild, never disposed
  onKeyEvent: (event) { ... },
  child: TextFormField(...),
),
```

**Impact:** Every OTP digit entry triggers `setState` → `build` → 6 new `FocusNode` objects are created and leaked. On a typical OTP entry of 6 digits plus any corrections, this leaks dozens of FocusNodes in a single screen visit.

**Fix Required:** Remove `KeyboardListener` entirely. Handle backspace navigation in `onChanged`:
```dart
onChanged: (value) {
  if (value.isEmpty && index > 0) {
    _otpFocusNodes[index - 1].requestFocus();
  }
  _handleOtpDigitChange(index, value);
},
```
The `_otpFocusNodes` list already exists, is properly initialised, and is disposed in `dispose()`.

---

### H2 — Silent empty catch blocks in auth notifier data-clearing methods

**File:** `lib/features/auth/application/providers/auth_provider.dart:224–245, 252–271`

**Severity:** HIGH

**Issue:** Both `_clearUserData()` and `_refreshUserData()` have catch blocks that silently swallow all exceptions with no logging.

**Code:**
```dart
} catch (e) {
  // Log error but don't fail the logout/guest mode
  // Guest mode should still work even if data clearing fails
}
```

**Impact:** If wishlist/cart/category refresh fails after login or logout, users see stale data from the previous session with no way to diagnose what went wrong. The comment says "log error" but no logging is actually done.

**Fix Required:**
```dart
} catch (e, st) {
  debugPrint('[AuthNotifier] _clearUserData failed: $e\n$st');
}
```
Or use the project's logger service if one exists.

---

## Medium Priority Issues

---

### M1 — Unnecessary full rebuild on every OTP digit change

**File:** `lib/features/auth/presentation/screen/otp_screen.dart:73–83`

**Severity:** MEDIUM

**Issue:** `_onOtpChanged()` calls `setState(() {})` unconditionally after every keystroke to trigger a rebuild for button enable/disable logic.

**Code:**
```dart
void _onOtpChanged() {
  if (_hasOtpError) {
    setState(() {
      _hasOtpError = false;
      _otpErrorMessage = '';
    });
  }
  setState(() {}); // unconditional full rebuild
}
```

**Impact:** Every digit press rebuilds the entire `OTPScreen` widget tree (6 input fields, button, error state). On low-end devices this causes visible jank during fast OTP entry.

**Fix Required:** Replace the raw `setState(() {})` with a `ValueNotifier<bool>` for the button's enabled state. Only call `setState` when `_hasOtpError` actually changes.

---

### M2 — Hardcoded pixel sizes in OTP loading indicator

**File:** `lib/features/auth/presentation/screen/otp_screen.dart:488–494`

**Severity:** MEDIUM

**Issue:** The loading spinner inside the OTP button uses hardcoded raw pixel values instead of ScreenUtil responsive sizes.

**Code:**
```dart
const SizedBox(
  height: 24,   // should be 24.h
  width: 24,    // should be 24.w
  child: CircularProgressIndicator(
    strokeWidth: 3.0, // should be 3.r
    color: Colors.white,
  ),
)
```

**Impact:** The spinner does not scale on tablets or high-density displays, appearing disproportionately small and inconsistent with the rest of the auth UI.

**Fix Required:** `SizedBox(height: 24.h, width: 24.w, child: CircularProgressIndicator(strokeWidth: 3.r, color: Colors.white))`. Remove `const`.

---

### M3 — OTP screen fade-in transition is 2 seconds — excessively long

**File:** `lib/app/router/app_router.dart:144–150`

**Severity:** MEDIUM

**Issue:** The OTP route's `CustomTransitionPage` uses a `transitionDuration` of 2 full seconds.

**Code:**
```dart
pageBuilder: (context, state) => CustomTransitionPage(
  key: state.pageKey,
  child: const OTPScreen(),
  transitionDuration: const Duration(seconds: 2), // way too slow
  ...
),
```

**Impact:** Users experience a 2-second wait on the most frequently visited auth screen. This reads as a broken or frozen app. Standard Flutter transitions are 250–400ms.

**Fix Required:** `transitionDuration: const Duration(milliseconds: 350)`.

---

---

# QA Prompt 4 — Code Quality & Deployment Readiness

---

## Critical Issues

---

### C1 — Broken new-user onboarding: address navigation commented out (deployment blocker)

**File:** `lib/features/auth/presentation/screen/otp_screen.dart:533–538`

**Severity:** CRITICAL

**Issue:** Identical to Prompt 3 C1 — listed again because it is a hard deployment blocker. New users who verify via OTP never reach address setup.

**Code:**
```dart
if (state.isNewUser) {
  // goToAddress(context,);
} else {
  goToHome(context);
}
```

**Impact:** The new-user registration flow via OTP is non-functional. All OTP-registered users skip address setup.

**Fix Required:** `goToAddress(context, state.user);`

---

### C2 — Zero test files exist for the entire auth feature

**File:** `lib/features/auth/` (entire directory)

**Severity:** CRITICAL

**Issue:** There are no unit, widget, or integration tests anywhere in the auth feature directory. All 10 screens and the full `AuthNotifier` state machine are untested.

**Impact:** Any regression in login, signup, OTP, forgot password, or session restore silently ships to production. CI cannot catch regressions. The auth flow is the highest-risk feature in the app.

**Fix Required:** At minimum, add:
- Unit tests for every `AuthNotifier` state transition (login success, login failure, OTP send, OTP verify, logout, guest mode)
- Unit tests for `AuthRepositoryImpl` mocking `AuthApi` and `AuthLocalDs`
- Widget tests for `LoginScreen` (happy path + error state) and `OTPScreen` (send OTP + verify OTP)

---

## High Priority Issues

---

### H1 — Password minimum length is inconsistent between signup and reset

**File:** `lib/features/auth/presentation/screen/signup_password_screen.dart:212` vs `lib/features/auth/presentation/screen/reset_password_screen.dart:59`

**Severity:** HIGH

**Issue:** Signup enforces a minimum of 8 characters; reset password enforces only 6 characters. The two screens use different constants.

**Code:**
```dart
// signup_password_screen.dart
if (password.length < 8) {
  _showError('Password must be at least 8 characters');

// reset_password_screen.dart
if (password.length < 6) {
  _showSnack('Password must be at least 6 characters');
```

**Impact:** A user who resets their password to 6–7 characters cannot reproduce it on a fresh signup. Creates confusion and a weaker reset-path security standard.

**Fix Required:** Define `const int kMinPasswordLength = 8;` in a constants file. Replace both hardcoded values. Update the hint text in `ResetPasswordScreen` to say "at least 8 characters" (it currently says 6).

---

### H2 — OTP expiry timer fires `AuthError` in wrong context

**File:** `lib/features/auth/application/providers/auth_provider.dart:176–186`

**Severity:** HIGH

**Issue:** The OTP expiry timer emits `AuthError('OTP Expired')` after 5 minutes regardless of what state the user is in. If the user is still on the phone-number entry step (before the OTP was shown), the error fires unexpectedly.

**Code:**
```dart
_otpExpiryTimer = Timer(const Duration(seconds: 300), () {
  if (state is OtpSent) { // guard is too narrow — OtpVerifying not covered
    state = const AuthError(
      failure: AppFailure('OTP Expired'),
      previousState: GuestMode(),
    );
  }
});
```

**Impact:** An "OTP Expired" snackbar appearing when the user never even entered OTP fields is confusing. The timer also starts on every `sendOtp()` call including resends, potentially firing for a previously cancelled OTP.

**Fix Required:** Cancel and restart the timer only on a fresh OTP send. In the handler, check `if (state is OtpSent || state is OtpVerifying)` before emitting the error. The OTP screen's listener should reset back to the phone-number step on expiry.

---

### H3 — Commented-out dead code left in production API layer

**File:** `lib/features/auth/infrastructure/data_sources/remote/auth_api.dart:41`

**Severity:** HIGH

**Issue:** A commented-out line from a previous implementation remains in the login API method.

**Code:**
```dart
// final user = UserEntity.fromMap(res.data['user']); // ← stale dead code
final data = res.data as Map<String, dynamic>;
final user = UserEntity.fromMap(data['user']);
```

**Impact:** Adds noise, confuses reviewers about which parsing path is correct, and signals incomplete cleanup. Should not exist in a production file.

**Fix Required:** Delete the commented line entirely.

---

## Medium Priority Issues

---

### M1 — `Future.delayed` used as a timing hack for focus management

**File:** `lib/features/auth/presentation/screen/otp_screen.dart:521`

**Severity:** MEDIUM

**Issue:** A raw 100ms delay is used to defer focus request to the OTP field after the field becomes visible.

**Code:**
```dart
Future.delayed(const Duration(milliseconds: 100), () {
  if (mounted) {
    _otpFocusNodes[0].requestFocus();
  }
});
```

**Impact:** The 100ms is arbitrary. On slower devices the field may not be laid out yet; on fast devices it is an unnecessary wait. Magic delay values are fragile and non-deterministic.

**Fix Required:**
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) _otpFocusNodes[0].requestFocus();
});
```
This fires deterministically after the frame is committed, with no hardcoded delay.

---

### M2 — Clipboard polling triggers a system privacy alert on Android 12+ and iOS 16+

**File:** `lib/features/auth/presentation/screen/forgot_password_otp_screen.dart:53–66`

**Severity:** MEDIUM

**Issue:** The app reads the clipboard silently every time the first OTP field gains focus, not just on first mount.

**Code:**
```dart
_focusNodes[0].addListener(() {
  if (_focusNodes[0].hasFocus) {
    _checkClipboardForOtp(); // reads clipboard silently on every focus
  }
});
```

**Impact:** Android 12+ and iOS 16+ display a system-level toast ("App pasted from clipboard") on every clipboard access without an explicit user paste gesture. This appears multiple times if the user taps the field repeatedly, alarming users.

**Fix Required:** Remove manual clipboard polling. The field already has `autofillHints: const [AutofillHints.oneTimeCode]` — the OS will offer the OTP suggestion natively via the keyboard bar. Rely on this mechanism instead.

---

### M3 — "Remember Me" checkbox is non-functional

**File:** `lib/features/auth/presentation/screen/login_screen.dart:29`

**Severity:** MEDIUM

**Issue:** The `_rememberMe` bool is stored in widget state but is never passed to the login method or used anywhere.

**Code:**
```dart
bool _rememberMe = false;
// ...
void _handleLogin(AuthState state) {
  ref.read(authProvider.notifier).login(
    username: username,
    password: password,
    // rememberMe is never passed
  );
}
```

**Impact:** Users who tick "Remember Me" have exactly the same session behaviour as users who don't. The UI creates a false expectation of persistent sessions.

**Fix Required:** Either wire `_rememberMe` to the login call and have the backend issue a longer-lived session cookie, or remove the checkbox entirely until the feature is properly implemented end-to-end.

---

### M4 — Confirm password excluded from empty-field check in SignupPasswordScreen

**File:** `lib/features/auth/presentation/screen/signup_password_screen.dart:206`

**Severity:** MEDIUM

**Issue:** The empty-field guard only includes `password` in the list, not `confirm`.

**Code:**
```dart
if ([password].any((e) => e.isEmpty)) { // 'confirm' excluded
  _showError('All fields are required');
  return;
}
```

**Impact:** A user can submit with an empty confirm-password field. The mismatch check catches it, but shows "Passwords do not match" instead of the more accurate "All fields are required".

**Fix Required:**
```dart
if (password.isEmpty || confirm.isEmpty) {
  _showError('All fields are required');
  return;
}
```

---

---

# QA Prompt 6 — Architecture Compliance (4-Layer Violations)

---

## Critical Issues

---

### C1 — ForgotPasswordScreen: Presentation imports Infrastructure remote layer directly

**File:** `lib/features/auth/presentation/screen/forgot_password_screen.dart:9`

**Layer:** Presentation → Infrastructure (Rule 4 violation)

**Severity:** CRITICAL

**Issue:** The screen imports `auth_api.dart` from the `infrastructure/data_sources/remote/` directory. Presentation must never access `AuthApi`, `Dio`, or `Hive` directly — all access must go through a provider or notifier.

**Code:**
```dart
import '../../infrastructure/data_sources/remote/auth_api.dart';
```

**Impact:** The 4-layer boundary is broken. The application layer is bypassed entirely for this flow. GoRouter redirect logic, global auth state, and provider invalidation are all skipped.

**Fix Required:** Create a `ForgotPasswordNotifier` in the application layer. Screen imports only `application/providers/forgot_password_provider.dart`.

---

### C2 — ForgotPasswordOtpScreen: Presentation imports Infrastructure remote layer directly

**File:** `lib/features/auth/presentation/screen/forgot_password_otp_screen.dart:12`

**Layer:** Presentation → Infrastructure (Rule 4 violation)

**Severity:** CRITICAL

**Issue:** Same violation as C1. Both `sendOtp()` and `verifyOtpOnly()` are called on `authApiProvider` from a presentation screen.

**Code:**
```dart
import '../../infrastructure/data_sources/remote/auth_api.dart';
```

**Impact:** OTP verification for the forgot-password path produces zero Riverpod state. Loading and error states are managed with raw booleans. The entire flow is architecturally invisible.

**Fix Required:** Route through a `ForgotPasswordNotifier`. Remove the infrastructure import from the screen.

---

### C3 — ResetPasswordScreen: Presentation calls repository, bypassing StateNotifier

**File:** `lib/features/auth/presentation/screen/reset_password_screen.dart:9`

**Layer:** Presentation → bypasses Application layer (Rule 4 violation)

**Severity:** CRITICAL

**Issue:** The screen imports `auth_repository_provider.dart` and calls `repo.resetPassword()` directly, skipping the notifier entirely.

**Code:**
```dart
import '../../application/providers/auth_repository_provider.dart';
// ...
final repo = ref.read(authRepositoryProvider);
final result = await repo.resetPassword(newPassword: password);
```

**Impact:** Presentation is calling repository-level code directly. This is one layer below where presentation should interact. State management is entirely local.

**Fix Required:** Add `resetPassword()` to `AuthNotifier`. Screen uses `ref.read(authProvider.notifier).resetPassword(password)`.

---

## High Priority Issues

---

### H1 — Domain entity contains serialization logic

**File:** `lib/features/auth/domain/entities/user.dart:20–45`

**Layer:** Domain (Rule 8 violation)

**Severity:** HIGH

**Issue:** `UserEntity` contains `fromMap()`, `toMap()`, and `toString()` methods. Domain entities must contain only final fields — serialization to/from API JSON belongs in the infrastructure layer DTO.

**Code:**
```dart
factory UserEntity.fromMap(Map<String, dynamic> map) {
  return UserEntity(
    id: map['id'] as int,
    username: map['username'] as String,
    // ... directly mapping raw API keys
  );
}

Map<String, dynamic> toMap() { ... }
```

**Impact:** Domain layer gains a dependency on the shape of the API response (field names like `first_name`, `phone_number`). A backend key rename forces a change in the domain layer. Domain unit tests require raw Map mocks instead of clean constructors.

**Fix Required:** Move `fromMap` / `toMap` to `UserDto` in `infrastructure/models/`. The domain entity keeps only final fields and a primary constructor. `UserDto.toEntity()` performs the mapping.

---

### H2 — Domain entity has no `copyWith()` method

**File:** `lib/features/auth/domain/entities/user.dart:1–48`

**Layer:** Domain (Rule 20 violation)

**Severity:** HIGH

**Issue:** `UserEntity` has no `copyWith()`. Per architecture rules, entities must be immutable value objects with a safe update path.

**Code:**
```dart
class UserEntity {
  final int id;
  final String username;
  // ... 7 final fields, no copyWith
}
```

**Impact:** Any update to a `UserEntity` (e.g. after a profile edit) requires manually reconstructing all 7 fields. Error-prone and verbose.

**Fix Required:** Add a `copyWith()` method. Consider adopting `freezed` for compile-time immutability enforcement across all domain entities.

---

### H3 — Address route guard redirects to a non-existent route `/number`

**File:** `lib/app/router/app_router.dart:155–163`

**Layer:** Presentation (routing)

**Severity:** HIGH

**Issue:** The `/address` route's `AuthGuard` uses `redirectTo: '/number'` but `/number` is not defined anywhere in the GoRouter route table.

**Code:**
```dart
GoRoute(
  path: '/address',
  redirect: (context, state) {
    final guard = AuthGuard(ref);
    return guard.protect(redirectTo: '/number'); // /number does not exist
  },
  ...
),
```

**Impact:** Any unauthenticated attempt to access `/address` (e.g. deep link) causes a GoRouter navigation error (404 / assertion failure) in production.

**Fix Required:** Change `redirectTo: '/otp'` to point to the actual auth entry route. Confirm `/number` was not intended as an alias for `/otp`.

---

## Medium Priority Issues

---

### M1 — Hardcoded pixel values in OTP loading spinner violate ScreenUtil rules

**File:** `lib/features/auth/presentation/screen/otp_screen.dart:488–494`

**Layer:** Presentation (Rule 19 violation)

**Severity:** MEDIUM

**Issue:** The spinner inside the OTP button uses raw hardcoded integers instead of ScreenUtil responsive units.

**Code:**
```dart
const SizedBox(
  height: 24,       // should be 24.h
  width: 24,        // should be 24.w
  child: CircularProgressIndicator(strokeWidth: 3.0), // should be 3.r
)
```

**Impact:** Spinner does not scale on tablets or high-DPI displays. Inconsistent with the rest of the auth UI which correctly uses `.h`, `.w`, `.sp`, `.r`.

**Fix Required:** `SizedBox(height: 24.h, width: 24.w, child: CircularProgressIndicator(strokeWidth: 3.r, color: Colors.white))`. Remove `const`.

---

### M2 — Splash screen navigation has a race condition between animation and async session check

**File:** `lib/features/auth/presentation/screen/splash_screen.dart:27–41`

**Layer:** Presentation (Rule 21 — ref.read in wrong context)

**Severity:** MEDIUM

**Issue:** `_navigateBasedOnAuthState()` uses `ref.read(authProvider)` inside the animation's `whenComplete` callback. If `_checkExistingSession()` has not resolved by the time the animation finishes, `ref.read` captures `AuthChecking` and falls to the `else` branch — sending authenticated users to the OTP screen.

**Code:**
```dart
..forward().whenComplete(() {
  if (mounted) {
    _navigateBasedOnAuthState(); // ref.read here captures a snapshot
  }
});

void _navigateBasedOnAuthState() {
  final authState = ref.read(authProvider); // may still be AuthChecking
  if (authState is Authenticated) { ... }
  else { goToOTP(context); } // wrong for slow session checks
}
```

**Impact:** On cold start with a slow device or slow Hive read, authenticated users are incorrectly redirected to the OTP screen before being bounced back to home — a visible flash of the wrong screen.

**Fix Required:** Use `ref.listen` in `build()` exclusively for navigation. In `onLoaded.whenComplete`, only set `_animationDone = true` and call the listener-driven navigation, not `ref.read`.

---
