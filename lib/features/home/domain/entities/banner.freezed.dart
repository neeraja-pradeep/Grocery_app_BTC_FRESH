// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'banner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Banner {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get descriptionPlaintext => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  int? get categoryId => throw _privateConstructorUsedError;
  int? get productId => throw _privateConstructorUsedError;
  int? get productVariantId => throw _privateConstructorUsedError;

  /// Create a copy of Banner
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BannerCopyWith<Banner> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BannerCopyWith<$Res> {
  factory $BannerCopyWith(Banner value, $Res Function(Banner) then) =
      _$BannerCopyWithImpl<$Res, Banner>;
  @useResult
  $Res call({
    int id,
    String name,
    String? descriptionPlaintext,
    String imageUrl,
    int? categoryId,
    int? productId,
    int? productVariantId,
  });
}

/// @nodoc
class _$BannerCopyWithImpl<$Res, $Val extends Banner>
    implements $BannerCopyWith<$Res> {
  _$BannerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Banner
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? descriptionPlaintext = freezed,
    Object? imageUrl = null,
    Object? categoryId = freezed,
    Object? productId = freezed,
    Object? productVariantId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            descriptionPlaintext: freezed == descriptionPlaintext
                ? _value.descriptionPlaintext
                : descriptionPlaintext // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as int?,
            productId: freezed == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as int?,
            productVariantId: freezed == productVariantId
                ? _value.productVariantId
                : productVariantId // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BannerImplCopyWith<$Res> implements $BannerCopyWith<$Res> {
  factory _$$BannerImplCopyWith(
    _$BannerImpl value,
    $Res Function(_$BannerImpl) then,
  ) = __$$BannerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String? descriptionPlaintext,
    String imageUrl,
    int? categoryId,
    int? productId,
    int? productVariantId,
  });
}

/// @nodoc
class __$$BannerImplCopyWithImpl<$Res>
    extends _$BannerCopyWithImpl<$Res, _$BannerImpl>
    implements _$$BannerImplCopyWith<$Res> {
  __$$BannerImplCopyWithImpl(
    _$BannerImpl _value,
    $Res Function(_$BannerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Banner
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? descriptionPlaintext = freezed,
    Object? imageUrl = null,
    Object? categoryId = freezed,
    Object? productId = freezed,
    Object? productVariantId = freezed,
  }) {
    return _then(
      _$BannerImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        descriptionPlaintext: freezed == descriptionPlaintext
            ? _value.descriptionPlaintext
            : descriptionPlaintext // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as int?,
        productId: freezed == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as int?,
        productVariantId: freezed == productVariantId
            ? _value.productVariantId
            : productVariantId // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$BannerImpl extends _Banner {
  const _$BannerImpl({
    required this.id,
    required this.name,
    this.descriptionPlaintext,
    required this.imageUrl,
    this.categoryId,
    this.productId,
    this.productVariantId,
  }) : super._();

  @override
  final int id;
  @override
  final String name;
  @override
  final String? descriptionPlaintext;
  @override
  final String imageUrl;
  @override
  final int? categoryId;
  @override
  final int? productId;
  @override
  final int? productVariantId;

  @override
  String toString() {
    return 'Banner(id: $id, name: $name, descriptionPlaintext: $descriptionPlaintext, imageUrl: $imageUrl, categoryId: $categoryId, productId: $productId, productVariantId: $productVariantId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BannerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.descriptionPlaintext, descriptionPlaintext) ||
                other.descriptionPlaintext == descriptionPlaintext) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productVariantId, productVariantId) ||
                other.productVariantId == productVariantId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    descriptionPlaintext,
    imageUrl,
    categoryId,
    productId,
    productVariantId,
  );

  /// Create a copy of Banner
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BannerImplCopyWith<_$BannerImpl> get copyWith =>
      __$$BannerImplCopyWithImpl<_$BannerImpl>(this, _$identity);
}

abstract class _Banner extends Banner {
  const factory _Banner({
    required final int id,
    required final String name,
    final String? descriptionPlaintext,
    required final String imageUrl,
    final int? categoryId,
    final int? productId,
    final int? productVariantId,
  }) = _$BannerImpl;
  const _Banner._() : super._();

  @override
  int get id;
  @override
  String get name;
  @override
  String? get descriptionPlaintext;
  @override
  String get imageUrl;
  @override
  int? get categoryId;
  @override
  int? get productId;
  @override
  int? get productVariantId;

  /// Create a copy of Banner
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BannerImplCopyWith<_$BannerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
