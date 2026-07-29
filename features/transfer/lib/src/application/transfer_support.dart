/// features/transfer/lib/src/application/transfer_support.dart
///
/// Shared building blocks for the import/export services:
///  * [ImportReport] — the one report shape every bulk importer returns
///    (returned directly by the CSV, DOCX, and legacy importers).
///  * [NotebookResolver] — resolve-or-create notebooks by name with a
///    per-import cache, so every importer creates notebooks identically.
///  * [banglaByWordId] / [clampField] / [kBanglaLangCode] — small helpers
///    that previously existed as four separate copies.
library;

import 'package:core_db/core_db.dart';
import 'package:drift/drift.dart';

/// Language code used for Bangla translations across every format.
const String kBanglaLangCode = 'bn';

/// Notebook name used when an imported word has no (or an invalid) notebook.
const String kFallbackNotebookName = 'Imported';

/// Outcome of a bulk import (CSV, DOCX, or legacy database).
class ImportReport {
  const ImportReport({
    required this.notebooksCreated,
    required this.wordsImported,
    required this.wordsSkipped,
    required this.translationsImported,
  });

  final int notebooksCreated;
  final int wordsImported;
  final int wordsSkipped;
  final int translationsImported;

  /// Human-readable one-line summary shown after the import finishes.
  String get summary =>
      'Imported $wordsImported words ($translationsImported Bangla '
      'translations, $notebooksCreated new notebooks). '
      'Skipped $wordsSkipped duplicates/empty rows.';
}

/// Resolves notebook display names to ids, creating missing notebooks and
/// caching results so repeated rows never re-query.
///
/// Must be used inside the surrounding import transaction so notebooks
/// created here roll back together with their words if the import fails.
final class NotebookResolver {
  NotebookResolver(this._db);

  final AppDatabase _db;

  /// Lowercased notebook name -> id.
  final Map<String, int> _idsByLowerName = {};

  /// Number of notebooks created through this resolver so far.
  int created = 0;

  /// Returns the id of the notebook named [rawName], creating it if needed.
  /// Blank or invalid names fall back to [kFallbackNotebookName].
  Future<int> resolve(String rawName) async {
    final trimmed = rawName.trim();
    final name = switch (normalizeNotebookName(
      trimmed.isEmpty ? kFallbackNotebookName : trimmed,
    )) {
      ValidNotebookName(:final name) => name,
      InvalidNotebookName() => kFallbackNotebookName,
    };
    final cached = _idsByLowerName[name.toLowerCase()];
    if (cached != null) return cached;

    final existing = await (_db.select(_db.notebooks)
          ..where((n) => n.name.equals(name)))
        .getSingleOrNull();
    final int id;
    if (existing != null) {
      id = existing.id;
    } else {
      final row = await _db
          .into(_db.notebooks)
          .insertReturning(NotebooksCompanion.insert(name: name));
      id = row.id;
      created++;
    }
    _idsByLowerName[name.toLowerCase()] = id;
    return id;
  }
}

/// Maps word id -> Bangla translation from the raw translation rows.
Map<int, String> banglaByWordId(Iterable<WordTranslationRow> translations) => {
      for (final t in translations)
        if (t.langCode == kBanglaLangCode) t.wordId: t.translation,
    };

/// Trims a free-text field and clamps it to the database column limit.
String clampField(String raw) {
  final trimmed = raw.trim();
  return trimmed.length <= DbLimits.maxFieldLength
      ? trimmed
      : trimmed.substring(0, DbLimits.maxFieldLength);
}
