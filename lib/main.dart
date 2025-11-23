import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:new_app/core/navigation/main_navigation.dart';
import 'package:new_app/core/constants/hive_boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFcaf5ac), // Custom green color
      statusBarIconBrightness:
          Brightness.dark, // Dark icons for light background
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Open all required boxes concurrently for better performance
  await Future.wait([
    Hive.openBox(HiveBoxes.homeBox),
    Hive.openBox(HiveBoxes.catalogBox),
    Hive.openBox(HiveBoxes.userPrefsBox),
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Close all Hive boxes when app is disposed
    Hive.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes for better resource management
    switch (state) {
      case AppLifecycleState.paused:
        // App moved to background - could implement additional cleanup here
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground
        break;
      case AppLifecycleState.detached:
        // App is being terminated - ensure Hive is closed
        Hive.close();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 835), // From Figma design
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BTC Grocery',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: child,
        );
      },
      child: const MainNavigation(),
    );
  }
}
