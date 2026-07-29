// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrichment_dao.dart';

// ignore_for_file: type=lint
mixin _$EnrichmentDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotebooksTable get notebooks => attachedDatabase.notebooks;
  $WordsTable get words => attachedDatabase.words;
  $WordTranslationsTable get wordTranslations =>
      attachedDatabase.wordTranslations;
  $PendingEnrichmentsTable get pendingEnrichments =>
      attachedDatabase.pendingEnrichments;
  EnrichmentDaoManager get managers => EnrichmentDaoManager(this);
}

class EnrichmentDaoManager {
  final _$EnrichmentDaoMixin _db;
  EnrichmentDaoManager(this._db);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db.attachedDatabase, _db.notebooks);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$WordTranslationsTableTableManager get wordTranslations =>
      $$WordTranslationsTableTableManager(
          _db.attachedDatabase, _db.wordTranslations);
  $$PendingEnrichmentsTableTableManager get pendingEnrichments =>
      $$PendingEnrichmentsTableTableManager(
          _db.attachedDatabase, _db.pendingEnrichments);
}
