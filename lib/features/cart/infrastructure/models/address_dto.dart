import '../../domain/entities/address.dart';

/// Data Transfer Object for Address API response
class AddressDto {
  const AddressDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.streetAddress1,
    this.streetAddress2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    required this.addressType,
    required this.selected,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String streetAddress1;
  final String? streetAddress2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String addressType;
  final bool selected;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AddressDto.fromJson(Map<String, dynamic> json) {
    return AddressDto(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      streetAddress1: json['street_address1'] as String,
      streetAddress2: json['street_address2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      addressType: json['address_type'] as String,
      selected: json['selected'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Parse a value that could be num, String, or null to double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'street_address1': streetAddress1,
      'street_address2': streetAddress2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'address_type': addressType,
      'selected': selected,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert DTO to domain entity
  Address toDomain() {
    return Address(
      id: id,
      firstName: firstName,
      lastName: lastName,
      streetAddress1: streetAddress1,
      streetAddress2: streetAddress2,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      latitude: latitude,
      longitude: longitude,
      addressType: addressType,
      selected: selected,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Data Transfer Object for paginated address list response
class AddressListResponseDto {
  const AddressListResponseDto({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<AddressDto> results;

  factory AddressListResponseDto.fromJson(Map<String, dynamic> json) {
    return AddressListResponseDto(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => AddressDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }

  /// Convert DTO to domain entity
  AddressListResponse toDomain() {
    return AddressListResponse(
      count: count,
      next: next,
      previous: previous,
      results: results.map((e) => e.toDomain()).toList(),
    );
  }
}
