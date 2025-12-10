// This file is no longer used.
// The main app widget is now defined in main.dart as MyApp using GoRouter.
// Keeping this file for reference only.

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import '../core/network/socket_provider.dart';
// import '../core/polling/polling_navigation_observer.dart';
// import '../core/widgets/network_status_banner.dart';
// import 'router/app_router.dart';
// import 'theme/theme.dart';

// class App extends ConsumerWidget {
//   const App({super.key});

//   static const AppRouter _router = AppRouter();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Initialize Socket.IO on app startup
//     ref.watch(socketServiceProvider);

//     // Set the status bar style
//     SystemChrome.setSystemUIOverlayStyle(
//       const SystemUiOverlayStyle(
//         statusBarColor: Color(0xFFcaf5ac),
//         statusBarIconBrightness: Brightness.dark,
//       ),
//     );

//     return ScreenUtilInit(
//       designSize: const Size(390, 835),
//       minTextAdapt: true,
//       splitScreenMode: true,
//       builder: (context, _) {
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'BTC Grocery',
//           theme: AppTheme.light,
//           initialRoute: AppRouter.initialRoute,
//           onGenerateRoute: _router.onGenerateRoute,
//           navigatorObservers: [
//             PollingNavigationObserver(),
//           ],
//           builder: (context, child) {
//             return Column(
//               children: [
//                 const NetworkStatusBanner(),
//                 Expanded(child: child ?? const SizedBox.shrink()),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }
