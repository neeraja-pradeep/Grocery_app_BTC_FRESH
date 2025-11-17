// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CatalogState {
  // Used unqualified names
  List<Category> get categories => throw _privateConstructorUsedError;
  List<Product> get bestDeals => throw _privateConstructorUsedError;
  List<Offer> get megaOffers => throw _privateConstructorUsedError;
  bool get isRefreshing => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  /// Create a copy of CatalogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CatalogStateCopyWith<CatalogState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CatalogStateCopyWith<$Res> {
  factory $CatalogStateCopyWith(
    CatalogState value,
    $Res Function(CatalogState) then,
  ) = _$CatalogStateCopyWithImpl<$Res, CatalogState>;
  @useResult
  $Res call({
    List<Category> categories,
    List<Product> bestDeals,
    List<Offer> megaOffers,
    bool isRefreshing,
    String? error,
    DateTime? lastUpdated,
  });
}

/// @nodoc
class _$CatalogStateCopyWithImpl<$Res, $Val extends CatalogState>
    implements $CatalogStateCopyWith<$Res> {
  _$CatalogStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CatalogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
    Object? bestDeals = null,
    Object? megaOffers = null,
    Object? isRefreshing = null,
    Object? error = freezed,
    Object? lastUpdated = freezed,
  }) {
    return _then(
      _value.copyWith(
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<Category>,
            bestDeals: null == bestDeals
                ? _value.bestDeals
                : bestDeals // ignore: cast_nullable_to_non_nullable
                      as List<Product>,
            megaOffers: null == megaOffers
                ? _value.megaOffers
                : megaOffers // ignore: cast_nullable_to_non_nullable
                      as List<Offer>,
            isRefreshing: null == isRefreshing
                ? _value.isRefreshing
                : isRefreshing // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastUpdated: freezed == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CatalogStateImplCopyWith<$Res>
    implements $CatalogStateCopyWith<$Res> {
  factory _$$CatalogStateImplCopyWith(
    _$CatalogStateImpl value,
    $Res Function(_$CatalogStateImpl) then,
  ) = __$$CatalogStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Category> categories,
    List<Product> bestDeals,
    List<Offer> megaOffers,
    bool isRefreshing,
    String? error,
    DateTime? lastUpdated,
  });
}

/// @nodoc
class __$$CatalogStateImplCopyWithImpl<$Res>
    extends _$CatalogStateCopyWithImpl<$Res, _$CatalogStateImpl>
    implements _$$CatalogStateImplCopyWith<$Res> {
  __$$CatalogStateImplCopyWithImpl(
    _$CatalogStateImpl _value,
    $Res Function(_$CatalogStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CatalogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
    Object? bestDeals = null,
    Object? megaOffers = null,
    Object? isRefreshing = null,
    Object? error = freezed,
    Object? lastUpdated = freezed,
  }) {
    return _then(
      _$CatalogStateImpl(
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<Category>,
        bestDeals: null == bestDeals
            ? _value._bestDeals
            : bestDeals // ignore: cast_nullable_to_non_nullable
                  as List<Product>,
        megaOffers: null == megaOffers
            ? _value._megaOffers
            : megaOffers // ignore: cast_nullable_to_non_nullable
                  as List<Offer>,
        isRefreshing: null == isRefreshing
            ? _value.isRefreshing
            : isRefreshing // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastUpdated: freezed == lastUpdated
            ? _value.lastUpdated
            : lastUpdated // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$CatalogStateImpl extends _CatalogState with DiagnosticableTreeMixin {
  const _$CatalogStateImpl({
    final List<Category> categories = const <Category>[],
    final List<Product> bestDeals = const <Product>[],
    final List<Offer> megaOffers = const <Offer>[],
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
  }) : _categories = categories,
       _bestDeals = bestDeals,
       _megaOffers = megaOffers,
       super._();

  // Used unqualified names
  final List<Category> _categories;
  // Used unqualified names
  @override
  @JsonKey()
  List<Category> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final List<Product> _bestDeals;
  @override
  @JsonKey()
  List<Product> get bestDeals {
    if (_bestDeals is EqualUnmodifiableListView) return _bestDeals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bestDeals);
  }

  final List<Offer> _megaOffers;
  @override
  @JsonKey()
  List<Offer> get megaOffers {
    if (_megaOffers is EqualUnmodifiableListView) return _megaOffers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_megaOffers);
  }

  @override
  @JsonKey()
  final bool isRefreshing;
  @override
  final String? error;
  @override
  final DateTime? lastUpdated;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CatalogState(categories: $categories, bestDeals: $bestDeals, megaOffers: $megaOffers, isRefreshing: $isRefreshing, error: $error, lastUpdated: $lastUpdated)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CatalogState'))
      ..add(DiagnosticsProperty('categories', categories))
      ..add(DiagnosticsProperty('bestDeals', bestDeals))
      ..add(DiagnosticsProperty('megaOffers', megaOffers))
      ..add(DiagnosticsProperty('isRefreshing', isRefreshing))
      ..add(DiagnosticsProperty('error', error))
      ..add(DiagnosticsProperty('lastUpdated', lastUpdated));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CatalogStateImpl &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            const DeepCollectionEquality().equals(
              other._bestDeals,
              _bestDeals,
            ) &&
            const DeepCollectionEquality().equals(
              other._megaOffers,
              _megaOffers,
            ) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_categories),
    const DeepCollectionEquality().hash(_bestDeals),
    const DeepCollectionEquality().hash(_megaOffers),
    isRefreshing,
    error,
    lastUpdated,
  );

  /// Create a copy of CatalogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CatalogStateImplCopyWith<_$CatalogStateImpl> get copyWith =>
      __$$CatalogStateImplCopyWithImpl<_$CatalogStateImpl>(this, _$identity);
}

abstract class _CatalogState extends CatalogState {
  const factory _CatalogState({
    final List<Category> categories,
    final List<Product> bestDeals,
    final List<Offer> megaOffers,
    final bool isRefreshing,
    final String? error,
    final DateTime? lastUpdated,
  }) = _$CatalogStateImpl;
  const _CatalogState._() : super._();

  // Used unqualified names
  @override
  List<Category> get categories;
  @override
  List<Product> get bestDeals;
  @override
  List<Offer> get megaOffers;
  @override
  bool get isRefreshing;
  @override
  String? get error;
  @override
  DateTime? get lastUpdated;

  /// Create a copy of CatalogState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CatalogStateImplCopyWith<_$CatalogStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
