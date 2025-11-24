import 'dart:async';

import 'package:grocery_app/core/error/failure.dart';
import 'package:grocery_app/features/auth/application/providers/auth_repository_provider.dart';
import 'package:grocery_app/features/auth/application/states/auth_state.dart';
import 'package:grocery_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  late final AuthRepository _repository;
  Timer? _otpExpiryTimer;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);

    _checkExistingSession();

    return const AuthChecking();
  }

  // --------------------------------------------------------
  // CHECK EXISTING SESSION
  // --------------------------------------------------------
  Future<void> _checkExistingSession() async {
    final session = await _repository.getCurrentSession();

    if (session != null) {
      final user = await _repository.getSavedUser();

      if (user != null) {
        state = Authenticated(user: user, isNewUser: false);
        return; // IMPORTANT!
      }
    }

    state = const AuthInitial(); // runs only if no session
  }

  // --------------------------------------------------------
  // SEND OTP
  // --------------------------------------------------------
  Future<void> sendOtp(String mobileNumber) async {
    state = OtpSending(mobileNumber);

    final result = await _repository.sendOTP(phoneNumber: mobileNumber);

    result.fold(
      (failure) => state = AuthError(
        failure: failure,
        previousState: const AuthInitial(),
      ),
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
    state = const AuthLoading(message: "Creating account...");

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
        state = AuthError(failure: failure, previousState: const AuthInitial());
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
    state = const AuthLoading(message: "Logging in...");

    final result = await _repository.login(
      username: username,
      password: password,
    );

    result.fold(
      (failure) {
        state = AuthError(failure: failure, previousState: const AuthInitial());
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
          failure: AppFailure("OTP Expired"),
          previousState: AuthInitial(),
        );
      }
    });
  }

  // // --------------------------------------------------------
  // // LOGOUT (optional)
  // // --------------------------------------------------------
  // Future<void> logout() async {
  //   await _repository.logout();
  //   state = AuthInitial();
  // }

  // @override
  // void dispose() {
  //   _otpExpiryTimer?.cancel();
  //   super.dispose();
  // }
}
