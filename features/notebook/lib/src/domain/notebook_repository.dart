/// features/notebook/lib/src/domain/notebook_repository.dart
///
/// The feature's data boundary. Widgets and controllers depend on this
/// interface only; the Drift implementation lives in `data/`.
library;

import 'notebook.dart';
import 'word.dart';

/// Keyset pagination cursor: sort key of the last row of the previous page.
typedef WordPageCursor = ({String norm, int id});

/// Outcome of creating a notebook.
sealed class CreateNotebookResult {
  const CreateNotebookResult();
}

final class NotebookCreated extends CreateNotebookResult {
  const NotebookCreated(this.notebook);

  final Notebook notebook;
}

final class NotebookNameRejected extends CreateNotebookResult {
  const NotebookNameRejected(this.reason);

  final String reason;
}

abstract interface class NotebookRepository {
  /// Fires whenever word data changes anywhere (insert/update/delete/
  /// enrichment). List controllers listen to this to refresh.
  Stream<void> get wordChanges;

  Stream<List<Notebook>> watchNotebooks();

  Future<CreateNotebookResult> createNotebook(String rawName);

  /// Renames a notebook; rejects invalid or duplicate names.
  Future<CreateNotebookResult> renameNotebook(int id, String rawName);

  /// Deletes a notebook. Legacy guards apply: only empty notebooks can be
  /// deleted, and the last remaining notebook never can. Returns an error
  /// message on rejection, or null on success.
  Future<String?> deleteNotebook(int id);

  /// Word count per notebook id (for pickers and management dialogs).
  Future<Map<int, int>> notebookWordCounts();

  /// One alphabetical page; [after] = null loads the first page.
  Future<List<Word>> fetchPage({
    int? notebookId,
    bool favoritesOnly = false,
    WordPageCursor? after,
    required int limit,
  });

  /// Ranked full-text search (FTS5) over headword/meaning/example/notes.
  Future<List<Word>> search({
    required String query,
    int? notebookId,
    bool favoritesOnly = false,
    int limit = 200,
  });

  Future<int> countWords({int? notebookId, bool favoritesOnly = false});

  Future<Word?> wordById(int id);

  Stream<Word?> watchWord(int id);

  /// Translations keyed by BCP-47 language code (e.g. `bn`).
  Stream<Map<String, String>> watchTranslations(int wordId);

  Future<void> updateWordFields(int id, WordFieldPatch patch);

  Future<void> setFavorite(int id, {required bool value});

  Future<void> deleteWord(int id);
}
