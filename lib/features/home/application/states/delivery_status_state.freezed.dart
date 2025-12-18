// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_status_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DeliveryStatusState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(int orderId) loading,
    required TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )
    active,
    required TResult Function(int orderId, DeliveryEntity delivery) completed,
    required TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )
    failed,
    required TResult Function(int orderId, String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(int orderId)? loading,
    TResult? Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult? Function(int orderId, DeliveryEntity delivery)? completed,
    TResult? Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult? Function(int orderId, String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(int orderId)? loading,
    TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult Function(int orderId, DeliveryEntity delivery)? completed,
    TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult Function(int orderId, String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeliveryStatusHidden value) hidden,
    required TResult Function(DeliveryStatusLoading value) loading,
    required TResult Function(DeliveryStatusActive value) active,
    required TResult Function(DeliveryStatusCompleted value) completed,
    required TResult Function(DeliveryStatusFailed value) failed,
    required TResult Function(DeliveryStatusError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeliveryStatusHidden value)? hidden,
    TResult? Function(DeliveryStatusLoading value)? loading,
    TResult? Function(DeliveryStatusActive value)? active,
    TResult? Function(DeliveryStatusCompleted value)? completed,
    TResult? Function(DeliveryStatusFailed value)? failed,
    TResult? Function(DeliveryStatusError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeliveryStatusHidden value)? hidden,
    TResult Function(DeliveryStatusLoading value)? loading,
    TResult Function(DeliveryStatusActive value)? active,
    TResult Function(DeliveryStatusCompleted value)? completed,
    TResult Function(DeliveryStatusFailed value)? failed,
    TResult Function(DeliveryStatusError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliveryStatusStateCopyWith<$Res> {
  factory $DeliveryStatusStateCopyWith(
    DeliveryStatusState value,
    $Res Function(DeliveryStatusState) then,
  ) = _$DeliveryStatusStateCopyWithImpl<$Res, DeliveryStatusState>;
}

/// @nodoc
class _$DeliveryStatusStateCopyWithImpl<$Res, $Val extends DeliveryStatusState>
    implements $DeliveryStatusStateCopyWith<$Res> {
  _$DeliveryStatusStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$DeliveryStatusHiddenImplCopyWith<$Res> {
  factory _$$DeliveryStatusHiddenImplCopyWith(
    _$DeliveryStatusHiddenImpl value,
    $Res Function(_$DeliveryStatusHiddenImpl) then,
  ) = __$$DeliveryStatusHiddenImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DeliveryStatusHiddenImplCopyWithImpl<$Res>
    extends _$DeliveryStatusStateCopyWithImpl<$Res, _$DeliveryStatusHiddenImpl>
    implements _$$DeliveryStatusHiddenImplCopyWith<$Res> {
  __$$DeliveryStatusHiddenImplCopyWithImpl(
    _$DeliveryStatusHiddenImpl _value,
    $Res Function(_$DeliveryStatusHiddenImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DeliveryStatusHiddenImpl implements DeliveryStatusHidden {
  const _$DeliveryStatusHiddenImpl();

  @override
  String toString() {
    return 'DeliveryStatusState.hidden()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryStatusHiddenImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(int orderId) loading,
    required TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )
    active,
    required TResult Function(int orderId, DeliveryEntity delivery) completed,
    required TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )
    failed,
    required TResult Function(int orderId, String message) error,
  }) {
    return hidden();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(int orderId)? loading,
    TResult? Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult? Function(int orderId, DeliveryEntity delivery)? completed,
    TResult? Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult? Function(int orderId, String message)? error,
  }) {
    return hidden?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(int orderId)? loading,
    TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult Function(int orderId, DeliveryEntity delivery)? completed,
    TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult Function(int orderId, String message)? error,
    required TResult orElse(),
  }) {
    if (hidden != null) {
      return hidden();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeliveryStatusHidden value) hidden,
    required TResult Function(DeliveryStatusLoading value) loading,
    required TResult Function(DeliveryStatusActive value) active,
    required TResult Function(DeliveryStatusCompleted value) completed,
    required TResult Function(DeliveryStatusFailed value) failed,
    required TResult Function(DeliveryStatusError value) error,
  }) {
    return hidden(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeliveryStatusHidden value)? hidden,
    TResult? Function(DeliveryStatusLoading value)? loading,
    TResult? Function(DeliveryStatusActive value)? active,
    TResult? Function(DeliveryStatusCompleted value)? completed,
    TResult? Function(DeliveryStatusFailed value)? failed,
    TResult? Function(DeliveryStatusError value)? error,
  }) {
    return hidden?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeliveryStatusHidden value)? hidden,
    TResult Function(DeliveryStatusLoading value)? loading,
    TResult Function(DeliveryStatusActive value)? active,
    TResult Function(DeliveryStatusCompleted value)? completed,
    TResult Function(DeliveryStatusFailed value)? failed,
    TResult Function(DeliveryStatusError value)? error,
    required TResult orElse(),
  }) {
    if (hidden != null) {
      return hidden(this);
    }
    return orElse();
  }
}

