class Address {
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
    this.addressType,
    this.selected = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
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

  String get fullName => '$firstName $lastName';

  String get fullAddress {
    final parts = <String>[
      streetAddress1,
      if (streetAddress2?.isNotEmpty == true) streetAddress2!,
      if (city?.isNotEmpty == true) city!,
      if (state?.isNotEmpty == true) state!,
      if (postalCode?.isNotEmpty == true) postalCode!,
      if (country?.isNotEmpty == true) country!,
    ];
    return parts.join(', ');
  }

  String get addressTypeLabel {
    if (addressType == null || addressType!.isEmpty) return 'Other';
    return addressType![0].toUpperCase() + addressType!.substring(1);
  }
}
