import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/hive/boxes.dart';

class HiveInit {
  const HiveInit._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Open all required boxes concurrently for better performance
    await Future.wait([
      // Profile module boxes
      Hive.openBox<dynamic>(AppHiveBoxes.cache),
      Hive.openBox<dynamic>(AppHiveBoxes.profile),
      Hive.openBox<dynamic>(AppHiveBoxes.address),
      // Home/Wishlist module boxes
      Hive.openBox<dynamic>(AppHiveBoxes.homeBox),
      Hive.openBox<dynamic>(AppHiveBoxes.catalogBox),
      Hive.openBox<dynamic>(AppHiveBoxes.userPrefsBox),
    ]);

    _initialized = true;
  }
}
