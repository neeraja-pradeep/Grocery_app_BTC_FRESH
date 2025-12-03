import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_address.freezed.dart';

@freezed
class UserAddress with _$UserAddress {
  // Private constructor required for computed properties
  const UserAddress._();

  const factory UserAddress({
    required int id,
    required String firstName,
    required String lastName,
    required String streetAddress1,
    String? streetAddress2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    String? latitude,
    String? longitude,
    required String addressType, // 'home', 'work', 'other'
    required bool selected,
    required DateTime createdAt,
  }) = _UserAddress;

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      streetAddress1: json['street_address_1']?.toString() ?? '',
      streetAddress2: json['street_address_2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      addressType: json['address_type']?.toString() ?? 'home',
      selected: json['selected'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  // --- Computed Properties ---

  /// Returns "Street, City"
  String get shortDisplay {
    return '$streetAddress1, $city';
  }

  /// Returns the complete formatted address
  String get fullDisplay {
    final StringBuffer buffer = StringBuffer();
    buffer.write('$streetAddress1, ');
    if (streetAddress2 != null && streetAddress2!.isNotEmpty) {
      buffer.write('$streetAddress2, ');
    }
    buffer.write('$city, $state $postalCode, $country');
    return buffer.toString();
  }
}
