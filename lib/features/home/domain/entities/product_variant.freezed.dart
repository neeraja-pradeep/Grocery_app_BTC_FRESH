// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_variant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProductVariant {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get productId => throw _privateConstructorUsedError;
  String get sku => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  double? get discountedPrice => throw _privateConstructorUsedError;
  String? get stockUnit => throw _privateConstructorUsedError;
  String get currentQuantity => throw _privateConstructorUsedError;
  bool get status => throw _privateConstructorUsedError;
  List<ProductMedia> get media => throw _privateConstructorUsedError;
  String? get productDescription => throw _privateConstructorUsedError;
  double? get productRating => throw _privateConstructorUsedError;
  int? get quantityLimitPerCustomer => throw _privateConstructorUsedError;
  bool get isPreorder => throw _privateConstructorUsedError;
  DateTime? get preorderEndDate => throw _privateConstructorUsedError;
  String? get tags => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of ProductVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductVariantCopyWith<ProductVariant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductVariantCopyWith<$Res> {
  factory $ProductVariantCopyWith(
    ProductVariant value,
    $Res Function(ProductVariant) then,
  ) = _$ProductVariantCopyWithImpl<$Res, ProductVariant>;
  @useResult
  $Res call({
    int id,
    String name,
    int productId,
    String sku,
    double price,
    double? discountedPrice,
    String? stockUnit,
    String currentQuantity,
    bool status,
    List<ProductMedia> media,
    String? productDescription,
    double? productRating,
    int? quantityLimitPerCustomer,
    bool isPreorder,
    DateTime? preorderEndDate,
    String? tags,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$ProductVariantCopyWithImpl<$Res, $Val extends ProductVariant>
    implements $ProductVariantCopyWith<$Res> {
  _$ProductVariantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? productId = null,
    Object? sku = null,
    Object? price = null,
    Object? discountedPrice = freezed,
    Object? stockUnit = freezed,
    Object? currentQuantity = null,
    Object? status = null,
    Object? media = null,
    Object? productDescription = freezed,
    Object? productRating = freezed,
    Object? quantityLimitPerCustomer = freezed,
    Object? isPreorder = null,
    Object? preorderEndDate = freezed,
    Object? tags = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as int,
            sku: null == sku
                ? _value.sku
                : sku // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            discountedPrice: freezed == discountedPrice
                ? _value.discountedPrice
                : discountedPrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            stockUnit: freezed == stockUnit
                ? _value.stockUnit
                : stockUnit // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentQuantity: null == currentQuantity
                ? _value.currentQuantity
                : currentQuantity // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as bool,
            media: null == media
                ? _value.media
                : media // ignore: cast_nullable_to_non_nullable
                      as List<ProductMedia>,
            productDescription: freezed == productDescription
                ? _value.productDescription
                : productDescription // ignore: cast_nullable_to_non_nullable
                      as String?,
            productRating: freezed == productRating
                ? _value.productRating
                : productRating // ignore: cast_nullable_to_non_nullable
                      as double?,
            quantityLimitPerCustomer: freezed == quantityLimitPerCustomer
                ? _value.quantityLimitPerCustomer
                : quantityLimitPerCustomer // ignore: cast_nullable_to_non_nullable
                      as int?,
            isPreorder: null == isPreorder
                ? _value.isPreorder
                : isPreorder // ignore: cast_nullable_to_non_nullable
                      as bool,
            preorderEndDate: freezed == preorderEndDate
                ? _value.preorderEndDate
                : preorderEndDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            tags: freezed == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductVariantImplCopyWith<$Res>
    implements $ProductVariantCopyWith<$Res> {
  factory _$$ProductVariantImplCopyWith(
    _$ProductVariantImpl value,
    $Res Function(_$ProductVariantImpl) then,
  ) = __$$ProductVariantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    int productId,
    String sku,
    double price,
    double? discountedPrice,
    String? stockUnit,
    String currentQuantity,
    bool status,
    List<ProductMedia> media,
    String? productDescription,
    double? productRating,
    int? quantityLimitPerCustomer,
    bool isPreorder,
    DateTime? preorderEndDate,
    String? tags,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$ProductVariantImplCopyWithImpl<$Res>
    extends _$ProductVariantCopyWithImpl<$Res, _$ProductVariantImpl>
    implements _$$ProductVariantImplCopyWith<$Res> {
  __$$ProductVariantImplCopyWithImpl(
    _$ProductVariantImpl _value,
    $Res Function(_$ProductVariantImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? productId = null,
    Object? sku = null,
    Object? price = null,
    Object? discountedPrice = freezed,
    Object? stockUnit = freezed,
    Object? currentQuantity = null,
    Object? status = null,
    Object? media = null,
    Object? productDescription = freezed,
    Object? productRating = freezed,
    Object? quantityLimitPerCustomer = freezed,
    Object? isPreorder = null,
    Object? preorderEndDate = freezed,
    Object? tags = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ProductVariantImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as int,
        sku: null == sku
            ? _value.sku
            : sku // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        discountedPrice: freezed == discountedPrice
            ? _value.discountedPrice
            : discountedPrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        stockUnit: freezed == stockUnit
            ? _value.stockUnit
            : stockUnit // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentQuantity: null == currentQuantity
            ? _value.currentQuantity
            : currentQuantity // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as bool,
        media: null == media
            ? _value._media
            : media // ignore: cast_nullable_to_non_nullable
                  as List<ProductMedia>,
        productDescription: freezed == productDescription
            ? _value.productDescription
            : productDescription // ignore: cast_nullable_to_non_nullable
                  as String?,
        productRating: freezed == productRating
            ? _value.productRating
            : productRating // ignore: cast_nullable_to_non_nullable
                  as double?,
        quantityLimitPerCustomer: freezed == quantityLimitPerCustomer
            ? _value.quantityLimitPerCustomer
            : quantityLimitPerCustomer // ignore: cast_nullable_to_non_nullable
                  as int?,
        isPreorder: null == isPreorder
            ? _value.isPreorder
            : isPreorder // ignore: cast_nullable_to_non_nullable
                  as bool,
        preorderEndDate: freezed == preorderEndDate
            ? _value.preorderEndDate
            : preorderEndDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        tags: freezed == tags
            ? _value.tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$ProductVariantImpl extends _ProductVariant {
  const _$ProductVariantImpl({
    required this.id,
    required this.name,
    required this.productId,
    required this.sku,
    required this.price,
    this.discountedPrice,
    this.stockUnit,
    required this.currentQuantity,
    required this.status,
    required final List<ProductMedia> media,
    this.productDescription,
    this.productRating,
    this.quantityLimitPerCustomer,
    required this.isPreorder,
    this.preorderEndDate,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  }) : _media = media,
       super._();

  @override
  final int id;
  @override
  final String name;
  @override
  final int productId;
  @override
  final String sku;
  @override
  final double price;
  @override
  final double? discountedPrice;
  @override
  final String? stockUnit;
  @override
  final String currentQuantity;
  @override
  final bool status;
  final List<ProductMedia> _media;
  @override
  List<ProductMedia> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  final String? productDescription;
  @override
  final double? productRating;
  @override
  final int? quantityLimitPerCustomer;
  @override
  final bool isPreorder;
  @override
  final DateTime? preorderEndDate;
  @override
  final String? tags;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ProductVariant(id: $id, name: $name, productId: $productId, sku: $sku, price: $price, discountedPrice: $discountedPrice, stockUnit: $stockUnit, currentQuantity: $currentQuantity, status: $status, media: $media, productDescription: $productDescription, productRating: $productRating, quantityLimitPerCustomer: $quantityLimitPerCustomer, isPreorder: $isPreorder, preorderEndDate: $preorderEndDate, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductVariantImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.sku, sku) || other.sku == sku) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.discountedPrice, discountedPrice) ||
                other.discountedPrice == discountedPrice) &&
            (identical(other.stockUnit, stockUnit) ||
                other.stockUnit == stockUnit) &&
            (identical(other.currentQuantity, currentQuantity) ||
                other.currentQuantity == currentQuantity) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._media, _media) &&
            (identical(other.productDescription, productDescription) ||
                other.productDescription == productDescription) &&
            (identical(other.productRating, productRating) ||
                other.productRating == productRating) &&
            (identical(
                  other.quantityLimitPerCustomer,
                  quantityLimitPerCustomer,
                ) ||
                other.quantityLimitPerCustomer == quantityLimitPerCustomer) &&
            (identical(other.isPreorder, isPreorder) ||
                other.isPreorder == isPreorder) &&
            (identical(other.preorderEndDate, preorderEndDate) ||
                other.preorderEndDate == preorderEndDate) &&
            (identical(other.tags, tags) || other.tags == tags) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    productId,
    sku,
    price,
    discountedPrice,
    stockUnit,
    currentQuantity,
    status,
    const DeepCollectionEquality().hash(_media),
    productDescription,
    productRating,
    quantityLimitPerCustomer,
    isPreorder,
    preorderEndDate,
    tags,
    createdAt,
    updatedAt,
  );

  /// Create a copy of ProductVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductVariantImplCopyWith<_$ProductVariantImpl> get copyWith =>
      __$$ProductVariantImplCopyWithImpl<_$ProductVariantImpl>(
        this,
        _$identity,
      );
}

abstract class _ProductVariant extends ProductVariant {
  const factory _ProductVariant({
    required final int id,
    required final String name,
    required final int productId,
    required final String sku,
    required final double price,
    final double? discountedPrice,
    final String? stockUnit,
    required final String currentQuantity,
    required final bool status,
    required final List<ProductMedia> media,
    final String? productDescription,
    final double? productRating,
    final int? quantityLimitPerCustomer,
    required final bool isPreorder,
    final DateTime? preorderEndDate,
    final String? tags,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$ProductVariantImpl;
  const _ProductVariant._() : super._();

  @override
  int get id;
  @override
  String get name;
  @override
  int get productId;
  @override
  String get sku;
  @override
  double get price;
  @override
  double? get discountedPrice;
  @override
  String? get stockUnit;
  @override
  String get currentQuantity;
  @override
  bool get status;
  @override
  List<ProductMedia> get media;
  @override
  String? get productDescription;
  @override
  double? get productRating;
  @override
  int? get quantityLimitPerCustomer;
  @override
  bool get isPreorder;
  @override
  DateTime? get preorderEndDate;
  @override
  String? get tags;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of ProductVariant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductVariantImplCopyWith<_$ProductVariantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
