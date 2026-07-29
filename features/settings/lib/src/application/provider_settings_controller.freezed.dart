// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'provider_settings_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProviderSettingsState {
  /// The provider currently being edited (== active provider).
  ProviderConfig get config;

  /// Whether an API key is verifiably stored for this provider.
  bool get hasApiKey;

  /// Last four characters of the stored key, for "a key is stored" UI.
  String? get apiKeyHint;

  /// Which storage backend passed the round-trip self-test, or null when
  /// no backend is currently working.
  StorageBackend? get storageBackend;

  /// Create a copy of ProviderSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProviderSettingsStateCopyWith<ProviderSettingsState> get copyWith =>
      _$ProviderSettingsStateCopyWithImpl<ProviderSettingsState>(
          this as ProviderSettingsState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProviderSettingsState &&
            (identical(other.config, config) || other.config == config) &&
            (identical(other.hasApiKey, hasApiKey) ||
                other.hasApiKey == hasApiKey) &&
            (identical(other.apiKeyHint, apiKeyHint) ||
                other.apiKeyHint == apiKeyHint) &&
            (identical(other.storageBackend, storageBackend) ||
                other.storageBackend == storageBackend));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, config, hasApiKey, apiKeyHint, storageBackend);

  @override
  String toString() {
    return 'ProviderSettingsState(config: $config, hasApiKey: $hasApiKey, apiKeyHint: $apiKeyHint, storageBackend: $storageBackend)';
  }
}

/// @nodoc
abstract mixin class $ProviderSettingsStateCopyWith<$Res> {
  factory $ProviderSettingsStateCopyWith(ProviderSettingsState value,
          $Res Function(ProviderSettingsState) _then) =
      _$ProviderSettingsStateCopyWithImpl;
  @useResult
  $Res call(
      {ProviderConfig config,
      bool hasApiKey,
      String? apiKeyHint,
      StorageBackend? storageBackend});

  $ProviderConfigCopyWith<$Res> get config;
}

