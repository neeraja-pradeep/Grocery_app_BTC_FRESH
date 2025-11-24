import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/core/providers/network_providers.dart';
import 'package:grocery_app/core/storage/hive/adapters/address.dart';
import 'package:grocery_app/core/storage/hive/adapters/user.dart';
import 'package:grocery_app/core/storage/hive/boxes.dart';
import 'package:grocery_app/core/storage/hive/keys.dart';
import 'package:grocery_app/features/auth/domain/entities/address.dart';
import 'package:grocery_app/features/auth/domain/entities/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

    for (final c in cookies) {
      final name = c.name.toLowerCase();

      if (name.contains('session') && c.value.trim().isNotEmpty) {
        return c; // return the actual session cookie
      }
    }

    return null; // no valid session
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
}
