import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/auth_repository.dart';
import '../states/forgot_password_state.dart';
import 'auth_repository_provider.dart';

part 'forgot_password_provider.g.dart';

@riverpod
class ForgotPassword extends _$ForgotPassword {
  late final AuthRepository _repository;

  @override
  ForgotPasswordState build() {
    _repository = ref.read(authRepositoryProvider);
    return const FpInitial();
  }

  Future<void> sendOtp(String phone) async {
    state = const FpLoading();
    final result = await _repository.sendOTP(phoneNumber: phone);
    result.fold(
      (failure) => state = FpError(
        message: failure.message,
        previousState: const FpInitial(),
      ),
      (_) => state = FpOtpSent(phone: phone),
    );
  }

  Future<void> resendOtp() async {
    final phone = _currentPhone;
    if (phone == null) return;
    state = const FpLoading();
    final result = await _repository.sendOTP(phoneNumber: phone);
    result.fold(
      (failure) => state = FpError(
        message: failure.message,
        previousState: FpOtpSent(phone: phone),
      ),
      (_) => state = FpOtpSent(phone: phone),
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (state is! FpOtpSent) return;
    final phone = (state as FpOtpSent).phone;
    state = const FpLoading();
    final result = await _repository.verifyOtpOnly(
      phoneNumber: phone,
      otp: otp,
    );
    result.fold(
      (failure) => state = FpError(
        message: failure.message,
        previousState: FpOtpSent(phone: phone),
      ),
      (_) => state = FpOtpVerified(phone: phone, otp: otp),
    );
  }

  Future<void> resetPassword(String newPassword) async {
    if (state is! FpOtpVerified) return;
    final verified = state as FpOtpVerified;
    state = const FpLoading();
    final result = await _repository.resetPassword(
      newPassword: newPassword,
      otp: verified.otp,
    );
    result.fold(
      (failure) => state = FpError(
        message: failure.message,
        previousState: verified,
      ),
      (_) => state = const FpPasswordReset(),
    );
  }

  String? get _currentPhone {
    final s = state;
    if (s is FpOtpSent) return s.phone;
    if (s is FpError) {
      final prev = s.previousState;
      if (prev is FpOtpSent) return prev.phone;
    }
    return null;
  }
}
