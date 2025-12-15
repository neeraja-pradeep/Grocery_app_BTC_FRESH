// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SearchState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isVoiceSearch) listening,
    required TResult Function(String query, bool isVoiceSearch) loading,
    required TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )
    loaded,
    required TResult Function(String query) empty,
    required TResult Function(Failure failure, String query) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isVoiceSearch)? listening,
    TResult? Function(String query, bool isVoiceSearch)? loading,
    TResult? Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult? Function(String query)? empty,
    TResult? Function(Failure failure, String query)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isVoiceSearch)? listening,
    TResult Function(String query, bool isVoiceSearch)? loading,
    TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult Function(String query)? empty,
    TResult Function(Failure failure, String query)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchListening value) listening,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchListening value)? listening,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchListening value)? listening,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchStateCopyWith<$Res> {
  factory $SearchStateCopyWith(
    SearchState value,
    $Res Function(SearchState) then,
  ) = _$SearchStateCopyWithImpl<$Res, SearchState>;
}

/// @nodoc
class _$SearchStateCopyWithImpl<$Res, $Val extends SearchState>
    implements $SearchStateCopyWith<$Res> {
  _$SearchStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SearchInitialImplCopyWith<$Res> {
  factory _$$SearchInitialImplCopyWith(
    _$SearchInitialImpl value,
    $Res Function(_$SearchInitialImpl) then,
  ) = __$$SearchInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SearchInitialImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchInitialImpl>
    implements _$$SearchInitialImplCopyWith<$Res> {
  __$$SearchInitialImplCopyWithImpl(
    _$SearchInitialImpl _value,
    $Res Function(_$SearchInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SearchInitialImpl implements SearchInitial {
  const _$SearchInitialImpl();

  @override
  String toString() {
    return 'SearchState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SearchInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isVoiceSearch) listening,
    required TResult Function(String query, bool isVoiceSearch) loading,
    required TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )
    loaded,
    required TResult Function(String query) empty,
    required TResult Function(Failure failure, String query) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isVoiceSearch)? listening,
    TResult? Function(String query, bool isVoiceSearch)? loading,
    TResult? Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult? Function(String query)? empty,
    TResult? Function(Failure failure, String query)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isVoiceSearch)? listening,
    TResult Function(String query, bool isVoiceSearch)? loading,
    TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult Function(String query)? empty,
    TResult Function(Failure failure, String query)? error,
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
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchListening value) listening,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchListening value)? listening,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchListening value)? listening,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class SearchInitial implements SearchState {
  const factory SearchInitial() = _$SearchInitialImpl;
}

/// @nodoc
abstract class _$$SearchListeningImplCopyWith<$Res> {
  factory _$$SearchListeningImplCopyWith(
    _$SearchListeningImpl value,
    $Res Function(_$SearchListeningImpl) then,
  ) = __$$SearchListeningImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool isVoiceSearch});
}

/// @nodoc
class __$$SearchListeningImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchListeningImpl>
    implements _$$SearchListeningImplCopyWith<$Res> {
  __$$SearchListeningImplCopyWithImpl(
    _$SearchListeningImpl _value,
    $Res Function(_$SearchListeningImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isVoiceSearch = null}) {
    return _then(
      _$SearchListeningImpl(
        isVoiceSearch: null == isVoiceSearch
            ? _value.isVoiceSearch
            : isVoiceSearch // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$SearchListeningImpl implements SearchListening {
  const _$SearchListeningImpl({required this.isVoiceSearch});

  @override
  final bool isVoiceSearch;

  @override
  String toString() {
    return 'SearchState.listening(isVoiceSearch: $isVoiceSearch)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchListeningImpl &&
            (identical(other.isVoiceSearch, isVoiceSearch) ||
                other.isVoiceSearch == isVoiceSearch));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isVoiceSearch);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchListeningImplCopyWith<_$SearchListeningImpl> get copyWith =>
      __$$SearchListeningImplCopyWithImpl<_$SearchListeningImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isVoiceSearch) listening,
    required TResult Function(String query, bool isVoiceSearch) loading,
    required TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )
    loaded,
    required TResult Function(String query) empty,
    required TResult Function(Failure failure, String query) error,
  }) {
    return listening(isVoiceSearch);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isVoiceSearch)? listening,
    TResult? Function(String query, bool isVoiceSearch)? loading,
    TResult? Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult? Function(String query)? empty,
    TResult? Function(Failure failure, String query)? error,
  }) {
    return listening?.call(isVoiceSearch);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isVoiceSearch)? listening,
    TResult Function(String query, bool isVoiceSearch)? loading,
    TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult Function(String query)? empty,
    TResult Function(Failure failure, String query)? error,
    required TResult orElse(),
  }) {
    if (listening != null) {
      return listening(isVoiceSearch);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchListening value) listening,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchError value) error,
  }) {
    return listening(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchListening value)? listening,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchError value)? error,
  }) {
    return listening?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchListening value)? listening,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchError value)? error,
    required TResult orElse(),
  }) {
    if (listening != null) {
      return listening(this);
    }
    return orElse();
  }
}

