// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notebook_dao.dart';

// ignore_for_file: type=lint
mixin _$NotebookDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotebooksTable get notebooks => attachedDatabase.notebooks;
  $WordsTable get words => attachedDatabase.words;
  NotebookDaoManager get managers => NotebookDaoManager(this);
}

class NotebookDaoManager {
  final _$NotebookDaoMixin _db;
  NotebookDaoManager(this._db);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db.attachedDatabase, _db.notebooks);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
}
