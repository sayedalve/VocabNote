// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enrichment_queue_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EnrichmentQueueState {
  int get pendingCount;
  bool get isProcessing;

  /// Human-readable reason the queue is stalled (offline, missing key...),
  /// or null when everything is flowing.
  String? get stallReason;

  /// Create a copy of EnrichmentQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EnrichmentQueueStateCopyWith<EnrichmentQueueState> get copyWith =>
      _$EnrichmentQueueStateCopyWithImpl<EnrichmentQueueState>(
          this as EnrichmentQueueState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EnrichmentQueueState &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount) &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing) &&
            (identical(other.stallReason, stallReason) ||
                other.stallReason == stallReason));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, pendingCount, isProcessing, stallReason);

  @override
  String toString() {
    return 'EnrichmentQueueState(pendingCount: $pendingCount, isProcessing: $isProcessing, stallReason: $stallReason)';
  }
}

/// @nodoc
abstract mixin class $EnrichmentQueueStateCopyWith<$Res> {
  factory $EnrichmentQueueStateCopyWith(EnrichmentQueueState value,
          $Res Function(EnrichmentQueueState) _then) =
      _$EnrichmentQueueStateCopyWithImpl;
  @useResult
  $Res call({int pendingCount, bool isProcessing, String? stallReason});
}

/// @nodoc
class _$EnrichmentQueueStateCopyWithImpl<$Res>
    implements $EnrichmentQueueStateCopyWith<$Res> {
  _$EnrichmentQueueStateCopyWithImpl(this._self, this._then);

  final EnrichmentQueueState _self;
  final $Res Function(EnrichmentQueueState) _then;

  /// Create a copy of EnrichmentQueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pendingCount = null,
    Object? isProcessing = null,
    Object? stallReason = freezed,
  }) {
    return _then(_self.copyWith(
      pendingCount: null == pendingCount
          ? _self.pendingCount
          : pendingCount // ignore: cast_nullable_to_non_nullable
              as int,
      isProcessing: null == isProcessing
          ? _self.isProcessing
          : isProcessing // ignore: cast_nullable_to_non_nullable
              as bool,
      stallReason: freezed == stallReason
          ? _self.stallReason
          : stallReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [EnrichmentQueueState].
extension EnrichmentQueueStatePatterns on EnrichmentQueueState {
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
    TResult Function(_EnrichmentQueueState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EnrichmentQueueState() when $default != null:
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
    TResult Function(_EnrichmentQueueState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EnrichmentQueueState():
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
    TResult? Function(_EnrichmentQueueState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EnrichmentQueueState() when $default != null:
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
    TResult Function(int pendingCount, bool isProcessing, String? stallReason)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EnrichmentQueueState() when $default != null:
        return $default(
            _that.pendingCount, _that.isProcessing, _that.stallReason);
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
    TResult Function(int pendingCount, bool isProcessing, String? stallReason)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EnrichmentQueueState():
        return $default(
            _that.pendingCount, _that.isProcessing, _that.stallReason);
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
    TResult? Function(int pendingCount, bool isProcessing, String? stallReason)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EnrichmentQueueState() when $default != null:
        return $default(
            _that.pendingCount, _that.isProcessing, _that.stallReason);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _EnrichmentQueueState extends EnrichmentQueueState {
  const _EnrichmentQueueState(
      {this.pendingCount = 0, this.isProcessing = false, this.stallReason})
      : super._();

  @override
  @JsonKey()
  final int pendingCount;
  @override
  @JsonKey()
  final bool isProcessing;

  /// Human-readable reason the queue is stalled (offline, missing key...),
  /// or null when everything is flowing.
  @override
  final String? stallReason;

  /// Create a copy of EnrichmentQueueState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EnrichmentQueueStateCopyWith<_EnrichmentQueueState> get copyWith =>
      __$EnrichmentQueueStateCopyWithImpl<_EnrichmentQueueState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EnrichmentQueueState &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount) &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing) &&
            (identical(other.stallReason, stallReason) ||
                other.stallReason == stallReason));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, pendingCount, isProcessing, stallReason);

  @override
  String toString() {
    return 'EnrichmentQueueState(pendingCount: $pendingCount, isProcessing: $isProcessing, stallReason: $stallReason)';
  }
}

/// @nodoc
abstract mixin class _$EnrichmentQueueStateCopyWith<$Res>
    implements $EnrichmentQueueStateCopyWith<$Res> {
  factory _$EnrichmentQueueStateCopyWith(_EnrichmentQueueState value,
          $Res Function(_EnrichmentQueueState) _then) =
      __$EnrichmentQueueStateCopyWithImpl;
  @override
  @useResult
  $Res call({int pendingCount, bool isProcessing, String? stallReason});
}

/// @nodoc
class __$EnrichmentQueueStateCopyWithImpl<$Res>
    implements _$EnrichmentQueueStateCopyWith<$Res> {
  __$EnrichmentQueueStateCopyWithImpl(this._self, this._then);

  final _EnrichmentQueueState _self;
  final $Res Function(_EnrichmentQueueState) _then;

  /// Create a copy of EnrichmentQueueState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pendingCount = null,
    Object? isProcessing = null,
    Object? stallReason = freezed,
  }) {
    return _then(_EnrichmentQueueState(
      pendingCount: null == pendingCount
          ? _self.pendingCount
          : pendingCount // ignore: cast_nullable_to_non_nullable
              as int,
      isProcessing: null == isProcessing
          ? _self.isProcessing
          : isProcessing // ignore: cast_nullable_to_non_nullable
              as bool,
      stallReason: freezed == stallReason
          ? _self.stallReason
          : stallReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
