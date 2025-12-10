import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/providers/network_providers.dart';
import '../../../../../core/storage/hive/adapters/address.dart';
import '../../../../../core/storage/hive/adapters/user.dart';
import '../../../../../core/storage/hive/boxes.dart';
import '../../../../../core/storage/hive/keys.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/user.dart';

part 'auth_local_ds.g.dart';

@riverpod
AuthLocalDs authLocalDs(Ref ref) {
  return AuthLocalDs(ref.watch(cookieJarProvider));
}

class AuthLocalDs {
  final PersistCookieJar cookieJar;

  AuthLocalDs(this.cookieJar);

  /// Get cookies for a given URL
  Future<List<Cookie>> getCookies(String url) async {
    return cookieJar.loadForRequest(Uri.parse(url));
  }

  /// Save UserEntity in Hive
  Future<void> saveUser(UserEntity? user) async {
    final box = Boxes.userBox;

    if (user == null) {
      await box.delete(HiveKeys.userbox);
    } else {
      final model = UserModel.fromEntity(user);
      await box.put(HiveKeys.userbox, model);
    }
  }

  /// Delete the saved user from Hive
  Future<void> deleteUser() async {
    final box = Boxes.userBox;
    await box.delete(HiveKeys.userbox);
  }

  /// Get saved user
  Future<UserEntity?> getUser() async {
    final box = Boxes.userBox;
    final user = box.get(HiveKeys.userbox);

    if (user == null) return null;
    return (user as UserModel).toEntity();
  }

  /// Get CSRF token from cookies
  Future<String?> getCsrfToken(String url) async {
    final cookies = await getCookies(url);
    final csrf = cookies.firstWhere(
      (cookie) => cookie.name.toLowerCase() == 'csrftoken',
      orElse: () => Cookie('csrftoken', ''),
    );
    return csrf.value.isNotEmpty ? csrf.value : null;
  }

  /// Clear all cookies (logout)
  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }

  Future<Cookie?> getValidSession(String url) async {
    final cookies = await getCookies(url);
    final now = DateTime.now();

    for (final c in cookies) {
      final name = c.name.toLowerCase();

      if (name.contains('session') && c.value.trim().isNotEmpty) {
        // Validate cookie expiry if expires field is set
        if (c.expires != null && c.expires!.isBefore(now)) {
          // Cookie is expired, skip it
          continue;
        }

        // Cookie is valid and not expired
        return c;
      }
    }

    return null; // no valid session found
  }

  Future<void> saveAddress(AddressEntity? address) async {
    final box = Boxes.addressBox;

    if (address == null) {
      await box.delete(HiveKeys.addressBox);
    } else {
      final model = AddressModel.fromEntity(address);

      await box.put(HiveKeys.addressBox, model);
    }
  }

  /// Delete the saved address from Hive
  Future<void> deleteAddress() async {
    final box = Boxes.addressBox;
    await box.delete(HiveKeys.addressBox);
  }

  /// Comprehensive logout - clears all user-specific data
  Future<void> clearAllUserData() async {
    // Clear cookies first
    await clearCookies();

    // Clear all user-specific Hive data
    await Boxes.clearUserDataOnly();
  }
}
