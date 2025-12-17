// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voice_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$VoiceSearchState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() initializing,
    required TResult Function(String partialText, double soundLevel) listening,
    required TResult Function(String recognizedText) processing,
    required TResult Function(String recognizedText) completed,
    required TResult Function() notAvailable,
    required TResult Function() permissionDenied,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? initializing,
    TResult? Function(String partialText, double soundLevel)? listening,
    TResult? Function(String recognizedText)? processing,
    TResult? Function(String recognizedText)? completed,
    TResult? Function()? notAvailable,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? initializing,
    TResult Function(String partialText, double soundLevel)? listening,
    TResult Function(String recognizedText)? processing,
    TResult Function(String recognizedText)? completed,
    TResult Function()? notAvailable,
    TResult Function()? permissionDenied,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VoiceSearchIdle value) idle,
    required TResult Function(VoiceSearchInitializing value) initializing,
    required TResult Function(VoiceSearchListening value) listening,
    required TResult Function(VoiceSearchProcessing value) processing,
    required TResult Function(VoiceSearchCompleted value) completed,
    required TResult Function(VoiceSearchNotAvailable value) notAvailable,
    required TResult Function(VoiceSearchPermissionDenied value)
    permissionDenied,
    required TResult Function(VoiceSearchError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VoiceSearchIdle value)? idle,
    TResult? Function(VoiceSearchInitializing value)? initializing,
    TResult? Function(VoiceSearchListening value)? listening,
    TResult? Function(VoiceSearchProcessing value)? processing,
    TResult? Function(VoiceSearchCompleted value)? completed,
    TResult? Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult? Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult? Function(VoiceSearchError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VoiceSearchIdle value)? idle,
    TResult Function(VoiceSearchInitializing value)? initializing,
    TResult Function(VoiceSearchListening value)? listening,
    TResult Function(VoiceSearchProcessing value)? processing,
    TResult Function(VoiceSearchCompleted value)? completed,
    TResult Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult Function(VoiceSearchError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoiceSearchStateCopyWith<$Res> {
  factory $VoiceSearchStateCopyWith(
    VoiceSearchState value,
    $Res Function(VoiceSearchState) then,
  ) = _$VoiceSearchStateCopyWithImpl<$Res, VoiceSearchState>;
}

/// @nodoc
class _$VoiceSearchStateCopyWithImpl<$Res, $Val extends VoiceSearchState>
    implements $VoiceSearchStateCopyWith<$Res> {
  _$VoiceSearchStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$VoiceSearchIdleImplCopyWith<$Res> {
  factory _$$VoiceSearchIdleImplCopyWith(
    _$VoiceSearchIdleImpl value,
    $Res Function(_$VoiceSearchIdleImpl) then,
  ) = __$$VoiceSearchIdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VoiceSearchIdleImplCopyWithImpl<$Res>
    extends _$VoiceSearchStateCopyWithImpl<$Res, _$VoiceSearchIdleImpl>
    implements _$$VoiceSearchIdleImplCopyWith<$Res> {
  __$$VoiceSearchIdleImplCopyWithImpl(
    _$VoiceSearchIdleImpl _value,
    $Res Function(_$VoiceSearchIdleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VoiceSearchIdleImpl implements VoiceSearchIdle {
  const _$VoiceSearchIdleImpl();

  @override
  String toString() {
    return 'VoiceSearchState.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$VoiceSearchIdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() initializing,
    required TResult Function(String partialText, double soundLevel) listening,
    required TResult Function(String recognizedText) processing,
    required TResult Function(String recognizedText) completed,
    required TResult Function() notAvailable,
    required TResult Function() permissionDenied,
    required TResult Function(String message) error,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? initializing,
    TResult? Function(String partialText, double soundLevel)? listening,
    TResult? Function(String recognizedText)? processing,
    TResult? Function(String recognizedText)? completed,
    TResult? Function()? notAvailable,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? error,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? initializing,
    TResult Function(String partialText, double soundLevel)? listening,
    TResult Function(String recognizedText)? processing,
    TResult Function(String recognizedText)? completed,
    TResult Function()? notAvailable,
    TResult Function()? permissionDenied,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VoiceSearchIdle value) idle,
    required TResult Function(VoiceSearchInitializing value) initializing,
    required TResult Function(VoiceSearchListening value) listening,
    required TResult Function(VoiceSearchProcessing value) processing,
    required TResult Function(VoiceSearchCompleted value) completed,
    required TResult Function(VoiceSearchNotAvailable value) notAvailable,
    required TResult Function(VoiceSearchPermissionDenied value)
    permissionDenied,
    required TResult Function(VoiceSearchError value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VoiceSearchIdle value)? idle,
    TResult? Function(VoiceSearchInitializing value)? initializing,
    TResult? Function(VoiceSearchListening value)? listening,
    TResult? Function(VoiceSearchProcessing value)? processing,
    TResult? Function(VoiceSearchCompleted value)? completed,
    TResult? Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult? Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult? Function(VoiceSearchError value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VoiceSearchIdle value)? idle,
    TResult Function(VoiceSearchInitializing value)? initializing,
    TResult Function(VoiceSearchListening value)? listening,
    TResult Function(VoiceSearchProcessing value)? processing,
    TResult Function(VoiceSearchCompleted value)? completed,
    TResult Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult Function(VoiceSearchError value)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class VoiceSearchIdle implements VoiceSearchState {
  const factory VoiceSearchIdle() = _$VoiceSearchIdleImpl;
}

/// @nodoc
abstract class _$$VoiceSearchInitializingImplCopyWith<$Res> {
  factory _$$VoiceSearchInitializingImplCopyWith(
    _$VoiceSearchInitializingImpl value,
    $Res Function(_$VoiceSearchInitializingImpl) then,
  ) = __$$VoiceSearchInitializingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VoiceSearchInitializingImplCopyWithImpl<$Res>
    extends _$VoiceSearchStateCopyWithImpl<$Res, _$VoiceSearchInitializingImpl>
    implements _$$VoiceSearchInitializingImplCopyWith<$Res> {
  __$$VoiceSearchInitializingImplCopyWithImpl(
    _$VoiceSearchInitializingImpl _value,
    $Res Function(_$VoiceSearchInitializingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VoiceSearchInitializingImpl implements VoiceSearchInitializing {
  const _$VoiceSearchInitializingImpl();

  @override
  String toString() {
    return 'VoiceSearchState.initializing()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoiceSearchInitializingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() initializing,
    required TResult Function(String partialText, double soundLevel) listening,
    required TResult Function(String recognizedText) processing,
    required TResult Function(String recognizedText) completed,
    required TResult Function() notAvailable,
    required TResult Function() permissionDenied,
    required TResult Function(String message) error,
  }) {
    return initializing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? initializing,
    TResult? Function(String partialText, double soundLevel)? listening,
    TResult? Function(String recognizedText)? processing,
    TResult? Function(String recognizedText)? completed,
    TResult? Function()? notAvailable,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? error,
  }) {
    return initializing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? initializing,
    TResult Function(String partialText, double soundLevel)? listening,
    TResult Function(String recognizedText)? processing,
    TResult Function(String recognizedText)? completed,
    TResult Function()? notAvailable,
    TResult Function()? permissionDenied,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initializing != null) {
      return initializing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VoiceSearchIdle value) idle,
    required TResult Function(VoiceSearchInitializing value) initializing,
    required TResult Function(VoiceSearchListening value) listening,
    required TResult Function(VoiceSearchProcessing value) processing,
    required TResult Function(VoiceSearchCompleted value) completed,
    required TResult Function(VoiceSearchNotAvailable value) notAvailable,
    required TResult Function(VoiceSearchPermissionDenied value)
    permissionDenied,
    required TResult Function(VoiceSearchError value) error,
  }) {
    return initializing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VoiceSearchIdle value)? idle,
    TResult? Function(VoiceSearchInitializing value)? initializing,
    TResult? Function(VoiceSearchListening value)? listening,
    TResult? Function(VoiceSearchProcessing value)? processing,
    TResult? Function(VoiceSearchCompleted value)? completed,
    TResult? Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult? Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult? Function(VoiceSearchError value)? error,
  }) {
    return initializing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VoiceSearchIdle value)? idle,
    TResult Function(VoiceSearchInitializing value)? initializing,
    TResult Function(VoiceSearchListening value)? listening,
    TResult Function(VoiceSearchProcessing value)? processing,
    TResult Function(VoiceSearchCompleted value)? completed,
    TResult Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult Function(VoiceSearchError value)? error,
    required TResult orElse(),
  }) {
    if (initializing != null) {
      return initializing(this);
    }
    return orElse();
  }
}

abstract class VoiceSearchInitializing implements VoiceSearchState {
  const factory VoiceSearchInitializing() = _$VoiceSearchInitializingImpl;
}

/// @nodoc
abstract class _$$VoiceSearchListeningImplCopyWith<$Res> {
  factory _$$VoiceSearchListeningImplCopyWith(
    _$VoiceSearchListeningImpl value,
    $Res Function(_$VoiceSearchListeningImpl) then,
  ) = __$$VoiceSearchListeningImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String partialText, double soundLevel});
}

/// @nodoc
class __$$VoiceSearchListeningImplCopyWithImpl<$Res>
    extends _$VoiceSearchStateCopyWithImpl<$Res, _$VoiceSearchListeningImpl>
    implements _$$VoiceSearchListeningImplCopyWith<$Res> {
  __$$VoiceSearchListeningImplCopyWithImpl(
    _$VoiceSearchListeningImpl _value,
    $Res Function(_$VoiceSearchListeningImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? partialText = null, Object? soundLevel = null}) {
    return _then(
      _$VoiceSearchListeningImpl(
        partialText: null == partialText
            ? _value.partialText
            : partialText // ignore: cast_nullable_to_non_nullable
                  as String,
        soundLevel: null == soundLevel
            ? _value.soundLevel
            : soundLevel // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$VoiceSearchListeningImpl implements VoiceSearchListening {
  const _$VoiceSearchListeningImpl({
    this.partialText = '',
    this.soundLevel = 0.0,
  });

  @override
  @JsonKey()
  final String partialText;
  @override
  @JsonKey()
  final double soundLevel;

  @override
  String toString() {
    return 'VoiceSearchState.listening(partialText: $partialText, soundLevel: $soundLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoiceSearchListeningImpl &&
            (identical(other.partialText, partialText) ||
                other.partialText == partialText) &&
            (identical(other.soundLevel, soundLevel) ||
                other.soundLevel == soundLevel));
  }

  @override
  int get hashCode => Object.hash(runtimeType, partialText, soundLevel);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoiceSearchListeningImplCopyWith<_$VoiceSearchListeningImpl>
  get copyWith =>
      __$$VoiceSearchListeningImplCopyWithImpl<_$VoiceSearchListeningImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() initializing,
    required TResult Function(String partialText, double soundLevel) listening,
    required TResult Function(String recognizedText) processing,
    required TResult Function(String recognizedText) completed,
    required TResult Function() notAvailable,
    required TResult Function() permissionDenied,
    required TResult Function(String message) error,
  }) {
    return listening(partialText, soundLevel);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? initializing,
    TResult? Function(String partialText, double soundLevel)? listening,
    TResult? Function(String recognizedText)? processing,
    TResult? Function(String recognizedText)? completed,
    TResult? Function()? notAvailable,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? error,
  }) {
    return listening?.call(partialText, soundLevel);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? initializing,
    TResult Function(String partialText, double soundLevel)? listening,
    TResult Function(String recognizedText)? processing,
    TResult Function(String recognizedText)? completed,
    TResult Function()? notAvailable,
    TResult Function()? permissionDenied,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (listening != null) {
      return listening(partialText, soundLevel);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VoiceSearchIdle value) idle,
    required TResult Function(VoiceSearchInitializing value) initializing,
    required TResult Function(VoiceSearchListening value) listening,
    required TResult Function(VoiceSearchProcessing value) processing,
    required TResult Function(VoiceSearchCompleted value) completed,
    required TResult Function(VoiceSearchNotAvailable value) notAvailable,
    required TResult Function(VoiceSearchPermissionDenied value)
    permissionDenied,
    required TResult Function(VoiceSearchError value) error,
  }) {
    return listening(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VoiceSearchIdle value)? idle,
    TResult? Function(VoiceSearchInitializing value)? initializing,
    TResult? Function(VoiceSearchListening value)? listening,
    TResult? Function(VoiceSearchProcessing value)? processing,
    TResult? Function(VoiceSearchCompleted value)? completed,
    TResult? Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult? Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult? Function(VoiceSearchError value)? error,
  }) {
    return listening?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VoiceSearchIdle value)? idle,
    TResult Function(VoiceSearchInitializing value)? initializing,
    TResult Function(VoiceSearchListening value)? listening,
    TResult Function(VoiceSearchProcessing value)? processing,
    TResult Function(VoiceSearchCompleted value)? completed,
    TResult Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult Function(VoiceSearchError value)? error,
    required TResult orElse(),
  }) {
    if (listening != null) {
      return listening(this);
    }
    return orElse();
  }
}

