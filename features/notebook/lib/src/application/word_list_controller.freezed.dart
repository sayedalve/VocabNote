// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'word_list_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WordListFilter {
  int? get notebookId;
  bool get favoritesOnly;

  /// Create a copy of WordListFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WordListFilterCopyWith<WordListFilter> get copyWith =>
      _$WordListFilterCopyWithImpl<WordListFilter>(
          this as WordListFilter, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WordListFilter &&
            (identical(other.notebookId, notebookId) ||
                other.notebookId == notebookId) &&
            (identical(other.favoritesOnly, favoritesOnly) ||
                other.favoritesOnly == favoritesOnly));
  }

  @override
  int get hashCode => Object.hash(runtimeType, notebookId, favoritesOnly);

  @override
  String toString() {
    return 'WordListFilter(notebookId: $notebookId, favoritesOnly: $favoritesOnly)';
  }
}

/// @nodoc
abstract mixin class $WordListFilterCopyWith<$Res> {
  factory $WordListFilterCopyWith(
          WordListFilter value, $Res Function(WordListFilter) _then) =
      _$WordListFilterCopyWithImpl;
  @useResult
  $Res call({int? notebookId, bool favoritesOnly});
}

/// @nodoc
class _$WordListFilterCopyWithImpl<$Res>
    implements $WordListFilterCopyWith<$Res> {
  _$WordListFilterCopyWithImpl(this._self, this._then);

  final WordListFilter _self;
  final $Res Function(WordListFilter) _then;

  /// Create a copy of WordListFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notebookId = freezed,
    Object? favoritesOnly = null,
  }) {
    return _then(_self.copyWith(
      notebookId: freezed == notebookId
          ? _self.notebookId
          : notebookId // ignore: cast_nullable_to_non_nullable
              as int?,
      favoritesOnly: null == favoritesOnly
          ? _self.favoritesOnly
          : favoritesOnly // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [WordListFilter].
extension WordListFilterPatterns on WordListFilter {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_WordListFilter value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordListFilter() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_WordListFilter value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordListFilter():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_WordListFilter value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordListFilter() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(int? notebookId, bool favoritesOnly)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordListFilter() when $default != null:
        return $default(_that.notebookId, _that.favoritesOnly);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(int? notebookId, bool favoritesOnly) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordListFilter():
        return $default(_that.notebookId, _that.favoritesOnly);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(int? notebookId, bool favoritesOnly)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordListFilter() when $default != null:
        return $default(_that.notebookId, _that.favoritesOnly);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _WordListFilter implements WordListFilter {
  const _WordListFilter({this.notebookId, this.favoritesOnly = false});

  @override
  final int? notebookId;
  @override
  @JsonKey()
  final bool favoritesOnly;

  /// Create a copy of WordListFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WordListFilterCopyWith<_WordListFilter> get copyWith =>
      __$WordListFilterCopyWithImpl<_WordListFilter>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WordListFilter &&
            (identical(other.notebookId, notebookId) ||
                other.notebookId == notebookId) &&
            (identical(other.favoritesOnly, favoritesOnly) ||
                other.favoritesOnly == favoritesOnly));
  }

  @override
  int get hashCode => Object.hash(runtimeType, notebookId, favoritesOnly);

  @override
  String toString() {
    return 'WordListFilter(notebookId: $notebookId, favoritesOnly: $favoritesOnly)';
  }
}

/// @nodoc
abstract mixin class _$WordListFilterCopyWith<$Res>
    implements $WordListFilterCopyWith<$Res> {
  factory _$WordListFilterCopyWith(
          _WordListFilter value, $Res Function(_WordListFilter) _then) =
      __$WordListFilterCopyWithImpl;
  @override
  @useResult
  $Res call({int? notebookId, bool favoritesOnly});
}

/// @nodoc
class __$WordListFilterCopyWithImpl<$Res>
    implements _$WordListFilterCopyWith<$Res> {
  __$WordListFilterCopyWithImpl(this._self, this._then);

  final _WordListFilter _self;
  final $Res Function(_WordListFilter) _then;

  /// Create a copy of WordListFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? notebookId = freezed,
    Object? favoritesOnly = null,
  }) {
    return _then(_WordListFilter(
      notebookId: freezed == notebookId
          ? _self.notebookId
          : notebookId // ignore: cast_nullable_to_non_nullable
              as int?,
      favoritesOnly: null == favoritesOnly
          ? _self.favoritesOnly
          : favoritesOnly // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$WordListState {
  List<Word> get words;
  bool get hasMore;
  int get totalCount;
  bool get isLoadingMore;
  String get query;

  /// Create a copy of WordListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WordListStateCopyWith<WordListState> get copyWith =>
      _$WordListStateCopyWithImpl<WordListState>(
          this as WordListState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WordListState &&
            const DeepCollectionEquality().equals(other.words, words) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(words),
      hasMore,
      totalCount,
      isLoadingMore,
      query);

  @override
  String toString() {
    return 'WordListState(words: $words, hasMore: $hasMore, totalCount: $totalCount, isLoadingMore: $isLoadingMore, query: $query)';
  }
}

/// @nodoc
abstract mixin class $WordListStateCopyWith<$Res> {
  factory $WordListStateCopyWith(
          WordListState value, $Res Function(WordListState) _then) =
      _$WordListStateCopyWithImpl;
  @useResult
  $Res call(
      {List<Word> words,
      bool hasMore,
      int totalCount,
      bool isLoadingMore,
      String query});
}

/// @nodoc
class _$WordListStateCopyWithImpl<$Res>
    implements $WordListStateCopyWith<$Res> {
  _$WordListStateCopyWithImpl(this._self, this._then);

  final WordListState _self;
  final $Res Function(WordListState) _then;

  /// Create a copy of WordListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? words = null,
    Object? hasMore = null,
    Object? totalCount = null,
    Object? isLoadingMore = null,
    Object? query = null,
  }) {
    return _then(_self.copyWith(
      words: null == words
          ? _self.words
          : words // ignore: cast_nullable_to_non_nullable
              as List<Word>,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      totalCount: null == totalCount
          ? _self.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      isLoadingMore: null == isLoadingMore
          ? _self.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [WordListState].
extension WordListStatePatterns on WordListState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_WordListState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordListState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_WordListState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordListState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_WordListState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordListState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(List<Word> words, bool hasMore, int totalCount,
            bool isLoadingMore, String query)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordListState() when $default != null:
        return $default(_that.words, _that.hasMore, _that.totalCount,
            _that.isLoadingMore, _that.query);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(List<Word> words, bool hasMore, int totalCount,
            bool isLoadingMore, String query)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordListState():
        return $default(_that.words, _that.hasMore, _that.totalCount,
            _that.isLoadingMore, _that.query);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(List<Word> words, bool hasMore, int totalCount,
            bool isLoadingMore, String query)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordListState() when $default != null:
        return $default(_that.words, _that.hasMore, _that.totalCount,
            _that.isLoadingMore, _that.query);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _WordListState extends WordListState {
  const _WordListState(
      {required final List<Word> words,
      required this.hasMore,
      required this.totalCount,
      this.isLoadingMore = false,
      this.query = ''})
      : _words = words,
        super._();

  final List<Word> _words;
  @override
  List<Word> get words {
    if (_words is EqualUnmodifiableListView) return _words;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_words);
  }

  @override
  final bool hasMore;
  @override
  final int totalCount;
  @override
  @JsonKey()
  final bool isLoadingMore;
  @override
  @JsonKey()
  final String query;

  /// Create a copy of WordListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WordListStateCopyWith<_WordListState> get copyWith =>
      __$WordListStateCopyWithImpl<_WordListState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WordListState &&
            const DeepCollectionEquality().equals(other._words, _words) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_words),
      hasMore,
      totalCount,
      isLoadingMore,
      query);

  @override
  String toString() {
    return 'WordListState(words: $words, hasMore: $hasMore, totalCount: $totalCount, isLoadingMore: $isLoadingMore, query: $query)';
  }
}

/// @nodoc
abstract mixin class _$WordListStateCopyWith<$Res>
    implements $WordListStateCopyWith<$Res> {
  factory _$WordListStateCopyWith(
          _WordListState value, $Res Function(_WordListState) _then) =
      __$WordListStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<Word> words,
      bool hasMore,
      int totalCount,
      bool isLoadingMore,
      String query});
}

/// @nodoc
class __$WordListStateCopyWithImpl<$Res>
    implements _$WordListStateCopyWith<$Res> {
  __$WordListStateCopyWithImpl(this._self, this._then);

  final _WordListState _self;
  final $Res Function(_WordListState) _then;

  /// Create a copy of WordListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? words = null,
    Object? hasMore = null,
    Object? totalCount = null,
    Object? isLoadingMore = null,
    Object? query = null,
  }) {
    return _then(_WordListState(
      words: null == words
          ? _self._words
          : words // ignore: cast_nullable_to_non_nullable
              as List<Word>,
      hasMore: null == hasMore
          ? _self.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      totalCount: null == totalCount
          ? _self.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      isLoadingMore: null == isLoadingMore
          ? _self.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
