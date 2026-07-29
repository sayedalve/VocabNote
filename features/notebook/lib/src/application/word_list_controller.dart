/// features/notebook/lib/src/application/word_list_controller.dart
///
/// Owns word-list state: keyset pagination, debounced FTS search, optimistic
/// favorite/delete, and reactive refresh when the database changes.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/notebook_repository.dart';
import '../domain/word.dart';
import 'providers.dart';

part 'word_list_controller.freezed.dart';
part 'word_list_controller.g.dart';

/// Family key. Freezed gives value equality, which Riverpod families require.
@freezed
abstract class WordListFilter with _$WordListFilter {
  const factory WordListFilter({
    int? notebookId,
    @Default(false) bool favoritesOnly,
  }) = _WordListFilter;
}

@freezed
abstract class WordListState with _$WordListState {
  const factory WordListState({
    required List<Word> words,
    required bool hasMore,
    required int totalCount,
    @Default(false) bool isLoadingMore,
    @Default('') String query,
  }) = _WordListState;

  const WordListState._();

  bool get isSearching => query.isNotEmpty;
}

@riverpod
class WordListController extends _$WordListController {
  static const int pageSize = 60;
  static const Duration _searchDebounce = Duration(milliseconds: 250);

  Timer? _debounce;

  /// Monotonic token that guards every asynchronous state write. Debounced
  /// searches, reactive refreshes, and pagination can overlap; without the
  /// guard a slow older load could clobber the result of a newer one
  /// (classic stale-response race).
  int _loadGeneration = 0;

  @override
  Future<WordListState> build(WordListFilter filter) async {
    // Invalidate any in-flight load from a previous build cycle.
    _loadGeneration++;
    final repo = ref.watch(notebookRepositoryProvider);
    final subscription = repo.wordChanges.listen((_) => _refresh());
    ref.onDispose(() {
      subscription.cancel();
      _debounce?.cancel();
    });
    return _load(repo, query: '');
  }

  NotebookRepository get _repo => ref.read(notebookRepositoryProvider);

  Future<WordListState> _load(
    NotebookRepository repo, {
    required String query,
    int? minRows,
  }) async {
    if (query.isNotEmpty) {
      final results = await repo.search(
        query: query,
        notebookId: filter.notebookId,
        favoritesOnly: filter.favoritesOnly,
      );
      return WordListState(
        words: results,
        hasMore: false,
        totalCount: results.length,
        query: query,
      );
    }

    final limit = math.max(minRows ?? pageSize, pageSize);
    final (page, total) = await (
      repo.fetchPage(
        notebookId: filter.notebookId,
        favoritesOnly: filter.favoritesOnly,
        limit: limit,
      ),
      repo.countWords(
        notebookId: filter.notebookId,
        favoritesOnly: filter.favoritesOnly,
      ),
    ).wait;
    return WordListState(
      words: page,
      hasMore: page.length == limit && page.length < total,
      totalCount: total,
    );
  }

  /// Debounced search entry point bound to the search field.
  void setQuery(String raw) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () async {
      final generation = ++_loadGeneration;
      final next = await AsyncValue.guard(
        () => _load(_repo, query: raw.trim()),
      );
      if (generation != _loadGeneration) return;
      state = next;
    });
  }

  /// Loads the next alphabetical page (no-op while searching).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isSearching ||
        current.words.isEmpty) {
      return;
    }
    final generation = ++_loadGeneration;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final last = current.words.last;
    try {
      final next = await _repo.fetchPage(
        notebookId: filter.notebookId,
        favoritesOnly: filter.favoritesOnly,
        after: (norm: last.headwordNorm, id: last.id),
        limit: pageSize,
      );
      if (generation != _loadGeneration) return;
      state = AsyncData(
        current.copyWith(
          words: [...current.words, ...next],
          hasMore: next.length == pageSize,
          isLoadingMore: false,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (generation != _loadGeneration) return;
      state = AsyncError(error, stackTrace);
    }
  }

  /// Optimistic favorite toggle; the DB change stream reconciles afterwards.
  Future<void> toggleFavorite(Word word) async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          words: [
            for (final w in current.words)
              if (w.id == word.id)
                w.copyWith(isFavorite: !word.isFavorite)
              else
                w,
          ],
        ),
      );
    }
    await _repo.setFavorite(word.id, value: !word.isFavorite);
  }

  /// Optimistic delete; the DB change stream reconciles afterwards.
  Future<void> deleteWord(Word word) async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          words: [
            for (final w in current.words)
              if (w.id != word.id) w,
          ],
          totalCount: math.max(0, current.totalCount - 1),
        ),
      );
    }
    await _repo.deleteWord(word.id);
  }

  /// Re-fetches exactly as many rows as are visible so scroll position
  /// survives external changes (enrichment completing, captures, imports).
  Future<void> _refresh() async {
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    final generation = ++_loadGeneration;
    final next = await AsyncValue.guard(
      () => _load(
        _repo,
        query: current.query,
        minRows: current.words.length,
      ),
    );
    if (generation != _loadGeneration) return;
    state = next;
  }
}
