/// features/transfer/lib/src/application/legacy_import_service.dart
///
/// One-shot importer for the legacy Python app's `vocab_notebook.db`
/// (schema v5). Reads the old file directly with package:sqlite3 (read-only,
/// side-by-side with the Drift database) and maps:
///   volumes           -> notebooks
///   words             -> words (+ bangla_meaning -> word_translations 'bn')
///   favorites         -> words.is_favorite
/// Duplicates (same normalized headword in the same notebook) are skipped.
/// Column access is defensive (PRAGMA table_info) so minor legacy schema
/// drift never crashes the import.
library;

import 'package:core_db/core_db.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sq;

import 'transfer_support.dart';

class LegacyImportException implements Exception {
  const LegacyImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class LegacyImportService {
  const LegacyImportService(this._db);

  final AppDatabase _db;

  Future<ImportReport> importFrom(String path) async {
    final sq.Database legacy;
    try {
      legacy = sq.sqlite3.open(path, mode: sq.OpenMode.readOnly);
    } on sq.SqliteException catch (e) {
      throw LegacyImportException(
        'Could not open the file as an SQLite database: ${e.message}',
      );
    }

    try {
      final tables = legacy
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((row) => row['name'] as String)
          .toSet();
      if (!tables.contains('words')) {
        throw const LegacyImportException(
          'This does not look like a VocabNote 3.x database '
          '(no "words" table found).',
        );
      }

      final wordCols = _columnsOf(legacy, 'words');

      // Legacy volume id -> display name.
      final volumeNames = <int, String>{};
      if (tables.contains('volumes')) {
        for (final row in legacy.select('SELECT * FROM volumes')) {
          final id = row['id'];
          final name = (row['name'] as String?)?.trim() ?? '';
          if (id is int && name.isNotEmpty) {
            volumeNames[id] = name;
          }
        }
      }

      var wordsImported = 0;
      var wordsSkipped = 0;
      var translationsImported = 0;
      final notebooks = NotebookResolver(_db);

      await _db.transaction(() async {
        // Legacy volume id (null = words without a volume) -> new notebook id.
        final notebookIds = <int?, int>{};

        Future<int> notebookFor(int? volumeId) async {
          final cached = notebookIds[volumeId];
          if (cached != null) return cached;
          final raw = volumeId == null
              ? kFallbackNotebookName
              : (volumeNames[volumeId] ?? kFallbackNotebookName);
          // Clamp first: legacy names may exceed the limit, and 3.x
          // truncated them rather than rejecting them.
          final id = await notebooks.resolve(
            _truncate(raw, DbLimits.maxNotebookNameLength),
          );
          notebookIds[volumeId] = id;
          return id;
        }

        for (final row in legacy.select('SELECT * FROM words')) {
          String col(String name) {
            if (!wordCols.contains(name)) return '';
            final value = row[name];
            return value is String ? value : (value?.toString() ?? '');
          }

          // Prefer the display casing; fall back to the normalized word.
          final rawDisplay = col('display_word').trim().isNotEmpty
              ? col('display_word').trim()
              : col('word').trim();
          // Clamp first (legacy rows may exceed the limit), then run the
          // same validation as the rest of the app so imported rows can
          // never carry lookup keys the app itself would not produce.
          final headwordResult = normalizeHeadword(
            _truncate(rawDisplay, DbLimits.maxHeadwordLength),
          );
          if (headwordResult is! ValidHeadword) {
            wordsSkipped++;
            continue;
          }

          final rawVolumeId =
              wordCols.contains('volume_id') ? row['volume_id'] : null;
          final notebookId =
              await notebookFor(rawVolumeId is int ? rawVolumeId : null);

          final duplicate = await _db.wordDao.byNormalizedHeadword(
            notebookId: notebookId,
            norm: headwordResult.norm,
          );
          if (duplicate != null) {
            wordsSkipped++;
            continue;
          }

          final favRaw = wordCols.contains('is_favorite')
              ? row['is_favorite']
              : (wordCols.contains('favorite') ? row['favorite'] : 0);
          final isFavorite = favRaw == 1 || favRaw == true || favRaw == '1';

          final inserted = await _db.wordDao.insertWord(
            WordsCompanion.insert(
              notebookId: notebookId,
              headwordNorm: headwordResult.norm,
              headwordDisplay: headwordResult.display,
              meaning: Value(clampField(col('meaning'))),
              ipa: Value(clampField(col('ipa'))),
              partOfSpeech: Value(clampField(col('part_of_speech'))),
              exampleSentence: Value(clampField(col('example_sentence'))),
              synonyms: Value(clampField(col('synonyms'))),
              antonyms: Value(clampField(col('antonyms'))),
              importantSynonyms: Value(clampField(col('important_synonyms'))),
              importantAntonyms: Value(clampField(col('important_antonyms'))),
              notes: Value(clampField(col('notes'))),
              isFavorite: Value(isFavorite),
            ),
          );
          wordsImported++;

          final bangla = clampField(col('bangla_meaning'));
          if (bangla.isNotEmpty) {
            await _db.wordDao.upsertTranslation(
              wordId: inserted.id,
              langCode: kBanglaLangCode,
              translation: bangla,
            );
            translationsImported++;
          }
        }
      });

      // Bulk import: rebuild FTS once instead of trusting per-row triggers.
      await _db.rebuildSearchIndex();

      return ImportReport(
        notebooksCreated: notebooks.created,
        wordsImported: wordsImported,
        wordsSkipped: wordsSkipped,
        translationsImported: translationsImported,
      );
    } on sq.SqliteException catch (e) {
      throw LegacyImportException('Import failed while reading: ${e.message}');
    } finally {
      legacy.dispose();
    }
  }

  static Set<String> _columnsOf(sq.Database db, String table) => db
      .select('PRAGMA table_info($table)')
      .map((row) => row['name'] as String)
      .toSet();

  static String _truncate(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);
}