abstract class SearchListening implements SearchState {
  const factory SearchListening({required final bool isVoiceSearch}) =
      _$SearchListeningImpl;

  bool get isVoiceSearch;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchListeningImplCopyWith<_$SearchListeningImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchLoadingImplCopyWith<$Res> {
  factory _$$SearchLoadingImplCopyWith(
    _$SearchLoadingImpl value,
    $Res Function(_$SearchLoadingImpl) then,
  ) = __$$SearchLoadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query, bool isVoiceSearch});
}

/// @nodoc
class __$$SearchLoadingImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchLoadingImpl>
    implements _$$SearchLoadingImplCopyWith<$Res> {
  __$$SearchLoadingImplCopyWithImpl(
    _$SearchLoadingImpl _value,
    $Res Function(_$SearchLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null, Object? isVoiceSearch = null}) {
    return _then(
      _$SearchLoadingImpl(
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        isVoiceSearch: null == isVoiceSearch
            ? _value.isVoiceSearch
            : isVoiceSearch // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$SearchLoadingImpl implements SearchLoading {
  const _$SearchLoadingImpl({required this.query, required this.isVoiceSearch});

  @override
  final String query;
  @override
  final bool isVoiceSearch;

  @override
  String toString() {
    return 'SearchState.loading(query: $query, isVoiceSearch: $isVoiceSearch)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchLoadingImpl &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.isVoiceSearch, isVoiceSearch) ||
                other.isVoiceSearch == isVoiceSearch));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query, isVoiceSearch);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchLoadingImplCopyWith<_$SearchLoadingImpl> get copyWith =>
      __$$SearchLoadingImplCopyWithImpl<_$SearchLoadingImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isVoiceSearch) listening,
    required TResult Function(String query, bool isVoiceSearch) loading,
    required TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )
    loaded,
    required TResult Function(String query) empty,
    required TResult Function(Failure failure, String query) error,
  }) {
    return loading(query, isVoiceSearch);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isVoiceSearch)? listening,
    TResult? Function(String query, bool isVoiceSearch)? loading,
    TResult? Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult? Function(String query)? empty,
    TResult? Function(Failure failure, String query)? error,
  }) {
    return loading?.call(query, isVoiceSearch);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isVoiceSearch)? listening,
    TResult Function(String query, bool isVoiceSearch)? loading,
    TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult Function(String query)? empty,
    TResult Function(Failure failure, String query)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(query, isVoiceSearch);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchListening value) listening,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchListening value)? listening,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchListening value)? listening,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class SearchLoading implements SearchState {
  const factory SearchLoading({
    required final String query,
    required final bool isVoiceSearch,
  }) = _$SearchLoadingImpl;

  String get query;
  bool get isVoiceSearch;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchLoadingImplCopyWith<_$SearchLoadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchLoadedImplCopyWith<$Res> {
  factory _$$SearchLoadedImplCopyWith(
    _$SearchLoadedImpl value,
    $Res Function(_$SearchLoadedImpl) then,
  ) = __$$SearchLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String query,
    List<ProductVariant> results,
    bool hasMore,
    int currentPage,
  });
}

/// @nodoc
class __$$SearchLoadedImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchLoadedImpl>
    implements _$$SearchLoadedImplCopyWith<$Res> {
  __$$SearchLoadedImplCopyWithImpl(
    _$SearchLoadedImpl _value,
    $Res Function(_$SearchLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? results = null,
    Object? hasMore = null,
    Object? currentPage = null,
  }) {
    return _then(
      _$SearchLoadedImpl(
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        results: null == results
            ? _value._results
            : results // ignore: cast_nullable_to_non_nullable
                  as List<ProductVariant>,
        hasMore: null == hasMore
            ? _value.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentPage: null == currentPage
            ? _value.currentPage
            : currentPage // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$SearchLoadedImpl implements SearchLoaded {
  const _$SearchLoadedImpl({
    required this.query,
    required final List<ProductVariant> results,
    this.hasMore = false,
    this.currentPage = 1,
  }) : _results = results;

  @override
  final String query;
  final List<ProductVariant> _results;
  @override
  List<ProductVariant> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final int currentPage;

  @override
  String toString() {
    return 'SearchState.loaded(query: $query, results: $results, hasMore: $hasMore, currentPage: $currentPage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchLoadedImpl &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    const DeepCollectionEquality().hash(_results),
    hasMore,
    currentPage,
  );

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchLoadedImplCopyWith<_$SearchLoadedImpl> get copyWith =>
      __$$SearchLoadedImplCopyWithImpl<_$SearchLoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isVoiceSearch) listening,
    required TResult Function(String query, bool isVoiceSearch) loading,
    required TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )
    loaded,
    required TResult Function(String query) empty,
    required TResult Function(Failure failure, String query) error,
  }) {
    return loaded(query, results, hasMore, currentPage);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isVoiceSearch)? listening,
    TResult? Function(String query, bool isVoiceSearch)? loading,
    TResult? Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult? Function(String query)? empty,
    TResult? Function(Failure failure, String query)? error,
  }) {
    return loaded?.call(query, results, hasMore, currentPage);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isVoiceSearch)? listening,
    TResult Function(String query, bool isVoiceSearch)? loading,
    TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult Function(String query)? empty,
    TResult Function(Failure failure, String query)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(query, results, hasMore, currentPage);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchListening value) listening,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchListening value)? listening,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchListening value)? listening,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class SearchLoaded implements SearchState {
  const factory SearchLoaded({
    required final String query,
    required final List<ProductVariant> results,
    final bool hasMore,
    final int currentPage,
  }) = _$SearchLoadedImpl;

  String get query;
  List<ProductVariant> get results;
  bool get hasMore;
  int get currentPage;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchLoadedImplCopyWith<_$SearchLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchEmptyImplCopyWith<$Res> {
  factory _$$SearchEmptyImplCopyWith(
    _$SearchEmptyImpl value,
    $Res Function(_$SearchEmptyImpl) then,
  ) = __$$SearchEmptyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query});
}

