/// features/transfer/lib/src/application/export_service.dart
///
/// Full-workspace JSON export (human-readable, forward-compatible backup).
/// Pure query + serialization; file I/O lives in the controller.
library;

import 'dart:convert';

import 'package:core_db/core_db.dart';

import 'transfer_support.dart';

final class ExportService {
  const ExportService(this._db);

  final AppDatabase _db;

  Future<String> buildJson() async {
    final notebooks = await _db.select(_db.notebooks).get();
    final words = await _db.select(_db.words).get();
    final translations = await _db.select(_db.wordTranslations).get();

    final banglaByWord = banglaByWordId(translations);

    final data = <String, Object?>{
      'format': 'vocabnote-export',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'notebooks': [
        for (final notebook in notebooks)
          {
            'name': notebook.name,
            'isArchived': notebook.isArchived,
            'createdAt': notebook.createdAt.toIso8601String(),
            'words': [
              for (final word
                  in words.where((w) => w.notebookId == notebook.id))
                {
                  'headword': word.headwordDisplay,
                  'meaning': word.meaning,
                  'banglaMeaning': banglaByWord[word.id] ?? '',
                  'ipa': word.ipa,
                  'partOfSpeech': word.partOfSpeech,
                  'exampleSentence': word.exampleSentence,
                  'synonyms': word.synonyms,
                  'antonyms': word.antonyms,
                  'importantSynonyms': word.importantSynonyms,
                  'importantAntonyms': word.importantAntonyms,
                  'notes': word.notes,
                  'isFavorite': word.isFavorite,
                  'createdAt': word.createdAt.toIso8601String(),
                  'updatedAt': word.updatedAt.toIso8601String(),
                },
            ],
          },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
