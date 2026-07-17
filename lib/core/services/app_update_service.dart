import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Thin orchestrator over Google Play's In-App Update API.
///
/// The pop-up itself is rendered by Play Store — this service only decides
/// when to call `checkForUpdate` and which flow (immediate vs flexible) to
/// invoke. Silent failure throughout: an outage in Play Core must never
/// block the user from using the app.
///
/// See `in_app_update_implementation.md` for the full design rationale.
class AppUpdateService {
  AppUpdateInfo? _info;

  /// Entry point — call from the home screen's `initState` via a
  /// post-frame callback so an Activity context exists.
  ///
  /// Decision flow:
  /// 1. Bail on non-Android (iOS unsupported by Play Core).
  /// 2. Ask Play whether an update is available.
  /// 3. If `updatePriority >= 4` and immediate flow is allowed → blocking
  ///    Play-rendered overlay via `performImmediateUpdate`.
  /// 4. Otherwise, if flexible flow is allowed → background download via
  ///    `startFlexibleUpdate` + restart prompt via `completeFlexibleUpdate`.
  Future<void> checkAndPrompt() async {
    if (!Platform.isAndroid) return;

    try {
      _info = await InAppUpdate.checkForUpdate();
      if (_info!.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      // High-priority updates → blocking immediate flow.
      if ((_info!.updatePriority) >= 4 && _info!.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      // Otherwise → flexible (non-blocking) flow.
      if (_info!.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] check/prompt failed: $e');
      }
      // Silent failure — never block the user.
    }
  }
}
