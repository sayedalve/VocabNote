/// core/db/lib/src/database.dart
///
/// The single Drift database. The SQLite connection runs in a background
/// isolate (NativeDatabase.createInBackground) so no query ever blocks the UI
/// thread. Pragmas mirror the legacy connection factory contract:
/// WAL + NORMAL synchronous + foreign_keys ON + 5s busy timeout.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/enrichment_dao.dart';
import 'daos/notebook_dao.dart';
import 'daos/quiz_dao.dart';
import 'daos/tag_dao.dart';
import 'daos/word_dao.dart';
import 'tables.dart';

part 'database.g.dart';

/// Filename kept distinct from the legacy `vocab_notebook.db` so the legacy
/// importer can read the old file side-by-side during migration.
const String kDatabaseFileName = 'vocabnote.db';

/// Environment override for the data directory (parity with the legacy
/// `VOCABNOTE_DATA_DIR` behaviour; used by tests and portable installs).
const String kDataDirEnvVar = 'VOCABNOTE_DATA_DIR';

/// A restored backup is staged next to the live database with this suffix
/// and swapped in atomically on the next launch, before SQLite opens.
const String kRestorePendingSuffix = '.restore-pending';

@DriftDatabase(
  tables: [
    Notebooks,
    Words,
    WordTranslations,
    Tags,
    WordTags,
    PendingEnrichments,
    QuizAttempts,
    QuizQuestions,
  ],
  daos: [WordDao, NotebookDao, EnrichmentDao, QuizDao, TagDao],
)
class AppDatabase extends _$AppDatabase {
  /// Injectable executor for tests (`NativeDatabase.memory()`).
  AppDatabase(super.executor);

  /// Opens the production database in a background isolate.
  AppDatabase.open() : super(_openConnection());