abstract class VoiceSearchListening implements VoiceSearchState {
  const factory VoiceSearchListening({
    final String partialText,
    final double soundLevel,
  }) = _$VoiceSearchListeningImpl;

  String get partialText;
  double get soundLevel;

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoiceSearchListeningImplCopyWith<_$VoiceSearchListeningImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VoiceSearchProcessingImplCopyWith<$Res> {
  factory _$$VoiceSearchProcessingImplCopyWith(
    _$VoiceSearchProcessingImpl value,
    $Res Function(_$VoiceSearchProcessingImpl) then,
  ) = __$$VoiceSearchProcessingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String recognizedText});
}

/// @nodoc
class __$$VoiceSearchProcessingImplCopyWithImpl<$Res>
    extends _$VoiceSearchStateCopyWithImpl<$Res, _$VoiceSearchProcessingImpl>
    implements _$$VoiceSearchProcessingImplCopyWith<$Res> {
  __$$VoiceSearchProcessingImplCopyWithImpl(
    _$VoiceSearchProcessingImpl _value,
    $Res Function(_$VoiceSearchProcessingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? recognizedText = null}) {
    return _then(
      _$VoiceSearchProcessingImpl(
        recognizedText: null == recognizedText
            ? _value.recognizedText
            : recognizedText // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VoiceSearchProcessingImpl implements VoiceSearchProcessing {
  const _$VoiceSearchProcessingImpl({required this.recognizedText});

  @override
  final String recognizedText;

  @override
  String toString() {
    return 'VoiceSearchState.processing(recognizedText: $recognizedText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoiceSearchProcessingImpl &&
            (identical(other.recognizedText, recognizedText) ||
                other.recognizedText == recognizedText));
  }

  @override
  int get hashCode => Object.hash(runtimeType, recognizedText);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoiceSearchProcessingImplCopyWith<_$VoiceSearchProcessingImpl>
  get copyWith =>
      __$$VoiceSearchProcessingImplCopyWithImpl<_$VoiceSearchProcessingImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() initializing,
    required TResult Function(String partialText, double soundLevel) listening,
    required TResult Function(String recognizedText) processing,
    required TResult Function(String recognizedText) completed,
    required TResult Function() notAvailable,
    required TResult Function() permissionDenied,
    required TResult Function(String message) error,
  }) {
    return processing(recognizedText);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? initializing,
    TResult? Function(String partialText, double soundLevel)? listening,
    TResult? Function(String recognizedText)? processing,
    TResult? Function(String recognizedText)? completed,
    TResult? Function()? notAvailable,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? error,
  }) {
    return processing?.call(recognizedText);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? initializing,
    TResult Function(String partialText, double soundLevel)? listening,
    TResult Function(String recognizedText)? processing,
    TResult Function(String recognizedText)? completed,
    TResult Function()? notAvailable,
    TResult Function()? permissionDenied,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (processing != null) {
      return processing(recognizedText);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VoiceSearchIdle value) idle,
    required TResult Function(VoiceSearchInitializing value) initializing,
    required TResult Function(VoiceSearchListening value) listening,
    required TResult Function(VoiceSearchProcessing value) processing,
    required TResult Function(VoiceSearchCompleted value) completed,
    required TResult Function(VoiceSearchNotAvailable value) notAvailable,
    required TResult Function(VoiceSearchPermissionDenied value)
    permissionDenied,
    required TResult Function(VoiceSearchError value) error,
  }) {
    return processing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VoiceSearchIdle value)? idle,
    TResult? Function(VoiceSearchInitializing value)? initializing,
    TResult? Function(VoiceSearchListening value)? listening,
    TResult? Function(VoiceSearchProcessing value)? processing,
    TResult? Function(VoiceSearchCompleted value)? completed,
    TResult? Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult? Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult? Function(VoiceSearchError value)? error,
  }) {
    return processing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VoiceSearchIdle value)? idle,
    TResult Function(VoiceSearchInitializing value)? initializing,
    TResult Function(VoiceSearchListening value)? listening,
    TResult Function(VoiceSearchProcessing value)? processing,
    TResult Function(VoiceSearchCompleted value)? completed,
    TResult Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult Function(VoiceSearchError value)? error,
    required TResult orElse(),
  }) {
    if (processing != null) {
      return processing(this);
    }
    return orElse();
  }
}

