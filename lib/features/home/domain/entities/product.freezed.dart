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
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get categoryName => throw _privateConstructorUsedError;
  int get categoryId => throw _privateConstructorUsedError;
  String? get slug => throw _privateConstructorUsedError;
  String? get descriptionPlaintext => throw _privateConstructorUsedError;
  String? get searchDocument => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get weight => throw _privateConstructorUsedError;
  int? get defaultVariantId => throw _privateConstructorUsedError;
  String get rating => throw _privateConstructorUsedError;
  int get taxClassId => throw _privateConstructorUsedError;
  List<ProductMedia> get media => throw _privateConstructorUsedError;
  List<ProductVariant> get variants => throw _privateConstructorUsedError;
  bool get status => throw _privateConstructorUsedError;
  String? get tags => throw _privateConstructorUsedError;

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
    int id,
    String name,
    String? description,
    String categoryName,
    int categoryId,
    String? slug,
    String? descriptionPlaintext,
    String? searchDocument,
    DateTime createdAt,
    DateTime updatedAt,
    String? weight,
    int? defaultVariantId,
    String rating,
    int taxClassId,
    List<ProductMedia> media,
    List<ProductVariant> variants,
    bool status,
    String? tags,
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
    Object? description = freezed,
    Object? categoryName = null,
    Object? categoryId = null,
    Object? slug = freezed,
    Object? descriptionPlaintext = freezed,
    Object? searchDocument = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? weight = freezed,
    Object? defaultVariantId = freezed,
    Object? rating = null,
    Object? taxClassId = null,
    Object? media = null,
    Object? variants = null,
    Object? status = null,
    Object? tags = freezed,
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
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryName: null == categoryName
                ? _value.categoryName
                : categoryName // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as int,
            slug: freezed == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String?,
            descriptionPlaintext: freezed == descriptionPlaintext
                ? _value.descriptionPlaintext
                : descriptionPlaintext // ignore: cast_nullable_to_non_nullable
                      as String?,
            searchDocument: freezed == searchDocument
                ? _value.searchDocument
                : searchDocument // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            weight: freezed == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as String?,
            defaultVariantId: freezed == defaultVariantId
                ? _value.defaultVariantId
                : defaultVariantId // ignore: cast_nullable_to_non_nullable
                      as int?,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as String,
            taxClassId: null == taxClassId
                ? _value.taxClassId
                : taxClassId // ignore: cast_nullable_to_non_nullable
                      as int,
            media: null == media
                ? _value.media
                : media // ignore: cast_nullable_to_non_nullable
                      as List<ProductMedia>,
            variants: null == variants
                ? _value.variants
                : variants // ignore: cast_nullable_to_non_nullable
                      as List<ProductVariant>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as bool,
            tags: freezed == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as String?,
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
    int id,
    String name,
    String? description,
    String categoryName,
    int categoryId,
    String? slug,
    String? descriptionPlaintext,
    String? searchDocument,
    DateTime createdAt,
    DateTime updatedAt,
    String? weight,
    int? defaultVariantId,
    String rating,
    int taxClassId,
    List<ProductMedia> media,
    List<ProductVariant> variants,
    bool status,
    String? tags,
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
    Object? description = freezed,
    Object? categoryName = null,
    Object? categoryId = null,
    Object? slug = freezed,
    Object? descriptionPlaintext = freezed,
    Object? searchDocument = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? weight = freezed,
    Object? defaultVariantId = freezed,
    Object? rating = null,
    Object? taxClassId = null,
    Object? media = null,
    Object? variants = null,
    Object? status = null,
    Object? tags = freezed,
  }) {
    return _then(
      _$ProductImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryName: null == categoryName
            ? _value.categoryName
            : categoryName // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as int,
        slug: freezed == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String?,
        descriptionPlaintext: freezed == descriptionPlaintext
            ? _value.descriptionPlaintext
            : descriptionPlaintext // ignore: cast_nullable_to_non_nullable
                  as String?,
        searchDocument: freezed == searchDocument
            ? _value.searchDocument
            : searchDocument // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        weight: freezed == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as String?,
        defaultVariantId: freezed == defaultVariantId
            ? _value.defaultVariantId
            : defaultVariantId // ignore: cast_nullable_to_non_nullable
                  as int?,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as String,
        taxClassId: null == taxClassId
            ? _value.taxClassId
            : taxClassId // ignore: cast_nullable_to_non_nullable
                  as int,
        media: null == media
            ? _value._media
            : media // ignore: cast_nullable_to_non_nullable
                  as List<ProductMedia>,
        variants: null == variants
            ? _value._variants
            : variants // ignore: cast_nullable_to_non_nullable
                  as List<ProductVariant>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as bool,
        tags: freezed == tags
            ? _value.tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ProductImpl extends _Product {
  const _$ProductImpl({
    required this.id,
    required this.name,
    this.description,
    required this.categoryName,
    required this.categoryId,
    this.slug,
    this.descriptionPlaintext,
    this.searchDocument,
    required this.createdAt,
    required this.updatedAt,
    this.weight,
    this.defaultVariantId,
    required this.rating,
    required this.taxClassId,
    required final List<ProductMedia> media,
    required final List<ProductVariant> variants,
    required this.status,
    this.tags,
  }) : _media = media,
       _variants = variants,
       super._();

  @override
  final int id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String categoryName;
  @override
  final int categoryId;
  @override
  final String? slug;
  @override
  final String? descriptionPlaintext;
  @override
  final String? searchDocument;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? weight;
  @override
  final int? defaultVariantId;
  @override
  final String rating;
  @override
  final int taxClassId;
  final List<ProductMedia> _media;
  @override
  List<ProductMedia> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  final List<ProductVariant> _variants;
  @override
  List<ProductVariant> get variants {
    if (_variants is EqualUnmodifiableListView) return _variants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_variants);
  }

  @override
  final bool status;
  @override
  final String? tags;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, description: $description, categoryName: $categoryName, categoryId: $categoryId, slug: $slug, descriptionPlaintext: $descriptionPlaintext, searchDocument: $searchDocument, createdAt: $createdAt, updatedAt: $updatedAt, weight: $weight, defaultVariantId: $defaultVariantId, rating: $rating, taxClassId: $taxClassId, media: $media, variants: $variants, status: $status, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.descriptionPlaintext, descriptionPlaintext) ||
                other.descriptionPlaintext == descriptionPlaintext) &&
            (identical(other.searchDocument, searchDocument) ||
                other.searchDocument == searchDocument) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.defaultVariantId, defaultVariantId) ||
                other.defaultVariantId == defaultVariantId) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.taxClassId, taxClassId) ||
                other.taxClassId == taxClassId) &&
            const DeepCollectionEquality().equals(other._media, _media) &&
            const DeepCollectionEquality().equals(other._variants, _variants) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.tags, tags) || other.tags == tags));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    categoryName,
    categoryId,
    slug,
    descriptionPlaintext,
    searchDocument,
    createdAt,
    updatedAt,
    weight,
    defaultVariantId,
    rating,
    taxClassId,
    const DeepCollectionEquality().hash(_media),
    const DeepCollectionEquality().hash(_variants),
    status,
    tags,
  );

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);
}

abstract class _Product extends Product {
  const factory _Product({
    required final int id,
    required final String name,
    final String? description,
    required final String categoryName,
    required final int categoryId,
    final String? slug,
    final String? descriptionPlaintext,
    final String? searchDocument,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final String? weight,
    final int? defaultVariantId,
    required final String rating,
    required final int taxClassId,
    required final List<ProductMedia> media,
    required final List<ProductVariant> variants,
    required final bool status,
    final String? tags,
  }) = _$ProductImpl;
  const _Product._() : super._();

  @override
  int get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get categoryName;
  @override
  int get categoryId;
  @override
  String? get slug;
  @override
  String? get descriptionPlaintext;
  @override
  String? get searchDocument;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get weight;
  @override
  int? get defaultVariantId;
  @override
  String get rating;
  @override
  int get taxClassId;
  @override
  List<ProductMedia> get media;
  @override
  List<ProductVariant> get variants;
  @override
  bool get status;
  @override
  String? get tags;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
