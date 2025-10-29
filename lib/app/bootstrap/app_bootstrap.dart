import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef AppBuilder = FutureOr<Widget> Function();

/// Handles all application level bootstrapping before rendering the widget tree.
class AppBootstrap {
  const AppBootstrap._();

  /// Ensures bindings are initialised, wires up global error handling, and
  /// executes the provided [builder] inside a guarded zone.
  static Future<void> run(AppBuilder builder) async {
    await runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        FlutterError.onError = (details) {
          Zone.current.handleUncaughtError(
            details.exception,
            details.stack ?? StackTrace.empty,
          );
        };

        await _initialize();

        final widget = await builder();
        runApp(widget);
      },
      (error, stackTrace) {
        if (kDebugMode) {
          // ignore: avoid_print
          // log('Uncaught zone error: $error\n$stackTrace');
        }
      },
    );
  }

  static Future<void> _initialize() async {}
}