abstract class VoiceSearchProcessing implements VoiceSearchState {
  const factory VoiceSearchProcessing({required final String recognizedText}) =
      _$VoiceSearchProcessingImpl;

  String get recognizedText;

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoiceSearchProcessingImplCopyWith<_$VoiceSearchProcessingImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VoiceSearchCompletedImplCopyWith<$Res> {
  factory _$$VoiceSearchCompletedImplCopyWith(
    _$VoiceSearchCompletedImpl value,
    $Res Function(_$VoiceSearchCompletedImpl) then,
  ) = __$$VoiceSearchCompletedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String recognizedText});
}

/// @nodoc
class __$$VoiceSearchCompletedImplCopyWithImpl<$Res>
    extends _$VoiceSearchStateCopyWithImpl<$Res, _$VoiceSearchCompletedImpl>
    implements _$$VoiceSearchCompletedImplCopyWith<$Res> {
  __$$VoiceSearchCompletedImplCopyWithImpl(
    _$VoiceSearchCompletedImpl _value,
    $Res Function(_$VoiceSearchCompletedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? recognizedText = null}) {
    return _then(
      _$VoiceSearchCompletedImpl(
        recognizedText: null == recognizedText
            ? _value.recognizedText
            : recognizedText // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VoiceSearchCompletedImpl implements VoiceSearchCompleted {
  const _$VoiceSearchCompletedImpl({required this.recognizedText});

  @override
  final String recognizedText;

  @override
  String toString() {
    return 'VoiceSearchState.completed(recognizedText: $recognizedText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoiceSearchCompletedImpl &&
            (identical(other.recognizedText, recognizedText) ||
                other.recognizedText == recognizedText));
  }

  @override
  int get hashCode => Object.hash(runtimeType, recognizedText);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoiceSearchCompletedImplCopyWith<_$VoiceSearchCompletedImpl>
  get copyWith =>
      __$$VoiceSearchCompletedImplCopyWithImpl<_$VoiceSearchCompletedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() initializing,
    required TResult Function(String partialText, double soundLevel) listening,
    required TResult Function(String recognizedText) processing,
    required TResult Function(String recognizedText) completed,
    required TResult Function() notAvailable,
    required TResult Function() permissionDenied,
    required TResult Function(String message) error,
  }) {
    return completed(recognizedText);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? initializing,
    TResult? Function(String partialText, double soundLevel)? listening,
    TResult? Function(String recognizedText)? processing,
    TResult? Function(String recognizedText)? completed,
    TResult? Function()? notAvailable,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? error,
  }) {
    return completed?.call(recognizedText);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? initializing,
    TResult Function(String partialText, double soundLevel)? listening,
    TResult Function(String recognizedText)? processing,
    TResult Function(String recognizedText)? completed,
    TResult Function()? notAvailable,
    TResult Function()? permissionDenied,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(recognizedText);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VoiceSearchIdle value) idle,
    required TResult Function(VoiceSearchInitializing value) initializing,
    required TResult Function(VoiceSearchListening value) listening,
    required TResult Function(VoiceSearchProcessing value) processing,
    required TResult Function(VoiceSearchCompleted value) completed,
    required TResult Function(VoiceSearchNotAvailable value) notAvailable,
    required TResult Function(VoiceSearchPermissionDenied value)
    permissionDenied,
    required TResult Function(VoiceSearchError value) error,
  }) {
    return completed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VoiceSearchIdle value)? idle,
    TResult? Function(VoiceSearchInitializing value)? initializing,
    TResult? Function(VoiceSearchListening value)? listening,
    TResult? Function(VoiceSearchProcessing value)? processing,
    TResult? Function(VoiceSearchCompleted value)? completed,
    TResult? Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult? Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult? Function(VoiceSearchError value)? error,
  }) {
    return completed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VoiceSearchIdle value)? idle,
    TResult Function(VoiceSearchInitializing value)? initializing,
    TResult Function(VoiceSearchListening value)? listening,
    TResult Function(VoiceSearchProcessing value)? processing,
    TResult Function(VoiceSearchCompleted value)? completed,
    TResult Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult Function(VoiceSearchError value)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(this);
    }
    return orElse();
  }
}

