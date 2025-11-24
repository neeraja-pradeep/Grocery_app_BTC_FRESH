import 'package:grocery_app/core/storage/hive/adapters/address.dart';
import 'package:grocery_app/core/storage/hive/adapters/user.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/storage/hive/boxes.dart';

class HiveInit {
  const HiveInit._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    // 2️⃣ Register all adapters (must be before opening boxes)
    Hive.registerAdapter(AddressModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(AddressTypeAdapter());

    // 3️⃣ Open all needed boxes
    await Boxes.openHiveBoxes();

    _initialized = true;
  }
}
