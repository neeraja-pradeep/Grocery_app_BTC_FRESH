import 'package:flutter/material.dart';

import '../../features/auth/presentation/screen/login_screen.dart';
import '../../features/home/screen/home_screen.dart';

class AppRouter {
  const AppRouter();

  static const String home = '/';
  static const String login = '/auth/login';

  static const String initialRoute = home;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildRoute<void>(settings, const HomeScreen());
      case login:
        return _buildRoute<void>(settings, const LoginScreen());
      default:
        return _buildRoute<void>(
          settings,
          UnknownRouteScreen(unknownRoute: settings.name),
        );
    }
  }

  MaterialPageRoute<T> _buildRoute<T>(RouteSettings settings, Widget child) {
    return MaterialPageRoute<T>(builder: (_) => child, settings: settings);
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key, required this.unknownRoute});

  final String? unknownRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Text(
          'No route registered for "$unknownRoute".',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
