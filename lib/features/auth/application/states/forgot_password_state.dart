sealed class ForgotPasswordState {
  const ForgotPasswordState();
}

class FpInitial extends ForgotPasswordState {
  const FpInitial();
}

class FpLoading extends ForgotPasswordState {
  const FpLoading();
}

class FpOtpSent extends ForgotPasswordState {
  final String phone;
  const FpOtpSent({required this.phone});
}

class FpOtpVerified extends ForgotPasswordState {
  final String phone;
  final String otp;
  const FpOtpVerified({required this.phone, required this.otp});
}

class FpPasswordReset extends ForgotPasswordState {
  const FpPasswordReset();
}

class FpError extends ForgotPasswordState {
  final String message;
  final ForgotPasswordState previousState;
  const FpError({required this.message, required this.previousState});
}