abstract class DeliveryStatusHidden implements DeliveryStatusState {
  const factory DeliveryStatusHidden() = _$DeliveryStatusHiddenImpl;
}

/// @nodoc
abstract class _$$DeliveryStatusLoadingImplCopyWith<$Res> {
  factory _$$DeliveryStatusLoadingImplCopyWith(
    _$DeliveryStatusLoadingImpl value,
    $Res Function(_$DeliveryStatusLoadingImpl) then,
  ) = __$$DeliveryStatusLoadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int orderId});
}

/// @nodoc
class __$$DeliveryStatusLoadingImplCopyWithImpl<$Res>
    extends _$DeliveryStatusStateCopyWithImpl<$Res, _$DeliveryStatusLoadingImpl>
    implements _$$DeliveryStatusLoadingImplCopyWith<$Res> {
  __$$DeliveryStatusLoadingImplCopyWithImpl(
    _$DeliveryStatusLoadingImpl _value,
    $Res Function(_$DeliveryStatusLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? orderId = null}) {
    return _then(
      _$DeliveryStatusLoadingImpl(
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$DeliveryStatusLoadingImpl implements DeliveryStatusLoading {
  const _$DeliveryStatusLoadingImpl({required this.orderId});

  @override
  final int orderId;

  @override
  String toString() {
    return 'DeliveryStatusState.loading(orderId: $orderId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryStatusLoadingImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, orderId);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryStatusLoadingImplCopyWith<_$DeliveryStatusLoadingImpl>
  get copyWith =>
      __$$DeliveryStatusLoadingImplCopyWithImpl<_$DeliveryStatusLoadingImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(int orderId) loading,
    required TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )
    active,
    required TResult Function(int orderId, DeliveryEntity delivery) completed,
    required TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )
    failed,
    required TResult Function(int orderId, String message) error,
  }) {
    return loading(orderId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(int orderId)? loading,
    TResult? Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult? Function(int orderId, DeliveryEntity delivery)? completed,
    TResult? Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult? Function(int orderId, String message)? error,
  }) {
    return loading?.call(orderId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(int orderId)? loading,
    TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult Function(int orderId, DeliveryEntity delivery)? completed,
    TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult Function(int orderId, String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(orderId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeliveryStatusHidden value) hidden,
    required TResult Function(DeliveryStatusLoading value) loading,
    required TResult Function(DeliveryStatusActive value) active,
    required TResult Function(DeliveryStatusCompleted value) completed,
    required TResult Function(DeliveryStatusFailed value) failed,
    required TResult Function(DeliveryStatusError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeliveryStatusHidden value)? hidden,
    TResult? Function(DeliveryStatusLoading value)? loading,
    TResult? Function(DeliveryStatusActive value)? active,
    TResult? Function(DeliveryStatusCompleted value)? completed,
    TResult? Function(DeliveryStatusFailed value)? failed,
    TResult? Function(DeliveryStatusError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeliveryStatusHidden value)? hidden,
    TResult Function(DeliveryStatusLoading value)? loading,
    TResult Function(DeliveryStatusActive value)? active,
    TResult Function(DeliveryStatusCompleted value)? completed,
    TResult Function(DeliveryStatusFailed value)? failed,
    TResult Function(DeliveryStatusError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class DeliveryStatusLoading implements DeliveryStatusState {
  const factory DeliveryStatusLoading({required final int orderId}) =
      _$DeliveryStatusLoadingImpl;

  int get orderId;

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryStatusLoadingImplCopyWith<_$DeliveryStatusLoadingImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeliveryStatusActiveImplCopyWith<$Res> {
  factory _$$DeliveryStatusActiveImplCopyWith(
    _$DeliveryStatusActiveImpl value,
    $Res Function(_$DeliveryStatusActiveImpl) then,
  ) = __$$DeliveryStatusActiveImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int orderId, DeliveryApiStatus status, DeliveryEntity delivery});

  $DeliveryEntityCopyWith<$Res> get delivery;
}

/// @nodoc
class __$$DeliveryStatusActiveImplCopyWithImpl<$Res>
    extends _$DeliveryStatusStateCopyWithImpl<$Res, _$DeliveryStatusActiveImpl>
    implements _$$DeliveryStatusActiveImplCopyWith<$Res> {
  __$$DeliveryStatusActiveImplCopyWithImpl(
    _$DeliveryStatusActiveImpl _value,
    $Res Function(_$DeliveryStatusActiveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? status = null,
    Object? delivery = null,
  }) {
    return _then(
      _$DeliveryStatusActiveImpl(
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DeliveryApiStatus,
        delivery: null == delivery
            ? _value.delivery
            : delivery // ignore: cast_nullable_to_non_nullable
                  as DeliveryEntity,
      ),
    );
  }

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DeliveryEntityCopyWith<$Res> get delivery {
    return $DeliveryEntityCopyWith<$Res>(_value.delivery, (value) {
      return _then(_value.copyWith(delivery: value));
    });
  }
}

/// @nodoc

class _$DeliveryStatusActiveImpl implements DeliveryStatusActive {
  const _$DeliveryStatusActiveImpl({
    required this.orderId,
    required this.status,
    required this.delivery,
  });

  @override
  final int orderId;
  @override
  final DeliveryApiStatus status;
  @override
  final DeliveryEntity delivery;

  @override
  String toString() {
    return 'DeliveryStatusState.active(orderId: $orderId, status: $status, delivery: $delivery)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryStatusActiveImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.delivery, delivery) ||
                other.delivery == delivery));
  }

  @override
  int get hashCode => Object.hash(runtimeType, orderId, status, delivery);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryStatusActiveImplCopyWith<_$DeliveryStatusActiveImpl>
  get copyWith =>
      __$$DeliveryStatusActiveImplCopyWithImpl<_$DeliveryStatusActiveImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(int orderId) loading,
    required TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )
    active,
    required TResult Function(int orderId, DeliveryEntity delivery) completed,
    required TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )
    failed,
    required TResult Function(int orderId, String message) error,
  }) {
    return active(orderId, status, delivery);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(int orderId)? loading,
    TResult? Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult? Function(int orderId, DeliveryEntity delivery)? completed,
    TResult? Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult? Function(int orderId, String message)? error,
  }) {
    return active?.call(orderId, status, delivery);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(int orderId)? loading,
    TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult Function(int orderId, DeliveryEntity delivery)? completed,
    TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult Function(int orderId, String message)? error,
    required TResult orElse(),
  }) {
    if (active != null) {
      return active(orderId, status, delivery);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeliveryStatusHidden value) hidden,
    required TResult Function(DeliveryStatusLoading value) loading,
    required TResult Function(DeliveryStatusActive value) active,
    required TResult Function(DeliveryStatusCompleted value) completed,
    required TResult Function(DeliveryStatusFailed value) failed,
    required TResult Function(DeliveryStatusError value) error,
  }) {
    return active(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeliveryStatusHidden value)? hidden,
    TResult? Function(DeliveryStatusLoading value)? loading,
    TResult? Function(DeliveryStatusActive value)? active,
    TResult? Function(DeliveryStatusCompleted value)? completed,
    TResult? Function(DeliveryStatusFailed value)? failed,
    TResult? Function(DeliveryStatusError value)? error,
  }) {
    return active?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeliveryStatusHidden value)? hidden,
    TResult Function(DeliveryStatusLoading value)? loading,
    TResult Function(DeliveryStatusActive value)? active,
    TResult Function(DeliveryStatusCompleted value)? completed,
    TResult Function(DeliveryStatusFailed value)? failed,
    TResult Function(DeliveryStatusError value)? error,
    required TResult orElse(),
  }) {
    if (active != null) {
      return active(this);
    }
    return orElse();
  }
}

