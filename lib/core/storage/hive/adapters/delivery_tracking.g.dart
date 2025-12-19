// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_tracking.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeliveryTrackingDataAdapter extends TypeAdapter<DeliveryTrackingData> {
  @override
  final typeId = 3;

  @override
  DeliveryTrackingData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryTrackingData(
      orderId: (fields[0] as num).toInt(),
      deliveryId: (fields[1] as num).toInt(),
      status: fields[2] as String,
      lastUpdated: fields[3] as DateTime,
      notes: fields[4] as String?,
      proofOfDelivery: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryTrackingData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.orderId)
      ..writeByte(1)
      ..write(obj.deliveryId)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.lastUpdated)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.proofOfDelivery);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryTrackingDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
