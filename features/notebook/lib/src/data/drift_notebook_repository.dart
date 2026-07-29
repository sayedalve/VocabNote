/// features/notebook/lib/src/data/drift_notebook_repository.dart
///
/// Drift-backed implementation of [NotebookRepository]. This is the only
/// file in the feature that imports core_db row types.
library;

import 'package:core_db/core_db.dart';
import 'package:drift/drift.dart' show Value;

import '../domain/notebook.dart';
import '../domain/notebook_repository.dart';
import '../domain/word.dart';

final class DriftNotebookRepository implements NotebookRepository {
  const DriftNotebookRepository(this._db);

  final AppDatabase _db;

  WordDao get _words => _db.wordDao;

  NotebookDao get _notebooks => _db.notebookDao;

  static Word _toWord(WordRow row, {String banglaMeaning = ''}) => Word(
        id: row.id,
        notebookId: row.notebookId,
        headwordNorm: row.headwordNorm,
        headword: row.headwordDisplay,
        partOfSpeech: row.partOfSpeech,
        ipa: row.ipa,
        meaning: row.meaning,
        banglaMeaning: banglaMeaning,
        exampleSentence: row.exampleSentence,
        synonyms: row.synonyms,
        antonyms: row.antonyms,
        importantSynonyms: row.importantSynonyms,
        importantAntonyms: row.importantAntonyms,
        notes: row.notes,
        isFavorite: row.isFavorite,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static Notebook _toNotebook(NotebookRow row) => Notebook(
        id: row.id,
        name: row.name,
        position: row.position,
        isArchived: row.isArchived,
        createdAt: row.createdAt,
      );

  @override
  Stream<void> get wordChanges => _words.changes();

  @override
  Stream<List<Notebook>> watchNotebooks() => _notebooks
      .watchActive()
      .map((rows) => rows.map(_toNotebook).toList(growable: false));

  @override
  Future<CreateNotebookResult> createNotebook(String rawName) async {
    switch (normalizeNotebookName(rawName)) {
      case InvalidNotebookName(:final reason):
        return NotebookNameRejected(reason);
      case ValidNotebookName(:final name):
        if (await _notebooks.byNameInsensitive(name) != null) {
          return const NotebookNameRejected(
            'A notebook with this name already exists.',
          );
        }
        final row = await _notebooks.insertNotebook(name);
        return NotebookCreated(_toNotebook(row));
    }
  }

  @override
  Future<CreateNotebookResult> renameNotebook(int id, String rawName) async {
    switch (normalizeNotebookName(rawName)) {
      case InvalidNotebookName(:final reason):
        return NotebookNameRejected(reason);
      case ValidNotebookName(:final name):
        final existing = await _notebooks.byNameInsensitive(name);
        if (existing != null && existing.id != id) {
          return const NotebookNameRejected(
            'A notebook with this name already exists.',
          );
        }
        await _notebooks.rename(id, name);
        final row = await _notebooks.byId(id);
        if (row == null) {
          return const NotebookNameRejected('Notebook not found.');
        }
        return NotebookCreated(_toNotebook(row));
    }
  }

  @override
  Future<String?> deleteNotebook(int id) async {
    // Legacy guards: never delete a non-empty notebook or the last one.
    final counts = await _notebooks.wordCounts();
    if ((counts[id] ?? 0) > 0) {
      return 'Only empty notebooks can be deleted. '
          'Move or delete its words first.';
    }
    if (await _notebooks.countActive() <= 1) {
      return 'You need at least one notebook.';
    }
    await _notebooks.deleteNotebook(id);
    return null;
  }

  @override
  Future<Map<int, int>> notebookWordCounts() => _notebooks.wordCounts();

  /// Maps rows to [Word]s with their Bangla translation attached via one
  /// batched IN query (never one query per row).
  Future<List<Word>> _toWordsWithBangla(List<WordRow> rows) async {
    if (rows.isEmpty) return const [];
    final bangla = await _words.translationsForWordIds(
      [for (final row in rows) row.id],
    );
    return [
      for (final row in rows)
        _toWord(row, banglaMeaning: bangla[row.id] ?? ''),
    ];
  }

  @override
  Future<List<Word>> fetchPage({
    int? notebookId,
    bool favoritesOnly = false,
    WordPageCursor? after,
    required int limit,
  }) async {
    final rows = await _words.fetchPage(
      filter: (notebookId: notebookId, favoritesOnly: favoritesOnly),
      after: after,
      limit: limit,
    );
    return _toWordsWithBangla(rows);
  }

  @override
  Future<List<Word>> search({
    required String query,
    int? notebookId,
    bool favoritesOnly = false,
    int limit = 200,
  }) async {
    final rows = await _words.search(
      rawQuery: query,
      filter: (notebookId: notebookId, favoritesOnly: favoritesOnly),
      limit: limit,
    );
    return _toWordsWithBangla(rows);
  }

  @override
  Future<int> countWords({int? notebookId, bool favoritesOnly = false}) =>
      _words.countWords(
        (notebookId: notebookId, favoritesOnly: favoritesOnly),
      );

  @override
  Future<Word?> wordById(int id) async {
    final row = await _words.byId(id);
    if (row == null) return null;
    final bangla = await _words.translationsForWordIds([id]);
    return _toWord(row, banglaMeaning: bangla[id] ?? '');
  }

  @override
  Stream<Word?> watchWord(int id) =>
      _words.watchById(id).map((row) => row == null ? null : _toWord(row));

  @override
  Stream<Map<String, String>> watchTranslations(int wordId) =>
      _words.watchTranslationsFor(wordId).map(
            (rows) => {
              for (final row in rows) row.langCode: row.translation,
            },
          );

  @override
  Future<void> updateWordFields(int id, WordFieldPatch patch) {
    Value<String> value(String? v) =>
        v == null ? const Value.absent() : Value(v);
    return _words.updateWordFields(
      id,
      WordsCompanion(
        headwordDisplay: value(patch.headwordDisplay),
        partOfSpeech: value(patch.partOfSpeech),
        ipa: value(patch.ipa),
        meaning: value(patch.meaning),
        exampleSentence: value(patch.exampleSentence),
        synonyms: value(patch.synonyms),
        antonyms: value(patch.antonyms),
        importantSynonyms: value(patch.importantSynonyms),
        importantAntonyms: value(patch.importantAntonyms),
        notes: value(patch.notes),
      ),
    );
  }

  @override
  Future<void> setFavorite(int id, {required bool value}) =>
      _words.setFavorite(id, value: value);

  @override
  Future<void> deleteWord(int id) => _words.deleteById(id);
}
