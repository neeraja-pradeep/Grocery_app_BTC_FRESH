import '../../domain/entities/address.dart';

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
    this.addressType,
    this.selected = false,
    this.createdAt,
    this.updatedAt,
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
  final String? latitude;
  final String? longitude;
  final String? addressType;
  final bool selected;
  final String? createdAt;
  final String? updatedAt;

  factory AddressDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId == null) {
      throw const FormatException('Address payload missing `id`.');
    }

    final rawFirstName = json['first_name'];
    if (rawFirstName == null || rawFirstName.toString().isEmpty) {
      throw const FormatException('Address payload missing `first_name`.');
    }

    final rawLastName = json['last_name'];
    if (rawLastName == null || rawLastName.toString().isEmpty) {
      throw const FormatException('Address payload missing `last_name`.');
    }

    final rawStreetAddress1 = json['street_address1'];
    if (rawStreetAddress1 == null || rawStreetAddress1.toString().isEmpty) {
      throw const FormatException('Address payload missing `street_address1`.');
    }

    return AddressDto(
      id: rawId is int ? rawId : int.parse('$rawId'),
      firstName: '$rawFirstName',
      lastName: '$rawLastName',
      streetAddress1: '$rawStreetAddress1',
      streetAddress2: json['street_address2']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postal_code']?.toString(),
      country: json['country']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      addressType: json['address_type']?.toString(),
      selected: json['selected'] == true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'street_address1': streetAddress1,
    if (streetAddress2 != null) 'street_address2': streetAddress2,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (postalCode != null) 'postal_code': postalCode,
    if (country != null) 'country': country,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (addressType != null) 'address_type': addressType,
    'selected': selected,
  };

  Address toDomain() => Address(
    id: '$id',
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
