import 'package:grocery_app/core/storage/hive/keys.dart';
import 'package:hive_ce/hive.dart';

class Boxes {
  const Boxes._();

  static const String cache = 'app_cache_box';
  static late Box userBox;
  static late Box addressBox;

  static Future<void> openHiveBoxes() async {
    userBox = await Hive.openBox(HiveKeys.userbox);
    addressBox = await Hive.openBox(HiveKeys.addressBox);
  }
}
