import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/bootstrap/app_bootstrap.dart';
import 'app/router/app_router.dart';
import 'app/theme/colors.dart';
import 'core/network/api_client.dart';
import 'core/providers/network_providers.dart';
import 'features/auth/application/providers/auth_provider.dart';
import 'features/auth/application/states/auth_state.dart';

// Global container to access ProviderContainer
late ProviderContainer _container;

Future<void> main() async {
  await AppBootstrap.run(() async {
    final api = AppBootstrap.result.apiClient;

    _container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(api.dio),
        cookieJarProvider.overrideWithValue(api.cookieJar),
        apiClientProvider.overrideWithValue(api),
      ],
    );

    // Set the guest mode check function in ApiClient
    api.isGuestMode = () {
      final authState = _container.read(authProvider);
      return authState is GuestMode;
    };

    return UncontrolledProviderScope(
      container: _container,
      child: const MyApp(),
    );
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 835),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: ThemeData(
            useMaterial3: true,
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: AppColors.loaderGreen,
            ),
            fontFamily: 'Inter',
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontFamily: 'Poppins'),
              displayMedium: TextStyle(fontFamily: 'Poppins'),
              displaySmall: TextStyle(fontFamily: 'Poppins'),

              headlineLarge: TextStyle(fontFamily: 'Poppins'),
              headlineMedium: TextStyle(fontFamily: 'Poppins'),
              headlineSmall: TextStyle(fontFamily: 'Poppins'),

              titleLarge: TextStyle(fontFamily: 'Poppins'),

              bodyLarge: TextStyle(),
              bodyMedium: TextStyle(),
              bodySmall: TextStyle(),

              labelLarge: TextStyle(),
              labelMedium: TextStyle(),
              labelSmall: TextStyle(),
            ),
          ),
        );
      },
    );
  }
}
