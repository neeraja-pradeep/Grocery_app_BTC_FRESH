import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
    await runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        FlutterError.onError = (details) {
          Zone.current.handleUncaughtError(
            details.exception,
            details.stack ?? StackTrace.empty,
          );
        };

        // 🔥 COMBINED INITIALIZATION (theirs + yours)
        result = await _initialize();

        final widget = await builder();
        runApp(widget);
      },
      (error, stack) {
        if (kDebugMode) {
          log('Uncaught zone error: $error\n$stack');
        }
      },
    );
  }

  /// 🔥 This is the MERGED INITIALIZE function
  static Future<AppBootstrapResult> _initialize() async {
    // --- THEIR Hive init ---
    await HiveInit.initialize();

    // --- YOUR API client init ---
    final apiClient = ApiClient();
    await apiClient.init();

    return AppBootstrapResult(apiClient: apiClient);
  }
}
