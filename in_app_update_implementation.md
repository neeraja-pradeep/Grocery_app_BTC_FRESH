# In-App Update Pop-Up (Android) — Implementation Details

This document describes how the Android in-app update pop-up is implemented in this Flutter app using the [`in_app_update`](https://pub.dev/packages/in_app_update) package (currently pinned to `^4.2.3` in `pubspec.yaml`).

The pop-up is the system-rendered Google Play update dialog — the app does **not** render a custom modal. Play Core provides the UI; our code only decides *when* and *which flow* to invoke.

---

## 1. What `in_app_update` actually shows

The package is a thin Flutter wrapper over Google Play's **Play In-App Update API** (Play Core). It can trigger two distinct Play-rendered pop-ups:

| Flow | UI behavior | Use case |
|------|-------------|----------|
| **Immediate** | Full-screen Play-controlled overlay. User cannot use the app until they update or quit. App restarts automatically once installed. | Critical / breaking updates (e.g. force-upgrade for an API change). |
| **Flexible** | Small bottom dialog. User can dismiss and keep using the app while the update downloads in the background. App prompts again to "Restart" once download completes. | Optional / non-blocking updates. |

Both pop-ups are rendered by Play Store itself; you only control which flow is requested and when `complete` is called.

> Note: iOS is not supported by this API. The service short-circuits with a `Platform.isAndroid` guard.

---

## 2. Prerequisites (Android side)

1. **Play Store install** — the API only works for apps installed from Google Play (internal testing track counts).
2. **Signed build** — debug builds with a different signing key than the Play upload key will not see updates.
3. **Higher versionCode on Play** — Play must have a *newer* `versionCode` available on a track the test account has access to.
4. **`minSdkVersion`** — the package's underlying Play Core dependency requires `minSdk >= 21`. This project uses Flutter's default (`flutter.minSdkVersion` in `android/app/build.gradle.kts:39`), which satisfies this.
5. **No manual `AndroidManifest.xml` changes** required for `in_app_update ^4.2.x` — Play Core is pulled in transitively.

---

## 3. Project implementation

### 3.1 Service: `lib/core/services/app_update_service.dart`

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateInfo? _info;

  Future<void> checkAndPrompt() async {
    if (!Platform.isAndroid) return; // iOS no-op

    try {
      _info = await InAppUpdate.checkForUpdate();
      if (_info!.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      // High-priority updates → immediate (blocking) flow.
      if ((_info!.updatePriority ?? 0) >= 4 &&
          _info!.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      // Everything else → flexible (background) flow.
      if (_info!.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      if (kDebugMode) print('In-app update failed: $e');
      // Silent failure — never block the user.
    }
  }
}
```

### 3.2 Invocation: `lib/features/home/presentation/screens/home_screen.dart`

The check fires once on first frame of the home screen, *after* the user has been routed in (so it doesn't compete with auth/onboarding flows):

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppUpdateService().checkAndPrompt();
  });
  // ...
}
```

`addPostFrameCallback` ensures the call happens after the first build so the Play overlay has a proper Activity context to attach to.

---

## 4. Decision flow

```
checkAndPrompt()
  │
  ├─ Platform.isAndroid? ── no ──► return
  │
  ▼
InAppUpdate.checkForUpdate()
  │
  ├─ updateAvailability ≠ updateAvailable ──► return (nothing to do)
  │
  ▼
updatePriority ≥ 4  AND  immediateUpdateAllowed?
  │
  ├─ YES ──► InAppUpdate.performImmediateUpdate()   [blocking Play pop-up]
  │
  └─ NO  ──► flexibleUpdateAllowed?
              │
              ├─ YES ──► startFlexibleUpdate() → completeFlexibleUpdate()
              │
              └─ NO  ──► return
```

### Why `updatePriority >= 4`?

`AppUpdateInfo.updatePriority` is a 0–5 integer set by the developer in the **Play Developer API** when publishing a release (it is *not* set in the Play Console UI directly — it requires the API call). Convention used here:

| Priority | Meaning | Flow |
|----------|---------|------|
| 0–3 | Optional improvements | Flexible |
| 4–5 | Important / force update | Immediate |

If you never set priority via the Play Developer API, it defaults to `0`, so every update goes through the flexible flow. That is the safe default.

---

## 5. The two pop-ups in detail

### 5.1 Immediate update pop-up

Triggered by: `InAppUpdate.performImmediateUpdate()`

- Rendered full-screen by Play Store on top of the Activity.
- Shows app name, "Update" button, and a close (×) button. Closing the dialog leaves the app in a state where it should not proceed — typical pattern is to call `SystemNavigator.pop()` if the user cancels, but this implementation does not (Play itself blocks app usage while the dialog is up, and the user is free to quit).
- On accept: Play downloads + installs the new APK/AAB, then **automatically restarts** the app. No further code needed.
- The `Future` returned by `performImmediateUpdate()` resolves with an `AppUpdateResult` (`success` / `userDeniedUpdate` / `inAppUpdateFailed`). This implementation ignores the result and lets the catch block handle errors.

### 5.2 Flexible update pop-up

Triggered by: `InAppUpdate.startFlexibleUpdate()`

- Small bottom-sheet style dialog rendered by Play.
- User can dismiss it; the app remains fully usable.
- If accepted, the download runs in the background. The `Future` resolves when the download completes (or is cancelled / fails).
- After the download completes, `InAppUpdate.completeFlexibleUpdate()` shows a second Play pop-up prompting the user to **restart** the app to install. The install only happens after the user confirms the restart.

> Caveat in the current code: `startFlexibleUpdate()` is `await`-ed and then `completeFlexibleUpdate()` is called immediately. If the user dismisses the flexible pop-up, `startFlexibleUpdate` resolves with `AppUpdateResult.userDeniedUpdate` and `completeFlexibleUpdate()` will fail (caught by the try/catch). This is acceptable for fire-and-forget UX, but if you want to *only* prompt for restart on successful download you should branch on the result:
>
> ```dart
> final result = await InAppUpdate.startFlexibleUpdate();
> if (result == AppUpdateResult.success) {
>   await InAppUpdate.completeFlexibleUpdate();
> }
> ```

---

## 6. `AppUpdateInfo` fields used

Returned by `InAppUpdate.checkForUpdate()`:

| Field | Type | Meaning |
|-------|------|---------|
| `updateAvailability` | enum | `updateNotAvailable` / `updateAvailable` / `developerTriggeredUpdateInProgress` / `unknown` |
| `immediateUpdateAllowed` | bool | Whether the Play release allows immediate flow |
| `flexibleUpdateAllowed` | bool | Whether the Play release allows flexible flow |
| `updatePriority` | int? | 0–5 priority set via Play Developer API |
| `availableVersionCode` | int? | The `versionCode` of the update on Play |
| `installStatus` | enum | Used to resume a download in progress (not used here) |
| `clientVersionStalenessDays` | int? | Days since the user could have updated (useful for "nudge after N days" logic) |

---

## 7. Testing the pop-up

In-app update cannot be tested with `flutter run` debug builds. Use one of:

1. **Internal App Sharing** (fastest):
   - Build release AAB: `flutter build appbundle --release`
   - Upload to Play Console → Release → Internal app sharing → upload.
   - Use the *previous* shareable link to install version N on the device, then publish version N+1 to a new link. Open the app installed from link N — Play will detect N+1 is available.

2. **Internal testing track**:
   - Publish version N, accept the test invite, install via Play.
   - Publish version N+1 to the same track.
   - Reopen the app — `checkForUpdate()` will report `updateAvailable`.

3. **`FakeAppUpdateManager`** (native Android instrumentation only — not exposed via `in_app_update` Flutter API). Not usable from Dart tests.

### Forcing the immediate flow during testing

The `updatePriority` is set via the Play Developer API at release publish time:

```bash
# Edit + commit a release with priority 5
gcloud auth application-default login
# Then use the Edits resource: edits.tracks.update with inAppUpdatePriority=5
```

There is no way to override priority client-side.

---

## 8. Why this implementation is shaped this way

- **Called from `HomeScreen.initState` via `addPostFrameCallback`** — guarantees an Activity context exists and the user is past the auth gate.
- **Service is stateless / re-instantiated per call** — `_info` is kept as an instance field but the service is created inline (`AppUpdateService().checkAndPrompt()`). This means there is no cross-screen throttling. Each fresh navigation to `HomeScreen` re-checks. Play Core itself rate-limits the actual network call, so this is fine in practice.
- **Silent failure** — any exception (no Play Store, no network, signing mismatch on debug build) is swallowed. The user must never be blocked by an in-app update infrastructure failure.
- **No custom UI** — by design. The Play-rendered dialog is the platform standard and gives the user a recognizable trust signal.

---

## 9. Things this implementation does **not** do (yet)

If/when needed, consider adding:

- **Listener for flexible download progress** — `InAppUpdate` does not expose a Dart stream for download progress in `^4.2.3`; you would need a custom platform channel or upgrade if a newer version exposes it.
- **Resume on app foreground** — if the user backgrounds during a flexible download, call `checkForUpdate()` again on `AppLifecycleState.resumed` and inspect `installStatus == downloaded` to re-show the restart prompt.
- **Staleness-based nudge** — escalate flexible → immediate when `clientVersionStalenessDays > N`.
- **Branch on `startFlexibleUpdate` result** before calling `completeFlexibleUpdate` (see §5.2 caveat).

---

## 10. References

- Package: <https://pub.dev/packages/in_app_update>
- Google Play In-App Updates guide: <https://developer.android.com/guide/playcore/in-app-updates>
- Play Developer API (for `inAppUpdatePriority`): <https://developers.google.com/android-publisher/api-ref/rest/v3/edits.tracks>

---

## File map

| File | Role |
|------|------|
| `pubspec.yaml:132` | Declares `in_app_update: ^4.2.3` |
| `lib/core/services/app_update_service.dart` | `AppUpdateService.checkAndPrompt()` — the entire decision logic |
| `lib/features/home/presentation/screens/home_screen.dart:68-70` | Single invocation site, fired from `initState` post-frame callback |
