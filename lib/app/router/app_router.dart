import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/app/router/auth_guard.dart';
import 'package:grocery_app/features/auth/application/providers/auth_provider.dart';
import 'package:grocery_app/features/auth/application/states/auth_state.dart';
import 'package:grocery_app/features/auth/domain/entities/user.dart';
import 'package:grocery_app/features/auth/presentation/screen/address_screen.dart';
import 'package:grocery_app/features/auth/presentation/screen/home_screen.dart';
import 'package:grocery_app/features/auth/presentation/screen/login_screen.dart';
import 'package:grocery_app/features/auth/presentation/screen/otp_screen.dart';
import 'package:grocery_app/features/auth/presentation/screen/signup_password_screen.dart';
import 'package:grocery_app/features/auth/presentation/screen/signup_screen.dart';
import 'package:grocery_app/features/auth/presentation/screen/splash_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',

    // // Auto refresh router on authState updates (Riverpod 3)
    // refreshListenable: ref.listenable(authProvider),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final authState = ref.read(authProvider);
      final isAuthenticated = authState is Authenticated;

      final isAuthRoute = location == '/login' || location == '/otp';

      // If logged in → block auth screens
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/sign-pass',
        builder: (context, state) {
          final data = state.extra as Map<String, String>;

          return SignupPasswordScreen(
            username: data['username']!,
            email: data['email']!,
            first: data['first']!,
            last: data['last']!,
            number: data['number']!,
          );
        },
      ),

      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OTPScreen(),
          transitionDuration: const Duration(seconds: 2),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // PROTECTED ROUTE EXAMPLE (Using AuthGuard)
      GoRoute(
        path: '/address',
        redirect: (context, state) {
          final guard = AuthGuard(ref);
          return guard.protect(redirectTo: '/number');
        },
        builder: (context, state) {
          final user = state.extra as UserEntity;
          return AddressScreen(user: user);
        },
      ),
      GoRoute(path: '/home', builder: (_, state) => const HomeScreen()),
    ],
  );
});

void goToHome(BuildContext context) {
  context.go('/home');
}

void goToAddress(BuildContext context, UserEntity user) {
  context.go('/address', extra: user);
}

void goToOTP(BuildContext context) {
  context.go('/otp');
}

void goToLogin(BuildContext context) {
  context.push('/login');
}

void goToSignup(BuildContext context) {
  context.push('/signup');
}

void goToSignWithPass(
  BuildContext context, {
  required String username,
  required String email,
  required String first,
  required String last,
  required String number,
}) {
  context.push(
    '/sign-pass',
    extra: {
      'username': username,
      'email': email,
      'first': first,
      'last': last,
      'number': number,
    },
  );
}
