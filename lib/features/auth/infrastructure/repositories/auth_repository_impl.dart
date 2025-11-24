import 'package:cookie_jar/cookie_jar.dart';

import 'package:fpdart/fpdart.dart';
import 'package:grocery_app/core/error/failure.dart';
import 'package:grocery_app/core/network/api_client.dart';
import 'package:grocery_app/core/network/network_exceptions.dart';
import 'package:grocery_app/features/auth/domain/entities/address.dart';
import 'package:grocery_app/features/auth/domain/entities/user.dart';
import 'package:grocery_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:grocery_app/features/auth/infrastructure/data_sources/local/auth_local_ds.dart';
import 'package:grocery_app/features/auth/infrastructure/data_sources/remote/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi remote;
  final AuthLocalDs local;

  AuthRepositoryImpl({required this.remote, required this.local});

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await remote.login(username: username, password: password);

      await local.saveUser(user);

      final session = await local.getValidSession(ApiClient.baseUrl);

      if (session == null) {
        return const Left(AppFailure('No valid session cookie stored'));
      }

      return Right(user);
    } catch (e) {
      return Left(mapDioError(e));
    }
  }

  // ----------------------------------------------------------
  // GET CURRENT SESSION
  // ----------------------------------------------------------
  @override
  Future<Cookie?> getCurrentSession() async {
    try {
      return await local.getValidSession(ApiClient.baseUrl);
    } catch (_) {
      throw Exception("Error Occurred");
    }
  }

  @override
  Future<UserEntity?> getSavedUser() async {
    return await local.getUser();
  }

  // ----------------------------------------------------------
  // SIGNUP
  // ----------------------------------------------------------
  @override
  Future<Either<Failure, UserEntity>> signup({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final user = await remote.signup(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
      );

      await local.saveUser(user);

      final session = await local.getValidSession(ApiClient.baseUrl);

      if (session == null) {
        return const Left(AppFailure('No valid session cookie stored'));
      }

      return Right(user);
    } catch (e) {
      return Left(mapDioError(e));
    }
  }

  // ----------------------------------------------------------
  // SEND OTP
  // ----------------------------------------------------------
  @override
  Future<Either<Failure, bool>> sendOTP({required String phoneNumber}) async {
    try {
      final message = await remote.sendOtp(phoneNumber: phoneNumber);

      // SUCCESS
      if (message == "OTP sent successfully") {
        return const Right(true);
      }

      // ERROR message from backend → show to frontend
      return Left(AppFailure(message));
    } catch (e) {
      return Left(mapDioError(e)); // for Dio errors
    }
  }

  // ----------------------------------------------------------
  // VERIFY OTP
  // ----------------------------------------------------------
  @override
  Future<Either<Failure, UserEntity>> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final user = await remote.verifyOTP(
        phoneNumber: phoneNumber,
        otp: otpCode,
      );

      await local.saveUser(user);

      final session = await local.getValidSession(ApiClient.baseUrl);

      if (session == null) {
        return const Left(AppFailure('No valid session cookie stored'));
      }

      return Right(user);
    } catch (e) {
      return Left(mapDioError(e));
    }
  }

  // ----------------------------------------------------------
  // ADD ADDRESS
  // ----------------------------------------------------------
  @override
  Future<Either<Failure, AddressEntity>> addAddress({
    required String firstName,
    required String lastName,
    required String streetAddress,
    required String addressType,
  }) async {
    try {
      final address = await remote.sendAddress(
        firstName: firstName,
        lastName: lastName,
        streetAddress: streetAddress,
        addressType: addressType,
      );

      await local.saveAddress(address);

      return Right(address);
    } catch (e) {
      return Left(mapDioError(e));
    }
  }
}
