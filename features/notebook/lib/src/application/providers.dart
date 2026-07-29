/// features/notebook/lib/src/application/providers.dart
library;

import 'package:core_db/core_db.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/drift_notebook_repository.dart';
import '../domain/notebook.dart';
import '../domain/notebook_repository.dart';
import '../domain/word.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
NotebookRepository notebookRepository(Ref ref) =>
    DriftNotebookRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<Notebook>> notebooks(Ref ref) =>
    ref.watch(notebookRepositoryProvider).watchNotebooks();

/// The word highlighted in the master-detail layout (null = nothing).
@riverpod
class SelectedWordId extends _$SelectedWordId {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

@riverpod
Stream<Word?> wordDetail(Ref ref, int wordId) =>
    ref.watch(notebookRepositoryProvider).watchWord(wordId);

@riverpod
Stream<Map<String, String>> wordTranslations(Ref ref, int wordId) =>
    ref.watch(notebookRepositoryProvider).watchTranslations(wordId);
