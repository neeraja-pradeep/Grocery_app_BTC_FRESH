// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wishlist_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$WishlistState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WishlistItem> items, bool isRefreshing)
    loaded,
    required TResult Function(List<WishlistItem> items) refreshing,
    required TResult Function(Failure failure, WishlistState? previousState)
    error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult? Function(List<WishlistItem> items)? refreshing,
    TResult? Function(Failure failure, WishlistState? previousState)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult Function(List<WishlistItem> items)? refreshing,
    TResult Function(Failure failure, WishlistState? previousState)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WishlistInitial value) initial,
    required TResult Function(WishlistLoading value) loading,
    required TResult Function(WishlistLoaded value) loaded,
    required TResult Function(WishlistRefreshing value) refreshing,
    required TResult Function(WishlistError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WishlistInitial value)? initial,
    TResult? Function(WishlistLoading value)? loading,
    TResult? Function(WishlistLoaded value)? loaded,
    TResult? Function(WishlistRefreshing value)? refreshing,
    TResult? Function(WishlistError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WishlistInitial value)? initial,
    TResult Function(WishlistLoading value)? loading,
    TResult Function(WishlistLoaded value)? loaded,
    TResult Function(WishlistRefreshing value)? refreshing,
    TResult Function(WishlistError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WishlistStateCopyWith<$Res> {
  factory $WishlistStateCopyWith(
    WishlistState value,
    $Res Function(WishlistState) then,
  ) = _$WishlistStateCopyWithImpl<$Res, WishlistState>;
}

/// @nodoc
class _$WishlistStateCopyWithImpl<$Res, $Val extends WishlistState>
    implements $WishlistStateCopyWith<$Res> {
  _$WishlistStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$WishlistInitialImplCopyWith<$Res> {
  factory _$$WishlistInitialImplCopyWith(
    _$WishlistInitialImpl value,
    $Res Function(_$WishlistInitialImpl) then,
  ) = __$$WishlistInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$WishlistInitialImplCopyWithImpl<$Res>
    extends _$WishlistStateCopyWithImpl<$Res, _$WishlistInitialImpl>
    implements _$$WishlistInitialImplCopyWith<$Res> {
  __$$WishlistInitialImplCopyWithImpl(
    _$WishlistInitialImpl _value,
    $Res Function(_$WishlistInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$WishlistInitialImpl implements WishlistInitial {
  const _$WishlistInitialImpl();

  @override
  String toString() {
    return 'WishlistState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$WishlistInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WishlistItem> items, bool isRefreshing)
    loaded,
    required TResult Function(List<WishlistItem> items) refreshing,
    required TResult Function(Failure failure, WishlistState? previousState)
    error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult? Function(List<WishlistItem> items)? refreshing,
    TResult? Function(Failure failure, WishlistState? previousState)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult Function(List<WishlistItem> items)? refreshing,
    TResult Function(Failure failure, WishlistState? previousState)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WishlistInitial value) initial,
    required TResult Function(WishlistLoading value) loading,
    required TResult Function(WishlistLoaded value) loaded,
    required TResult Function(WishlistRefreshing value) refreshing,
    required TResult Function(WishlistError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WishlistInitial value)? initial,
    TResult? Function(WishlistLoading value)? loading,
    TResult? Function(WishlistLoaded value)? loaded,
    TResult? Function(WishlistRefreshing value)? refreshing,
    TResult? Function(WishlistError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WishlistInitial value)? initial,
    TResult Function(WishlistLoading value)? loading,
    TResult Function(WishlistLoaded value)? loaded,
    TResult Function(WishlistRefreshing value)? refreshing,
    TResult Function(WishlistError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class WishlistInitial implements WishlistState {
  const factory WishlistInitial() = _$WishlistInitialImpl;
}

/// @nodoc
abstract class _$$WishlistLoadingImplCopyWith<$Res> {
  factory _$$WishlistLoadingImplCopyWith(
    _$WishlistLoadingImpl value,
    $Res Function(_$WishlistLoadingImpl) then,
  ) = __$$WishlistLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$WishlistLoadingImplCopyWithImpl<$Res>
    extends _$WishlistStateCopyWithImpl<$Res, _$WishlistLoadingImpl>
    implements _$$WishlistLoadingImplCopyWith<$Res> {
  __$$WishlistLoadingImplCopyWithImpl(
    _$WishlistLoadingImpl _value,
    $Res Function(_$WishlistLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$WishlistLoadingImpl implements WishlistLoading {
  const _$WishlistLoadingImpl();

  @override
  String toString() {
    return 'WishlistState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$WishlistLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WishlistItem> items, bool isRefreshing)
    loaded,
    required TResult Function(List<WishlistItem> items) refreshing,
    required TResult Function(Failure failure, WishlistState? previousState)
    error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult? Function(List<WishlistItem> items)? refreshing,
    TResult? Function(Failure failure, WishlistState? previousState)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult Function(List<WishlistItem> items)? refreshing,
    TResult Function(Failure failure, WishlistState? previousState)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WishlistInitial value) initial,
    required TResult Function(WishlistLoading value) loading,
    required TResult Function(WishlistLoaded value) loaded,
    required TResult Function(WishlistRefreshing value) refreshing,
    required TResult Function(WishlistError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WishlistInitial value)? initial,
    TResult? Function(WishlistLoading value)? loading,
    TResult? Function(WishlistLoaded value)? loaded,
    TResult? Function(WishlistRefreshing value)? refreshing,
    TResult? Function(WishlistError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WishlistInitial value)? initial,
    TResult Function(WishlistLoading value)? loading,
    TResult Function(WishlistLoaded value)? loaded,
    TResult Function(WishlistRefreshing value)? refreshing,
    TResult Function(WishlistError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class WishlistLoading implements WishlistState {
  const factory WishlistLoading() = _$WishlistLoadingImpl;
}

/// @nodoc
abstract class _$$WishlistLoadedImplCopyWith<$Res> {
  factory _$$WishlistLoadedImplCopyWith(
    _$WishlistLoadedImpl value,
    $Res Function(_$WishlistLoadedImpl) then,
  ) = __$$WishlistLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<WishlistItem> items, bool isRefreshing});
}

/// @nodoc
class __$$WishlistLoadedImplCopyWithImpl<$Res>
    extends _$WishlistStateCopyWithImpl<$Res, _$WishlistLoadedImpl>
    implements _$$WishlistLoadedImplCopyWith<$Res> {
  __$$WishlistLoadedImplCopyWithImpl(
    _$WishlistLoadedImpl _value,
    $Res Function(_$WishlistLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null, Object? isRefreshing = null}) {
    return _then(
      _$WishlistLoadedImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<WishlistItem>,
        isRefreshing: null == isRefreshing
            ? _value.isRefreshing
            : isRefreshing // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$WishlistLoadedImpl implements WishlistLoaded {
  const _$WishlistLoadedImpl({
    required final List<WishlistItem> items,
    this.isRefreshing = false,
  }) : _items = items;

  final List<WishlistItem> _items;
  @override
  List<WishlistItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final bool isRefreshing;

  @override
  String toString() {
    return 'WishlistState.loaded(items: $items, isRefreshing: $isRefreshing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WishlistLoadedImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    isRefreshing,
  );

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WishlistLoadedImplCopyWith<_$WishlistLoadedImpl> get copyWith =>
      __$$WishlistLoadedImplCopyWithImpl<_$WishlistLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WishlistItem> items, bool isRefreshing)
    loaded,
    required TResult Function(List<WishlistItem> items) refreshing,
    required TResult Function(Failure failure, WishlistState? previousState)
    error,
  }) {
    return loaded(items, isRefreshing);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult? Function(List<WishlistItem> items)? refreshing,
    TResult? Function(Failure failure, WishlistState? previousState)? error,
  }) {
    return loaded?.call(items, isRefreshing);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult Function(List<WishlistItem> items)? refreshing,
    TResult Function(Failure failure, WishlistState? previousState)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(items, isRefreshing);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WishlistInitial value) initial,
    required TResult Function(WishlistLoading value) loading,
    required TResult Function(WishlistLoaded value) loaded,
    required TResult Function(WishlistRefreshing value) refreshing,
    required TResult Function(WishlistError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WishlistInitial value)? initial,
    TResult? Function(WishlistLoading value)? loading,
    TResult? Function(WishlistLoaded value)? loaded,
    TResult? Function(WishlistRefreshing value)? refreshing,
    TResult? Function(WishlistError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WishlistInitial value)? initial,
    TResult Function(WishlistLoading value)? loading,
    TResult Function(WishlistLoaded value)? loaded,
    TResult Function(WishlistRefreshing value)? refreshing,
    TResult Function(WishlistError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class WishlistLoaded implements WishlistState {
  const factory WishlistLoaded({
    required final List<WishlistItem> items,
    final bool isRefreshing,
  }) = _$WishlistLoadedImpl;

  List<WishlistItem> get items;
  bool get isRefreshing;

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WishlistLoadedImplCopyWith<_$WishlistLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WishlistRefreshingImplCopyWith<$Res> {
  factory _$$WishlistRefreshingImplCopyWith(
    _$WishlistRefreshingImpl value,
    $Res Function(_$WishlistRefreshingImpl) then,
  ) = __$$WishlistRefreshingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<WishlistItem> items});
}

/// @nodoc
class __$$WishlistRefreshingImplCopyWithImpl<$Res>
    extends _$WishlistStateCopyWithImpl<$Res, _$WishlistRefreshingImpl>
    implements _$$WishlistRefreshingImplCopyWith<$Res> {
  __$$WishlistRefreshingImplCopyWithImpl(
    _$WishlistRefreshingImpl _value,
    $Res Function(_$WishlistRefreshingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _$WishlistRefreshingImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<WishlistItem>,
      ),
    );
  }
}

/// @nodoc

class _$WishlistRefreshingImpl implements WishlistRefreshing {
  const _$WishlistRefreshingImpl({required final List<WishlistItem> items})
    : _items = items;

  final List<WishlistItem> _items;
  @override
  List<WishlistItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'WishlistState.refreshing(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WishlistRefreshingImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WishlistRefreshingImplCopyWith<_$WishlistRefreshingImpl> get copyWith =>
      __$$WishlistRefreshingImplCopyWithImpl<_$WishlistRefreshingImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WishlistItem> items, bool isRefreshing)
    loaded,
    required TResult Function(List<WishlistItem> items) refreshing,
    required TResult Function(Failure failure, WishlistState? previousState)
    error,
  }) {
    return refreshing(items);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult? Function(List<WishlistItem> items)? refreshing,
    TResult? Function(Failure failure, WishlistState? previousState)? error,
  }) {
    return refreshing?.call(items);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult Function(List<WishlistItem> items)? refreshing,
    TResult Function(Failure failure, WishlistState? previousState)? error,
    required TResult orElse(),
  }) {
    if (refreshing != null) {
      return refreshing(items);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WishlistInitial value) initial,
    required TResult Function(WishlistLoading value) loading,
    required TResult Function(WishlistLoaded value) loaded,
    required TResult Function(WishlistRefreshing value) refreshing,
    required TResult Function(WishlistError value) error,
  }) {
    return refreshing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WishlistInitial value)? initial,
    TResult? Function(WishlistLoading value)? loading,
    TResult? Function(WishlistLoaded value)? loaded,
    TResult? Function(WishlistRefreshing value)? refreshing,
    TResult? Function(WishlistError value)? error,
  }) {
    return refreshing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WishlistInitial value)? initial,
    TResult Function(WishlistLoading value)? loading,
    TResult Function(WishlistLoaded value)? loaded,
    TResult Function(WishlistRefreshing value)? refreshing,
    TResult Function(WishlistError value)? error,
    required TResult orElse(),
  }) {
    if (refreshing != null) {
      return refreshing(this);
    }
    return orElse();
  }
}

