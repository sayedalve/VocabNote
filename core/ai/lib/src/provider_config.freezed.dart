// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'provider_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProviderConfig {
  /// Stable identifier used as the secure-storage key suffix.
  String get id;

  /// Human-readable label shown in Settings.
  String get label;
  ProviderKind get kind;
  String get baseUrl;
  String get model;

  /// Create a copy of ProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProviderConfigCopyWith<ProviderConfig> get copyWith =>
      _$ProviderConfigCopyWithImpl<ProviderConfig>(
          this as ProviderConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProviderConfig &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl) &&
            (identical(other.model, model) || other.model == model));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, label, kind, baseUrl, model);

  @override
  String toString() {
    return 'ProviderConfig(id: $id, label: $label, kind: $kind, baseUrl: $baseUrl, model: $model)';
  }
}

/// @nodoc
abstract mixin class $ProviderConfigCopyWith<$Res> {
  factory $ProviderConfigCopyWith(
          ProviderConfig value, $Res Function(ProviderConfig) _then) =
      _$ProviderConfigCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String label,
      ProviderKind kind,
      String baseUrl,
      String model});
}

/// @nodoc
class _$ProviderConfigCopyWithImpl<$Res>
    implements $ProviderConfigCopyWith<$Res> {
  _$ProviderConfigCopyWithImpl(this._self, this._then);

  final ProviderConfig _self;
  final $Res Function(ProviderConfig) _then;

  /// Create a copy of ProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? kind = null,
    Object? baseUrl = null,
    Object? model = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as ProviderKind,
      baseUrl: null == baseUrl
          ? _self.baseUrl
          : baseUrl // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProviderConfig].
extension ProviderConfigPatterns on ProviderConfig {
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
    TResult Function(_ProviderConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProviderConfig() when $default != null:
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
    TResult Function(_ProviderConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProviderConfig():
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
    TResult? Function(_ProviderConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProviderConfig() when $default != null:
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
    TResult Function(String id, String label, ProviderKind kind, String baseUrl,
            String model)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProviderConfig() when $default != null:
        return $default(
            _that.id, _that.label, _that.kind, _that.baseUrl, _that.model);
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
    TResult Function(String id, String label, ProviderKind kind, String baseUrl,
            String model)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProviderConfig():
        return $default(
            _that.id, _that.label, _that.kind, _that.baseUrl, _that.model);
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
    TResult? Function(String id, String label, ProviderKind kind,
            String baseUrl, String model)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProviderConfig() when $default != null:
        return $default(
            _that.id, _that.label, _that.kind, _that.baseUrl, _that.model);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ProviderConfig implements ProviderConfig {
  const _ProviderConfig(
      {required this.id,
      required this.label,
      required this.kind,
      required this.baseUrl,
      required this.model});

  /// Stable identifier used as the secure-storage key suffix.
  @override
  final String id;

  /// Human-readable label shown in Settings.
  @override
  final String label;
  @override
  final ProviderKind kind;
  @override
  final String baseUrl;
  @override
  final String model;

  /// Create a copy of ProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProviderConfigCopyWith<_ProviderConfig> get copyWith =>
      __$ProviderConfigCopyWithImpl<_ProviderConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProviderConfig &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl) &&
            (identical(other.model, model) || other.model == model));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, label, kind, baseUrl, model);

  @override
  String toString() {
    return 'ProviderConfig(id: $id, label: $label, kind: $kind, baseUrl: $baseUrl, model: $model)';
  }
}

/// @nodoc
abstract mixin class _$ProviderConfigCopyWith<$Res>
    implements $ProviderConfigCopyWith<$Res> {
  factory _$ProviderConfigCopyWith(
          _ProviderConfig value, $Res Function(_ProviderConfig) _then) =
      __$ProviderConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      ProviderKind kind,
      String baseUrl,
      String model});
}

/// @nodoc
class __$ProviderConfigCopyWithImpl<$Res>
    implements _$ProviderConfigCopyWith<$Res> {
  __$ProviderConfigCopyWithImpl(this._self, this._then);

  final _ProviderConfig _self;
  final $Res Function(_ProviderConfig) _then;

  /// Create a copy of ProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? kind = null,
    Object? baseUrl = null,
    Object? model = null,
  }) {
    return _then(_ProviderConfig(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as ProviderKind,
      baseUrl: null == baseUrl
          ? _self.baseUrl
          : baseUrl // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
