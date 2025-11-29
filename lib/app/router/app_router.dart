import 'package:flutter/material.dart';
import 'package:grocery_app/features/cart/presentation/screen/cart_screen.dart';
import 'package:grocery_app/features/cart/presentation/screen/coupons_screen.dart';

import '../../features/auth/presentation/screen/login_screen.dart';
import '../../features/bottomnavbar/bottom_navbar.dart';
import '../../features/product_details/presentation/screen/product_details_screen.dart';

class AppRouter {
  const AppRouter();

  static const String home = '/';
  static const String login = '/auth/login';
  static const String bottomNavBar = '/auth/login/bottomNavBar';
  static const String productDetails = '/product-details';
  static const String cart = '/cart';
  static const String coupon = '/coupon';

  static const String initialRoute = home;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute<void>(settings, const LoginScreen());
      case home:
        return _buildRoute<void>(
          settings,
          BottomNavigation(key: BottomNavigation.globalKey),
        );
      case bottomNavBar:
        return _buildRoute<void>(
          settings,
          BottomNavigation(key: BottomNavigation.globalKey),
        );
      case productDetails:
        final variantId = settings.arguments as String?;
        if (variantId == null || variantId.isEmpty) {
          return _buildRoute<void>(
            settings,
            UnknownRouteScreen(unknownRoute: settings.name),
          );
        }
        return _buildRoute<void>(
          settings,
          ProductDetailsScreen(variantId: variantId),
        );
      case cart:
        return _buildRoute<void>(settings, const CartScreen());
      case coupon:
        return _buildRoute<void>(settings, const CouponsScreen());

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
