import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/core/network/endpoints.dart';
import 'package:grocery_app/core/network/network_exceptions.dart';
import 'package:grocery_app/core/providers/network_providers.dart';
import 'package:grocery_app/features/auth/domain/entities/address.dart';
import 'package:grocery_app/features/auth/domain/entities/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_api.g.dart';

@riverpod
AuthApi authApi(Ref ref) {
  final dio = ref.watch(dioProvider); // your shared Dio instance
  return AuthApi(dio);
}

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  // ----------------------------------------------------------
  // 1️⃣ LOGIN API
  // Backend returns: { "accessToken": "..." }
  // So the return type must be Session, NOT UserEntity
  // ----------------------------------------------------------
  Future<UserEntity> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );

      if (res.statusCode != 200) {
        throw Exception("Login failed: ${res.statusCode}");
      }

      final user = UserEntity.fromMap(res.data['user']);

      return user;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  // 3️⃣ SIGNUP API

  Future<UserEntity> signup({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.signup,
        data: {
          'username': username,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirm': confirmPassword,
        },
      );
      if (res.statusCode != 201) {
        throw Exception("SignUp failed: ${res.statusCode}");
      }
      return UserEntity.fromMap(res.data['user']);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  // ----------------------------------------------------------
  // 2️⃣ SEND OTP API
  // ----------------------------------------------------------

  Future<String> sendOtp({required String phoneNumber}) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.sendOtp,
        data: {'phone_number': phoneNumber},
      );
      if (res.statusCode != 200) {
        return res.data['error'];
      }

      return res.data['message'];
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<UserEntity> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.verifyOTP,
        data: {"phone_number": phoneNumber, "otp_code": otp},
      );
      if (res.statusCode != 200) {
        throw Exception("Login failed: ${res.statusCode}");
      }

      return UserEntity.fromMap(res.data['user']);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AddressEntity> sendAddress({
    required String firstName,
    required String lastName,
    required String streetAddress,
    required String addressType,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.addAddress,
        data: {
          "first_name": firstName,
          "last_name": lastName,
          "street_address1": streetAddress,

          "address_type": addressType,
          "selected": true,
        },
      );
      if (res.statusCode != 201) {
        throw Exception("Send Address failed: ${res.statusCode}");
      }

      return AddressEntity.fromMap(res.data);
    } catch (e) {
      throw mapDioError(e);
    }
  }
}