abstract class VoiceSearchCompleted implements VoiceSearchState {
  const factory VoiceSearchCompleted({required final String recognizedText}) =
      _$VoiceSearchCompletedImpl;

  String get recognizedText;

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoiceSearchCompletedImplCopyWith<_$VoiceSearchCompletedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VoiceSearchNotAvailableImplCopyWith<$Res> {
  factory _$$VoiceSearchNotAvailableImplCopyWith(
    _$VoiceSearchNotAvailableImpl value,
    $Res Function(_$VoiceSearchNotAvailableImpl) then,
  ) = __$$VoiceSearchNotAvailableImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VoiceSearchNotAvailableImplCopyWithImpl<$Res>
    extends _$VoiceSearchStateCopyWithImpl<$Res, _$VoiceSearchNotAvailableImpl>
    implements _$$VoiceSearchNotAvailableImplCopyWith<$Res> {
  __$$VoiceSearchNotAvailableImplCopyWithImpl(
    _$VoiceSearchNotAvailableImpl _value,
    $Res Function(_$VoiceSearchNotAvailableImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VoiceSearchNotAvailableImpl implements VoiceSearchNotAvailable {
  const _$VoiceSearchNotAvailableImpl();

  @override
  String toString() {
    return 'VoiceSearchState.notAvailable()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoiceSearchNotAvailableImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() initializing,
    required TResult Function(String partialText, double soundLevel) listening,
    required TResult Function(String recognizedText) processing,
    required TResult Function(String recognizedText) completed,
    required TResult Function() notAvailable,
    required TResult Function() permissionDenied,
    required TResult Function(String message) error,
  }) {
    return notAvailable();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? initializing,
    TResult? Function(String partialText, double soundLevel)? listening,
    TResult? Function(String recognizedText)? processing,
    TResult? Function(String recognizedText)? completed,
    TResult? Function()? notAvailable,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? error,
  }) {
    return notAvailable?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? initializing,
    TResult Function(String partialText, double soundLevel)? listening,
    TResult Function(String recognizedText)? processing,
    TResult Function(String recognizedText)? completed,
    TResult Function()? notAvailable,
    TResult Function()? permissionDenied,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (notAvailable != null) {
      return notAvailable();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VoiceSearchIdle value) idle,
    required TResult Function(VoiceSearchInitializing value) initializing,
    required TResult Function(VoiceSearchListening value) listening,
    required TResult Function(VoiceSearchProcessing value) processing,
    required TResult Function(VoiceSearchCompleted value) completed,
    required TResult Function(VoiceSearchNotAvailable value) notAvailable,
    required TResult Function(VoiceSearchPermissionDenied value)
    permissionDenied,
    required TResult Function(VoiceSearchError value) error,
  }) {
    return notAvailable(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VoiceSearchIdle value)? idle,
    TResult? Function(VoiceSearchInitializing value)? initializing,
    TResult? Function(VoiceSearchListening value)? listening,
    TResult? Function(VoiceSearchProcessing value)? processing,
    TResult? Function(VoiceSearchCompleted value)? completed,
    TResult? Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult? Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult? Function(VoiceSearchError value)? error,
  }) {
    return notAvailable?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VoiceSearchIdle value)? idle,
    TResult Function(VoiceSearchInitializing value)? initializing,
    TResult Function(VoiceSearchListening value)? listening,
    TResult Function(VoiceSearchProcessing value)? processing,
    TResult Function(VoiceSearchCompleted value)? completed,
    TResult Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult Function(VoiceSearchError value)? error,
    required TResult orElse(),
  }) {
    if (notAvailable != null) {
      return notAvailable(this);
    }
    return orElse();
  }
}

