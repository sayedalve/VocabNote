// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'word.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Word {
  int get id;
  int get notebookId;

  /// Normalized lookup key (lowercase).
  String get headwordNorm;

  /// Display form preserving the user's casing.
  String get headword;
  String get partOfSpeech;
  String get ipa;
  String get meaning;

  /// Bangla translation of [meaning] (legacy `bangla_meaning`). Attached
  /// in batch by the repository so list rows can always show it.
  String get banglaMeaning;
  String get exampleSentence;
  String get synonyms;
  String get antonyms;

  /// Curated subset of [synonyms] worth highlighting, carried over from
  /// legacy imports and CSV/JSON transfer. Comma-separated, same format
  /// as [synonyms].
  String get importantSynonyms;

  /// Curated subset of [antonyms] worth highlighting. Comma-separated,
  /// same format as [antonyms].
  String get importantAntonyms;
  String get notes;
  bool get isFavorite;
  DateTime get createdAt;
  DateTime get updatedAt;

  /// Create a copy of Word
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WordCopyWith<Word> get copyWith =>
      _$WordCopyWithImpl<Word>(this as Word, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Word &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.notebookId, notebookId) ||
                other.notebookId == notebookId) &&
            (identical(other.headwordNorm, headwordNorm) ||
                other.headwordNorm == headwordNorm) &&
            (identical(other.headword, headword) ||
                other.headword == headword) &&
            (identical(other.partOfSpeech, partOfSpeech) ||
                other.partOfSpeech == partOfSpeech) &&
            (identical(other.ipa, ipa) || other.ipa == ipa) &&
            (identical(other.meaning, meaning) || other.meaning == meaning) &&
            (identical(other.banglaMeaning, banglaMeaning) ||
                other.banglaMeaning == banglaMeaning) &&
            (identical(other.exampleSentence, exampleSentence) ||
                other.exampleSentence == exampleSentence) &&
            (identical(other.synonyms, synonyms) ||
                other.synonyms == synonyms) &&
            (identical(other.antonyms, antonyms) ||
                other.antonyms == antonyms) &&
            (identical(other.importantSynonyms, importantSynonyms) ||
                other.importantSynonyms == importantSynonyms) &&
            (identical(other.importantAntonyms, importantAntonyms) ||
                other.importantAntonyms == importantAntonyms) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      notebookId,
      headwordNorm,
      headword,
      partOfSpeech,
      ipa,
      meaning,
      banglaMeaning,
      exampleSentence,
      synonyms,
      antonyms,
      importantSynonyms,
      importantAntonyms,
      notes,
      isFavorite,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Word(id: $id, notebookId: $notebookId, headwordNorm: $headwordNorm, headword: $headword, partOfSpeech: $partOfSpeech, ipa: $ipa, meaning: $meaning, banglaMeaning: $banglaMeaning, exampleSentence: $exampleSentence, synonyms: $synonyms, antonyms: $antonyms, importantSynonyms: $importantSynonyms, importantAntonyms: $importantAntonyms, notes: $notes, isFavorite: $isFavorite, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $WordCopyWith<$Res> {
  factory $WordCopyWith(Word value, $Res Function(Word) _then) =
      _$WordCopyWithImpl;
  @useResult
  $Res call(
      {int id,
      int notebookId,
      String headwordNorm,
      String headword,
      String partOfSpeech,
      String ipa,
      String meaning,
      String banglaMeaning,
      String exampleSentence,
      String synonyms,
      String antonyms,
      String importantSynonyms,
      String importantAntonyms,
      String notes,
      bool isFavorite,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$WordCopyWithImpl<$Res> implements $WordCopyWith<$Res> {
  _$WordCopyWithImpl(this._self, this._then);

  final Word _self;
  final $Res Function(Word) _then;

  /// Create a copy of Word
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? notebookId = null,
    Object? headwordNorm = null,
    Object? headword = null,
    Object? partOfSpeech = null,
    Object? ipa = null,
    Object? meaning = null,
    Object? banglaMeaning = null,
    Object? exampleSentence = null,
    Object? synonyms = null,
    Object? antonyms = null,
    Object? importantSynonyms = null,
    Object? importantAntonyms = null,
    Object? notes = null,
    Object? isFavorite = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      notebookId: null == notebookId
          ? _self.notebookId
          : notebookId // ignore: cast_nullable_to_non_nullable
              as int,
      headwordNorm: null == headwordNorm
          ? _self.headwordNorm
          : headwordNorm // ignore: cast_nullable_to_non_nullable
              as String,
      headword: null == headword
          ? _self.headword
          : headword // ignore: cast_nullable_to_non_nullable
              as String,
      partOfSpeech: null == partOfSpeech
          ? _self.partOfSpeech
          : partOfSpeech // ignore: cast_nullable_to_non_nullable
              as String,
      ipa: null == ipa
          ? _self.ipa
          : ipa // ignore: cast_nullable_to_non_nullable
              as String,
      meaning: null == meaning
          ? _self.meaning
          : meaning // ignore: cast_nullable_to_non_nullable
              as String,
      banglaMeaning: null == banglaMeaning
          ? _self.banglaMeaning
          : banglaMeaning // ignore: cast_nullable_to_non_nullable
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
      importantSynonyms: null == importantSynonyms
          ? _self.importantSynonyms
          : importantSynonyms // ignore: cast_nullable_to_non_nullable
              as String,
      importantAntonyms: null == importantAntonyms
          ? _self.importantAntonyms
          : importantAntonyms // ignore: cast_nullable_to_non_nullable
              as String,
      notes: null == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _self.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [Word].
extension WordPatterns on Word {
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
    TResult Function(_Word value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Word() when $default != null:
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
    TResult Function(_Word value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Word():
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
    TResult? Function(_Word value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Word() when $default != null:
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
            int id,
            int notebookId,
            String headwordNorm,
            String headword,
            String partOfSpeech,
            String ipa,
            String meaning,
            String banglaMeaning,
            String exampleSentence,
            String synonyms,
            String antonyms,
            String importantSynonyms,
            String importantAntonyms,
            String notes,
            bool isFavorite,
            DateTime createdAt,
            DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Word() when $default != null:
        return $default(
            _that.id,
            _that.notebookId,
            _that.headwordNorm,
            _that.headword,
            _that.partOfSpeech,
            _that.ipa,
            _that.meaning,
            _that.banglaMeaning,
            _that.exampleSentence,
            _that.synonyms,
            _that.antonyms,
            _that.importantSynonyms,
            _that.importantAntonyms,
            _that.notes,
            _that.isFavorite,
            _that.createdAt,
            _that.updatedAt);
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
            int id,
            int notebookId,
            String headwordNorm,
            String headword,
            String partOfSpeech,
            String ipa,
            String meaning,
            String banglaMeaning,
            String exampleSentence,
            String synonyms,
            String antonyms,
            String importantSynonyms,
            String importantAntonyms,
            String notes,
            bool isFavorite,
            DateTime createdAt,
            DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Word():
        return $default(
            _that.id,
            _that.notebookId,
            _that.headwordNorm,
            _that.headword,
            _that.partOfSpeech,
            _that.ipa,
            _that.meaning,
            _that.banglaMeaning,
            _that.exampleSentence,
            _that.synonyms,
            _that.antonyms,
            _that.importantSynonyms,
            _that.importantAntonyms,
            _that.notes,
            _that.isFavorite,
            _that.createdAt,
            _that.updatedAt);
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
            int id,
            int notebookId,
            String headwordNorm,
            String headword,
            String partOfSpeech,
            String ipa,
            String meaning,
            String banglaMeaning,
            String exampleSentence,
            String synonyms,
            String antonyms,
            String importantSynonyms,
            String importantAntonyms,
            String notes,
            bool isFavorite,
            DateTime createdAt,
            DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Word() when $default != null:
        return $default(
            _that.id,
            _that.notebookId,
            _that.headwordNorm,
            _that.headword,
            _that.partOfSpeech,
            _that.ipa,
            _that.meaning,
            _that.banglaMeaning,
            _that.exampleSentence,
            _that.synonyms,
            _that.antonyms,
            _that.importantSynonyms,
            _that.importantAntonyms,
            _that.notes,
            _that.isFavorite,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Word extends Word {
  const _Word(
      {required this.id,
      required this.notebookId,
      required this.headwordNorm,
      required this.headword,
      this.partOfSpeech = '',
      this.ipa = '',
      this.meaning = '',
      this.banglaMeaning = '',
      this.exampleSentence = '',
      this.synonyms = '',
      this.antonyms = '',
      this.importantSynonyms = '',
      this.importantAntonyms = '',
      this.notes = '',
      this.isFavorite = false,
      required this.createdAt,
      required this.updatedAt})
      : super._();

  @override
  final int id;
  @override
  final int notebookId;

  /// Normalized lookup key (lowercase).
  @override
  final String headwordNorm;

  /// Display form preserving the user's casing.
  @override
  final String headword;
  @override
  @JsonKey()
  final String partOfSpeech;
  @override
  @JsonKey()
  final String ipa;
  @override
  @JsonKey()
  final String meaning;

  /// Bangla translation of [meaning] (legacy `bangla_meaning`). Attached
  /// in batch by the repository so list rows can always show it.
  @override
  @JsonKey()
  final String banglaMeaning;
  @override
  @JsonKey()
  final String exampleSentence;
  @override
  @JsonKey()
  final String synonyms;
  @override
  @JsonKey()
  final String antonyms;

  /// Curated subset of [synonyms] worth highlighting, carried over from
  /// legacy imports and CSV/JSON transfer. Comma-separated, same format
  /// as [synonyms].
  @override
  @JsonKey()
  final String importantSynonyms;

  /// Curated subset of [antonyms] worth highlighting. Comma-separated,
  /// same format as [antonyms].
  @override
  @JsonKey()
  final String importantAntonyms;
  @override
  @JsonKey()
  final String notes;
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  /// Create a copy of Word
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WordCopyWith<_Word> get copyWith =>
      __$WordCopyWithImpl<_Word>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Word &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.notebookId, notebookId) ||
                other.notebookId == notebookId) &&
            (identical(other.headwordNorm, headwordNorm) ||
                other.headwordNorm == headwordNorm) &&
            (identical(other.headword, headword) ||
                other.headword == headword) &&
            (identical(other.partOfSpeech, partOfSpeech) ||
                other.partOfSpeech == partOfSpeech) &&
            (identical(other.ipa, ipa) || other.ipa == ipa) &&
            (identical(other.meaning, meaning) || other.meaning == meaning) &&
            (identical(other.banglaMeaning, banglaMeaning) ||
                other.banglaMeaning == banglaMeaning) &&
            (identical(other.exampleSentence, exampleSentence) ||
                other.exampleSentence == exampleSentence) &&
            (identical(other.synonyms, synonyms) ||
                other.synonyms == synonyms) &&
            (identical(other.antonyms, antonyms) ||
                other.antonyms == antonyms) &&
            (identical(other.importantSynonyms, importantSynonyms) ||
                other.importantSynonyms == importantSynonyms) &&
            (identical(other.importantAntonyms, importantAntonyms) ||
                other.importantAntonyms == importantAntonyms) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      notebookId,
      headwordNorm,
      headword,
      partOfSpeech,
      ipa,
      meaning,
      banglaMeaning,
      exampleSentence,
      synonyms,
      antonyms,
      importantSynonyms,
      importantAntonyms,
      notes,
      isFavorite,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Word(id: $id, notebookId: $notebookId, headwordNorm: $headwordNorm, headword: $headword, partOfSpeech: $partOfSpeech, ipa: $ipa, meaning: $meaning, banglaMeaning: $banglaMeaning, exampleSentence: $exampleSentence, synonyms: $synonyms, antonyms: $antonyms, importantSynonyms: $importantSynonyms, importantAntonyms: $importantAntonyms, notes: $notes, isFavorite: $isFavorite, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$WordCopyWith<$Res> implements $WordCopyWith<$Res> {
  factory _$WordCopyWith(_Word value, $Res Function(_Word) _then) =
      __$WordCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int id,
      int notebookId,
      String headwordNorm,
      String headword,
      String partOfSpeech,
      String ipa,
      String meaning,
      String banglaMeaning,
      String exampleSentence,
      String synonyms,
      String antonyms,
      String importantSynonyms,
      String importantAntonyms,
      String notes,
      bool isFavorite,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$WordCopyWithImpl<$Res> implements _$WordCopyWith<$Res> {
  __$WordCopyWithImpl(this._self, this._then);

  final _Word _self;
  final $Res Function(_Word) _then;

  /// Create a copy of Word
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? notebookId = null,
    Object? headwordNorm = null,
    Object? headword = null,
    Object? partOfSpeech = null,
    Object? ipa = null,
    Object? meaning = null,
    Object? banglaMeaning = null,
    Object? exampleSentence = null,
    Object? synonyms = null,
    Object? antonyms = null,
    Object? importantSynonyms = null,
    Object? importantAntonyms = null,
    Object? notes = null,
    Object? isFavorite = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_Word(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      notebookId: null == notebookId
          ? _self.notebookId
          : notebookId // ignore: cast_nullable_to_non_nullable
              as int,
      headwordNorm: null == headwordNorm
          ? _self.headwordNorm
          : headwordNorm // ignore: cast_nullable_to_non_nullable
              as String,
      headword: null == headword
          ? _self.headword
          : headword // ignore: cast_nullable_to_non_nullable
              as String,
      partOfSpeech: null == partOfSpeech
          ? _self.partOfSpeech
          : partOfSpeech // ignore: cast_nullable_to_non_nullable
              as String,
      ipa: null == ipa
          ? _self.ipa
          : ipa // ignore: cast_nullable_to_non_nullable
              as String,
      meaning: null == meaning
          ? _self.meaning
          : meaning // ignore: cast_nullable_to_non_nullable
              as String,
      banglaMeaning: null == banglaMeaning
          ? _self.banglaMeaning
          : banglaMeaning // ignore: cast_nullable_to_non_nullable
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
      importantSynonyms: null == importantSynonyms
          ? _self.importantSynonyms
          : importantSynonyms // ignore: cast_nullable_to_non_nullable
              as String,
      importantAntonyms: null == importantAntonyms
          ? _self.importantAntonyms
          : importantAntonyms // ignore: cast_nullable_to_non_nullable
              as String,
      notes: null == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _self.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
mixin _$WordFieldPatch {
  String? get headwordDisplay;
  String? get partOfSpeech;
  String? get ipa;
  String? get meaning;
  String? get exampleSentence;
  String? get synonyms;
  String? get antonyms;
  String? get importantSynonyms;
  String? get importantAntonyms;
  String? get notes;

  /// Create a copy of WordFieldPatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WordFieldPatchCopyWith<WordFieldPatch> get copyWith =>
      _$WordFieldPatchCopyWithImpl<WordFieldPatch>(
          this as WordFieldPatch, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WordFieldPatch &&
            (identical(other.headwordDisplay, headwordDisplay) ||
                other.headwordDisplay == headwordDisplay) &&
            (identical(other.partOfSpeech, partOfSpeech) ||
                other.partOfSpeech == partOfSpeech) &&
            (identical(other.ipa, ipa) || other.ipa == ipa) &&
            (identical(other.meaning, meaning) || other.meaning == meaning) &&
            (identical(other.exampleSentence, exampleSentence) ||
                other.exampleSentence == exampleSentence) &&
            (identical(other.synonyms, synonyms) ||
                other.synonyms == synonyms) &&
            (identical(other.antonyms, antonyms) ||
                other.antonyms == antonyms) &&
            (identical(other.importantSynonyms, importantSynonyms) ||
                other.importantSynonyms == importantSynonyms) &&
            (identical(other.importantAntonyms, importantAntonyms) ||
                other.importantAntonyms == importantAntonyms) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      headwordDisplay,
      partOfSpeech,
      ipa,
      meaning,
      exampleSentence,
      synonyms,
      antonyms,
      importantSynonyms,
      importantAntonyms,
      notes);

  @override
  String toString() {
    return 'WordFieldPatch(headwordDisplay: $headwordDisplay, partOfSpeech: $partOfSpeech, ipa: $ipa, meaning: $meaning, exampleSentence: $exampleSentence, synonyms: $synonyms, antonyms: $antonyms, importantSynonyms: $importantSynonyms, importantAntonyms: $importantAntonyms, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $WordFieldPatchCopyWith<$Res> {
  factory $WordFieldPatchCopyWith(
          WordFieldPatch value, $Res Function(WordFieldPatch) _then) =
      _$WordFieldPatchCopyWithImpl;
  @useResult
  $Res call(
      {String? headwordDisplay,
      String? partOfSpeech,
      String? ipa,
      String? meaning,
      String? exampleSentence,
      String? synonyms,
      String? antonyms,
      String? importantSynonyms,
      String? importantAntonyms,
      String? notes});
}

/// @nodoc
class _$WordFieldPatchCopyWithImpl<$Res>
    implements $WordFieldPatchCopyWith<$Res> {
  _$WordFieldPatchCopyWithImpl(this._self, this._then);

  final WordFieldPatch _self;
  final $Res Function(WordFieldPatch) _then;

  /// Create a copy of WordFieldPatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? headwordDisplay = freezed,
    Object? partOfSpeech = freezed,
    Object? ipa = freezed,
    Object? meaning = freezed,
    Object? exampleSentence = freezed,
    Object? synonyms = freezed,
    Object? antonyms = freezed,
    Object? importantSynonyms = freezed,
    Object? importantAntonyms = freezed,
    Object? notes = freezed,
  }) {
    return _then(_self.copyWith(
      headwordDisplay: freezed == headwordDisplay
          ? _self.headwordDisplay
          : headwordDisplay // ignore: cast_nullable_to_non_nullable
              as String?,
      partOfSpeech: freezed == partOfSpeech
          ? _self.partOfSpeech
          : partOfSpeech // ignore: cast_nullable_to_non_nullable
              as String?,
      ipa: freezed == ipa
          ? _self.ipa
          : ipa // ignore: cast_nullable_to_non_nullable
              as String?,
      meaning: freezed == meaning
          ? _self.meaning
          : meaning // ignore: cast_nullable_to_non_nullable
              as String?,
      exampleSentence: freezed == exampleSentence
          ? _self.exampleSentence
          : exampleSentence // ignore: cast_nullable_to_non_nullable
              as String?,
      synonyms: freezed == synonyms
          ? _self.synonyms
          : synonyms // ignore: cast_nullable_to_non_nullable
              as String?,
      antonyms: freezed == antonyms
          ? _self.antonyms
          : antonyms // ignore: cast_nullable_to_non_nullable
              as String?,
      importantSynonyms: freezed == importantSynonyms
          ? _self.importantSynonyms
          : importantSynonyms // ignore: cast_nullable_to_non_nullable
              as String?,
      importantAntonyms: freezed == importantAntonyms
          ? _self.importantAntonyms
          : importantAntonyms // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [WordFieldPatch].
extension WordFieldPatchPatterns on WordFieldPatch {
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
    TResult Function(_WordFieldPatch value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordFieldPatch() when $default != null:
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
    TResult Function(_WordFieldPatch value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordFieldPatch():
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
    TResult? Function(_WordFieldPatch value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordFieldPatch() when $default != null:
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
            String? headwordDisplay,
            String? partOfSpeech,
            String? ipa,
            String? meaning,
            String? exampleSentence,
            String? synonyms,
            String? antonyms,
            String? importantSynonyms,
            String? importantAntonyms,
            String? notes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WordFieldPatch() when $default != null:
        return $default(
            _that.headwordDisplay,
            _that.partOfSpeech,
            _that.ipa,
            _that.meaning,
            _that.exampleSentence,
            _that.synonyms,
            _that.antonyms,
            _that.importantSynonyms,
            _that.importantAntonyms,
            _that.notes);
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
            String? headwordDisplay,
            String? partOfSpeech,
            String? ipa,
            String? meaning,
            String? exampleSentence,
            String? synonyms,
            String? antonyms,
            String? importantSynonyms,
            String? importantAntonyms,
            String? notes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordFieldPatch():
        return $default(
            _that.headwordDisplay,
            _that.partOfSpeech,
            _that.ipa,
            _that.meaning,
            _that.exampleSentence,
            _that.synonyms,
            _that.antonyms,
            _that.importantSynonyms,
            _that.importantAntonyms,
            _that.notes);
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
            String? headwordDisplay,
            String? partOfSpeech,
            String? ipa,
            String? meaning,
            String? exampleSentence,
            String? synonyms,
            String? antonyms,
            String? importantSynonyms,
            String? importantAntonyms,
            String? notes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WordFieldPatch() when $default != null:
        return $default(
            _that.headwordDisplay,
            _that.partOfSpeech,
            _that.ipa,
            _that.meaning,
            _that.exampleSentence,
            _that.synonyms,
            _that.antonyms,
            _that.importantSynonyms,
            _that.importantAntonyms,
            _that.notes);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _WordFieldPatch implements WordFieldPatch {
  const _WordFieldPatch(
      {this.headwordDisplay,
      this.partOfSpeech,
      this.ipa,
      this.meaning,
      this.exampleSentence,
      this.synonyms,
      this.antonyms,
      this.importantSynonyms,
      this.importantAntonyms,
      this.notes});

  @override
  final String? headwordDisplay;
  @override
  final String? partOfSpeech;
  @override
  final String? ipa;
  @override
  final String? meaning;
  @override
  final String? exampleSentence;
  @override
  final String? synonyms;
  @override
  final String? antonyms;
  @override
  final String? importantSynonyms;
  @override
  final String? importantAntonyms;
  @override
  final String? notes;

  /// Create a copy of WordFieldPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WordFieldPatchCopyWith<_WordFieldPatch> get copyWith =>
      __$WordFieldPatchCopyWithImpl<_WordFieldPatch>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WordFieldPatch &&
            (identical(other.headwordDisplay, headwordDisplay) ||
                other.headwordDisplay == headwordDisplay) &&
            (identical(other.partOfSpeech, partOfSpeech) ||
                other.partOfSpeech == partOfSpeech) &&
            (identical(other.ipa, ipa) || other.ipa == ipa) &&
            (identical(other.meaning, meaning) || other.meaning == meaning) &&
            (identical(other.exampleSentence, exampleSentence) ||
                other.exampleSentence == exampleSentence) &&
            (identical(other.synonyms, synonyms) ||
                other.synonyms == synonyms) &&
            (identical(other.antonyms, antonyms) ||
                other.antonyms == antonyms) &&
            (identical(other.importantSynonyms, importantSynonyms) ||
                other.importantSynonyms == importantSynonyms) &&
            (identical(other.importantAntonyms, importantAntonyms) ||
                other.importantAntonyms == importantAntonyms) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      headwordDisplay,
      partOfSpeech,
      ipa,
      meaning,
      exampleSentence,
      synonyms,
      antonyms,
      importantSynonyms,
      importantAntonyms,
      notes);

  @override
  String toString() {
    return 'WordFieldPatch(headwordDisplay: $headwordDisplay, partOfSpeech: $partOfSpeech, ipa: $ipa, meaning: $meaning, exampleSentence: $exampleSentence, synonyms: $synonyms, antonyms: $antonyms, importantSynonyms: $importantSynonyms, importantAntonyms: $importantAntonyms, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class _$WordFieldPatchCopyWith<$Res>
    implements $WordFieldPatchCopyWith<$Res> {
  factory _$WordFieldPatchCopyWith(
          _WordFieldPatch value, $Res Function(_WordFieldPatch) _then) =
      __$WordFieldPatchCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? headwordDisplay,
      String? partOfSpeech,
      String? ipa,
      String? meaning,
      String? exampleSentence,
      String? synonyms,
      String? antonyms,
      String? importantSynonyms,
      String? importantAntonyms,
      String? notes});
}

/// @nodoc
class __$WordFieldPatchCopyWithImpl<$Res>
    implements _$WordFieldPatchCopyWith<$Res> {
  __$WordFieldPatchCopyWithImpl(this._self, this._then);

  final _WordFieldPatch _self;
  final $Res Function(_WordFieldPatch) _then;

  /// Create a copy of WordFieldPatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? headwordDisplay = freezed,
    Object? partOfSpeech = freezed,
    Object? ipa = freezed,
    Object? meaning = freezed,
    Object? exampleSentence = freezed,
    Object? synonyms = freezed,
    Object? antonyms = freezed,
    Object? importantSynonyms = freezed,
    Object? importantAntonyms = freezed,
    Object? notes = freezed,
  }) {
    return _then(_WordFieldPatch(
      headwordDisplay: freezed == headwordDisplay
          ? _self.headwordDisplay
          : headwordDisplay // ignore: cast_nullable_to_non_nullable
              as String?,
      partOfSpeech: freezed == partOfSpeech
          ? _self.partOfSpeech
          : partOfSpeech // ignore: cast_nullable_to_non_nullable
              as String?,
      ipa: freezed == ipa
          ? _self.ipa
          : ipa // ignore: cast_nullable_to_non_nullable
              as String?,
      meaning: freezed == meaning
          ? _self.meaning
          : meaning // ignore: cast_nullable_to_non_nullable
              as String?,
      exampleSentence: freezed == exampleSentence
          ? _self.exampleSentence
          : exampleSentence // ignore: cast_nullable_to_non_nullable
              as String?,
      synonyms: freezed == synonyms
          ? _self.synonyms
          : synonyms // ignore: cast_nullable_to_non_nullable
              as String?,
      antonyms: freezed == antonyms
          ? _self.antonyms
          : antonyms // ignore: cast_nullable_to_non_nullable
              as String?,
      importantSynonyms: freezed == importantSynonyms
          ? _self.importantSynonyms
          : importantSynonyms // ignore: cast_nullable_to_non_nullable
              as String?,
      importantAntonyms: freezed == importantAntonyms
          ? _self.importantAntonyms
          : importantAntonyms // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
