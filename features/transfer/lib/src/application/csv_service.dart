/// features/transfer/lib/src/application/csv_service.dart
///
/// CSV export/import (Phase 4). The export writes a fixed header
/// (kCsvColumns); the importer accepts those columns in any order, requires
/// only `headword`, ignores unknown columns, and skips duplicates the same
/// way the legacy importer does.
library;

import 'package:core_db/core_db.dart';
import 'package:drift/drift.dart';

import 'csv_codec.dart';
import 'transfer_support.dart';

/// Fixed export header. Import accepts these columns in any order.
const List<String> kCsvColumns = [
  'notebook',
  'headword',
  'meaning',
  'bangla_meaning',
  'ipa',
  'part_of_speech',
  'example_sentence',
  'synonyms',
  'antonyms',
  'important_synonyms',
  'important_antonyms',
  'notes',
  'is_favorite',
];

class CsvImportException implements Exception {
  const CsvImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class CsvTransferService {
  const CsvTransferService(this._db);

  final AppDatabase _db;

  /// Builds the full-workspace CSV: header + one row per word.
  Future<String> buildCsv() async {
    final notebooks = await _db.select(_db.notebooks).get();
    final words = await _db.select(_db.words).get();
    final translations = await _db.select(_db.wordTranslations).get();

    final notebookNames = <int, String>{
      for (final notebook in notebooks) notebook.id: notebook.name,
    };
    final banglaByWord = banglaByWordId(translations);

    final rows = <List<String>>[
      kCsvColumns,
      for (final word in words)
        [
          notebookNames[word.notebookId] ?? '',
          word.headwordDisplay,
          word.meaning,
          banglaByWord[word.id] ?? '',
          word.ipa,
          word.partOfSpeech,
          word.exampleSentence,
          word.synonyms,
          word.antonyms,
          word.importantSynonyms,
          word.importantAntonyms,
          word.notes,
          word.isFavorite ? 'true' : 'false',
        ],
    ];
    return encodeCsv(rows);
  }

  /// Imports words from CSV text. Only `headword` is required; duplicates
  /// (same normalized headword in the same notebook) are skipped.
  Future<ImportReport> importFrom(String csvText) async {
    final rows = decodeCsv(csvText);
    if (rows.isEmpty) {
      throw const CsvImportException('The CSV file is empty.');
    }

    final header = [
      for (final cell in rows.first) cell.trim().toLowerCase(),
    ];
    final columnIndex = <String, int>{
      for (var i = 0; i < header.length; i++) header[i]: i,
    };
    if (!columnIndex.containsKey('headword')) {
      throw CsvImportException(
        'The CSV file needs a "headword" column. '
        'Supported columns: ${kCsvColumns.join(', ')}.',
      );
    }

    var wordsImported = 0;
    var wordsSkipped = 0;
    var translationsImported = 0;
    final notebooks = NotebookResolver(_db);

    await _db.transaction(() async {
      for (final row in rows.skip(1)) {
        // Skip fully blank lines.
        if (row.every((cell) => cell.trim().isEmpty)) continue;

        String cell(String column) {
          final index = columnIndex[column];
          if (index == null || index >= row.length) return '';
          return row[index];
        }

        final headwordResult = normalizeHeadword(cell('headword'));
        if (headwordResult is! ValidHeadword) {
          wordsSkipped++;
          continue;
        }

        final notebookId = await notebooks.resolve(cell('notebook'));

        final duplicate = await _db.wordDao.byNormalizedHeadword(
          notebookId: notebookId,
          norm: headwordResult.norm,
        );
        if (duplicate != null) {
          wordsSkipped++;
          continue;
        }

        final favRaw = cell('is_favorite').trim().toLowerCase();
        final isFavorite =
            favRaw == 'true' || favRaw == '1' || favRaw == 'yes';

        final inserted = await _db.wordDao.insertWord(
          WordsCompanion.insert(
            notebookId: notebookId,
            headwordNorm: headwordResult.norm,
            headwordDisplay: headwordResult.display,
            meaning: Value(clampField(cell('meaning'))),
            ipa: Value(clampField(cell('ipa'))),
            partOfSpeech: Value(clampField(cell('part_of_speech'))),
            exampleSentence: Value(clampField(cell('example_sentence'))),
            synonyms: Value(clampField(cell('synonyms'))),
            antonyms: Value(clampField(cell('antonyms'))),
            importantSynonyms: Value(clampField(cell('important_synonyms'))),
            importantAntonyms: Value(clampField(cell('important_antonyms'))),
            notes: Value(clampField(cell('notes'))),
            isFavorite: Value(isFavorite),
          ),
        );
        wordsImported++;

        final bangla = clampField(cell('bangla_meaning'));
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
  }
}
