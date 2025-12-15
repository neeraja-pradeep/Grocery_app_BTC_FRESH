// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SearchHistoryState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<String> searches) loaded,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<String> searches)? loaded,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<String> searches)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchHistoryInitial value) initial,
    required TResult Function(SearchHistoryLoaded value) loaded,
    required TResult Function(SearchHistoryError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchHistoryInitial value)? initial,
    TResult? Function(SearchHistoryLoaded value)? loaded,
    TResult? Function(SearchHistoryError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchHistoryInitial value)? initial,
    TResult Function(SearchHistoryLoaded value)? loaded,
    TResult Function(SearchHistoryError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchHistoryStateCopyWith<$Res> {
  factory $SearchHistoryStateCopyWith(
    SearchHistoryState value,
    $Res Function(SearchHistoryState) then,
  ) = _$SearchHistoryStateCopyWithImpl<$Res, SearchHistoryState>;
}

/// @nodoc
class _$SearchHistoryStateCopyWithImpl<$Res, $Val extends SearchHistoryState>
    implements $SearchHistoryStateCopyWith<$Res> {
  _$SearchHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchHistoryState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SearchHistoryInitialImplCopyWith<$Res> {
  factory _$$SearchHistoryInitialImplCopyWith(
    _$SearchHistoryInitialImpl value,
    $Res Function(_$SearchHistoryInitialImpl) then,
  ) = __$$SearchHistoryInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SearchHistoryInitialImplCopyWithImpl<$Res>
    extends _$SearchHistoryStateCopyWithImpl<$Res, _$SearchHistoryInitialImpl>
    implements _$$SearchHistoryInitialImplCopyWith<$Res> {
  __$$SearchHistoryInitialImplCopyWithImpl(
    _$SearchHistoryInitialImpl _value,
    $Res Function(_$SearchHistoryInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchHistoryState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SearchHistoryInitialImpl implements SearchHistoryInitial {
  const _$SearchHistoryInitialImpl();

  @override
  String toString() {
    return 'SearchHistoryState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchHistoryInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<String> searches) loaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<String> searches)? loaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<String> searches)? loaded,
    TResult Function(String message)? error,
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
    required TResult Function(SearchHistoryInitial value) initial,
    required TResult Function(SearchHistoryLoaded value) loaded,
    required TResult Function(SearchHistoryError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchHistoryInitial value)? initial,
    TResult? Function(SearchHistoryLoaded value)? loaded,
    TResult? Function(SearchHistoryError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchHistoryInitial value)? initial,
    TResult Function(SearchHistoryLoaded value)? loaded,
    TResult Function(SearchHistoryError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class SearchHistoryInitial implements SearchHistoryState {
  const factory SearchHistoryInitial() = _$SearchHistoryInitialImpl;
}

/// @nodoc
abstract class _$$SearchHistoryLoadedImplCopyWith<$Res> {
  factory _$$SearchHistoryLoadedImplCopyWith(
    _$SearchHistoryLoadedImpl value,
    $Res Function(_$SearchHistoryLoadedImpl) then,
  ) = __$$SearchHistoryLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> searches});
}

/// @nodoc
class __$$SearchHistoryLoadedImplCopyWithImpl<$Res>
    extends _$SearchHistoryStateCopyWithImpl<$Res, _$SearchHistoryLoadedImpl>
    implements _$$SearchHistoryLoadedImplCopyWith<$Res> {
  __$$SearchHistoryLoadedImplCopyWithImpl(
    _$SearchHistoryLoadedImpl _value,
    $Res Function(_$SearchHistoryLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? searches = null}) {
    return _then(
      _$SearchHistoryLoadedImpl(
        searches: null == searches
            ? _value._searches
            : searches // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$SearchHistoryLoadedImpl implements SearchHistoryLoaded {
  const _$SearchHistoryLoadedImpl({required final List<String> searches})
    : _searches = searches;

  final List<String> _searches;
  @override
  List<String> get searches {
    if (_searches is EqualUnmodifiableListView) return _searches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_searches);
  }

  @override
  String toString() {
    return 'SearchHistoryState.loaded(searches: $searches)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchHistoryLoadedImpl &&
            const DeepCollectionEquality().equals(other._searches, _searches));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_searches));

  /// Create a copy of SearchHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchHistoryLoadedImplCopyWith<_$SearchHistoryLoadedImpl> get copyWith =>
      __$$SearchHistoryLoadedImplCopyWithImpl<_$SearchHistoryLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<String> searches) loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(searches);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<String> searches)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(searches);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<String> searches)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(searches);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchHistoryInitial value) initial,
    required TResult Function(SearchHistoryLoaded value) loaded,
    required TResult Function(SearchHistoryError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchHistoryInitial value)? initial,
    TResult? Function(SearchHistoryLoaded value)? loaded,
    TResult? Function(SearchHistoryError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchHistoryInitial value)? initial,
    TResult Function(SearchHistoryLoaded value)? loaded,
    TResult Function(SearchHistoryError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class SearchHistoryLoaded implements SearchHistoryState {
  const factory SearchHistoryLoaded({required final List<String> searches}) =
      _$SearchHistoryLoadedImpl;

  List<String> get searches;

  /// Create a copy of SearchHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchHistoryLoadedImplCopyWith<_$SearchHistoryLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchHistoryErrorImplCopyWith<$Res> {
  factory _$$SearchHistoryErrorImplCopyWith(
    _$SearchHistoryErrorImpl value,
    $Res Function(_$SearchHistoryErrorImpl) then,
  ) = __$$SearchHistoryErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$SearchHistoryErrorImplCopyWithImpl<$Res>
    extends _$SearchHistoryStateCopyWithImpl<$Res, _$SearchHistoryErrorImpl>
    implements _$$SearchHistoryErrorImplCopyWith<$Res> {
  __$$SearchHistoryErrorImplCopyWithImpl(
    _$SearchHistoryErrorImpl _value,
    $Res Function(_$SearchHistoryErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$SearchHistoryErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SearchHistoryErrorImpl implements SearchHistoryError {
  const _$SearchHistoryErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'SearchHistoryState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchHistoryErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of SearchHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchHistoryErrorImplCopyWith<_$SearchHistoryErrorImpl> get copyWith =>
      __$$SearchHistoryErrorImplCopyWithImpl<_$SearchHistoryErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<String> searches) loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<String> searches)? loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<String> searches)? loaded,
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
    required TResult Function(SearchHistoryInitial value) initial,
    required TResult Function(SearchHistoryLoaded value) loaded,
    required TResult Function(SearchHistoryError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchHistoryInitial value)? initial,
    TResult? Function(SearchHistoryLoaded value)? loaded,
    TResult? Function(SearchHistoryError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchHistoryInitial value)? initial,
    TResult Function(SearchHistoryLoaded value)? loaded,
    TResult Function(SearchHistoryError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class SearchHistoryError implements SearchHistoryState {
  const factory SearchHistoryError({required final String message}) =
      _$SearchHistoryErrorImpl;

  String get message;

  /// Create a copy of SearchHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchHistoryErrorImplCopyWith<_$SearchHistoryErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
