// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LocationState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LocationPermissionStatus status)
    permissionRequired,
    required TResult Function(LocationData location) loaded,
    required TResult Function(Failure failure, LocationData? previousLocation)
    error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LocationPermissionStatus status)? permissionRequired,
    TResult? Function(LocationData location)? loaded,
    TResult? Function(Failure failure, LocationData? previousLocation)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LocationPermissionStatus status)? permissionRequired,
    TResult Function(LocationData location)? loaded,
    TResult Function(Failure failure, LocationData? previousLocation)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LocationInitial value) initial,
    required TResult Function(LocationLoading value) loading,
    required TResult Function(LocationPermissionRequired value)
    permissionRequired,
    required TResult Function(LocationLoaded value) loaded,
    required TResult Function(LocationError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocationInitial value)? initial,
    TResult? Function(LocationLoading value)? loading,
    TResult? Function(LocationPermissionRequired value)? permissionRequired,
    TResult? Function(LocationLoaded value)? loaded,
    TResult? Function(LocationError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocationInitial value)? initial,
    TResult Function(LocationLoading value)? loading,
    TResult Function(LocationPermissionRequired value)? permissionRequired,
    TResult Function(LocationLoaded value)? loaded,
    TResult Function(LocationError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationStateCopyWith<$Res> {
  factory $LocationStateCopyWith(
    LocationState value,
    $Res Function(LocationState) then,
  ) = _$LocationStateCopyWithImpl<$Res, LocationState>;
}

/// @nodoc
class _$LocationStateCopyWithImpl<$Res, $Val extends LocationState>
    implements $LocationStateCopyWith<$Res> {
  _$LocationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LocationInitialImplCopyWith<$Res> {
  factory _$$LocationInitialImplCopyWith(
    _$LocationInitialImpl value,
    $Res Function(_$LocationInitialImpl) then,
  ) = __$$LocationInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LocationInitialImplCopyWithImpl<$Res>
    extends _$LocationStateCopyWithImpl<$Res, _$LocationInitialImpl>
    implements _$$LocationInitialImplCopyWith<$Res> {
  __$$LocationInitialImplCopyWithImpl(
    _$LocationInitialImpl _value,
    $Res Function(_$LocationInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LocationInitialImpl implements LocationInitial {
  const _$LocationInitialImpl();

  @override
  String toString() {
    return 'LocationState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LocationInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LocationPermissionStatus status)
    permissionRequired,
    required TResult Function(LocationData location) loaded,
    required TResult Function(Failure failure, LocationData? previousLocation)
    error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LocationPermissionStatus status)? permissionRequired,
    TResult? Function(LocationData location)? loaded,
    TResult? Function(Failure failure, LocationData? previousLocation)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LocationPermissionStatus status)? permissionRequired,
    TResult Function(LocationData location)? loaded,
    TResult Function(Failure failure, LocationData? previousLocation)? error,
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
    required TResult Function(LocationInitial value) initial,
    required TResult Function(LocationLoading value) loading,
    required TResult Function(LocationPermissionRequired value)
    permissionRequired,
    required TResult Function(LocationLoaded value) loaded,
    required TResult Function(LocationError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocationInitial value)? initial,
    TResult? Function(LocationLoading value)? loading,
    TResult? Function(LocationPermissionRequired value)? permissionRequired,
    TResult? Function(LocationLoaded value)? loaded,
    TResult? Function(LocationError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocationInitial value)? initial,
    TResult Function(LocationLoading value)? loading,
    TResult Function(LocationPermissionRequired value)? permissionRequired,
    TResult Function(LocationLoaded value)? loaded,
    TResult Function(LocationError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class LocationInitial implements LocationState {
  const factory LocationInitial() = _$LocationInitialImpl;
}

/// @nodoc
abstract class _$$LocationLoadingImplCopyWith<$Res> {
  factory _$$LocationLoadingImplCopyWith(
    _$LocationLoadingImpl value,
    $Res Function(_$LocationLoadingImpl) then,
  ) = __$$LocationLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LocationLoadingImplCopyWithImpl<$Res>
    extends _$LocationStateCopyWithImpl<$Res, _$LocationLoadingImpl>
    implements _$$LocationLoadingImplCopyWith<$Res> {
  __$$LocationLoadingImplCopyWithImpl(
    _$LocationLoadingImpl _value,
    $Res Function(_$LocationLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LocationLoadingImpl implements LocationLoading {
  const _$LocationLoadingImpl();

  @override
  String toString() {
    return 'LocationState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LocationLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LocationPermissionStatus status)
    permissionRequired,
    required TResult Function(LocationData location) loaded,
    required TResult Function(Failure failure, LocationData? previousLocation)
    error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LocationPermissionStatus status)? permissionRequired,
    TResult? Function(LocationData location)? loaded,
    TResult? Function(Failure failure, LocationData? previousLocation)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LocationPermissionStatus status)? permissionRequired,
    TResult Function(LocationData location)? loaded,
    TResult Function(Failure failure, LocationData? previousLocation)? error,
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
    required TResult Function(LocationInitial value) initial,
    required TResult Function(LocationLoading value) loading,
    required TResult Function(LocationPermissionRequired value)
    permissionRequired,
    required TResult Function(LocationLoaded value) loaded,
    required TResult Function(LocationError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocationInitial value)? initial,
    TResult? Function(LocationLoading value)? loading,
    TResult? Function(LocationPermissionRequired value)? permissionRequired,
    TResult? Function(LocationLoaded value)? loaded,
    TResult? Function(LocationError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocationInitial value)? initial,
    TResult Function(LocationLoading value)? loading,
    TResult Function(LocationPermissionRequired value)? permissionRequired,
    TResult Function(LocationLoaded value)? loaded,
    TResult Function(LocationError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class LocationLoading implements LocationState {
  const factory LocationLoading() = _$LocationLoadingImpl;
}

/// @nodoc
abstract class _$$LocationPermissionRequiredImplCopyWith<$Res> {
  factory _$$LocationPermissionRequiredImplCopyWith(
    _$LocationPermissionRequiredImpl value,
    $Res Function(_$LocationPermissionRequiredImpl) then,
  ) = __$$LocationPermissionRequiredImplCopyWithImpl<$Res>;
  @useResult
  $Res call({LocationPermissionStatus status});
}

/// @nodoc
class __$$LocationPermissionRequiredImplCopyWithImpl<$Res>
    extends _$LocationStateCopyWithImpl<$Res, _$LocationPermissionRequiredImpl>
    implements _$$LocationPermissionRequiredImplCopyWith<$Res> {
  __$$LocationPermissionRequiredImplCopyWithImpl(
    _$LocationPermissionRequiredImpl _value,
    $Res Function(_$LocationPermissionRequiredImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? status = null}) {
    return _then(
      _$LocationPermissionRequiredImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as LocationPermissionStatus,
      ),
    );
  }
}

/// @nodoc

class _$LocationPermissionRequiredImpl implements LocationPermissionRequired {
  const _$LocationPermissionRequiredImpl({required this.status});

  @override
  final LocationPermissionStatus status;

  @override
  String toString() {
    return 'LocationState.permissionRequired(status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationPermissionRequiredImpl &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status);

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationPermissionRequiredImplCopyWith<_$LocationPermissionRequiredImpl>
  get copyWith =>
      __$$LocationPermissionRequiredImplCopyWithImpl<
        _$LocationPermissionRequiredImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LocationPermissionStatus status)
    permissionRequired,
    required TResult Function(LocationData location) loaded,
    required TResult Function(Failure failure, LocationData? previousLocation)
    error,
  }) {
    return permissionRequired(status);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LocationPermissionStatus status)? permissionRequired,
    TResult? Function(LocationData location)? loaded,
    TResult? Function(Failure failure, LocationData? previousLocation)? error,
  }) {
    return permissionRequired?.call(status);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LocationPermissionStatus status)? permissionRequired,
    TResult Function(LocationData location)? loaded,
    TResult Function(Failure failure, LocationData? previousLocation)? error,
    required TResult orElse(),
  }) {
    if (permissionRequired != null) {
      return permissionRequired(status);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LocationInitial value) initial,
    required TResult Function(LocationLoading value) loading,
    required TResult Function(LocationPermissionRequired value)
    permissionRequired,
    required TResult Function(LocationLoaded value) loaded,
    required TResult Function(LocationError value) error,
  }) {
    return permissionRequired(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocationInitial value)? initial,
    TResult? Function(LocationLoading value)? loading,
    TResult? Function(LocationPermissionRequired value)? permissionRequired,
    TResult? Function(LocationLoaded value)? loaded,
    TResult? Function(LocationError value)? error,
  }) {
    return permissionRequired?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocationInitial value)? initial,
    TResult Function(LocationLoading value)? loading,
    TResult Function(LocationPermissionRequired value)? permissionRequired,
    TResult Function(LocationLoaded value)? loaded,
    TResult Function(LocationError value)? error,
    required TResult orElse(),
  }) {
    if (permissionRequired != null) {
      return permissionRequired(this);
    }
    return orElse();
  }
}

abstract class LocationPermissionRequired implements LocationState {
  const factory LocationPermissionRequired({
    required final LocationPermissionStatus status,
  }) = _$LocationPermissionRequiredImpl;

  LocationPermissionStatus get status;

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocationPermissionRequiredImplCopyWith<_$LocationPermissionRequiredImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LocationLoadedImplCopyWith<$Res> {
  factory _$$LocationLoadedImplCopyWith(
    _$LocationLoadedImpl value,
    $Res Function(_$LocationLoadedImpl) then,
  ) = __$$LocationLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({LocationData location});
}

/// @nodoc
class __$$LocationLoadedImplCopyWithImpl<$Res>
    extends _$LocationStateCopyWithImpl<$Res, _$LocationLoadedImpl>
    implements _$$LocationLoadedImplCopyWith<$Res> {
  __$$LocationLoadedImplCopyWithImpl(
    _$LocationLoadedImpl _value,
    $Res Function(_$LocationLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? location = null}) {
    return _then(
      _$LocationLoadedImpl(
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as LocationData,
      ),
    );
  }
}

/// @nodoc

class _$LocationLoadedImpl implements LocationLoaded {
  const _$LocationLoadedImpl({required this.location});

  @override
  final LocationData location;

  @override
  String toString() {
    return 'LocationState.loaded(location: $location)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationLoadedImpl &&
            (identical(other.location, location) ||
                other.location == location));
  }

  @override
  int get hashCode => Object.hash(runtimeType, location);

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationLoadedImplCopyWith<_$LocationLoadedImpl> get copyWith =>
      __$$LocationLoadedImplCopyWithImpl<_$LocationLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LocationPermissionStatus status)
    permissionRequired,
    required TResult Function(LocationData location) loaded,
    required TResult Function(Failure failure, LocationData? previousLocation)
    error,
  }) {
    return loaded(location);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LocationPermissionStatus status)? permissionRequired,
    TResult? Function(LocationData location)? loaded,
    TResult? Function(Failure failure, LocationData? previousLocation)? error,
  }) {
    return loaded?.call(location);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LocationPermissionStatus status)? permissionRequired,
    TResult Function(LocationData location)? loaded,
    TResult Function(Failure failure, LocationData? previousLocation)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(location);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LocationInitial value) initial,
    required TResult Function(LocationLoading value) loading,
    required TResult Function(LocationPermissionRequired value)
    permissionRequired,
    required TResult Function(LocationLoaded value) loaded,
    required TResult Function(LocationError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocationInitial value)? initial,
    TResult? Function(LocationLoading value)? loading,
    TResult? Function(LocationPermissionRequired value)? permissionRequired,
    TResult? Function(LocationLoaded value)? loaded,
    TResult? Function(LocationError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocationInitial value)? initial,
    TResult Function(LocationLoading value)? loading,
    TResult Function(LocationPermissionRequired value)? permissionRequired,
    TResult Function(LocationLoaded value)? loaded,
    TResult Function(LocationError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class LocationLoaded implements LocationState {
  const factory LocationLoaded({required final LocationData location}) =
      _$LocationLoadedImpl;

  LocationData get location;

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocationLoadedImplCopyWith<_$LocationLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LocationErrorImplCopyWith<$Res> {
  factory _$$LocationErrorImplCopyWith(
    _$LocationErrorImpl value,
    $Res Function(_$LocationErrorImpl) then,
  ) = __$$LocationErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Failure failure, LocationData? previousLocation});
}

