// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DeliveryEntity {
  int get id => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  DeliveryApiStatus get status => throw _privateConstructorUsedError;
  DateTime? get assignedAt => throw _privateConstructorUsedError;
  DateTime? get pickedUpAt => throw _privateConstructorUsedError;
  DateTime? get deliveredAt => throw _privateConstructorUsedError;
  String? get proofOfDelivery => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Create a copy of DeliveryEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeliveryEntityCopyWith<DeliveryEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliveryEntityCopyWith<$Res> {
  factory $DeliveryEntityCopyWith(
    DeliveryEntity value,
    $Res Function(DeliveryEntity) then,
  ) = _$DeliveryEntityCopyWithImpl<$Res, DeliveryEntity>;
  @useResult
  $Res call({
    int id,
    int order,
    DeliveryApiStatus status,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? proofOfDelivery,
    String? notes,
  });
}

/// @nodoc
class _$DeliveryEntityCopyWithImpl<$Res, $Val extends DeliveryEntity>
    implements $DeliveryEntityCopyWith<$Res> {
  _$DeliveryEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeliveryEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? order = null,
    Object? status = null,
    Object? assignedAt = freezed,
    Object? pickedUpAt = freezed,
    Object? deliveredAt = freezed,
    Object? proofOfDelivery = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as DeliveryApiStatus,
            assignedAt: freezed == assignedAt
                ? _value.assignedAt
                : assignedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            pickedUpAt: freezed == pickedUpAt
                ? _value.pickedUpAt
                : pickedUpAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deliveredAt: freezed == deliveredAt
                ? _value.deliveredAt
                : deliveredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            proofOfDelivery: freezed == proofOfDelivery
                ? _value.proofOfDelivery
                : proofOfDelivery // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeliveryEntityImplCopyWith<$Res>
    implements $DeliveryEntityCopyWith<$Res> {
  factory _$$DeliveryEntityImplCopyWith(
    _$DeliveryEntityImpl value,
    $Res Function(_$DeliveryEntityImpl) then,
  ) = __$$DeliveryEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int order,
    DeliveryApiStatus status,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? proofOfDelivery,
    String? notes,
  });
}

/// @nodoc
class __$$DeliveryEntityImplCopyWithImpl<$Res>
    extends _$DeliveryEntityCopyWithImpl<$Res, _$DeliveryEntityImpl>
    implements _$$DeliveryEntityImplCopyWith<$Res> {
  __$$DeliveryEntityImplCopyWithImpl(
    _$DeliveryEntityImpl _value,
    $Res Function(_$DeliveryEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? order = null,
    Object? status = null,
    Object? assignedAt = freezed,
    Object? pickedUpAt = freezed,
    Object? deliveredAt = freezed,
    Object? proofOfDelivery = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$DeliveryEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DeliveryApiStatus,
        assignedAt: freezed == assignedAt
            ? _value.assignedAt
            : assignedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pickedUpAt: freezed == pickedUpAt
            ? _value.pickedUpAt
            : pickedUpAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deliveredAt: freezed == deliveredAt
            ? _value.deliveredAt
            : deliveredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        proofOfDelivery: freezed == proofOfDelivery
            ? _value.proofOfDelivery
            : proofOfDelivery // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$DeliveryEntityImpl extends _DeliveryEntity {
  const _$DeliveryEntityImpl({
    required this.id,
    required this.order,
    required this.status,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.proofOfDelivery,
    this.notes,
  }) : super._();

  @override
  final int id;
  @override
  final int order;
  @override
  final DeliveryApiStatus status;
  @override
  final DateTime? assignedAt;
  @override
  final DateTime? pickedUpAt;
  @override
  final DateTime? deliveredAt;
  @override
  final String? proofOfDelivery;
  @override
  final String? notes;

  @override
  String toString() {
    return 'DeliveryEntity(id: $id, order: $order, status: $status, assignedAt: $assignedAt, pickedUpAt: $pickedUpAt, deliveredAt: $deliveredAt, proofOfDelivery: $proofOfDelivery, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.assignedAt, assignedAt) ||
                other.assignedAt == assignedAt) &&
            (identical(other.pickedUpAt, pickedUpAt) ||
                other.pickedUpAt == pickedUpAt) &&
            (identical(other.deliveredAt, deliveredAt) ||
                other.deliveredAt == deliveredAt) &&
            (identical(other.proofOfDelivery, proofOfDelivery) ||
                other.proofOfDelivery == proofOfDelivery) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    order,
    status,
    assignedAt,
    pickedUpAt,
    deliveredAt,
    proofOfDelivery,
    notes,
  );

  /// Create a copy of DeliveryEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryEntityImplCopyWith<_$DeliveryEntityImpl> get copyWith =>
      __$$DeliveryEntityImplCopyWithImpl<_$DeliveryEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _DeliveryEntity extends DeliveryEntity {
  const factory _DeliveryEntity({
    required final int id,
    required final int order,
    required final DeliveryApiStatus status,
    final DateTime? assignedAt,
    final DateTime? pickedUpAt,
    final DateTime? deliveredAt,
    final String? proofOfDelivery,
    final String? notes,
  }) = _$DeliveryEntityImpl;
  const _DeliveryEntity._() : super._();

  @override
  int get id;
  @override
  int get order;
  @override
  DeliveryApiStatus get status;
  @override
  DateTime? get assignedAt;
  @override
  DateTime? get pickedUpAt;
  @override
  DateTime? get deliveredAt;
  @override
  String? get proofOfDelivery;
  @override
  String? get notes;

  /// Create a copy of DeliveryEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryEntityImplCopyWith<_$DeliveryEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
