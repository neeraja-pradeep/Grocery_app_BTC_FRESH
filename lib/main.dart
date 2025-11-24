import 'package:grocery_app/app/bootstrap/app_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/app/router/app_router.dart';
import 'package:grocery_app/core/network/api_client.dart';
import 'package:grocery_app/core/providers/network_providers.dart';

Future<void> main() async {
  await AppBootstrap.run(() async {
    final api = AppBootstrap.result.apiClient;

    return ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(api.dio),
        cookieJarProvider.overrideWithValue(api.cookieJar),
        apiClientProvider.overrideWithValue(api),
      ],
      child: const MyApp(),
    );
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      routerConfig: router,
    );
  }
}
