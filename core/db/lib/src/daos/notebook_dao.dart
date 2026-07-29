/// core/db/lib/src/daos/notebook_dao.dart
library;

import 'package:drift/drift.dart';

import 'package:core_db/src/database.dart';
import 'package:core_db/src/tables.dart';

part 'notebook_dao.g.dart';

@DriftAccessor(tables: [Notebooks, Words])
class NotebookDao extends DatabaseAccessor<AppDatabase>
    with _$NotebookDaoMixin {
  NotebookDao(super.attachedDatabase);

  Stream<List<NotebookRow>> watchActive() => (select(notebooks)
        ..where((n) => n.isArchived.equals(false))
        ..orderBy([
          (n) => OrderingTerm.asc(n.position),
          (n) => OrderingTerm.asc(n.id),
        ]))
      .watch();

  Future<NotebookRow> insertNotebook(String name) =>
      into(notebooks).insertReturning(NotebooksCompanion.insert(name: name));

  Future<void> rename(int id, String name) async {
    await (update(notebooks)..where((n) => n.id.equals(id)))
        .write(NotebooksCompanion(name: Value(name)));
  }

  Future<void> setArchived(int id, {required bool value}) async {
    await (update(notebooks)..where((n) => n.id.equals(id)))
        .write(NotebooksCompanion(isArchived: Value(value)));
  }

  /// Word count per notebook id (sidebar/dropdown badges).
  Future<Map<int, int>> wordCounts() async {
    final count = words.id.count();
    final query = selectOnly(words)
      ..addColumns([words.notebookId, count])
      ..groupBy([words.notebookId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        if (row.read(words.notebookId) case final int id)
          id: row.read(count) ?? 0,
    };
  }

  Future<int> countActive() async {
    final count = notebooks.id.count();
    final query = selectOnly(notebooks)
      ..addColumns([count])
      ..where(notebooks.isArchived.equals(false));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Case-insensitive name lookup among active notebooks (legacy volumes
  /// enforced unique names ignoring case).
  Future<NotebookRow?> byNameInsensitive(String name) =>
      (select(notebooks)
            ..where(
              (n) =>
                  n.isArchived.equals(false) &
                  n.name.lower().equals(name.toLowerCase()),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Deletes a notebook row. Callers must enforce the legacy guards first
  /// (only empty notebooks, never the last one) — see the repository.
  Future<void> deleteNotebook(int id) async {
    await (delete(notebooks)..where((n) => n.id.equals(id))).go();
  }

  /// Returns the first active notebook, creating the default one if the
  /// table is somehow empty (defensive: onCreate seeds one).
  Future<NotebookRow> ensureDefaultNotebook() async {
    final existing = await (select(notebooks)
          ..where((n) => n.isArchived.equals(false))
          ..orderBy([
            (n) => OrderingTerm.asc(n.position),
            (n) => OrderingTerm.asc(n.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing;
    return insertNotebook('My Notebook');
  }

  Future<NotebookRow?> byId(int id) =>
      (select(notebooks)..where((n) => n.id.equals(id))).getSingleOrNull();
}