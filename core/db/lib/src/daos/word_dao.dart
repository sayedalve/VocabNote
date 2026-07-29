/// core/db/lib/src/daos/word_dao.dart
///
/// All word reads/writes. Pagination is keyset-based (headword_norm, id) so
/// page N+1 costs the same as page 1 regardless of dataset size. Search goes
/// through the FTS5 index — LIKE scans are banned by convention.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'word_dao.g.dart';

/// Keyset cursor: the sort key of the last row of the previous page.
typedef WordCursor = ({String norm, int id});

/// Filter shared by list + search queries.
typedef WordFilter = ({int? notebookId, bool favoritesOnly});

@DriftAccessor(tables: [Words, WordTranslations])
class WordDao extends DatabaseAccessor<AppDatabase> with _$WordDaoMixin {
  WordDao(super.attachedDatabase);

  /// Fires whenever words or translations change; controllers listen to this
  /// to refresh visible pages.
  Stream<void> changes() => db
      .tableUpdates(TableUpdateQuery.onAllTables([words, wordTranslations]))
      .map((_) {});

  Expression<bool> _filterPredicate($WordsTable w, WordFilter filter) {
    Expression<bool> predicate = const Constant(true);
    final notebookId = filter.notebookId;
    if (notebookId != null) {
      predicate = predicate & w.notebookId.equals(notebookId);
    }
    if (filter.favoritesOnly) {
      predicate = predicate & w.isFavorite.equals(true);
    }
    return predicate;
  }

  /// One alphabetical page. Pass [after] = null for the first page.
  Future<List<WordRow>> fetchPage({
    required WordFilter filter,
    required int limit,
    WordCursor? after,
  }) {
    final query = select(words)
      ..where((w) {
        var predicate = _filterPredicate(w, filter);
        if (after != null) {
          predicate = predicate &
              (w.headwordNorm.isBiggerThanValue(after.norm) |
                  (w.headwordNorm.equals(after.norm) &
                      w.id.isBiggerThanValue(after.id)));
        }
        return predicate;
      })
      ..orderBy([
        (w) => OrderingTerm.asc(w.headwordNorm),
        (w) => OrderingTerm.asc(w.id),
      ])
      ..limit(limit);
    return query.get();
  }

  /// Escapes user input into an FTS5 prefix query:
  /// `run fast` -> `"run"* "fast"*` (implicit AND).
  static String buildMatchQuery(String raw) {
    final tokens = raw
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '"${t.replaceAll('"', '""')}"*');
    return tokens.join(' ');
  }

  /// Ranked FTS5 search across headword, meaning, example, and notes.
  Future<List<WordRow>> search({
    required String rawQuery,
    required WordFilter filter,
    int limit = 200,
  }) {
    final match = buildMatchQuery(rawQuery);
    if (match.isEmpty) return Future.value(<WordRow>[]);

    final variables = <Variable<Object>>[Variable<String>(match)];
    final where = StringBuffer();
    final notebookId = filter.notebookId;
    if (notebookId != null) {
      where.write(' AND w.notebook_id = ?');
      variables.add(Variable<int>(notebookId));
    }
    if (filter.favoritesOnly) {
      where.write(' AND w.is_favorite = 1');
    }
    variables.add(Variable<int>(limit));

    return customSelect(
      'SELECT w.* FROM words_fts AS f '
      'JOIN words AS w ON w.id = f.rowid '
      'WHERE words_fts MATCH ?$where '
      'ORDER BY rank LIMIT ?',
      variables: variables,
      readsFrom: {words},
    ).asyncMap(words.mapFromRow).get();
  }

  Future<WordRow?> byId(int id) =>
      (select(words)..where((w) => w.id.equals(id))).getSingleOrNull();

  Stream<WordRow?> watchById(int id) =>
      (select(words)..where((w) => w.id.equals(id))).watchSingleOrNull();

  Future<WordRow?> byNormalizedHeadword({
    required int notebookId,
    required String norm,
  }) =>
      (select(words)
            ..where(
              (w) =>
                  w.notebookId.equals(notebookId) &
                  w.headwordNorm.equals(norm),
            ))
          .getSingleOrNull();

  Future<WordRow> insertWord(WordsCompanion companion) =>
      into(words).insertReturning(companion);

  /// Partial update; always bumps `updated_at`.
  Future<void> updateWordFields(int id, WordsCompanion companion) async {
    await (update(words)..where((w) => w.id.equals(id))).write(
      companion.copyWith(updatedAt: Value(DateTime.now().toUtc())),
    );
  }

  Future<void> setFavorite(int id, {required bool value}) =>
      updateWordFields(id, WordsCompanion(isFavorite: Value(value)));

  Future<void> deleteById(int id) async {
    await (delete(words)..where((w) => w.id.equals(id))).go();
  }

  Future<int> countWords(WordFilter filter) async {
    final count = words.id.count();
    final query = selectOnly(words)
      ..addColumns([count])
      ..where(_filterPredicate(words, filter));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  // ---- Translations -------------------------------------------------------

  Future<List<WordTranslationRow>> translationsFor(int wordId) =>
      (select(wordTranslations)..where((t) => t.wordId.equals(wordId))).get();

  /// Batch translation lookup for list rows: word id -> translation for
  /// [langCode]. One IN query per page instead of one query per row.
  Future<Map<int, String>> translationsForWordIds(
    List<int> wordIds, {
    String langCode = 'bn',
  }) async {
    if (wordIds.isEmpty) return const {};
    final rows = await (select(wordTranslations)
          ..where(
            (t) => t.wordId.isIn(wordIds) & t.langCode.equals(langCode),
          ))
        .get();
    return {for (final row in rows) row.wordId: row.translation};
  }

  Stream<List<WordTranslationRow>> watchTranslationsFor(int wordId) =>
      (select(wordTranslations)..where((t) => t.wordId.equals(wordId)))
          .watch();

  Future<void> upsertTranslation({
    required int wordId,
    required String langCode,
    required String translation,
  }) =>
      into(wordTranslations).insertOnConflictUpdate(
        WordTranslationsCompanion.insert(
          wordId: wordId,
          langCode: langCode,
          translation: translation,
        ),
      );
}
