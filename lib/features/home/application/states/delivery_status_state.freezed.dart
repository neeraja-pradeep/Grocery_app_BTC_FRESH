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
    required TResult Function(
      DeliveryStage stage,
      DateTime startedAt,
      String orderId,
    )
    active,
    required TResult Function(String orderId) completed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(DeliveryStage stage, DateTime startedAt, String orderId)?
    active,
    TResult? Function(String orderId)? completed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(DeliveryStage stage, DateTime startedAt, String orderId)?
    active,
    TResult Function(String orderId)? completed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Hidden value) hidden,
    required TResult Function(_Active value) active,
    required TResult Function(_Completed value) completed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Hidden value)? hidden,
    TResult? Function(_Active value)? active,
    TResult? Function(_Completed value)? completed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Hidden value)? hidden,
    TResult Function(_Active value)? active,
    TResult Function(_Completed value)? completed,
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
abstract class _$$HiddenImplCopyWith<$Res> {
  factory _$$HiddenImplCopyWith(
    _$HiddenImpl value,
    $Res Function(_$HiddenImpl) then,
  ) = __$$HiddenImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$HiddenImplCopyWithImpl<$Res>
    extends _$DeliveryStatusStateCopyWithImpl<$Res, _$HiddenImpl>
    implements _$$HiddenImplCopyWith<$Res> {
  __$$HiddenImplCopyWithImpl(
    _$HiddenImpl _value,
    $Res Function(_$HiddenImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$HiddenImpl implements _Hidden {
  const _$HiddenImpl();

  @override
  String toString() {
    return 'DeliveryStatusState.hidden()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$HiddenImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(
      DeliveryStage stage,
      DateTime startedAt,
      String orderId,
    )
    active,
    required TResult Function(String orderId) completed,
  }) {
    return hidden();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(DeliveryStage stage, DateTime startedAt, String orderId)?
    active,
    TResult? Function(String orderId)? completed,
  }) {
    return hidden?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(DeliveryStage stage, DateTime startedAt, String orderId)?
    active,
    TResult Function(String orderId)? completed,
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
    required TResult Function(_Hidden value) hidden,
    required TResult Function(_Active value) active,
    required TResult Function(_Completed value) completed,
  }) {
    return hidden(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Hidden value)? hidden,
    TResult? Function(_Active value)? active,
    TResult? Function(_Completed value)? completed,
  }) {
    return hidden?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Hidden value)? hidden,
    TResult Function(_Active value)? active,
    TResult Function(_Completed value)? completed,
    required TResult orElse(),
  }) {
    if (hidden != null) {
      return hidden(this);
    }
    return orElse();
  }
}

abstract class _Hidden implements DeliveryStatusState {
  const factory _Hidden() = _$HiddenImpl;
}

/// @nodoc
abstract class _$$ActiveImplCopyWith<$Res> {
  factory _$$ActiveImplCopyWith(
    _$ActiveImpl value,
    $Res Function(_$ActiveImpl) then,
  ) = __$$ActiveImplCopyWithImpl<$Res>;
  @useResult
  $Res call({DeliveryStage stage, DateTime startedAt, String orderId});
}

