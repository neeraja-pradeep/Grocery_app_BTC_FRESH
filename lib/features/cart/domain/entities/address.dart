import 'package:equatable/equatable.dart';

/// Address domain entity
/// Represents a delivery address for orders
class Address extends Equatable {
  const Address({
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
  final String addressType; // 'home', 'work', etc.
  final bool selected;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Get formatted address
  String get formattedAddress {
    final parts = <String>[
      streetAddress1,
      if (streetAddress2 != null && streetAddress2!.isNotEmpty) streetAddress2!,
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(', ');
  }

  /// Get short address (first line only)
  String get shortAddress => streetAddress1;

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    streetAddress1,
    streetAddress2,
    city,
    state,
    postalCode,
    country,
    latitude,
    longitude,
    addressType,
    selected,
    createdAt,
    updatedAt,
  ];

  Address copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? streetAddress1,
    String? streetAddress2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? addressType,
    bool? selected,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      streetAddress1: streetAddress1 ?? this.streetAddress1,
      streetAddress2: streetAddress2 ?? this.streetAddress2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressType: addressType ?? this.addressType,
      selected: selected ?? this.selected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Paginated response for address list
class AddressListResponse extends Equatable {
  const AddressListResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<Address> results;

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;

  /// Get selected address
  Address? get selectedAddress {
    try {
      return results.firstWhere((address) => address.selected);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [count, next, previous, results];

  AddressListResponse copyWith({
    int? count,
    String? next,
    String? previous,
    List<Address>? results,
  }) {
    return AddressListResponse(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }
}
