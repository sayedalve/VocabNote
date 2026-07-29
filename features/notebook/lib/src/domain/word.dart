/// features/notebook/lib/src/domain/word.dart
///
/// Domain entity. Pure Dart — no Drift, no Flutter. The data layer maps
/// `WordRow` into this type; controllers and widgets only ever see [Word].
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'word.freezed.dart';

@freezed
abstract class Word with _$Word {
  const factory Word({
    required int id,
    required int notebookId,

    /// Normalized lookup key (lowercase).
    required String headwordNorm,

    /// Display form preserving the user's casing.
    required String headword,
    @Default('') String partOfSpeech,
    @Default('') String ipa,
    @Default('') String meaning,

    /// Bangla translation of [meaning] (legacy `bangla_meaning`). Attached
    /// in batch by the repository so list rows can always show it.
    @Default('') String banglaMeaning,
    @Default('') String exampleSentence,
    @Default('') String synonyms,
    @Default('') String antonyms,

    /// Curated subset of [synonyms] worth highlighting, carried over from
    /// legacy imports and CSV/JSON transfer. Comma-separated, same format
    /// as [synonyms].
    @Default('') String importantSynonyms,

    /// Curated subset of [antonyms] worth highlighting. Comma-separated,
    /// same format as [antonyms].
    @Default('') String importantAntonyms,
    @Default('') String notes,
    @Default(false) bool isFavorite,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Word;

  const Word._();

  /// A word is "enriched" once the AI pipeline has filled its card.
  bool get isEnriched => meaning.isNotEmpty;

  List<String> get synonymList => _splitCsv(synonyms);

  List<String> get antonymList => _splitCsv(antonyms);

  List<String> get importantSynonymList => _splitCsv(importantSynonyms);

  List<String> get importantAntonymList => _splitCsv(importantAntonyms);

  static List<String> _splitCsv(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

/// Partial update for editable card fields; `null` means "leave unchanged".
@freezed
abstract class WordFieldPatch with _$WordFieldPatch {
  const factory WordFieldPatch({
    String? headwordDisplay,
    String? partOfSpeech,
    String? ipa,
    String? meaning,
    String? exampleSentence,
    String? synonyms,
    String? antonyms,
    String? importantSynonyms,
    String? importantAntonyms,
    String? notes,
  }) = _WordFieldPatch;
}
