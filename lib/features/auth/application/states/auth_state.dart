// File: lib/features/auth/application/states/auth_state.dart

import 'package:grocery_app/core/error/failure.dart';
import 'package:grocery_app/features/auth/domain/entities/user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthChecking extends AuthState {
  const AuthChecking();
}

/// ----------------------
/// 1️⃣ Initial State
/// ----------------------
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// ----------------------
/// 2️⃣ Loading (Login, Signup, Generic loading)
/// ----------------------
class AuthLoading extends AuthState {
  final String message;

  const AuthLoading({this.message = "Loading..."});
}

/// ----------------------
/// 3️⃣ OTP Sending
/// ----------------------
class OtpSending extends AuthState {
  final String mobileNumber;
  const OtpSending(this.mobileNumber);
}

/// ----------------------
/// 4️⃣ OTP Sent
/// ----------------------
class OtpSent extends AuthState {
  final String mobileNumber;
  final bool isSuccess;
  final int expiresInSeconds;

  const OtpSent({
    required this.mobileNumber,
    required this.isSuccess,
    required this.expiresInSeconds,
  });
}

/// ----------------------
/// 5️⃣ OTP Verifying
/// ----------------------
class OtpVerifying extends AuthState {
  final String mobileNumber;
  const OtpVerifying(this.mobileNumber);
}

/// ----------------------
/// 6️⃣ Authenticated
/// ----------------------
class Authenticated extends AuthState {
  final UserEntity user;
  final bool isNewUser;

  const Authenticated({required this.user, required this.isNewUser});
}

/// ----------------------
/// 7️⃣ Auth Error
/// ----------------------
class AuthError extends AuthState {
  final Failure failure;
  final AuthState previousState;

  const AuthError({required this.failure, required this.previousState});
}
