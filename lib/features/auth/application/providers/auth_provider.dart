import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../../category/application/providers/category_providers.dart';
import '../../../wishlist/application/providers/wishlist_provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../states/auth_state.dart';
import 'auth_repository_provider.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  late final AuthRepository _repository;
  Timer? _otpExpiryTimer;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);

    // Dispose timer when provider is disposed to prevent memory leaks
    ref.onDispose(() {
      _otpExpiryTimer?.cancel();
    });

    _checkExistingSession();

    return const AuthChecking();
  }

  // --------------------------------------------------------
  // CHECK EXISTING SESSION
  // --------------------------------------------------------
  Future<void> _checkExistingSession() async {
    try {
      final session = await _repository.getCurrentSession();

      if (session != null) {
        final user = await _repository.getSavedUser();

        if (user != null) {
          state = Authenticated(user: user, isNewUser: false);
          return;
        }
      }

      // No session found - user can browse as guest
      state = const GuestMode();
    } catch (e) {
      // Handle corrupted Hive data or malformed cookies
      try {
        await _repository.logout();
      } catch (_) {
        // If logout fails, still proceed to guest mode for safety
      }

      // Always set guest mode to allow app to continue
      state = const GuestMode();
    }
  }

  // --------------------------------------------------------
  // SEND OTP
  // --------------------------------------------------------
  Future<void> sendOtp(String mobileNumber) async {
    state = OtpSending(mobileNumber);

    final result = await _repository.sendOTP(phoneNumber: mobileNumber);

    result.fold(
      (failure) =>
          state = AuthError(failure: failure, previousState: const GuestMode()),
      (isSuccess) {
        state = OtpSent(
          mobileNumber: mobileNumber,
          isSuccess: isSuccess,
          expiresInSeconds: 300,
        );
        _startOtpExpiryTimer();
      },
    );
  }

  // --------------------------------------------------------
  // VERIFY OTP
  // --------------------------------------------------------
  Future<void> verifyOtp(String mobile, String otp) async {
    state = OtpVerifying(mobile);

    final result = await _repository.verifyOTP(
      phoneNumber: mobile,
      otpCode: otp,
    );

    result.fold(
      (failure) => state = AuthError(failure: failure, previousState: state),
      (user) {
        state = Authenticated(user: user, isNewUser: false);

        // Refresh user-specific data after successful login
        _refreshUserData();
      },
    );
  }

  // --------------------------------------------------------
  // SIGNUP
  // --------------------------------------------------------
  Future<void> signup({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    state = const AuthLoading(message: 'Creating account...');

    final result = await _repository.signup(
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
    );

    result.fold(
      (failure) {
        state = AuthError(failure: failure, previousState: const GuestMode());
      },
      (user) {
        state = Authenticated(user: user, isNewUser: true);

        // Refresh user-specific data after successful signup
        _refreshUserData();
      },
    );
  }

  // --------------------------------------------------------
  // LOGIN
  // --------------------------------------------------------
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthLoading(message: 'Logging in...');

    final result = await _repository.login(
      username: username,
      password: password,
    );

    result.fold(
      (failure) {
        state = AuthError(failure: failure, previousState: const GuestMode());
      },
      (user) {
        state = Authenticated(user: user, isNewUser: false);

        // Refresh user-specific data after successful login
        _refreshUserData();
      },
    );
  }

  // --------------------------------------------------------
  // OTP EXPIRY TIMER
  // --------------------------------------------------------
  void _startOtpExpiryTimer() {
    _otpExpiryTimer?.cancel();
    _otpExpiryTimer = Timer(const Duration(seconds: 300), () {
      if (state is OtpSent) {
        state = const AuthError(
          failure: AppFailure('OTP Expired'),
          previousState: GuestMode(),
        );
      }
    });
  }

  // --------------------------------------------------------
  // LOGOUT
  // --------------------------------------------------------
  Future<void> logout() async {
    try {
      _otpExpiryTimer?.cancel();
      await _repository.logout();
      state = const GuestMode();

      // Clear user-specific data after logout
      await _clearUserData();
    } catch (e) {
      state = const GuestMode();
      // Still try to clear data even if logout fails
      await _clearUserData();
      rethrow;
    }
  }

  // --------------------------------------------------------
  // CONTINUE AS GUEST
  // --------------------------------------------------------
  void continueAsGuest() {
    _otpExpiryTimer?.cancel();
    state = const GuestMode();

    // Clear user-specific data when entering guest mode
    _clearUserData();
  }

  // --------------------------------------------------------
  // CLEAR USER-SPECIFIC DATA
  // --------------------------------------------------------
  /// Clears cached data that belongs to authenticated users
  /// This includes cart, wishlist, and refreshes categories
  Future<void> _clearUserData() async {
    try {
      // Import providers at the top of the file if needed
      // We'll use ref.read to access other providers

      // Clear wishlist cache and refresh
      final wishlistNotifier = ref.read(wishlistProvider.notifier);
      await wishlistNotifier.clearCacheAndRefresh();

      // Clear cart cache (checkout lines need to be re-fetched for guest)
      // Cart will be empty for guests or show different data
      final checkoutLineController = ref.read(
        checkoutLineControllerProvider.notifier,
      );
      await checkoutLineController.refresh();

      // Refresh category data to show guest version
      final categoryController = ref.read(categoryControllerProvider.notifier);
      await categoryController.refresh(force: true);
    } catch (e) {
      // Log error but don't fail the logout/guest mode
      // Guest mode should still work even if data clearing fails
    }
  }

  // --------------------------------------------------------
  // REFRESH USER-SPECIFIC DATA
  // --------------------------------------------------------
  /// Refreshes user-specific data after successful login
  /// This loads the authenticated user's cart, wishlist, and category preferences
  Future<void> _refreshUserData() async {
    try {
      // Refresh wishlist to load user's saved items
      final wishlistNotifier = ref.read(wishlistProvider.notifier);
      await wishlistNotifier.refresh();

      // Refresh cart to load user's cart items
      final checkoutLineController = ref.read(
        checkoutLineControllerProvider.notifier,
      );
      await checkoutLineController.refresh();

      // Refresh category data to show user's preferences (liked products, etc.)
      final categoryController = ref.read(categoryControllerProvider.notifier);
      await categoryController.refresh(force: true);
    } catch (e) {
      // Log error but don't fail the login
      // User should still be logged in even if data refresh fails
    }
  }
}
