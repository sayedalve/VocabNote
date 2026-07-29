/// core/db/lib/src/tables.dart
///
/// Schema v6/v7 — the Flutter-native schema. Design decisions ported from
/// the legacy Python schema (v5) with the agreed fixes:
///  * Words get a surrogate `id`; the normalized headword is a UNIQUE key
///    scoped per notebook, not global identity.
///  * `bangla_meaning` becomes a row in `word_translations` (lang code `bn`).
///  * Tags are relational instead of comma-joined strings.
///  * `pending_enrichments` persists the offline AI-enrichment queue.
///  * v7 (Part 3): `quiz_attempts`/`quiz_questions` for quiz history.
///
/// DateTime columns are stored as ISO-8601 UTC text
/// (see build.yaml: store_date_time_values_as_text).
library;

import 'package:drift/drift.dart';

/// Maximum lengths — ported verbatim from the legacy validation contract.
abstract final class DbLimits {
  static const int maxHeadwordLength = 64;
  static const int maxNotebookNameLength = 60;
  static const int maxFieldLength = 2000;
}

@DataClassName('NotebookRow')
class Notebooks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Display name, validated by [normalizeNotebookName] before insert.
  TextColumn get name =>
      text().withLength(min: 1, max: DbLimits.maxNotebookNameLength)();

  /// Manual sort order in the sidebar.
  IntColumn get position => integer().withDefault(const Constant(0))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('WordRow')
@TableIndex(name: 'idx_words_notebook', columns: {#notebookId})
@TableIndex(name: 'idx_words_favorite', columns: {#isFavorite})
@TableIndex(name: 'idx_words_norm', columns: {#headwordNorm})
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get notebookId => integer().references(
        Notebooks,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Normalized lookup key (lowercased, whitespace-collapsed). Uniqueness is
  /// per notebook — see [uniqueKeys].
  TextColumn get headwordNorm =>
      text().withLength(min: 1, max: DbLimits.maxHeadwordLength)();

  /// The exact casing the user typed (legacy `display_word`).
  TextColumn get headwordDisplay =>
      text().withLength(min: 1, max: DbLimits.maxHeadwordLength)();

  TextColumn get partOfSpeech => text().withDefault(const Constant(''))();
  TextColumn get ipa => text().withDefault(const Constant(''))();
  TextColumn get meaning => text().withDefault(const Constant(''))();
  TextColumn get exampleSentence => text().withDefault(const Constant(''))();

  /// Comma-joined for now to keep import from legacy v5 lossless; the
  /// relational split is scheduled with the tags feature work.
  TextColumn get synonyms => text().withDefault(const Constant(''))();
  TextColumn get antonyms => text().withDefault(const Constant(''))();
  TextColumn get importantSynonyms => text().withDefault(const Constant(''))();
  TextColumn get importantAntonyms => text().withDefault(const Constant(''))();

  TextColumn get notes => text().withDefault(const Constant(''))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {notebookId, headwordNorm},
      ];
}

/// One translation of a word's meaning per language (BCP-47 code).
/// Replaces the hardcoded legacy `bangla_meaning` column.
@DataClassName('WordTranslationRow')
class WordTranslations extends Table {
  IntColumn get wordId => integer().references(
        Words,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get langCode => text().withLength(min: 2, max: 12)();

  TextColumn get translation => text()();

  @override
  Set<Column<Object>> get primaryKey => {wordId, langCode};
}

@DataClassName('TagRow')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Case-insensitive unique tag label.
  TextColumn get name =>
      text().customConstraint('NOT NULL COLLATE NOCASE UNIQUE')();
}

@DataClassName('WordTagRow')
class WordTags extends Table {
  IntColumn get wordId => integer().references(
        Words,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get tagId => integer().references(
        Tags,
        #id,
        onDelete: KeyAction.cascade,
      )();

  @override
  Set<Column<Object>> get primaryKey => {wordId, tagId};
}

/// Offline AI-enrichment queue. A row exists while a word still needs its
/// card filled by the AI pipeline; deleting the word cascades the queue row.
@DataClassName('PendingEnrichmentRow')
@TableIndex(name: 'idx_pending_next_attempt', columns: {#nextAttemptAt})
class PendingEnrichments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get wordId => integer()
      .references(Words, #id, onDelete: KeyAction.cascade)
      .unique()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Earliest time the queue processor may retry this row (backoff schedule).
  DateTimeColumn get nextAttemptAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ---------------------------------------------------------------------------
// Schema v7 (Part 3): quiz history
// ---------------------------------------------------------------------------

/// One quiz session (legacy `quiz_attempts` parity: word source, question
/// type, provider, score and duration are all persisted for history).
@DataClassName('QuizAttemptRow')
class QuizAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get notebookId => integer().nullable().references(
        Notebooks,
        #id,
        onDelete: KeyAction.setNull,
      )();

  IntColumn get totalQuestions => integer()();

  IntColumn get correctCount => integer().withDefault(const Constant(0))();

  /// `mixed`, `meaning`, `synonym`, or `antonym` (legacy `question_type`).
  TextColumn get questionType => text().withDefault(const Constant('mixed'))();

  /// Human-readable word source, e.g. "All Words" or a notebook name
  /// (legacy `word_source_label`).
  TextColumn get sourceLabel => text().withDefault(const Constant(''))();

  /// Provider label used to generate the quiz, or `On-device` for the
  /// offline generator (legacy `provider_name`).
  TextColumn get provider => text().withDefault(const Constant(''))();

  /// Wall-clock duration of the attempt (legacy `time_taken_secs`).
  IntColumn get timeTakenSecs => integer().withDefault(const Constant(0))();

  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get finishedAt => dateTime().nullable()();
}

/// One multiple-choice question within an attempt. Options are stored as a
/// JSON array so the exact shuffled choices the user saw are reproducible.
@DataClassName('QuizQuestionRow')
@TableIndex(name: 'idx_quiz_questions_attempt', columns: {#attemptId})
class QuizQuestions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get attemptId => integer().references(
        QuizAttempts,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get wordId => integer().references(
        Words,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// The headword this question is about.
  TextColumn get prompt => text()();

  /// The full question text shown to the user (legacy `question_text`).
  /// Empty for pre-v3 rows; the UI falls back to a meaning-style question.
  TextColumn get questionText => text().withDefault(const Constant(''))();

  /// `meaning`, `synonym`, or `antonym` (legacy `question_type`).
  TextColumn get questionType =>
      text().withDefault(const Constant('meaning'))();

  /// One-line explanation of the correct answer (legacy `explanation`).
  TextColumn get explanation => text().withDefault(const Constant(''))();

  TextColumn get correctAnswer => text()();

  /// JSON-encoded array of the four shuffled options.
  TextColumn get optionsJson => text()();

  TextColumn get chosenAnswer => text().nullable()();

  BoolColumn get wasCorrect => boolean().nullable()();

  DateTimeColumn get answeredAt => dateTime().nullable()();
}
