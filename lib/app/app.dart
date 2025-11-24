// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import 'router/app_router.dart';
// import 'theme/theme.dart';

// class App extends StatelessWidget {
//   const App({super.key});

//   static const AppRouter _router = AppRouter();

//   @override
//   Widget build(BuildContext context) {
//     return ScreenUtilInit(
//       designSize: const Size(375, 812),
//       minTextAdapt: true,
//       splitScreenMode: true,
//       builder: (context, _) {
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'Grocery App',
//           theme: AppTheme.light,
//           darkTheme: AppTheme.light,
//           themeMode: ThemeMode.system,
//           initialRoute: AppRouter.initialRoute,
//           onGenerateRoute: _router.onGenerateRoute,
//         );
//       },
//     );
//   }
// }
