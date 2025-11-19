import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../features/profile/presentation/screen/profile_screen.dart';
import 'router/app_router.dart';
import 'theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  static const AppRouter _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 835),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Grocery App',
          theme: AppTheme.light,
          darkTheme: AppTheme.light,
          themeMode: ThemeMode.system,
          // TEMPORARILY SHOWING PROFILE SCREEN FOR TESTING
          home: const ProfileScreen(),
          // Uncomment below to use router navigation
          // initialRoute: AppRouter.initialRoute,
          // onGenerateRoute: _router.onGenerateRoute,
        );
      },
    );
  }
}