abstract class WishlistRefreshing implements WishlistState {
  const factory WishlistRefreshing({required final List<WishlistItem> items}) =
      _$WishlistRefreshingImpl;

  List<WishlistItem> get items;

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WishlistRefreshingImplCopyWith<_$WishlistRefreshingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WishlistErrorImplCopyWith<$Res> {
  factory _$$WishlistErrorImplCopyWith(
    _$WishlistErrorImpl value,
    $Res Function(_$WishlistErrorImpl) then,
  ) = __$$WishlistErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Failure failure, WishlistState? previousState});

  $WishlistStateCopyWith<$Res>? get previousState;
}

/// @nodoc
class __$$WishlistErrorImplCopyWithImpl<$Res>
    extends _$WishlistStateCopyWithImpl<$Res, _$WishlistErrorImpl>
    implements _$$WishlistErrorImplCopyWith<$Res> {
  __$$WishlistErrorImplCopyWithImpl(
    _$WishlistErrorImpl _value,
    $Res Function(_$WishlistErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failure = null, Object? previousState = freezed}) {
    return _then(
      _$WishlistErrorImpl(
        failure: null == failure
            ? _value.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as Failure,
        previousState: freezed == previousState
            ? _value.previousState
            : previousState // ignore: cast_nullable_to_non_nullable
                  as WishlistState?,
      ),
    );
  }

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WishlistStateCopyWith<$Res>? get previousState {
    if (_value.previousState == null) {
      return null;
    }

    return $WishlistStateCopyWith<$Res>(_value.previousState!, (value) {
      return _then(_value.copyWith(previousState: value));
    });
  }
}

