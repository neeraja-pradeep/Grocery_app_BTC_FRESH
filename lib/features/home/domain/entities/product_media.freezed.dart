// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProductMedia {
  int get id => throw _privateConstructorUsedError;
  String? get imagePath => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String? get alt => throw _privateConstructorUsedError;
  String? get externalUrl => throw _privateConstructorUsedError;
  int get productId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of ProductMedia
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductMediaCopyWith<ProductMedia> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductMediaCopyWith<$Res> {
  factory $ProductMediaCopyWith(
    ProductMedia value,
    $Res Function(ProductMedia) then,
  ) = _$ProductMediaCopyWithImpl<$Res, ProductMedia>;
  @useResult
  $Res call({
    int id,
    String? imagePath,
    String imageUrl,
    String? alt,
    String? externalUrl,
    int productId,
    DateTime createdAt,
  });
}

/// @nodoc
class _$ProductMediaCopyWithImpl<$Res, $Val extends ProductMedia>
    implements $ProductMediaCopyWith<$Res> {
  _$ProductMediaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductMedia
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imagePath = freezed,
    Object? imageUrl = null,
    Object? alt = freezed,
    Object? externalUrl = freezed,
    Object? productId = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            imagePath: freezed == imagePath
                ? _value.imagePath
                : imagePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            alt: freezed == alt
                ? _value.alt
                : alt // ignore: cast_nullable_to_non_nullable
                      as String?,
            externalUrl: freezed == externalUrl
                ? _value.externalUrl
                : externalUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductMediaImplCopyWith<$Res>
    implements $ProductMediaCopyWith<$Res> {
  factory _$$ProductMediaImplCopyWith(
    _$ProductMediaImpl value,
    $Res Function(_$ProductMediaImpl) then,
  ) = __$$ProductMediaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String? imagePath,
    String imageUrl,
    String? alt,
    String? externalUrl,
    int productId,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$ProductMediaImplCopyWithImpl<$Res>
    extends _$ProductMediaCopyWithImpl<$Res, _$ProductMediaImpl>
    implements _$$ProductMediaImplCopyWith<$Res> {
  __$$ProductMediaImplCopyWithImpl(
    _$ProductMediaImpl _value,
    $Res Function(_$ProductMediaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductMedia
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imagePath = freezed,
    Object? imageUrl = null,
    Object? alt = freezed,
    Object? externalUrl = freezed,
    Object? productId = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ProductMediaImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        imagePath: freezed == imagePath
            ? _value.imagePath
            : imagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        alt: freezed == alt
            ? _value.alt
            : alt // ignore: cast_nullable_to_non_nullable
                  as String?,
        externalUrl: freezed == externalUrl
            ? _value.externalUrl
            : externalUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$ProductMediaImpl implements _ProductMedia {
  const _$ProductMediaImpl({
    required this.id,
    this.imagePath,
    required this.imageUrl,
    this.alt,
    this.externalUrl,
    required this.productId,
    required this.createdAt,
  });

  @override
  final int id;
  @override
  final String? imagePath;
  @override
  final String imageUrl;
  @override
  final String? alt;
  @override
  final String? externalUrl;
  @override
  final int productId;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'ProductMedia(id: $id, imagePath: $imagePath, imageUrl: $imageUrl, alt: $alt, externalUrl: $externalUrl, productId: $productId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductMediaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.alt, alt) || other.alt == alt) &&
            (identical(other.externalUrl, externalUrl) ||
                other.externalUrl == externalUrl) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    imagePath,
    imageUrl,
    alt,
    externalUrl,
    productId,
    createdAt,
  );

  /// Create a copy of ProductMedia
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductMediaImplCopyWith<_$ProductMediaImpl> get copyWith =>
      __$$ProductMediaImplCopyWithImpl<_$ProductMediaImpl>(this, _$identity);
}

abstract class _ProductMedia implements ProductMedia {
  const factory _ProductMedia({
    required final int id,
    final String? imagePath,
    required final String imageUrl,
    final String? alt,
    final String? externalUrl,
    required final int productId,
    required final DateTime createdAt,
  }) = _$ProductMediaImpl;

  @override
  int get id;
  @override
  String? get imagePath;
  @override
  String get imageUrl;
  @override
  String? get alt;
  @override
  String? get externalUrl;
  @override
  int get productId;
  @override
  DateTime get createdAt;

  /// Create a copy of ProductMedia
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductMediaImplCopyWith<_$ProductMediaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
