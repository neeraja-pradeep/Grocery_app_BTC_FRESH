// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_discount_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CategoryDiscountGroup {
  Category get category => throw _privateConstructorUsedError;
  List<ProductVariant> get discountedProducts =>
      throw _privateConstructorUsedError;

  /// Create a copy of CategoryDiscountGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryDiscountGroupCopyWith<CategoryDiscountGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryDiscountGroupCopyWith<$Res> {
  factory $CategoryDiscountGroupCopyWith(
    CategoryDiscountGroup value,
    $Res Function(CategoryDiscountGroup) then,
  ) = _$CategoryDiscountGroupCopyWithImpl<$Res, CategoryDiscountGroup>;
  @useResult
  $Res call({Category category, List<ProductVariant> discountedProducts});

  $CategoryCopyWith<$Res> get category;
}

/// @nodoc
class _$CategoryDiscountGroupCopyWithImpl<
  $Res,
  $Val extends CategoryDiscountGroup
>
    implements $CategoryDiscountGroupCopyWith<$Res> {
  _$CategoryDiscountGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategoryDiscountGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? category = null, Object? discountedProducts = null}) {
    return _then(
      _value.copyWith(
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as Category,
            discountedProducts: null == discountedProducts
                ? _value.discountedProducts
                : discountedProducts // ignore: cast_nullable_to_non_nullable
                      as List<ProductVariant>,
          )
          as $Val,
    );
  }

  /// Create a copy of CategoryDiscountGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryCopyWith<$Res> get category {
    return $CategoryCopyWith<$Res>(_value.category, (value) {
      return _then(_value.copyWith(category: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CategoryDiscountGroupImplCopyWith<$Res>
    implements $CategoryDiscountGroupCopyWith<$Res> {
  factory _$$CategoryDiscountGroupImplCopyWith(
    _$CategoryDiscountGroupImpl value,
    $Res Function(_$CategoryDiscountGroupImpl) then,
  ) = __$$CategoryDiscountGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Category category, List<ProductVariant> discountedProducts});

  @override
  $CategoryCopyWith<$Res> get category;
}

/// @nodoc
class __$$CategoryDiscountGroupImplCopyWithImpl<$Res>
    extends
        _$CategoryDiscountGroupCopyWithImpl<$Res, _$CategoryDiscountGroupImpl>
    implements _$$CategoryDiscountGroupImplCopyWith<$Res> {
  __$$CategoryDiscountGroupImplCopyWithImpl(
    _$CategoryDiscountGroupImpl _value,
    $Res Function(_$CategoryDiscountGroupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CategoryDiscountGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? category = null, Object? discountedProducts = null}) {
    return _then(
      _$CategoryDiscountGroupImpl(
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as Category,
        discountedProducts: null == discountedProducts
            ? _value._discountedProducts
            : discountedProducts // ignore: cast_nullable_to_non_nullable
                  as List<ProductVariant>,
      ),
    );
  }
}

/// @nodoc

class _$CategoryDiscountGroupImpl extends _CategoryDiscountGroup {
  const _$CategoryDiscountGroupImpl({
    required this.category,
    required final List<ProductVariant> discountedProducts,
  }) : _discountedProducts = discountedProducts,
       super._();

  @override
  final Category category;
  final List<ProductVariant> _discountedProducts;
  @override
  List<ProductVariant> get discountedProducts {
    if (_discountedProducts is EqualUnmodifiableListView)
      return _discountedProducts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_discountedProducts);
  }

  @override
  String toString() {
    return 'CategoryDiscountGroup(category: $category, discountedProducts: $discountedProducts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryDiscountGroupImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(
              other._discountedProducts,
              _discountedProducts,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    category,
    const DeepCollectionEquality().hash(_discountedProducts),
  );

  /// Create a copy of CategoryDiscountGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryDiscountGroupImplCopyWith<_$CategoryDiscountGroupImpl>
  get copyWith =>
      __$$CategoryDiscountGroupImplCopyWithImpl<_$CategoryDiscountGroupImpl>(
        this,
        _$identity,
      );
}

abstract class _CategoryDiscountGroup extends CategoryDiscountGroup {
  const factory _CategoryDiscountGroup({
    required final Category category,
    required final List<ProductVariant> discountedProducts,
  }) = _$CategoryDiscountGroupImpl;
  const _CategoryDiscountGroup._() : super._();

  @override
  Category get category;
  @override
  List<ProductVariant> get discountedProducts;

  /// Create a copy of CategoryDiscountGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryDiscountGroupImplCopyWith<_$CategoryDiscountGroupImpl>
  get copyWith => throw _privateConstructorUsedError;
}
