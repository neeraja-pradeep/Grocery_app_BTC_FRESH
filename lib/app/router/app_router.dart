import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/providers/auth_provider.dart';
import '../../features/auth/application/states/auth_state.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/screen/address_screen.dart';
import '../../features/auth/presentation/screen/forgot_password_otp_screen.dart';
import '../../features/auth/presentation/screen/forgot_password_screen.dart';
import '../../features/auth/presentation/screen/login_screen.dart';
import '../../features/auth/presentation/screen/otp_screen.dart';
import '../../features/auth/presentation/screen/password_changed_screen.dart';
import '../../features/auth/presentation/screen/reset_password_screen.dart';
import '../../features/auth/presentation/screen/signup_password_screen.dart';
import '../../features/auth/presentation/screen/signup_screen.dart';
import '../../features/auth/presentation/screen/splash_screen.dart';
import '../../features/bottomnavbar/bottom_navbar.dart';
import '../../features/cart/presentation/screen/cart_screen.dart';
import '../../features/home/presentation/screen/categories_with_sidebar_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/product_details/presentation/screen/product_details_screen.dart';
import '../../features/profile/presentation/screen/profile_screen.dart';
import 'auth_guard.dart';

/// Notifier class to refresh GoRouter when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authProvider, (prev, next) {
      notifyListeners();
    });
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshStream(ref);

  return GoRouter(
    // Start with splash screen which checks auth state
    initialLocation: '/splash',

    // Refresh router when auth state changes
    refreshListenable: refreshNotifier,

    // Redirect logic for protected routes
    redirect: (context, state) {
      final location = state.matchedLocation;
      final authState = ref.read(authProvider);
      final isAuthenticated = authState is Authenticated;
      final isCheckingAuth = authState is AuthChecking;

      // Skip redirect while checking auth (let splash screen handle it)
      if (isCheckingAuth && location == '/splash') {
        return null;
      }

      // Protected routes that require authentication (guests will be redirected to OTP)
      final protectedRoutes = [
        '/cart',
        '/checkout',
        '/profile',
        '/orders',
        '/account',
      ];

      final isProtectedRoute = protectedRoutes.any(
        (route) => location.startsWith(route),
      );

      // Auth routes (login, signup, otp, forgot password)
      final authRoutes = [
        '/login',
        '/signup',
        '/otp',
        '/sign-pass',
        '/forgot-password',
        '/forgot-password-otp',
        '/reset-password',
        '/password-changed',
      ];
      final isAuthRoute = authRoutes.any((route) => location.startsWith(route));

      // If authenticated → block auth screens (redirect to home)
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      // If not authenticated and trying to access protected routes → redirect to OTP
      if (!isAuthenticated && !isCheckingAuth && isProtectedRoute) {
        return '/otp';
      }

      // Guest mode: Allow access to guest-accessible routes
      // (no redirect needed for /home, /product-details, /category-products)

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) {
          // Pass redirect parameter to login screen
          final redirectTo = state.uri.queryParameters['redirect'];
          return LoginScreen(redirectTo: redirectTo);
        },
      ),
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
      GoRoute(
        path: '/home',
        builder: (_, state) =>
            BottomNavigation(key: BottomNavigation.globalKey),
      ),
      GoRoute(path: '/cart', builder: (_, state) => const CartScreen()),
      GoRoute(path: '/orders', builder: (_, state) => const OrdersScreen()),
      GoRoute(path: '/profile', builder: (_, state) => const ProfileScreen()),
      GoRoute(
        path: '/product-details/:variantId',
        builder: (context, state) {
          final variantId = state.pathParameters['variantId'] ?? '';
          return ProductDetailsScreen(variantId: variantId);
        },
      ),

      // Forgot Password Flow Routes
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password-otp',
        builder: (context, state) {
          final mobileNumber = state.extra as String;
          return ForgotPasswordOtpScreen(mobileNumber: mobileNumber);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          return ResetPasswordScreen(
            mobileNumber: data['mobileNumber']!,
            otp: data['otp']!,
          );
        },
      ),
      GoRoute(
        path: '/password-changed',
        builder: (context, state) => const PasswordChangedScreen(),
      ),
      GoRoute(
        path: '/category-products',
        builder: (context, state) => const CategoriesWithSidebarScreen(),
      ),
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

void goToLogin(BuildContext context, {String? redirectTo}) {
  final uri = redirectTo != null ? '/login?redirect=$redirectTo' : '/login';
  context.push(uri);
}

/// Handles post-login redirect to intended destination
void handlePostLoginRedirect(BuildContext context, GoRouterState? state) {
  // Check if there's a redirect query parameter
  final redirectPath = state?.uri.queryParameters['redirect'];

  if (redirectPath != null && redirectPath.isNotEmpty) {
    // Decode and navigate to intended destination
    final decodedPath = Uri.decodeComponent(redirectPath);
    context.go(decodedPath);
  } else {
    // Default: go to home
    context.go('/home');
  }
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

// Forgot Password Flow Navigation
void goToForgotPassword(BuildContext context) {
  context.push('/forgot-password');
}

void goToForgotPasswordOtp(
  BuildContext context, {
  required String mobileNumber,
}) {
  context.push('/forgot-password-otp', extra: mobileNumber);
}

void goToResetPassword(
  BuildContext context, {
  required String mobileNumber,
  required String otp,
}) {
  context.push(
    '/reset-password',
    extra: {'mobileNumber': mobileNumber, 'otp': otp},
  );
}

void goToPasswordChanged(BuildContext context) {
  context.push('/password-changed');
}

void goToLoginFromPasswordChanged(BuildContext context) {
  context.go('/login');
}

void goToOrders(BuildContext context) {
  context.push('/orders');
}