/// @nodoc
class __$$ActiveImplCopyWithImpl<$Res>
    extends _$DeliveryStatusStateCopyWithImpl<$Res, _$ActiveImpl>
    implements _$$ActiveImplCopyWith<$Res> {
  __$$ActiveImplCopyWithImpl(
    _$ActiveImpl _value,
    $Res Function(_$ActiveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stage = null,
    Object? startedAt = null,
    Object? orderId = null,
  }) {
    return _then(
      _$ActiveImpl(
        stage: null == stage
            ? _value.stage
            : stage // ignore: cast_nullable_to_non_nullable
                  as DeliveryStage,
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ActiveImpl implements _Active {
  const _$ActiveImpl({
    required this.stage,
    required this.startedAt,
    required this.orderId,
  });

  @override
  final DeliveryStage stage;
  @override
  final DateTime startedAt;
  @override
  final String orderId;

  @override
  String toString() {
    return 'DeliveryStatusState.active(stage: $stage, startedAt: $startedAt, orderId: $orderId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActiveImpl &&
            (identical(other.stage, stage) || other.stage == stage) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.orderId, orderId) || other.orderId == orderId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, stage, startedAt, orderId);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActiveImplCopyWith<_$ActiveImpl> get copyWith =>
      __$$ActiveImplCopyWithImpl<_$ActiveImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(
      DeliveryStage stage,
      DateTime startedAt,
      String orderId,
    )
    active,
    required TResult Function(String orderId) completed,
  }) {
    return active(stage, startedAt, orderId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(DeliveryStage stage, DateTime startedAt, String orderId)?
    active,
    TResult? Function(String orderId)? completed,
  }) {
    return active?.call(stage, startedAt, orderId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(DeliveryStage stage, DateTime startedAt, String orderId)?
    active,
    TResult Function(String orderId)? completed,
    required TResult orElse(),
  }) {
    if (active != null) {
      return active(stage, startedAt, orderId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Hidden value) hidden,
    required TResult Function(_Active value) active,
    required TResult Function(_Completed value) completed,
  }) {
    return active(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Hidden value)? hidden,
    TResult? Function(_Active value)? active,
    TResult? Function(_Completed value)? completed,
  }) {
    return active?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Hidden value)? hidden,
    TResult Function(_Active value)? active,
    TResult Function(_Completed value)? completed,
    required TResult orElse(),
  }) {
    if (active != null) {
      return active(this);
    }
    return orElse();
  }
}

abstract class _Active implements DeliveryStatusState {
  const factory _Active({
    required final DeliveryStage stage,
    required final DateTime startedAt,
    required final String orderId,
  }) = _$ActiveImpl;

  DeliveryStage get stage;
  DateTime get startedAt;
  String get orderId;

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActiveImplCopyWith<_$ActiveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompletedImplCopyWith<$Res> {
  factory _$$CompletedImplCopyWith(
    _$CompletedImpl value,
    $Res Function(_$CompletedImpl) then,
  ) = __$$CompletedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String orderId});
}

/// @nodoc
class __$$CompletedImplCopyWithImpl<$Res>
    extends _$DeliveryStatusStateCopyWithImpl<$Res, _$CompletedImpl>
    implements _$$CompletedImplCopyWith<$Res> {
  __$$CompletedImplCopyWithImpl(
    _$CompletedImpl _value,
    $Res Function(_$CompletedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? orderId = null}) {
    return _then(
      _$CompletedImpl(
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$CompletedImpl implements _Completed {
  const _$CompletedImpl({required this.orderId});

  @override
  final String orderId;

  @override
  String toString() {
    return 'DeliveryStatusState.completed(orderId: $orderId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompletedImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, orderId);

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompletedImplCopyWith<_$CompletedImpl> get copyWith =>
      __$$CompletedImplCopyWithImpl<_$CompletedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() hidden,
    required TResult Function(
      DeliveryStage stage,
      DateTime startedAt,
      String orderId,
    )
    active,
    required TResult Function(String orderId) completed,
  }) {
    return completed(orderId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? hidden,
    TResult? Function(DeliveryStage stage, DateTime startedAt, String orderId)?
    active,
    TResult? Function(String orderId)? completed,
  }) {
    return completed?.call(orderId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? hidden,
    TResult Function(DeliveryStage stage, DateTime startedAt, String orderId)?
    active,
    TResult Function(String orderId)? completed,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(orderId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Hidden value) hidden,
    required TResult Function(_Active value) active,
    required TResult Function(_Completed value) completed,
  }) {
    return completed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Hidden value)? hidden,
    TResult? Function(_Active value)? active,
    TResult? Function(_Completed value)? completed,
  }) {
    return completed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Hidden value)? hidden,
    TResult Function(_Active value)? active,
    TResult Function(_Completed value)? completed,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(this);
    }
    return orElse();
  }
}

abstract class _Completed implements DeliveryStatusState {
  const factory _Completed({required final String orderId}) = _$CompletedImpl;

  String get orderId;

  /// Create a copy of DeliveryStatusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompletedImplCopyWith<_$CompletedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
