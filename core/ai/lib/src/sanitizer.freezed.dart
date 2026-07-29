// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sanitizer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EnrichedCard {
  String get meaning;
  String get banglaMeaning;
  String get ipa;
  String get partOfSpeech;
  String get exampleSentence;
  String get synonyms;
  String get antonyms;

  /// Create a copy of EnrichedCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EnrichedCardCopyWith<EnrichedCard> get copyWith =>
      _$EnrichedCardCopyWithImpl<EnrichedCard>(
          this as EnrichedCard, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EnrichedCard &&
            (identical(other.meaning, meaning) || other.meaning == meaning) &&
            (identical(other.banglaMeaning, banglaMeaning) ||
                other.banglaMeaning == banglaMeaning) &&
            (identical(other.ipa, ipa) || other.ipa == ipa) &&
            (identical(other.partOfSpeech, partOfSpeech) ||
                other.partOfSpeech == partOfSpeech) &&
            (identical(other.exampleSentence, exampleSentence) ||
                other.exampleSentence == exampleSentence) &&
            (identical(other.synonyms, synonyms) ||
                other.synonyms == synonyms) &&
            (identical(other.antonyms, antonyms) ||
                other.antonyms == antonyms));
  }

  @override
  int get hashCode => Object.hash(runtimeType, meaning, banglaMeaning, ipa,
      partOfSpeech, exampleSentence, synonyms, antonyms);

  @override
  String toString() {
    return 'EnrichedCard(meaning: $meaning, banglaMeaning: $banglaMeaning, ipa: $ipa, partOfSpeech: $partOfSpeech, exampleSentence: $exampleSentence, synonyms: $synonyms, antonyms: $antonyms)';
  }
}

/// @nodoc
abstract mixin class $EnrichedCardCopyWith<$Res> {
  factory $EnrichedCardCopyWith(
          EnrichedCard value, $Res Function(EnrichedCard) _then) =
      _$EnrichedCardCopyWithImpl;
  @useResult
  $Res call(
      {String meaning,
      String banglaMeaning,
      String ipa,
      String partOfSpeech,
      String exampleSentence,
      String synonyms,
      String antonyms});
}

/// @nodoc
class _$EnrichedCardCopyWithImpl<$Res> implements $EnrichedCardCopyWith<$Res> {
  _$EnrichedCardCopyWithImpl(this._self, this._then);

  final EnrichedCard _self;
  final $Res Function(EnrichedCard) _then;

