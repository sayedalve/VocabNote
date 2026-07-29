// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'capture_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CaptureState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CaptureState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'CaptureState()';
  }
}

/// @nodoc
class $CaptureStateCopyWith<$Res> {
  $CaptureStateCopyWith(CaptureState _, $Res Function(CaptureState) __);
}

/// Adds pattern-matching-related methods to [CaptureState].
extension CaptureStatePatterns on CaptureState {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CaptureIdle value)? idle,
    TResult Function(CaptureSaving value)? saving,
    TResult Function(CaptureSaved value)? saved,
    TResult Function(CaptureRejected value)? rejected,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case CaptureIdle() when idle != null:
        return idle(_that);
      case CaptureSaving() when saving != null:
        return saving(_that);
      case CaptureSaved() when saved != null:
        return saved(_that);
      case CaptureRejected() when rejected != null:
        return rejected(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(CaptureIdle value) idle,
    required TResult Function(CaptureSaving value) saving,
    required TResult Function(CaptureSaved value) saved,
    required TResult Function(CaptureRejected value) rejected,
  }) {
    final _that = this;
    switch (_that) {
      case CaptureIdle():
        return idle(_that);
      case CaptureSaving():
        return saving(_that);
      case CaptureSaved():
        return saved(_that);
      case CaptureRejected():
        return rejected(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CaptureIdle value)? idle,
    TResult? Function(CaptureSaving value)? saving,
    TResult? Function(CaptureSaved value)? saved,
    TResult? Function(CaptureRejected value)? rejected,
  }) {
    final _that = this;
    switch (_that) {
      case CaptureIdle() when idle != null:
        return idle(_that);
      case CaptureSaving() when saving != null:
        return saving(_that);
      case CaptureSaved() when saved != null:
        return saved(_that);
      case CaptureRejected() when rejected != null:
        return rejected(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? saving,
    TResult Function(int wordId, String headword)? saved,
    TResult Function(String reason)? rejected,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case CaptureIdle() when idle != null:
        return idle();
      case CaptureSaving() when saving != null:
        return saving();
      case CaptureSaved() when saved != null:
        return saved(_that.wordId, _that.headword);
      case CaptureRejected() when rejected != null:
        return rejected(_that.reason);
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
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() saving,
    required TResult Function(int wordId, String headword) saved,
    required TResult Function(String reason) rejected,
  }) {
    final _that = this;
    switch (_that) {
      case CaptureIdle():
        return idle();
      case CaptureSaving():
        return saving();
      case CaptureSaved():
        return saved(_that.wordId, _that.headword);
      case CaptureRejected():
        return rejected(_that.reason);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? saving,
    TResult? Function(int wordId, String headword)? saved,
    TResult? Function(String reason)? rejected,
  }) {
    final _that = this;
    switch (_that) {
      case CaptureIdle() when idle != null:
        return idle();
      case CaptureSaving() when saving != null:
        return saving();
      case CaptureSaved() when saved != null:
        return saved(_that.wordId, _that.headword);
      case CaptureRejected() when rejected != null:
        return rejected(_that.reason);
      case _:
        return null;
    }
  }
}

/// @nodoc

class CaptureIdle implements CaptureState {
  const CaptureIdle();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CaptureIdle);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'CaptureState.idle()';
  }
}

/// @nodoc

class CaptureSaving implements CaptureState {
  const CaptureSaving();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CaptureSaving);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'CaptureState.saving()';
  }
}

/// @nodoc

class CaptureSaved implements CaptureState {
  const CaptureSaved({required this.wordId, required this.headword});

  final int wordId;
  final String headword;

  /// Create a copy of CaptureState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CaptureSavedCopyWith<CaptureSaved> get copyWith =>
      _$CaptureSavedCopyWithImpl<CaptureSaved>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CaptureSaved &&
            (identical(other.wordId, wordId) || other.wordId == wordId) &&
            (identical(other.headword, headword) ||
                other.headword == headword));
  }

  @override
  int get hashCode => Object.hash(runtimeType, wordId, headword);

  @override
  String toString() {
    return 'CaptureState.saved(wordId: $wordId, headword: $headword)';
  }
}

/// @nodoc
abstract mixin class $CaptureSavedCopyWith<$Res>
    implements $CaptureStateCopyWith<$Res> {
  factory $CaptureSavedCopyWith(
          CaptureSaved value, $Res Function(CaptureSaved) _then) =
      _$CaptureSavedCopyWithImpl;
  @useResult
  $Res call({int wordId, String headword});
}

/// @nodoc
class _$CaptureSavedCopyWithImpl<$Res> implements $CaptureSavedCopyWith<$Res> {
  _$CaptureSavedCopyWithImpl(this._self, this._then);

  final CaptureSaved _self;
  final $Res Function(CaptureSaved) _then;

  /// Create a copy of CaptureState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? wordId = null,
    Object? headword = null,
  }) {
    return _then(CaptureSaved(
      wordId: null == wordId
          ? _self.wordId
          : wordId // ignore: cast_nullable_to_non_nullable
              as int,
      headword: null == headword
          ? _self.headword
          : headword // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class CaptureRejected implements CaptureState {
  const CaptureRejected({required this.reason});

  final String reason;

  /// Create a copy of CaptureState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CaptureRejectedCopyWith<CaptureRejected> get copyWith =>
      _$CaptureRejectedCopyWithImpl<CaptureRejected>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CaptureRejected &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @override
  String toString() {
    return 'CaptureState.rejected(reason: $reason)';
  }
}

/// @nodoc
abstract mixin class $CaptureRejectedCopyWith<$Res>
    implements $CaptureStateCopyWith<$Res> {
  factory $CaptureRejectedCopyWith(
          CaptureRejected value, $Res Function(CaptureRejected) _then) =
      _$CaptureRejectedCopyWithImpl;
  @useResult
  $Res call({String reason});
}

/// @nodoc
class _$CaptureRejectedCopyWithImpl<$Res>
    implements $CaptureRejectedCopyWith<$Res> {
  _$CaptureRejectedCopyWithImpl(this._self, this._then);

  final CaptureRejected _self;
  final $Res Function(CaptureRejected) _then;

  /// Create a copy of CaptureState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reason = null,
  }) {
    return _then(CaptureRejected(
      reason: null == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
