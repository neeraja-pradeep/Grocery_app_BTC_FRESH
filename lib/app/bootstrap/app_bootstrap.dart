import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import 'hive_init.dart';

class AppBootstrapResult {
  final ApiClient apiClient;

  AppBootstrapResult({required this.apiClient});
}

class AppBootstrap {
  const AppBootstrap._();

  static late AppBootstrapResult result;

  static Future<void> run(FutureOr<Widget> Function() builder) async {
    // Shared bootstrap body — runs inside either Sentry's guarded zone (when
    // a DSN is configured) or the plain runZonedGuarded fallback below.
    Future<void> bootstrapApp() async {
      WidgetsFlutterBinding.ensureInitialized();

      // When Sentry is active it installs its own FlutterError handler and
      // chains the previous one, so this assignment is harmless and keeps
      // dev builds (no DSN) routing uncaught Flutter errors into the zone.
      FlutterError.onError = (details) {
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.empty,
        );
      };

      result = await _initialize();

      final widget = await builder();
      runApp(widget);
    }

    if (AppConfig.isSentryEnabled) {
      await SentryFlutter.init(
        (options) {
          options.dsn = AppConfig.sentryDsn;
          options.environment = AppConfig.isProduction
              ? 'production'
              : 'development';
          options.release = '${AppConfig.appName}@${AppConfig.appVersion}';
          // Errors-only scope: no performance tracing, no profiling.
          options.tracesSampleRate = 0.0;
          options.attachStacktrace = true;
          // Verbose logs only outside production.
          options.debug = !AppConfig.isProduction;
        },
        appRunner: bootstrapApp,
      );
    } else {
      await runZonedGuarded(
        bootstrapApp,
        (error, stack) {
          if (kDebugMode) {
            log('Uncaught zone error: $error\n$stack');
          }
          // No DSN configured — nothing to report to.
        },
      );
    }
  }

  static Future<AppBootstrapResult> _initialize() async {
    await HiveInit.initialize();

    final apiClient = ApiClient();
    await apiClient.init();

    return AppBootstrapResult(apiClient: apiClient);
  }
}
