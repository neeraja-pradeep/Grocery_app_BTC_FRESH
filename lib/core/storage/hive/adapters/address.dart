import 'package:hive_ce/hive.dart';

import '../../../../features/auth/domain/entities/address.dart';
import '../../../utils/address_enum.dart';

part 'address.g.dart';

@HiveType(typeId: 1)
class AddressModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String firstName;

  @HiveField(2)
  final String lastName;

  @HiveField(3)
  final String streetAddress1;

  @HiveField(4)
  final String? streetAddress2;

  @HiveField(5)
  final String? city;

  @HiveField(6)
  final String? state;

  @HiveField(7)
  final double? latitude;

  @HiveField(8)
  final double? longitude;

  @HiveField(9)
  final AddressType addressType;

  @HiveField(10)
  final bool selected;

  AddressModel({
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

  /// Convert Entity → Hive model
  factory AddressModel.fromEntity(AddressEntity e) {
    return AddressModel(
      id: e.id,
      firstName: e.firstName,
      lastName: e.lastName,
      streetAddress1: e.streetAddress1,
      streetAddress2: e.streetAddress2,
      city: e.city,
      state: e.state,
      latitude: e.latitude,
      longitude: e.longitude,
      addressType: e.addressType,
      selected: e.selected,
    );
  }

  /// Convert Hive model → Entity
  AddressEntity toEntity() {
    return AddressEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      streetAddress1: streetAddress1,
      streetAddress2: streetAddress2,
      city: city,
      state: state,
      latitude: latitude,
      longitude: longitude,
      addressType: addressType,
      selected: selected,
    );
  }
}

class AddressTypeAdapter extends TypeAdapter<AddressType> {
  @override
  final int typeId = 2;

  @override
  AddressType read(BinaryReader reader) {
    return AddressType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, AddressType obj) {
    writer.writeInt(obj.index);
  }
}
