import '../../models/address_dto.dart';

class AddressCacheDto {
  const AddressCacheDto({
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
    required this.cachedAt,
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
  final DateTime cachedAt;

  factory AddressCacheDto.fromJson(Map<String, dynamic> json) {
    return AddressCacheDto(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      streetAddress1: json['streetAddress1'] as String,
      streetAddress2: json['streetAddress2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      addressType: json['addressType'] as String?,
      selected: json['selected'] as bool? ?? false,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'streetAddress1': streetAddress1,
    if (streetAddress2 != null) 'streetAddress2': streetAddress2,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (postalCode != null) 'postalCode': postalCode,
    if (country != null) 'country': country,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (addressType != null) 'addressType': addressType,
    'selected': selected,
    'cachedAt': cachedAt.toIso8601String(),
  };

  AddressDto toDto() {
    return AddressDto(
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
    );
  }

  factory AddressCacheDto.fromDto(AddressDto dto) {
    return AddressCacheDto(
      id: dto.id,
      firstName: dto.firstName,
      lastName: dto.lastName,
      streetAddress1: dto.streetAddress1,
      streetAddress2: dto.streetAddress2,
      city: dto.city,
      state: dto.state,
      postalCode: dto.postalCode,
      country: dto.country,
      latitude: dto.latitude,
      longitude: dto.longitude,
      addressType: dto.addressType,
      selected: dto.selected,
      cachedAt: DateTime.now(),
    );
  }
}