abstract class DeliveryStatusActive implements DeliveryStatusState {
  const factory DeliveryStatusActive({
    required final int orderId,
    required final DeliveryApiStatus status,
    required final DeliveryEntity delivery,
  }) = _$DeliveryStatusActiveImpl;

  int get orderId;
  DeliveryApiStatus get status;
  DeliveryEntity get delivery;

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryStatusActiveImplCopyWith<_$DeliveryStatusActiveImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeliveryStatusCompletedImplCopyWith<$Res> {
  factory _$$DeliveryStatusCompletedImplCopyWith(
    _$DeliveryStatusCompletedImpl value,
    $Res Function(_$DeliveryStatusCompletedImpl) then,
  ) = __$$DeliveryStatusCompletedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int orderId, DeliveryEntity delivery});

  $DeliveryEntityCopyWith<$Res> get delivery;
}

/// @nodoc
class __$$DeliveryStatusCompletedImplCopyWithImpl<$Res>
    extends
        _$DeliveryStatusStateCopyWithImpl<$Res, _$DeliveryStatusCompletedImpl>
    implements _$$DeliveryStatusCompletedImplCopyWith<$Res> {
  __$$DeliveryStatusCompletedImplCopyWithImpl(
    _$DeliveryStatusCompletedImpl _value,
    $Res Function(_$DeliveryStatusCompletedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? orderId = null, Object? delivery = null}) {
    return _then(
      _$DeliveryStatusCompletedImpl(
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as int,
        delivery: null == delivery
            ? _value.delivery
            : delivery // ignore: cast_nullable_to_non_nullable
                  as DeliveryEntity,
      ),
    );
  }

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DeliveryEntityCopyWith<$Res> get delivery {
    return $DeliveryEntityCopyWith<$Res>(_value.delivery, (value) {
      return _then(_value.copyWith(delivery: value));
    });
  }
}