/// @nodoc
class __$$SearchEmptyImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchEmptyImpl>
    implements _$$SearchEmptyImplCopyWith<$Res> {
  __$$SearchEmptyImplCopyWithImpl(
    _$SearchEmptyImpl _value,
    $Res Function(_$SearchEmptyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null}) {
    return _then(
      _$SearchEmptyImpl(
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SearchEmptyImpl implements SearchEmpty {
  const _$SearchEmptyImpl({required this.query});

  @override
  final String query;

  @override
  String toString() {
    return 'SearchState.empty(query: $query)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchEmptyImpl &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchEmptyImplCopyWith<_$SearchEmptyImpl> get copyWith =>
      __$$SearchEmptyImplCopyWithImpl<_$SearchEmptyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isVoiceSearch) listening,
    required TResult Function(String query, bool isVoiceSearch) loading,
    required TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )
    loaded,
    required TResult Function(String query) empty,
    required TResult Function(Failure failure, String query) error,
  }) {
    return empty(query);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isVoiceSearch)? listening,
    TResult? Function(String query, bool isVoiceSearch)? loading,
    TResult? Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult? Function(String query)? empty,
    TResult? Function(Failure failure, String query)? error,
  }) {
    return empty?.call(query);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isVoiceSearch)? listening,
    TResult Function(String query, bool isVoiceSearch)? loading,
    TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult Function(String query)? empty,
    TResult Function(Failure failure, String query)? error,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty(query);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchListening value) listening,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchError value) error,
  }) {
    return empty(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchListening value)? listening,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchError value)? error,
  }) {
    return empty?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchListening value)? listening,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchError value)? error,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty(this);
    }
    return orElse();
  }
}

abstract class SearchEmpty implements SearchState {
  const factory SearchEmpty({required final String query}) = _$SearchEmptyImpl;

  String get query;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchEmptyImplCopyWith<_$SearchEmptyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchErrorImplCopyWith<$Res> {
  factory _$$SearchErrorImplCopyWith(
    _$SearchErrorImpl value,
    $Res Function(_$SearchErrorImpl) then,
  ) = __$$SearchErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Failure failure, String query});
}

/// @nodoc
class __$$SearchErrorImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchErrorImpl>
    implements _$$SearchErrorImplCopyWith<$Res> {
  __$$SearchErrorImplCopyWithImpl(
    _$SearchErrorImpl _value,
    $Res Function(_$SearchErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failure = null, Object? query = null}) {
    return _then(
      _$SearchErrorImpl(
        failure: null == failure
            ? _value.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as Failure,
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SearchErrorImpl implements SearchError {
  const _$SearchErrorImpl({required this.failure, required this.query});

  @override
  final Failure failure;
  @override
  final String query;

  @override
  String toString() {
    return 'SearchState.error(failure: $failure, query: $query)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchErrorImpl &&
            (identical(other.failure, failure) || other.failure == failure) &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failure, query);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchErrorImplCopyWith<_$SearchErrorImpl> get copyWith =>
      __$$SearchErrorImplCopyWithImpl<_$SearchErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isVoiceSearch) listening,
    required TResult Function(String query, bool isVoiceSearch) loading,
    required TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )
    loaded,
    required TResult Function(String query) empty,
    required TResult Function(Failure failure, String query) error,
  }) {
    return error(failure, query);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isVoiceSearch)? listening,
    TResult? Function(String query, bool isVoiceSearch)? loading,
    TResult? Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult? Function(String query)? empty,
    TResult? Function(Failure failure, String query)? error,
  }) {
    return error?.call(failure, query);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isVoiceSearch)? listening,
    TResult Function(String query, bool isVoiceSearch)? loading,
    TResult Function(
      String query,
      List<ProductVariant> results,
      bool hasMore,
      int currentPage,
    )?
    loaded,
    TResult Function(String query)? empty,
    TResult Function(Failure failure, String query)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(failure, query);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchListening value) listening,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchListening value)? listening,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchListening value)? listening,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class SearchError implements SearchState {
  const factory SearchError({
    required final Failure failure,
    required final String query,
  }) = _$SearchErrorImpl;

  Failure get failure;
  String get query;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchErrorImplCopyWith<_$SearchErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
