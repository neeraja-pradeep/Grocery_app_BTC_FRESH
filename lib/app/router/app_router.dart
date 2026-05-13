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
import '../../features/cart/presentation/screen/confirm_order_screen.dart';
import '../../features/dev/presentation/screens/location_states_demo_screen.dart';
import '../../features/cart/presentation/screen/failed_order_screen.dart';
import '../../features/address/presentation/screens/address_list_screen.dart';
import '../../features/home/presentation/screen/categories_with_sidebar_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/product_details/presentation/screen/product_details_screen.dart';
import '../../features/profile/presentation/screen/contact_us_screen.dart';
import '../../features/profile/presentation/screen/profile_edit_screen.dart';
import '../../features/profile/presentation/screen/profile_screen.dart';
import 'auth_guard.dart';

const _protectedRoutes = {
  '/cart',
  '/checkout',
  '/profile',
  '/orders',
  '/account',
};

const _authRoutes = {
  '/login',
  '/signup',
  '/otp',
  '/sign-pass',
  '/forgot-password',
  '/forgot-password-otp',
  '/reset-password',
  '/password-changed',
};

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
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final authState = ref.read(authProvider);
      final isAuthenticated = authState is Authenticated;
      final isCheckingAuth = authState is AuthChecking;

      // Hold all routes until auth check completes
      if (isCheckingAuth) {
        return null;
      }

      final isProtectedRoute = _protectedRoutes.any(
        (route) => location.startsWith(route),
      );
      final isAuthRoute = _authRoutes.any((route) => location.startsWith(route));

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
          final rawData = state.extra;
          if (rawData == null || rawData is! Map) {
            // Redirect to signup if data is missing
            return const SignupScreen();
          }

          // Safely cast to Map<String, dynamic> first, then extract strings
          final data = rawData as Map<String, dynamic>;

          return SignupPasswordScreen(
            username: data['username']?.toString() ?? '',
            email: data['email']?.toString() ?? '',
            first: data['first']?.toString() ?? '',
            last: data['last']?.toString() ?? '',
            number: data['number']?.toString() ?? '',
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
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // PROTECTED ROUTE EXAMPLE (Using AuthGuard)
      GoRoute(
        path: '/address',
        redirect: (context, state) {
          final guard = AuthGuard(ref);
          return guard.protect(redirectTo: '/otp');
        },
        builder: (context, state) {
          final user = state.extra;
          if (user is! UserEntity) return const OTPScreen();
          return AddressScreen(user: user);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (_, state) =>
            BottomNavigation(key: BottomNavigation.globalKey),
      ),
      GoRoute(path: '/orders', builder: (_, state) => const OrdersScreen()),
      GoRoute(
        path: '/order-success',
        builder: (_, state) => const ConfirmOrderScreen(),
      ),
      GoRoute(
        path: '/order-failed',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return FailedOrderScreen(
              errorMessage: extra['error']?.toString(),
              isReservationExpired: extra['isReservationExpired'] == true,
            );
          }
          return const FailedOrderScreen();
        },
      ),
      GoRoute(path: '/profile', builder: (_, state) => const ProfileScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile/contact',
        builder: (_, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: '/address-list',
        builder: (_, state) => const AddressListScreen(),
      ),
      GoRoute(
        path: '/dev/location-states',
        builder: (_, state) => const LocationStatesDemoScreen(),
      ),
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
          final mobileNumber = state.extra as String?;
          if (mobileNumber == null || mobileNumber.isEmpty) {
            return const ForgotPasswordScreen();
          }
          return ForgotPasswordOtpScreen(mobileNumber: mobileNumber);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final rawData = state.extra;
          if (rawData == null || rawData is! Map) {
            // Redirect to forgot password if data is missing
            return const ForgotPasswordScreen();
          }

          final data = rawData as Map<String, dynamic>;
          return ResetPasswordScreen(
            mobileNumber: data['mobileNumber']?.toString() ?? '',
            otp: data['otp']?.toString() ?? '',
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