/// @nodoc

class _$DeliveryStatusCompletedImpl implements DeliveryStatusCompleted {
  const _$DeliveryStatusCompletedImpl({
    required this.orderId,
    required this.delivery,
  });

  @override
  final int orderId;
  @override
  final DeliveryEntity delivery;

  @override
  String toString() {
    return 'DeliveryStatusState.completed(orderId: $orderId, delivery: $delivery)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryStatusCompletedImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.delivery, delivery) ||
                other.delivery == delivery));
  }

  @override
  int get hashCode => Object.hash(runtimeType, orderId, delivery);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryStatusCompletedImplCopyWith<_$DeliveryStatusCompletedImpl>
  get copyWith =>
      __$$DeliveryStatusCompletedImplCopyWithImpl<
        _$DeliveryStatusCompletedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(int orderId) loading,
    required TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )
    active,
    required TResult Function(int orderId, DeliveryEntity delivery) completed,
    required TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )
    failed,
    required TResult Function(int orderId, String message) error,
  }) {
    return completed(orderId, delivery);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(int orderId)? loading,
    TResult? Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult? Function(int orderId, DeliveryEntity delivery)? completed,
    TResult? Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult? Function(int orderId, String message)? error,
  }) {
    return completed?.call(orderId, delivery);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(int orderId)? loading,
    TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult Function(int orderId, DeliveryEntity delivery)? completed,
    TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult Function(int orderId, String message)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(orderId, delivery);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeliveryStatusHidden value) hidden,
    required TResult Function(DeliveryStatusLoading value) loading,
    required TResult Function(DeliveryStatusActive value) active,
    required TResult Function(DeliveryStatusCompleted value) completed,
    required TResult Function(DeliveryStatusFailed value) failed,
    required TResult Function(DeliveryStatusError value) error,
  }) {
    return completed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeliveryStatusHidden value)? hidden,
    TResult? Function(DeliveryStatusLoading value)? loading,
    TResult? Function(DeliveryStatusActive value)? active,
    TResult? Function(DeliveryStatusCompleted value)? completed,
    TResult? Function(DeliveryStatusFailed value)? failed,
    TResult? Function(DeliveryStatusError value)? error,
  }) {
    return completed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeliveryStatusHidden value)? hidden,
    TResult Function(DeliveryStatusLoading value)? loading,
    TResult Function(DeliveryStatusActive value)? active,
    TResult Function(DeliveryStatusCompleted value)? completed,
    TResult Function(DeliveryStatusFailed value)? failed,
    TResult Function(DeliveryStatusError value)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(this);
    }
    return orElse();
  }
}

