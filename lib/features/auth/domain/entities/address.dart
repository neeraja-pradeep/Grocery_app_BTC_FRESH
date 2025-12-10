// ignore_for_file: public_member_api_docs, sort_constructors_first
import '../../../../core/utils/address_enum.dart';

class AddressEntity {
  final int id;
  final String firstName;
  final String lastName;
  final String streetAddress1;
  final String? streetAddress2;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final AddressType addressType;
  final bool selected;

  AddressEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.streetAddress1,
    this.streetAddress2,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    required this.addressType,
    required this.selected,
  });

  AddressEntity copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? streetAddress1,
    String? streetAddress2,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    AddressType? addressType,
    bool? selected,
  }) {
    return AddressEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      streetAddress1: streetAddress1 ?? this.streetAddress1,
      streetAddress2: streetAddress2 ?? this.streetAddress2,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressType: addressType ?? this.addressType,
      selected: selected ?? this.selected,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'streetAddress1': streetAddress1,
      'streetAddress2': streetAddress2,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'addressType': addressType.name,
      'selected': selected,
    };
  }

  factory AddressEntity.fromMap(Map<String, dynamic> map) {
    return AddressEntity(
      id: map['id'] as int,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      streetAddress1: map['street_address1'] as String,
      streetAddress2: map['street_address2'] != null
          ? map['street_address2'] as String
          : null,
      city: map['city'] != null ? map['city'] as String : null,
      state: map['state'] != null ? map['state'] as String : null,
      latitude: map['latitude'] != null ? map['latitude'] as double : null,
      longitude: map['longitude'] != null ? map['longitude'] as double : null,
      addressType: AddressType.values.firstWhere(
        (e) => e.name == map['address_type'],
      ),

      selected: map['selected'] as bool,
    );
  }
}
