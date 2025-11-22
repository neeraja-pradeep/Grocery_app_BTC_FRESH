import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:new_app/core/navigation/main_navigation.dart';

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

  // Open the required Hive boxes
  await Hive.openBox('home_cache_box');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'New App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          const MainNavigation(), // ✅ This provides Directionality and navigation
    );
  }
}