abstract class DeliveryStatusCompleted implements DeliveryStatusState {
  const factory DeliveryStatusCompleted({
    required final int orderId,
    required final DeliveryEntity delivery,
  }) = _$DeliveryStatusCompletedImpl;

  int get orderId;
  DeliveryEntity get delivery;

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryStatusCompletedImplCopyWith<_$DeliveryStatusCompletedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeliveryStatusFailedImplCopyWith<$Res> {
  factory _$$DeliveryStatusFailedImplCopyWith(
    _$DeliveryStatusFailedImpl value,
    $Res Function(_$DeliveryStatusFailedImpl) then,
  ) = __$$DeliveryStatusFailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int orderId, DeliveryEntity delivery, String? failureReason});

  $DeliveryEntityCopyWith<$Res> get delivery;
}

/// @nodoc
class __$$DeliveryStatusFailedImplCopyWithImpl<$Res>
    extends _$DeliveryStatusStateCopyWithImpl<$Res, _$DeliveryStatusFailedImpl>
    implements _$$DeliveryStatusFailedImplCopyWith<$Res> {
  __$$DeliveryStatusFailedImplCopyWithImpl(
    _$DeliveryStatusFailedImpl _value,
    $Res Function(_$DeliveryStatusFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? delivery = null,
    Object? failureReason = freezed,
  }) {
    return _then(
      _$DeliveryStatusFailedImpl(
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as int,
        delivery: null == delivery
            ? _value.delivery
            : delivery // ignore: cast_nullable_to_non_nullable
                  as DeliveryEntity,
        failureReason: freezed == failureReason
            ? _value.failureReason
            : failureReason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DeliveryEntityCopyWith<$Res> get delivery {
    return $DeliveryEntityCopyWith<$Res>(_value.delivery, (value) {
      return _then(_value.copyWith(delivery: value));
    });
  }
}

/// @nodoc

class _$DeliveryStatusFailedImpl implements DeliveryStatusFailed {
  const _$DeliveryStatusFailedImpl({
    required this.orderId,
    required this.delivery,
    this.failureReason,
  });

  @override
  final int orderId;
  @override
  final DeliveryEntity delivery;
  @override
  final String? failureReason;

  @override
  String toString() {
    return 'DeliveryStatusState.failed(orderId: $orderId, delivery: $delivery, failureReason: $failureReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryStatusFailedImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.delivery, delivery) ||
                other.delivery == delivery) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, orderId, delivery, failureReason);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryStatusFailedImplCopyWith<_$DeliveryStatusFailedImpl>
  get copyWith =>
      __$$DeliveryStatusFailedImplCopyWithImpl<_$DeliveryStatusFailedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(int orderId) loading,
    required TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )
    active,
    required TResult Function(int orderId, DeliveryEntity delivery) completed,
    required TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )
    failed,
    required TResult Function(int orderId, String message) error,
  }) {
    return failed(orderId, delivery, failureReason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(int orderId)? loading,
    TResult? Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult? Function(int orderId, DeliveryEntity delivery)? completed,
    TResult? Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult? Function(int orderId, String message)? error,
  }) {
    return failed?.call(orderId, delivery, failureReason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(int orderId)? loading,
    TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult Function(int orderId, DeliveryEntity delivery)? completed,
    TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult Function(int orderId, String message)? error,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(orderId, delivery, failureReason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeliveryStatusHidden value) hidden,
    required TResult Function(DeliveryStatusLoading value) loading,
    required TResult Function(DeliveryStatusActive value) active,
    required TResult Function(DeliveryStatusCompleted value) completed,
    required TResult Function(DeliveryStatusFailed value) failed,
    required TResult Function(DeliveryStatusError value) error,
  }) {
    return failed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeliveryStatusHidden value)? hidden,
    TResult? Function(DeliveryStatusLoading value)? loading,
    TResult? Function(DeliveryStatusActive value)? active,
    TResult? Function(DeliveryStatusCompleted value)? completed,
    TResult? Function(DeliveryStatusFailed value)? failed,
    TResult? Function(DeliveryStatusError value)? error,
  }) {
    return failed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeliveryStatusHidden value)? hidden,
    TResult Function(DeliveryStatusLoading value)? loading,
    TResult Function(DeliveryStatusActive value)? active,
    TResult Function(DeliveryStatusCompleted value)? completed,
    TResult Function(DeliveryStatusFailed value)? failed,
    TResult Function(DeliveryStatusError value)? error,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(this);
    }
    return orElse();
  }
}

