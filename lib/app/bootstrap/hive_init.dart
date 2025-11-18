import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/hive/boxes.dart';

class HiveInit {
  const HiveInit._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();
    await Hive.openBox<dynamic>(AppHiveBoxes.cache);
    await Hive.openBox<dynamic>(AppHiveBoxes.profile);

    _initialized = true;
  }
}
