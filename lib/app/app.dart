import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'router/app_router.dart';
import 'theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  static const AppRouter _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    // Set the status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac),
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ScreenUtilInit(
      designSize: const Size(390, 835),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BTC Grocery',
          theme: AppTheme.light,
          darkTheme: AppTheme.light,
          themeMode: ThemeMode.system,
          initialRoute: AppRouter.initialRoute,
          onGenerateRoute: _router.onGenerateRoute,
        );
      },
    );
  }
}