/// @nodoc
class __$$LocationErrorImplCopyWithImpl<$Res>
    extends _$LocationStateCopyWithImpl<$Res, _$LocationErrorImpl>
    implements _$$LocationErrorImplCopyWith<$Res> {
  __$$LocationErrorImplCopyWithImpl(
    _$LocationErrorImpl _value,
    $Res Function(_$LocationErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failure = null, Object? previousLocation = freezed}) {
    return _then(
      _$LocationErrorImpl(
        failure: null == failure
            ? _value.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as Failure,
        previousLocation: freezed == previousLocation
            ? _value.previousLocation
            : previousLocation // ignore: cast_nullable_to_non_nullable
                  as LocationData?,
      ),
    );
  }
}

/// @nodoc

class _$LocationErrorImpl implements LocationError {
  const _$LocationErrorImpl({required this.failure, this.previousLocation});

  @override
  final Failure failure;
  @override
  final LocationData? previousLocation;

  @override
  String toString() {
    return 'LocationState.error(failure: $failure, previousLocation: $previousLocation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationErrorImpl &&
            (identical(other.failure, failure) || other.failure == failure) &&
            (identical(other.previousLocation, previousLocation) ||
                other.previousLocation == previousLocation));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failure, previousLocation);

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationErrorImplCopyWith<_$LocationErrorImpl> get copyWith =>
      __$$LocationErrorImplCopyWithImpl<_$LocationErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LocationPermissionStatus status)
    permissionRequired,
    required TResult Function(LocationData location) loaded,
    required TResult Function(Failure failure, LocationData? previousLocation)
    error,
  }) {
    return error(failure, previousLocation);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LocationPermissionStatus status)? permissionRequired,
    TResult? Function(LocationData location)? loaded,
    TResult? Function(Failure failure, LocationData? previousLocation)? error,
  }) {
    return error?.call(failure, previousLocation);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LocationPermissionStatus status)? permissionRequired,
    TResult Function(LocationData location)? loaded,
    TResult Function(Failure failure, LocationData? previousLocation)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(failure, previousLocation);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LocationInitial value) initial,
    required TResult Function(LocationLoading value) loading,
    required TResult Function(LocationPermissionRequired value)
    permissionRequired,
    required TResult Function(LocationLoaded value) loaded,
    required TResult Function(LocationError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LocationInitial value)? initial,
    TResult? Function(LocationLoading value)? loading,
    TResult? Function(LocationPermissionRequired value)? permissionRequired,
    TResult? Function(LocationLoaded value)? loaded,
    TResult? Function(LocationError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LocationInitial value)? initial,
    TResult Function(LocationLoading value)? loading,
    TResult Function(LocationPermissionRequired value)? permissionRequired,
    TResult Function(LocationLoaded value)? loaded,
    TResult Function(LocationError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class LocationError implements LocationState {
  const factory LocationError({
    required final Failure failure,
    final LocationData? previousLocation,
  }) = _$LocationErrorImpl;

  Failure get failure;
  LocationData? get previousLocation;

  /// Create a copy of LocationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocationErrorImplCopyWith<_$LocationErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