/// @nodoc
class _$ProviderSettingsStateCopyWithImpl<$Res>
    implements $ProviderSettingsStateCopyWith<$Res> {
  _$ProviderSettingsStateCopyWithImpl(this._self, this._then);

  final ProviderSettingsState _self;
  final $Res Function(ProviderSettingsState) _then;

  /// Create a copy of ProviderSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? config = null,
    Object? hasApiKey = null,
    Object? apiKeyHint = freezed,
    Object? storageBackend = freezed,
  }) {
    return _then(_self.copyWith(
      config: null == config
          ? _self.config
          : config // ignore: cast_nullable_to_non_nullable
              as ProviderConfig,
      hasApiKey: null == hasApiKey
          ? _self.hasApiKey
          : hasApiKey // ignore: cast_nullable_to_non_nullable
              as bool,
      apiKeyHint: freezed == apiKeyHint
          ? _self.apiKeyHint
          : apiKeyHint // ignore: cast_nullable_to_non_nullable
              as String?,
      storageBackend: freezed == storageBackend
          ? _self.storageBackend
          : storageBackend // ignore: cast_nullable_to_non_nullable
              as StorageBackend?,
    ));
  }

  /// Create a copy of ProviderSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProviderConfigCopyWith<$Res> get config {
    return $ProviderConfigCopyWith<$Res>(_self.config, (value) {
      return _then(_self.copyWith(config: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ProviderSettingsState].
extension ProviderSettingsStatePatterns on ProviderSettingsState {
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
    TResult Function(_ProviderSettingsState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProviderSettingsState() when $default != null:
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
    TResult Function(_ProviderSettingsState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProviderSettingsState():
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
    TResult? Function(_ProviderSettingsState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProviderSettingsState() when $default != null:
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
    TResult Function(ProviderConfig config, bool hasApiKey, String? apiKeyHint,
            StorageBackend? storageBackend)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProviderSettingsState() when $default != null:
        return $default(_that.config, _that.hasApiKey, _that.apiKeyHint,
            _that.storageBackend);
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
    TResult Function(ProviderConfig config, bool hasApiKey, String? apiKeyHint,
            StorageBackend? storageBackend)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProviderSettingsState():
        return $default(_that.config, _that.hasApiKey, _that.apiKeyHint,
            _that.storageBackend);
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
    TResult? Function(ProviderConfig config, bool hasApiKey, String? apiKeyHint,
            StorageBackend? storageBackend)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProviderSettingsState() when $default != null:
        return $default(_that.config, _that.hasApiKey, _that.apiKeyHint,
            _that.storageBackend);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ProviderSettingsState implements ProviderSettingsState {
  const _ProviderSettingsState(
      {required this.config,
      required this.hasApiKey,
      this.apiKeyHint,
      this.storageBackend});

  /// The provider currently being edited (== active provider).
  @override
  final ProviderConfig config;

  /// Whether an API key is verifiably stored for this provider.
  @override
  final bool hasApiKey;

  /// Last four characters of the stored key, for "a key is stored" UI.
  @override
  final String? apiKeyHint;

  /// Which storage backend passed the round-trip self-test, or null when
  /// no backend is currently working.
  @override
  final StorageBackend? storageBackend;

  /// Create a copy of ProviderSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProviderSettingsStateCopyWith<_ProviderSettingsState> get copyWith =>
      __$ProviderSettingsStateCopyWithImpl<_ProviderSettingsState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProviderSettingsState &&
            (identical(other.config, config) || other.config == config) &&
            (identical(other.hasApiKey, hasApiKey) ||
                other.hasApiKey == hasApiKey) &&
            (identical(other.apiKeyHint, apiKeyHint) ||
                other.apiKeyHint == apiKeyHint) &&
            (identical(other.storageBackend, storageBackend) ||
                other.storageBackend == storageBackend));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, config, hasApiKey, apiKeyHint, storageBackend);

  @override
  String toString() {
    return 'ProviderSettingsState(config: $config, hasApiKey: $hasApiKey, apiKeyHint: $apiKeyHint, storageBackend: $storageBackend)';
  }
}

/// @nodoc
abstract mixin class _$ProviderSettingsStateCopyWith<$Res>
    implements $ProviderSettingsStateCopyWith<$Res> {
  factory _$ProviderSettingsStateCopyWith(_ProviderSettingsState value,
          $Res Function(_ProviderSettingsState) _then) =
      __$ProviderSettingsStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {ProviderConfig config,
      bool hasApiKey,
      String? apiKeyHint,
      StorageBackend? storageBackend});

  @override
  $ProviderConfigCopyWith<$Res> get config;
}

/// @nodoc
class __$ProviderSettingsStateCopyWithImpl<$Res>
    implements _$ProviderSettingsStateCopyWith<$Res> {
  __$ProviderSettingsStateCopyWithImpl(this._self, this._then);

  final _ProviderSettingsState _self;
  final $Res Function(_ProviderSettingsState) _then;

  /// Create a copy of ProviderSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? config = null,
    Object? hasApiKey = null,
    Object? apiKeyHint = freezed,
    Object? storageBackend = freezed,
  }) {
    return _then(_ProviderSettingsState(
      config: null == config
          ? _self.config
          : config // ignore: cast_nullable_to_non_nullable
              as ProviderConfig,
      hasApiKey: null == hasApiKey
          ? _self.hasApiKey
          : hasApiKey // ignore: cast_nullable_to_non_nullable
              as bool,
      apiKeyHint: freezed == apiKeyHint
          ? _self.apiKeyHint
          : apiKeyHint // ignore: cast_nullable_to_non_nullable
              as String?,
      storageBackend: freezed == storageBackend
          ? _self.storageBackend
          : storageBackend // ignore: cast_nullable_to_non_nullable
              as StorageBackend?,
    ));
  }

  /// Create a copy of ProviderSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProviderConfigCopyWith<$Res> get config {
    return $ProviderConfigCopyWith<$Res>(_self.config, (value) {
      return _then(_self.copyWith(config: value));
    });
  }
}

// dart format on
