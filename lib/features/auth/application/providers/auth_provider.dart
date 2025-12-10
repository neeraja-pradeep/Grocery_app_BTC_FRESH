import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
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
    } catch (e) {
      state = const GuestMode();
      rethrow;
    }
  }

  // --------------------------------------------------------
  // CONTINUE AS GUEST
  // --------------------------------------------------------
  void continueAsGuest() {
    _otpExpiryTimer?.cancel();
    state = const GuestMode();
  }
}
