import 'package:cookie_jar/cookie_jar.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/address.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signup({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  });

  Future<Either<Failure, bool>> sendOTP({required String phoneNumber});

  Future<Either<Failure, UserEntity>> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  });

  Future<Either<Failure, AddressEntity>> addAddress({
    required String firstName,
    required String lastName,
    required String streetAddress,
    required String addressType,
  });

  Future<Cookie?> getCurrentSession();
  Future<UserEntity?> getSavedUser();

  Future<Either<Failure, String>> verifyOtpOnly({
    required String phoneNumber,
    required String otp,
  });

  Future<Either<Failure, String>> resetPassword({required String newPassword});

  /// Clears all user data, cookies, and session
  Future<void> logout();
}
