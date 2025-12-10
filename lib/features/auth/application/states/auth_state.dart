import '../../../../core/error/failure.dart';
import '../../domain/entities/user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthChecking extends AuthState {
  const AuthChecking();
}

/// Initial State
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Guest Mode (Browsing without authentication)
class GuestMode extends AuthState {
  const GuestMode();
}

/// Loading (Login, Signup, Generic loading)
class AuthLoading extends AuthState {
  final String message;

  const AuthLoading({this.message = 'Loading...'});
}

/// OTP Sending
class OtpSending extends AuthState {
  final String mobileNumber;
  const OtpSending(this.mobileNumber);
}

/// OTP Sent
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

/// OTP Verifying
class OtpVerifying extends AuthState {
  final String mobileNumber;
  const OtpVerifying(this.mobileNumber);
}

/// Authenticated
class Authenticated extends AuthState {
  final UserEntity user;
  final bool isNewUser;

  const Authenticated({required this.user, required this.isNewUser});
}

/// Auth Error
class AuthError extends AuthState {
  final Failure failure;
  final AuthState previousState;

  const AuthError({required this.failure, required this.previousState});
}
