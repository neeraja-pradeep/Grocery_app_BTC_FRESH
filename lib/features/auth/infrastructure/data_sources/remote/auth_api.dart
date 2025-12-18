import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../../../../core/providers/network_providers.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/user.dart';

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
  // 1. LOGIN API
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
        throw Exception('Login failed: ${res.statusCode}');
      }

      // final user = UserEntity.fromMap(res.data['user']);
      final data = res.data as Map<String, dynamic>;
      final user = UserEntity.fromMap(data['user']);

      return user;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  // 2. SIGNUP API
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
        throw Exception('SignUp failed: ${res.statusCode}');
      }
      final data = res.data as Map<String, dynamic>;
      final user = UserEntity.fromMap(data['user']);
      return user;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  // ----------------------------------------------------------
  // 3. SEND OTP API
  // ----------------------------------------------------------
  Future<String> sendOtp({required String phoneNumber}) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.sendOtp,
        data: {'phone_number': phoneNumber},
      );
      if (res.statusCode != 200) {
        final data = res.data as Map<String, dynamic>;
        return data['error'] as String;
      }

      final data = res.data as Map<String, dynamic>;
      return data['message'] as String;
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
        data: {'phone_number': phoneNumber, 'otp_code': otp},
      );
      if (res.statusCode != 200) {
        throw Exception('Login failed: ${res.statusCode}');
      }

      final data = res.data as Map<String, dynamic>;
      final user = UserEntity.fromMap(data['user']);

      return user;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  // ----------------------------------------------------------
  // VERIFY OTP ONLY (for forgot password flow)
  // ----------------------------------------------------------
  Future<String> verifyOtpOnly({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.verifyOTP,
        data: {'phone_number': phoneNumber, 'otp_code': otp},
      );
      if (res.statusCode != 200) {
        final data = res.data as Map<String, dynamic>;
        return data['error'] as String? ?? 'OTP verification failed';
      }

      final data = res.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'OTP verified successfully';
    } catch (e) {
      throw mapDioError(e);
    }
  }

  // ----------------------------------------------------------
  // RESET PASSWORD (after OTP verification)
  // ----------------------------------------------------------
  Future<String> resetPassword({required String newPassword}) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.resetPassword,
        data: {'new_password': newPassword},
      );
      if (res.statusCode != 200) {
        final data = res.data as Map<String, dynamic>;
        return data['error'] as String? ?? 'Password reset failed';
      }

      final data = res.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'Password reset successfully';
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AddressEntity> sendAddress({
    required String firstName,
    required String lastName,
    required String streetAddress,
    required String addressType,
    String? streetAddress2,
    String? latitude,
    String? longitude,
    String? city,
    String? state,
    String? postalCode,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.addAddress,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'street_address1': streetAddress,
          if (streetAddress2 != null) 'street_address2': streetAddress2,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
          if (postalCode != null) 'postal_code': postalCode,
          'address_type': addressType,
          'selected': true,
        },
      );
      if (res.statusCode != 201) {
        throw Exception('Send Address failed: ${res.statusCode}');
      }

      return AddressEntity.fromMap(res.data);
    } catch (e) {
      throw mapDioError(e);
    }
  }
}