  /// DateTime columns are stored as ISO-8601 text (see tables.dart and
  /// build.yaml: store_date_time_values_as_text). This override keeps the
  /// runtime mapping in sync with that contract. Without it, Drift falls
  /// back to unix-timestamp integers and crashes with
  /// `FormatException: Invalid radix-10 number` the moment it reads a text
  /// timestamp written by a `CURRENT_TIMESTAMP` column default.
  @override
  DriftDatabaseOptions options =
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  int get schemaVersion => 3; // Drift-era v3 == product schema v8.

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await createFtsObjects();
          // Every install starts with one notebook; the UI never has to
          // handle a zero-notebook state.
          await into(notebooks).insert(
            NotebooksCompanion.insert(name: 'My Notebook'),
          );
        },
        onUpgrade: (m, from, to) async {
          // Append ordered steps here; never edit or reorder shipped steps.
          if (from < 2) {
            // Product schema v7 (Part 3): quiz persistence.
            await m.createTable(quizAttempts);
            await m.createTable(quizQuestions);
            await m.createIndex(idxQuizQuestionsAttempt);
          }
          if (from < 3) {
            // Product schema v8: full quiz parity with the legacy desktop
            // app — word source, question type, provider, duration, and
            // per-question text/explanations for the history review UI.
            await m.addColumn(quizAttempts, quizAttempts.questionType);
            await m.addColumn(quizAttempts, quizAttempts.sourceLabel);
            await m.addColumn(quizAttempts, quizAttempts.provider);
            await m.addColumn(quizAttempts, quizAttempts.timeTakenSecs);
            await m.addColumn(quizQuestions, quizQuestions.questionText);
            await m.addColumn(quizQuestions, quizQuestions.questionType);
            await m.addColumn(quizQuestions, quizQuestions.explanation);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA busy_timeout = 5000');
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
          await _repairDateTimeColumns();
        },
      );

  /// Creates the external-content FTS5 index over `words` plus the three
  /// triggers that keep it in sync. Idempotent (`IF NOT EXISTS` / recreate).
  Future<void> createFtsObjects() async {
    await customStatement('''
CREATE VIRTUAL TABLE IF NOT EXISTS words_fts USING fts5(
  headword,
  meaning,
  example_sentence,
  notes,
  content='words',
  content_rowid='id',
  tokenize='unicode61 remove_diacritics 2'
)''');

    await customStatement('''
CREATE TRIGGER IF NOT EXISTS words_fts_ai AFTER INSERT ON words BEGIN
  INSERT INTO words_fts(rowid, headword, meaning, example_sentence, notes)
  VALUES (new.id, new.headword_display, new.meaning, new.example_sentence, new.notes);
END''');

    await customStatement('''
CREATE TRIGGER IF NOT EXISTS words_fts_ad AFTER DELETE ON words BEGIN
  INSERT INTO words_fts(words_fts, rowid, headword, meaning, example_sentence, notes)
  VALUES ('delete', old.id, old.headword_display, old.meaning, old.example_sentence, old.notes);
END''');

    await customStatement('''
CREATE TRIGGER IF NOT EXISTS words_fts_au AFTER UPDATE ON words BEGIN
  INSERT INTO words_fts(words_fts, rowid, headword, meaning, example_sentence, notes)
  VALUES ('delete', old.id, old.headword_display, old.meaning, old.example_sentence, old.notes);
  INSERT INTO words_fts(rowid, headword, meaning, example_sentence, notes)
  VALUES (new.id, new.headword_display, new.meaning, new.example_sentence, new.notes);
END''');
  }

  /// Self-healing repair for DateTime columns.
  ///
  /// Databases written before the switch to text-mode DateTimes can contain
  /// a mix of unix-timestamp INTEGER values (written by Drift's old integer
  /// mapping) and `YYYY-MM-DD HH:MM:SS` TEXT values (written by the
  /// `CURRENT_TIMESTAMP` column defaults). Reading that mix crashed with
  /// `FormatException: Invalid radix-10 number (at character 2)`.
  ///
  /// This rewrites every integer value as ISO-8601 text and normalizes the
  /// space separator to `T` so all values parse and sort consistently.
  /// Idempotent -- safe to run on every launch.
  Future<void> _repairDateTimeColumns() async {
    const dateTimeColumns = <String, List<String>>{
      'notebooks': ['created_at'],
      'words': ['created_at', 'updated_at'],
      'pending_enrichments': ['created_at', 'next_attempt_at'],
      'quiz_attempts': ['started_at', 'finished_at'],
      'quiz_questions': ['answered_at'],
    };
    for (final MapEntry(key: table, value: columns)
        in dateTimeColumns.entries) {
      for (final column in columns) {
        // Unix-timestamp integers -> ISO-8601 text.
        await customStatement(
          'UPDATE "$table" SET "$column" = '
          "strftime('%Y-%m-%dT%H:%M:%S', \"$column\", 'unixepoch') "
          'WHERE typeof("$column") = \'integer\'',
        );
        // `YYYY-MM-DD HH:MM:SS` (CURRENT_TIMESTAMP) -> `YYYY-MM-DDTHH:MM:SS`.
        await customStatement(
          'UPDATE "$table" SET "$column" = replace("$column", \' \', \'T\') '
          'WHERE typeof("$column") = \'text\' AND "$column" LIKE \'% %\'',
        );
      }
    }
  }

  /// Rebuilds the FTS index from the content table. Called after bulk imports
  /// (legacy migration, CSV import) instead of relying on triggers.
  Future<void> rebuildSearchIndex() async {
    await customStatement("INSERT INTO words_fts(words_fts) VALUES('rebuild')");
  }

  /// Integrity check surfaced by the backup/recovery service.
  Future<bool> quickCheck() async {
    final row = await customSelect('PRAGMA quick_check').getSingle();
    return row.data.values.first == 'ok';
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await resolveDataDirectory();
    final file = File(p.join(dir.path, kDatabaseFileName));
    _applyPendingRestore(file);
    return NativeDatabase.createInBackground(
      file,
      logStatements: false,
    );
  });
}

/// If a staged restore exists (`vocabnote.db.restore-pending`), swap it in
/// before the connection opens. WAL/SHM sidecars are removed so SQLite
/// cannot replay stale journal pages over the restored file.
void _applyPendingRestore(File dbFile) {
  final pending = File('${dbFile.path}$kRestorePendingSuffix');
  if (!pending.existsSync()) return;
  for (final suffix in const ['-wal', '-shm']) {
    final sidecar = File('${dbFile.path}$suffix');
    if (sidecar.existsSync()) {
      sidecar.deleteSync();
    }
  }
  pending.renameSync(dbFile.path);
}

/// Resolves the writable data directory:
/// env override first (tests/portable), then the platform support directory.
Future<Directory> resolveDataDirectory() async {
  final override = Platform.environment[kDataDirEnvVar];
  final dir = override != null && override.isNotEmpty
      ? Directory(override)
      : await getApplicationSupportDirectory();
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}
