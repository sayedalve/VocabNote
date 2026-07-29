/// features/quiz/lib/src/domain/quiz_models.dart
///
/// Pure-Dart quiz domain types (no Flutter, no Drift, no codegen).
library;

/// Question types, ported from the legacy `QUESTION_TYPES` tuple.
enum QuizQuestionType {
  meaning('meaning', 'Meaning'),
  synonym('synonym', 'Synonym'),
  antonym('antonym', 'Antonym');

  const QuizQuestionType(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static QuizQuestionType? tryParse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final type in values) {
      if (type.dbValue == value) return type;
    }
    return null;
  }
}

/// The user-facing type selector: Mixed or one specific type.
enum QuizTypeChoice {
  mixed('mixed', 'Mixed', QuizQuestionType.values),
  meaning('meaning', 'Meaning', [QuizQuestionType.meaning]),
  synonym('synonym', 'Synonym', [QuizQuestionType.synonym]),
  antonym('antonym', 'Antonym', [QuizQuestionType.antonym]);

  const QuizTypeChoice(this.dbValue, this.label, this.allowedTypes);

  final String dbValue;
  final String label;
  final List<QuizQuestionType> allowedTypes;
}

/// Question count options (legacy setup offered 10/20/30).
const List<int> kQuizCountChoices = [10, 20, 30];

/// A quiz needs at least this many usable words (legacy contract).
const int kQuizMinPoolSize = 4;

/// One word's quizzable data, extracted from the database row.
class QuizWordEntry {
  QuizWordEntry({
    required this.wordId,
    required this.word,
    required this.meaning,
    required this.synonyms,
    required this.antonyms,
  });

  final int wordId;

  /// Display form (exact casing).
  final String word;
  final String meaning;
  final List<String> synonyms;
  final List<String> antonyms;

  bool supports(QuizQuestionType type) => switch (type) {
        QuizQuestionType.meaning => meaning.isNotEmpty,
        QuizQuestionType.synonym => synonyms.isNotEmpty,
        QuizQuestionType.antonym => antonyms.isNotEmpty,
      };

  /// True when this entry can produce at least one allowed question type.
  bool usableFor(Iterable<QuizQuestionType> allowed) =>
      allowed.any(supports);
}

/// One generated multiple-choice question (exactly four options).
class QuizQuestion {
  const QuizQuestion({
    required this.wordId,
    required this.word,
    required this.type,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final int wordId;
  final String word;
  final QuizQuestionType type;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

/// A word source in the setup dropdown (legacy: All Words / Current Volume /
/// per-volume entries with counts).
class QuizSource {
  const QuizSource({
    required this.label,
    required this.notebookId,
    required this.wordCount,
  });

  /// null = all notebooks.
  final int? notebookId;
  final String label;
  final int wordCount;
}

/// A provider choice in the setup dropdown.
class QuizProviderChoice {
  const QuizProviderChoice({required this.id, required this.label});

  /// null id = the on-device generator (no API key required).
  final String? id;
  final String label;
}
