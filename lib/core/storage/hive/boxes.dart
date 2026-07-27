import 'package:hive_ce/hive.dart';

import 'keys.dart';

class Boxes {
  const Boxes._();

  // Box names
  static const String cache = 'app_cache_box';
  static const String profile = 'profile_box';
  static const String address = 'address_box';
  static const String homeBox = 'homeBox';
  static const String deliveryTracking = 'delivery_tracking_box';

  // Late initialized boxes
  static late Box userBox;
  static late Box addressBox;
  static late Box cacheBox;
  static late Box profileBox;
  static late Box homeDataBox;
  static late Box deliveryTrackingBox;

  /// Compaction policy for the boxes we overwrite repeatedly.
  ///
  /// Hive boxes are append-only logs: overwriting a key appends a new entry and
  /// tombstones the old one, and the whole file is read into memory when the
  /// box is opened. The caches here are rewritten constantly, so without
  /// compaction the file keeps growing and startup gets slower the longer the
  /// app has been installed. This compacts once a quarter of the entries are
  /// dead, which keeps the file proportional to the live data.
  static bool _compactWhenQuarterDead(int entries, int deletedEntries) =>
      deletedEntries > 25 && deletedEntries / entries > 0.25;

  static Future<void> openHiveBoxes() async {
    // Opened concurrently rather than one after another. Every box is read off
    // disk before the first frame can render, so serialising six opens put
    // their full latency directly into cold-start time.
    final boxes = await Future.wait<Box<dynamic>>([
      Hive.openBox<dynamic>(HiveKeys.userbox),
      Hive.openBox<dynamic>(HiveKeys.addressBox),
      Hive.openBox<dynamic>(
        cache,
        compactionStrategy: _compactWhenQuarterDead,
      ),
      Hive.openBox<dynamic>(profile),
      Hive.openBox<dynamic>(
        homeBox,
        compactionStrategy: _compactWhenQuarterDead,
      ),
      Hive.openBox<dynamic>(
        deliveryTracking,
        compactionStrategy: _compactWhenQuarterDead,
      ),
    ]);

    userBox = boxes[0];
    addressBox = boxes[1];
    cacheBox = boxes[2];
    profileBox = boxes[3];
    homeDataBox = boxes[4];
    deliveryTrackingBox = boxes[5];
  }

  /// Close all Hive boxes
  static Future<void> closeHiveBoxes() async {
    await userBox.close();
    await addressBox.close();
    await cacheBox.close();
    await profileBox.close();
    await homeDataBox.close();
    await deliveryTrackingBox.close();
  }

  /// Clear all data from all boxes
  static Future<void> clearAllData() async {
    await userBox.clear();
    await addressBox.clear();
    await cacheBox.clear();
    await profileBox.clear();
    await homeDataBox.clear();
    await deliveryTrackingBox.clear();
  }

  /// Clear only user-specific data (keeps shared feature caches intact)
  static Future<void> clearUserDataOnly() async {
    await userBox.clear();
    await addressBox.clear();
    await profileBox.clear();
  }
}

// Alias for backward compatibility
typedef AppHiveBoxes = Boxes;
typedef HiveBoxes = Boxes;
