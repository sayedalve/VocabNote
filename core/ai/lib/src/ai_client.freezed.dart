// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_client.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiRequest {
  String get prompt;
  String? get system;
  double get temperature;
  Duration get timeout;

  /// Create a copy of AiRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AiRequestCopyWith<AiRequest> get copyWith =>
      _$AiRequestCopyWithImpl<AiRequest>(this as AiRequest, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AiRequest &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature) &&
            (identical(other.timeout, timeout) || other.timeout == timeout));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, prompt, system, temperature, timeout);

  @override
  String toString() {
    return 'AiRequest(prompt: $prompt, system: $system, temperature: $temperature, timeout: $timeout)';
  }
}

/// @nodoc
abstract mixin class $AiRequestCopyWith<$Res> {
  factory $AiRequestCopyWith(AiRequest value, $Res Function(AiRequest) _then) =
      _$AiRequestCopyWithImpl;
  @useResult
  $Res call(
      {String prompt, String? system, double temperature, Duration timeout});
}

/// @nodoc
class _$AiRequestCopyWithImpl<$Res> implements $AiRequestCopyWith<$Res> {
  _$AiRequestCopyWithImpl(this._self, this._then);

  final AiRequest _self;
  final $Res Function(AiRequest) _then;

  /// Create a copy of AiRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompt = null,
    Object? system = freezed,
    Object? temperature = null,
    Object? timeout = null,
  }) {
    return _then(_self.copyWith(
      prompt: null == prompt
          ? _self.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
      system: freezed == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String?,
      temperature: null == temperature
          ? _self.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
      timeout: null == timeout
          ? _self.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

/// Adds pattern-matching-related methods to [AiRequest].
extension AiRequestPatterns on AiRequest {
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
    TResult Function(_AiRequest value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiRequest() when $default != null:
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
    TResult Function(_AiRequest value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRequest():
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
    TResult? Function(_AiRequest value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRequest() when $default != null:
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
    TResult Function(String prompt, String? system, double temperature,
            Duration timeout)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiRequest() when $default != null:
        return $default(
            _that.prompt, _that.system, _that.temperature, _that.timeout);
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
    TResult Function(
            String prompt, String? system, double temperature, Duration timeout)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRequest():
        return $default(
            _that.prompt, _that.system, _that.temperature, _that.timeout);
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
    TResult? Function(String prompt, String? system, double temperature,
            Duration timeout)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRequest() when $default != null:
        return $default(
            _that.prompt, _that.system, _that.temperature, _that.timeout);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AiRequest implements AiRequest {
  const _AiRequest(
      {required this.prompt,
      this.system,
      this.temperature = 0.4,
      this.timeout = const Duration(seconds: 15)});

  @override
  final String prompt;
  @override
  final String? system;
  @override
  @JsonKey()
  final double temperature;
  @override
  @JsonKey()
  final Duration timeout;

  /// Create a copy of AiRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AiRequestCopyWith<_AiRequest> get copyWith =>
      __$AiRequestCopyWithImpl<_AiRequest>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AiRequest &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature) &&
            (identical(other.timeout, timeout) || other.timeout == timeout));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, prompt, system, temperature, timeout);

  @override
  String toString() {
    return 'AiRequest(prompt: $prompt, system: $system, temperature: $temperature, timeout: $timeout)';
  }
}

/// @nodoc
abstract mixin class _$AiRequestCopyWith<$Res>
    implements $AiRequestCopyWith<$Res> {
  factory _$AiRequestCopyWith(
          _AiRequest value, $Res Function(_AiRequest) _then) =
      __$AiRequestCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String prompt, String? system, double temperature, Duration timeout});
}

/// @nodoc
class __$AiRequestCopyWithImpl<$Res> implements _$AiRequestCopyWith<$Res> {
  __$AiRequestCopyWithImpl(this._self, this._then);

  final _AiRequest _self;
  final $Res Function(_AiRequest) _then;

  /// Create a copy of AiRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? prompt = null,
    Object? system = freezed,
    Object? temperature = null,
    Object? timeout = null,
  }) {
    return _then(_AiRequest(
      prompt: null == prompt
          ? _self.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
      system: freezed == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String?,
      temperature: null == temperature
          ? _self.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
      timeout: null == timeout
          ? _self.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

// dart format on
