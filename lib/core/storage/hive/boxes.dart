import 'package:hive_ce/hive.dart';

import 'keys.dart';

class Boxes {
  const Boxes._();

  // Box names
  static const String cache = 'app_cache_box';
  static const String profile = 'profile_box';
  static const String address = 'address_box';
  static const String homeBox = 'homeBox';
  static const String catalogBox = 'catalogBox';
  static const String userPrefsBox = 'userPrefsBox';
  static const String deliveryTracking = 'delivery_tracking_box';

  // Late initialized boxes
  static late Box userBox;
  static late Box addressBox;
  static late Box cacheBox;
  static late Box profileBox;
  static late Box deliveryTrackingBox;

  static Future<void> openHiveBoxes() async {
    userBox = await Hive.openBox(HiveKeys.userbox);
    addressBox = await Hive.openBox(HiveKeys.addressBox);
    cacheBox = await Hive.openBox(cache); // Global cache box for features
    profileBox = await Hive.openBox(profile); // Profile data cache
    deliveryTrackingBox = await Hive.openBox(
      deliveryTracking,
    ); // Delivery tracking persistence
  }

  /// Close all Hive boxes
  static Future<void> closeHiveBoxes() async {
    await userBox.close();
    await addressBox.close();
    await cacheBox.close();
    await profileBox.close();
    await deliveryTrackingBox.close();
  }

  /// Clear all data from all boxes
  static Future<void> clearAllData() async {
    await userBox.clear();
    await addressBox.clear();
    await cacheBox.clear();
    await profileBox.clear();
    await deliveryTrackingBox.clear();
  }

  /// Clear only user-specific data
  static Future<void> clearUserDataOnly() async {
    await userBox.clear();
    await addressBox.clear();
    await profileBox.clear();
    // Note: cacheBox contains feature cache, may want to keep or clear based on use case
  }
}

// Alias for backward compatibility
typedef AppHiveBoxes = Boxes;
typedef HiveBoxes = Boxes;
