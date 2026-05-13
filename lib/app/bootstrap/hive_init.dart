import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/storage/hive/adapters/address.dart';
import '../../core/storage/hive/adapters/delivery_tracking.dart';
import '../../core/storage/hive/adapters/user.dart';
import '../../core/storage/hive/boxes.dart';

class HiveInit {
  const HiveInit._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    // Register all adapters (must be before opening boxes)
    Hive.registerAdapter(AddressModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(AddressTypeAdapter());
    Hive.registerAdapter(DeliveryTrackingDataAdapter());

    // Open all needed boxes
    await Boxes.openHiveBoxes();

    _initialized = true;
  }

  /// Reset Hive state — for use in integration tests only.
  ///
  /// Closes all open boxes and clears the initialization flag so
  /// [initialize] can be called again with a fresh state.
  @visibleForTesting
  static Future<void> reset() async {
    if (!_initialized) return;
    await Boxes.closeHiveBoxes();
    _initialized = false;
  }
}