abstract class DeliveryStatusFailed implements DeliveryStatusState {
  const factory DeliveryStatusFailed({
    required final int orderId,
    required final DeliveryEntity delivery,
    final String? failureReason,
  }) = _$DeliveryStatusFailedImpl;

  int get orderId;
  DeliveryEntity get delivery;
  String? get failureReason;

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryStatusFailedImplCopyWith<_$DeliveryStatusFailedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeliveryStatusErrorImplCopyWith<$Res> {
  factory _$$DeliveryStatusErrorImplCopyWith(
    _$DeliveryStatusErrorImpl value,
    $Res Function(_$DeliveryStatusErrorImpl) then,
  ) = __$$DeliveryStatusErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int orderId, String message});
}

/// @nodoc
class __$$DeliveryStatusErrorImplCopyWithImpl<$Res>
    extends _$DeliveryStatusStateCopyWithImpl<$Res, _$DeliveryStatusErrorImpl>
    implements _$$DeliveryStatusErrorImplCopyWith<$Res> {
  __$$DeliveryStatusErrorImplCopyWithImpl(
    _$DeliveryStatusErrorImpl _value,
    $Res Function(_$DeliveryStatusErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? orderId = null, Object? message = null}) {
    return _then(
      _$DeliveryStatusErrorImpl(
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as int,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$DeliveryStatusErrorImpl implements DeliveryStatusError {
  const _$DeliveryStatusErrorImpl({
    required this.orderId,
    required this.message,
  });

  @override
  final int orderId;
  @override
  final String message;

  @override
  String toString() {
    return 'DeliveryStatusState.error(orderId: $orderId, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryStatusErrorImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, orderId, message);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryStatusErrorImplCopyWith<_$DeliveryStatusErrorImpl> get copyWith =>
      __$$DeliveryStatusErrorImplCopyWithImpl<_$DeliveryStatusErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(int orderId) loading,
    required TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )
    active,
    required TResult Function(int orderId, DeliveryEntity delivery) completed,
    required TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )
    failed,
    required TResult Function(int orderId, String message) error,
  }) {
    return error(orderId, message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(int orderId)? loading,
    TResult? Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult? Function(int orderId, DeliveryEntity delivery)? completed,
    TResult? Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult? Function(int orderId, String message)? error,
  }) {
    return error?.call(orderId, message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(int orderId)? loading,
    TResult Function(
      int orderId,
      DeliveryApiStatus status,
      DeliveryEntity delivery,
    )?
    active,
    TResult Function(int orderId, DeliveryEntity delivery)? completed,
    TResult Function(
      int orderId,
      DeliveryEntity delivery,
      String? failureReason,
    )?
    failed,
    TResult Function(int orderId, String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(orderId, message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DeliveryStatusHidden value) hidden,
    required TResult Function(DeliveryStatusLoading value) loading,
    required TResult Function(DeliveryStatusActive value) active,
    required TResult Function(DeliveryStatusCompleted value) completed,
    required TResult Function(DeliveryStatusFailed value) failed,
    required TResult Function(DeliveryStatusError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DeliveryStatusHidden value)? hidden,
    TResult? Function(DeliveryStatusLoading value)? loading,
    TResult? Function(DeliveryStatusActive value)? active,
    TResult? Function(DeliveryStatusCompleted value)? completed,
    TResult? Function(DeliveryStatusFailed value)? failed,
    TResult? Function(DeliveryStatusError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DeliveryStatusHidden value)? hidden,
    TResult Function(DeliveryStatusLoading value)? loading,
    TResult Function(DeliveryStatusActive value)? active,
    TResult Function(DeliveryStatusCompleted value)? completed,
    TResult Function(DeliveryStatusFailed value)? failed,
    TResult Function(DeliveryStatusError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class DeliveryStatusError implements DeliveryStatusState {
  const factory DeliveryStatusError({
    required final int orderId,
    required final String message,
  }) = _$DeliveryStatusErrorImpl;

  int get orderId;
  String get message;

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryStatusErrorImplCopyWith<_$DeliveryStatusErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
