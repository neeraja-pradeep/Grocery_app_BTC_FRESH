import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/network/socket_provider.dart';
import '../core/polling/polling_navigation_observer.dart';
import '../core/widgets/network_status_banner.dart';
import 'router/app_router.dart';
import 'theme/theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  static const AppRouter _router = AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize Socket.IO on app startup
    ref.watch(socketServiceProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Grocery App',
          theme: AppTheme.light,
          initialRoute: AppRouter.initialRoute,
          onGenerateRoute: _router.onGenerateRoute,
          navigatorObservers: [
            PollingNavigationObserver(), // ← Auto pause/resume polling on navigation
          ],
          builder: (context, child) {
            return Column(
              children: [
                // Global Network Status Banner (inside MaterialApp context)
                const NetworkStatusBanner(),
                // App content
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            );
          },
        );
      },
    );
  }
}
