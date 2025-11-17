// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Product {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  double get mrp => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get unitLabel => throw _privateConstructorUsedError;
  int get discountPct => throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call({
    String id,
    String name,
    double price,
    double mrp,
    String imageUrl,
    String unitLabel,
    int discountPct,
    double? rating,
  });
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? price = null,
    Object? mrp = null,
    Object? imageUrl = null,
    Object? unitLabel = null,
    Object? discountPct = null,
    Object? rating = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            mrp: null == mrp
                ? _value.mrp
                : mrp // ignore: cast_nullable_to_non_nullable
                      as double,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            unitLabel: null == unitLabel
                ? _value.unitLabel
                : unitLabel // ignore: cast_nullable_to_non_nullable
                      as String,
            discountPct: null == discountPct
                ? _value.discountPct
                : discountPct // ignore: cast_nullable_to_non_nullable
                      as int,
            rating: freezed == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
    _$ProductImpl value,
    $Res Function(_$ProductImpl) then,
  ) = __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    double price,
    double mrp,
    String imageUrl,
    String unitLabel,
    int discountPct,
    double? rating,
  });
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
    _$ProductImpl _value,
    $Res Function(_$ProductImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? price = null,
    Object? mrp = null,
    Object? imageUrl = null,
    Object? unitLabel = null,
    Object? discountPct = null,
    Object? rating = freezed,
  }) {
    return _then(
      _$ProductImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        mrp: null == mrp
            ? _value.mrp
            : mrp // ignore: cast_nullable_to_non_nullable
                  as double,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        unitLabel: null == unitLabel
            ? _value.unitLabel
            : unitLabel // ignore: cast_nullable_to_non_nullable
                  as String,
        discountPct: null == discountPct
            ? _value.discountPct
            : discountPct // ignore: cast_nullable_to_non_nullable
                  as int,
        rating: freezed == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc

class _$ProductImpl implements _Product {
  const _$ProductImpl({
    required this.id,
    required this.name,
    required this.price,
    required this.mrp,
    required this.imageUrl,
    required this.unitLabel,
    required this.discountPct,
    this.rating,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final double price;
  @override
  final double mrp;
  @override
  final String imageUrl;
  @override
  final String unitLabel;
  @override
  final int discountPct;
  @override
  final double? rating;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, mrp: $mrp, imageUrl: $imageUrl, unitLabel: $unitLabel, discountPct: $discountPct, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.mrp, mrp) || other.mrp == mrp) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.unitLabel, unitLabel) ||
                other.unitLabel == unitLabel) &&
            (identical(other.discountPct, discountPct) ||
                other.discountPct == discountPct) &&
            (identical(other.rating, rating) || other.rating == rating));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    price,
    mrp,
    imageUrl,
    unitLabel,
    discountPct,
    rating,
  );

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);
}

abstract class _Product implements Product {
  const factory _Product({
    required final String id,
    required final String name,
    required final double price,
    required final double mrp,
    required final String imageUrl,
    required final String unitLabel,
    required final int discountPct,
    final double? rating,
  }) = _$ProductImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  double get price;
  @override
  double get mrp;
  @override
  String get imageUrl;
  @override
  String get unitLabel;
  @override
  int get discountPct;
  @override
  double? get rating;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