  /// Create a copy of EnrichedCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? meaning = null,
    Object? banglaMeaning = null,
    Object? ipa = null,
    Object? partOfSpeech = null,
    Object? exampleSentence = null,
    Object? synonyms = null,
    Object? antonyms = null,
  }) {
    return _then(_self.copyWith(
      meaning: null == meaning
          ? _self.meaning
          : meaning // ignore: cast_nullable_to_non_nullable
              as String,
      banglaMeaning: null == banglaMeaning
          ? _self.banglaMeaning
          : banglaMeaning // ignore: cast_nullable_to_non_nullable
              as String,
      ipa: null == ipa
          ? _self.ipa
          : ipa // ignore: cast_nullable_to_non_nullable
              as String,
      partOfSpeech: null == partOfSpeech
          ? _self.partOfSpeech
          : partOfSpeech // ignore: cast_nullable_to_non_nullable
              as String,
      exampleSentence: null == exampleSentence
          ? _self.exampleSentence
          : exampleSentence // ignore: cast_nullable_to_non_nullable
              as String,
      synonyms: null == synonyms
          ? _self.synonyms
          : synonyms // ignore: cast_nullable_to_non_nullable
              as String,
      antonyms: null == antonyms
          ? _self.antonyms
          : antonyms // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [EnrichedCard].
extension EnrichedCardPatterns on EnrichedCard {
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
    TResult Function(_EnrichedCard value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EnrichedCard() when $default != null:
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
    TResult Function(_EnrichedCard value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EnrichedCard():
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
    TResult? Function(_EnrichedCard value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EnrichedCard() when $default != null:
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
    TResult Function(
            String meaning,
            String banglaMeaning,
            String ipa,
            String partOfSpeech,
            String exampleSentence,
            String synonyms,
            String antonyms)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EnrichedCard() when $default != null:
        return $default(
            _that.meaning,
            _that.banglaMeaning,
            _that.ipa,
            _that.partOfSpeech,
            _that.exampleSentence,
            _that.synonyms,
            _that.antonyms);
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
            String meaning,
            String banglaMeaning,
            String ipa,
            String partOfSpeech,
            String exampleSentence,
            String synonyms,
            String antonyms)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EnrichedCard():
        return $default(
            _that.meaning,
            _that.banglaMeaning,
            _that.ipa,
            _that.partOfSpeech,
            _that.exampleSentence,
            _that.synonyms,
            _that.antonyms);
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
    TResult? Function(
            String meaning,
            String banglaMeaning,
            String ipa,
            String partOfSpeech,
            String exampleSentence,
            String synonyms,
            String antonyms)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EnrichedCard() when $default != null:
        return $default(
            _that.meaning,
            _that.banglaMeaning,
            _that.ipa,
            _that.partOfSpeech,
            _that.exampleSentence,
            _that.synonyms,
            _that.antonyms);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _EnrichedCard implements EnrichedCard {
  const _EnrichedCard(
      {this.meaning = '',
      this.banglaMeaning = '',
      this.ipa = '',
      this.partOfSpeech = '',
      this.exampleSentence = '',
      this.synonyms = '',
      this.antonyms = ''});

  @override
  @JsonKey()
  final String meaning;
  @override
  @JsonKey()
  final String banglaMeaning;
  @override
  @JsonKey()
  final String ipa;
  @override
  @JsonKey()
  final String partOfSpeech;
  @override
  @JsonKey()
  final String exampleSentence;
  @override
  @JsonKey()
  final String synonyms;
  @override
  @JsonKey()
  final String antonyms;

  /// Create a copy of EnrichedCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EnrichedCardCopyWith<_EnrichedCard> get copyWith =>
      __$EnrichedCardCopyWithImpl<_EnrichedCard>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EnrichedCard &&
            (identical(other.meaning, meaning) || other.meaning == meaning) &&
            (identical(other.banglaMeaning, banglaMeaning) ||
                other.banglaMeaning == banglaMeaning) &&
            (identical(other.ipa, ipa) || other.ipa == ipa) &&
            (identical(other.partOfSpeech, partOfSpeech) ||
                other.partOfSpeech == partOfSpeech) &&
            (identical(other.exampleSentence, exampleSentence) ||
                other.exampleSentence == exampleSentence) &&
            (identical(other.synonyms, synonyms) ||
                other.synonyms == synonyms) &&
            (identical(other.antonyms, antonyms) ||
                other.antonyms == antonyms));
  }

  @override
  int get hashCode => Object.hash(runtimeType, meaning, banglaMeaning, ipa,
      partOfSpeech, exampleSentence, synonyms, antonyms);

  @override
  String toString() {
    return 'EnrichedCard(meaning: $meaning, banglaMeaning: $banglaMeaning, ipa: $ipa, partOfSpeech: $partOfSpeech, exampleSentence: $exampleSentence, synonyms: $synonyms, antonyms: $antonyms)';
  }
}

/// @nodoc
abstract mixin class _$EnrichedCardCopyWith<$Res>
    implements $EnrichedCardCopyWith<$Res> {
  factory _$EnrichedCardCopyWith(
          _EnrichedCard value, $Res Function(_EnrichedCard) _then) =
      __$EnrichedCardCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String meaning,
      String banglaMeaning,
      String ipa,
      String partOfSpeech,
      String exampleSentence,
      String synonyms,
      String antonyms});
}

/// @nodoc
class __$EnrichedCardCopyWithImpl<$Res>
    implements _$EnrichedCardCopyWith<$Res> {
  __$EnrichedCardCopyWithImpl(this._self, this._then);

  final _EnrichedCard _self;
  final $Res Function(_EnrichedCard) _then;

  /// Create a copy of EnrichedCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? meaning = null,
    Object? banglaMeaning = null,
    Object? ipa = null,
    Object? partOfSpeech = null,
    Object? exampleSentence = null,
    Object? synonyms = null,
    Object? antonyms = null,
  }) {
    return _then(_EnrichedCard(
      meaning: null == meaning
          ? _self.meaning
          : meaning // ignore: cast_nullable_to_non_nullable
              as String,
      banglaMeaning: null == banglaMeaning
          ? _self.banglaMeaning
          : banglaMeaning // ignore: cast_nullable_to_non_nullable
              as String,
      ipa: null == ipa
          ? _self.ipa
          : ipa // ignore: cast_nullable_to_non_nullable
              as String,
      partOfSpeech: null == partOfSpeech
          ? _self.partOfSpeech
          : partOfSpeech // ignore: cast_nullable_to_non_nullable
              as String,
      exampleSentence: null == exampleSentence
          ? _self.exampleSentence
          : exampleSentence // ignore: cast_nullable_to_non_nullable
              as String,
      synonyms: null == synonyms
          ? _self.synonyms
          : synonyms // ignore: cast_nullable_to_non_nullable
              as String,
      antonyms: null == antonyms
          ? _self.antonyms
          : antonyms // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