abstract class VoiceSearchNotAvailable implements VoiceSearchState {
  const factory VoiceSearchNotAvailable() = _$VoiceSearchNotAvailableImpl;
}

/// @nodoc
abstract class _$$VoiceSearchPermissionDeniedImplCopyWith<$Res> {
  factory _$$VoiceSearchPermissionDeniedImplCopyWith(
    _$VoiceSearchPermissionDeniedImpl value,
    $Res Function(_$VoiceSearchPermissionDeniedImpl) then,
  ) = __$$VoiceSearchPermissionDeniedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VoiceSearchPermissionDeniedImplCopyWithImpl<$Res>
    extends
        _$VoiceSearchStateCopyWithImpl<$Res, _$VoiceSearchPermissionDeniedImpl>
    implements _$$VoiceSearchPermissionDeniedImplCopyWith<$Res> {
  __$$VoiceSearchPermissionDeniedImplCopyWithImpl(
    _$VoiceSearchPermissionDeniedImpl _value,
    $Res Function(_$VoiceSearchPermissionDeniedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VoiceSearchPermissionDeniedImpl implements VoiceSearchPermissionDenied {
  const _$VoiceSearchPermissionDeniedImpl();

  @override
  String toString() {
    return 'VoiceSearchState.permissionDenied()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoiceSearchPermissionDeniedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() initializing,
    required TResult Function(String partialText, double soundLevel) listening,
    required TResult Function(String recognizedText) processing,
    required TResult Function(String recognizedText) completed,
    required TResult Function() notAvailable,
    required TResult Function() permissionDenied,
    required TResult Function(String message) error,
  }) {
    return permissionDenied();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? initializing,
    TResult? Function(String partialText, double soundLevel)? listening,
    TResult? Function(String recognizedText)? processing,
    TResult? Function(String recognizedText)? completed,
    TResult? Function()? notAvailable,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? error,
  }) {
    return permissionDenied?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? initializing,
    TResult Function(String partialText, double soundLevel)? listening,
    TResult Function(String recognizedText)? processing,
    TResult Function(String recognizedText)? completed,
    TResult Function()? notAvailable,
    TResult Function()? permissionDenied,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (permissionDenied != null) {
      return permissionDenied();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VoiceSearchIdle value) idle,
    required TResult Function(VoiceSearchInitializing value) initializing,
    required TResult Function(VoiceSearchListening value) listening,
    required TResult Function(VoiceSearchProcessing value) processing,
    required TResult Function(VoiceSearchCompleted value) completed,
    required TResult Function(VoiceSearchNotAvailable value) notAvailable,
    required TResult Function(VoiceSearchPermissionDenied value)
    permissionDenied,
    required TResult Function(VoiceSearchError value) error,
  }) {
    return permissionDenied(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VoiceSearchIdle value)? idle,
    TResult? Function(VoiceSearchInitializing value)? initializing,
    TResult? Function(VoiceSearchListening value)? listening,
    TResult? Function(VoiceSearchProcessing value)? processing,
    TResult? Function(VoiceSearchCompleted value)? completed,
    TResult? Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult? Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult? Function(VoiceSearchError value)? error,
  }) {
    return permissionDenied?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VoiceSearchIdle value)? idle,
    TResult Function(VoiceSearchInitializing value)? initializing,
    TResult Function(VoiceSearchListening value)? listening,
    TResult Function(VoiceSearchProcessing value)? processing,
    TResult Function(VoiceSearchCompleted value)? completed,
    TResult Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult Function(VoiceSearchError value)? error,
    required TResult orElse(),
  }) {
    if (permissionDenied != null) {
      return permissionDenied(this);
    }
    return orElse();
  }
}