/// @nodoc

class _$WishlistErrorImpl implements WishlistError {
  const _$WishlistErrorImpl({required this.failure, this.previousState});

  @override
  final Failure failure;
  @override
  final WishlistState? previousState;

  @override
  String toString() {
    return 'WishlistState.error(failure: $failure, previousState: $previousState)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WishlistErrorImpl &&
            (identical(other.failure, failure) || other.failure == failure) &&
            (identical(other.previousState, previousState) ||
                other.previousState == previousState));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failure, previousState);

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WishlistErrorImplCopyWith<_$WishlistErrorImpl> get copyWith =>
      __$$WishlistErrorImplCopyWithImpl<_$WishlistErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WishlistItem> items, bool isRefreshing)
    loaded,
    required TResult Function(List<WishlistItem> items) refreshing,
    required TResult Function(Failure failure, WishlistState? previousState)
    error,
  }) {
    return error(failure, previousState);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult? Function(List<WishlistItem> items)? refreshing,
    TResult? Function(Failure failure, WishlistState? previousState)? error,
  }) {
    return error?.call(failure, previousState);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WishlistItem> items, bool isRefreshing)? loaded,
    TResult Function(List<WishlistItem> items)? refreshing,
    TResult Function(Failure failure, WishlistState? previousState)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(failure, previousState);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WishlistInitial value) initial,
    required TResult Function(WishlistLoading value) loading,
    required TResult Function(WishlistLoaded value) loaded,
    required TResult Function(WishlistRefreshing value) refreshing,
    required TResult Function(WishlistError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WishlistInitial value)? initial,
    TResult? Function(WishlistLoading value)? loading,
    TResult? Function(WishlistLoaded value)? loaded,
    TResult? Function(WishlistRefreshing value)? refreshing,
    TResult? Function(WishlistError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WishlistInitial value)? initial,
    TResult Function(WishlistLoading value)? loading,
    TResult Function(WishlistLoaded value)? loaded,
    TResult Function(WishlistRefreshing value)? refreshing,
    TResult Function(WishlistError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class WishlistError implements WishlistState {
  const factory WishlistError({
    required final Failure failure,
    final WishlistState? previousState,
  }) = _$WishlistErrorImpl;

  Failure get failure;
  WishlistState? get previousState;

  /// Create a copy of WishlistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WishlistErrorImplCopyWith<_$WishlistErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