abstract class VoiceSearchPermissionDenied implements VoiceSearchState {
  const factory VoiceSearchPermissionDenied() =
      _$VoiceSearchPermissionDeniedImpl;
}

/// @nodoc
abstract class _$$VoiceSearchErrorImplCopyWith<$Res> {
  factory _$$VoiceSearchErrorImplCopyWith(
    _$VoiceSearchErrorImpl value,
    $Res Function(_$VoiceSearchErrorImpl) then,
  ) = __$$VoiceSearchErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$VoiceSearchErrorImplCopyWithImpl<$Res>
    extends _$VoiceSearchStateCopyWithImpl<$Res, _$VoiceSearchErrorImpl>
    implements _$$VoiceSearchErrorImplCopyWith<$Res> {
  __$$VoiceSearchErrorImplCopyWithImpl(
    _$VoiceSearchErrorImpl _value,
    $Res Function(_$VoiceSearchErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$VoiceSearchErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VoiceSearchErrorImpl implements VoiceSearchError {
  const _$VoiceSearchErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'VoiceSearchState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoiceSearchErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoiceSearchErrorImplCopyWith<_$VoiceSearchErrorImpl> get copyWith =>
      __$$VoiceSearchErrorImplCopyWithImpl<_$VoiceSearchErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() initializing,
    required TResult Function(String partialText, double soundLevel) listening,
    required TResult Function(String recognizedText) processing,
    required TResult Function(String recognizedText) completed,
    required TResult Function() notAvailable,
    required TResult Function() permissionDenied,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? initializing,
    TResult? Function(String partialText, double soundLevel)? listening,
    TResult? Function(String recognizedText)? processing,
    TResult? Function(String recognizedText)? completed,
    TResult? Function()? notAvailable,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? initializing,
    TResult Function(String partialText, double soundLevel)? listening,
    TResult Function(String recognizedText)? processing,
    TResult Function(String recognizedText)? completed,
    TResult Function()? notAvailable,
    TResult Function()? permissionDenied,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VoiceSearchIdle value) idle,
    required TResult Function(VoiceSearchInitializing value) initializing,
    required TResult Function(VoiceSearchListening value) listening,
    required TResult Function(VoiceSearchProcessing value) processing,
    required TResult Function(VoiceSearchCompleted value) completed,
    required TResult Function(VoiceSearchNotAvailable value) notAvailable,
    required TResult Function(VoiceSearchPermissionDenied value)
    permissionDenied,
    required TResult Function(VoiceSearchError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VoiceSearchIdle value)? idle,
    TResult? Function(VoiceSearchInitializing value)? initializing,
    TResult? Function(VoiceSearchListening value)? listening,
    TResult? Function(VoiceSearchProcessing value)? processing,
    TResult? Function(VoiceSearchCompleted value)? completed,
    TResult? Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult? Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult? Function(VoiceSearchError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VoiceSearchIdle value)? idle,
    TResult Function(VoiceSearchInitializing value)? initializing,
    TResult Function(VoiceSearchListening value)? listening,
    TResult Function(VoiceSearchProcessing value)? processing,
    TResult Function(VoiceSearchCompleted value)? completed,
    TResult Function(VoiceSearchNotAvailable value)? notAvailable,
    TResult Function(VoiceSearchPermissionDenied value)? permissionDenied,
    TResult Function(VoiceSearchError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class VoiceSearchError implements VoiceSearchState {
  const factory VoiceSearchError({required final String message}) =
      _$VoiceSearchErrorImpl;

  String get message;

  /// Create a copy of VoiceSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoiceSearchErrorImplCopyWith<_$VoiceSearchErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
