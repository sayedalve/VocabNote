/// features/notebook/lib/src/presentation/word_list_screen.dart
///
/// The main notebook surface: one simple, standard vertical scrolling list
/// under a single-row toolbar. Strictly virtualized (ListView.builder with
/// variable-height preview cards), debounced FTS search, infinite scroll
/// via keyset pagination.
///
/// Toolbar model: everything lives on ONE compact horizontal row -
/// [toolbarLeading] (composed by the app shell: notebook picker + capture
/// input), the search field, and [toolbarTrailing] (card zoom control).
/// The slots keep this feature decoupled from the enrich and settings
/// features.
///
/// There is deliberately no master-detail split view: double-clicking a
/// word always opens its card as a normal pushed screen, at every window
/// size.
///
/// Keyboard model:
///  * Ctrl+F is owned by the app shell (the only binding, so it works no
///    matter which widget has focus) and arrives here through
///    [SearchFocusCoordinator]; Esc clears the search (or unfocuses it
///    when already empty).
///  * Enter in the search field opens the first matching word.
///  * A root [Focus] node autofocuses when there is no toolbar leading slot
///    (Favorites tab), so shortcuts work before the user clicks anything;
///    on the notebook tab the capture field autofocuses instead.
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:core_tts/core_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../application/search_focus.dart';
import '../application/word_list_controller.dart';
import '../domain/important_terms.dart';
import '../domain/word.dart';
import 'word_card.dart';
import 'word_detail_panel.dart';

class WordListScreen extends ConsumerStatefulWidget {
  const WordListScreen({
    this.filter = const WordListFilter(),
    this.toolbarLeading,
    this.toolbarTrailing,
    this.onAddWord,
    this.onImport,
    this.onQuickCapture,
    super.key,
  });

  final WordListFilter filter;

  /// Slot rendered before the search field on the toolbar row (composed by
  /// the app shell: notebook picker + capture input, so this feature stays
  /// decoupled from the enrich feature).
  final Widget? toolbarLeading;

  /// Slot rendered after the search field on the toolbar row (composed by
  /// the app shell: the card zoom control).
  final Widget? toolbarTrailing;

  /// Empty-state “Add your first word” action (wired by the app shell).
  final VoidCallback? onAddWord;

  /// Empty-state “Import existing vocabulary” action (wired by the app
  /// shell; navigates to Settings → Data).
  final VoidCallback? onImport;

  /// “Add “term” to your notebook” action shown when a search has no
  /// matches (wired by the app shell to the capture flow).
  final ValueChanged<String>? onQuickCapture;

  @override
  ConsumerState<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends ConsumerState<WordListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late final SearchFocusCoordinator _searchFocusCoordinator;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    // App-wide Ctrl+F: the shell broadcasts a focus request; whichever
    // word list is visible responds (_onSearchFocusRequested).
    _searchFocusCoordinator = ref.read(searchFocusCoordinatorProvider)
      ..addListener(_onSearchFocusRequested);
  }

  @override
  void dispose() {
    _searchFocusCoordinator.removeListener(_onSearchFocusRequested);
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  WordListController get _controller =>
      ref.read(wordListControllerProvider(widget.filter).notifier);

  void _maybeLoadMore() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _controller.loadMore();
    }
  }

  /// Opens the word card as a normal pushed screen.
  void _openWord(BuildContext context, Word word) {
    ref.read(selectedWordIdProvider.notifier).select(word.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WordDetailScreen(wordId: word.id),
      ),
    );
  }

  /// Enter in the search field opens the first matching word.
  void _openFirstResult() {
    final state = ref.read(wordListControllerProvider(widget.filter)).value;
    if (state != null && state.words.isNotEmpty) {
      _openWord(context, state.words.first);
    } else {
      // Keep focus for continued typing on desktop.
      _searchFocus.requestFocus();
    }
  }

  /// Toggles the clicked synonym/antonym in the word's persistent
  /// "important" highlight set - the exact state the detail view chips
  /// use ([toggleImportantTermPatch] is shared by both surfaces, and the
  /// set is stored on the word row itself). Highlights accumulate,
  /// survive restarts, and stay in sync with the detail view; clicking an
  /// already-highlighted term removes it, exactly like the detail view.
  /// Deliberately does NOT run a search - the list stays exactly as it is.
  Future<void> _toggleImportantTerm(Word word, String term) async {
    final patch = toggleImportantTermPatch(word, term);
    if (patch == null) return;
    await ref
        .read(notebookRepositoryProvider)
        .updateWordFields(word.id, patch);
  }

  /// Context-menu delete with an explicit confirmation, mirroring the
  /// detail panel's delete flow.
  Future<void> _confirmDeleteWord(Word word) async {
    final confirmed = await showVnConfirmDialog(
      context,
      title: 'Delete \u201c${word.headword}\u201d?',
      message: 'This removes the word and its card.',
      confirmLabel: 'Delete',
    );
    if (confirmed && mounted) {
      await _controller.deleteWord(word);
    }
  }

  /// Responds to the shell's app-wide Ctrl+F only while this screen is
  /// the visible tab branch (offstage IndexedStack branches have their
  /// tickers disabled, which is what TickerMode reports).
  void _onSearchFocusRequested() {
    if (mounted && TickerMode.getNotifier(context).value) {
      _focusSearch();
    }
  }

  /// Focuses the search field and selects its text so typing replaces the
  /// previous query.
  ///
  /// When another widget holds focus (e.g. the capture field, which
  /// autofocuses on the notebook tab), moving focus synchronously while
  /// that text field's key event is still being dispatched is unreliable
  /// on desktop -- the focused field re-asserts its input connection.
  /// Unfocus first and grab focus on the next frame instead.
  void _focusSearch() {
    if (_searchFocus.hasFocus) {
      _selectAllSearchText();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocus.requestFocus();
      _selectAllSearchText();
    });
  }

  void _selectAllSearchText() {
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.setQuery('');
  }

  void _handleEscape() {
    if (_searchController.text.isNotEmpty) {
      _clearSearch();
    } else {
      _searchFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(wordListControllerProvider(widget.filter));

    // Reset scroll to the top when the search query changes.
    ref.listen(wordListControllerProvider(widget.filter), (previous, next) {
      final value = next.value;
      if (value == null) return;
      if (previous?.value?.query != value.query &&
          _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    // Ctrl+F is deliberately NOT bound here: a binding this deep in the
    // tree would shadow the shell's app-wide handler whenever focus sits
    // inside this subtree (notably the capture field on the notebook
    // tab), which is exactly what used to break Ctrl+F there. The shell
    // owns the single Ctrl+F binding and broadcasts through
    // SearchFocusCoordinator; _focusSearch handles the request safely.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _handleEscape,
      },
      // CallbackShortcuts only fires while focus is INSIDE its subtree.
      // When no toolbar leading slot exists (Favorites tab has no
      // autofocusing capture field), this root node takes focus so Esc
      // works immediately, without requiring a click first.
      child: Focus(
        autofocus: widget.toolbarLeading == null,
        skipTraversal: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VnSpacing.x3,
                VnSpacing.x3,
                VnSpacing.x3,
                VnSpacing.x2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.toolbarLeading case final leading?) ...[
                    Expanded(flex: 5, child: leading),
                    const SizedBox(width: VnSpacing.x2),
                  ],
                  Expanded(flex: 4, child: _buildSearchField()),
                  if (widget.toolbarTrailing case final trailing?) ...[
                    const SizedBox(width: VnSpacing.x2),
                    trailing,
                  ],
                ],
              ),
            ),
            Expanded(
              child: switch (asyncState) {
                AsyncData(:final value) => _buildList(context, value),
                AsyncError(:final error) => _ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(
                      wordListControllerProvider(widget.filter),
                    ),
                  ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Rebuilds only the search field on text changes (the old
  /// setState-per-keystroke rebuilt the whole screen). Dense so the whole
  /// toolbar stays one compact row.
  Widget _buildSearchField() {
    return ListenableBuilder(
      listenable: _searchController,
      builder: (context, _) => TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: VnSpacing.x3,
            vertical: VnSpacing.x2 + 2,
          ),
          hintText: 'Search...  (Ctrl+F)',
          prefixIcon: const Icon(Icons.search, size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search (Esc)',
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: _clearSearch,
                ),
        ),
        onChanged: _controller.setQuery,
        onSubmitted: (_) => _openFirstResult(),
      ),
    );
  }

  Widget _buildList(BuildContext context, WordListState state) {
    if (state.words.isEmpty) {
      return _EmptyState(
        isSearching: state.isSearching,
        query: state.query,
        favoritesOnly: widget.filter.favoritesOnly,
        onAddWord: widget.onAddWord,
        onImport: widget.onImport,
        onQuickCapture: widget.onQuickCapture,
      );
    }

    final itemCount = state.words.length + (state.hasMore ? 1 : 0);
    final newlyAddedId = ref.watch(newlyAddedWordIdProvider);

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: itemCount,
        padding: const EdgeInsets.only(bottom: VnSpacing.x8),
        itemBuilder: (context, index) {
          if (index >= state.words.length) {
            return const SizedBox(
              height: 56,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          final word = state.words[index];
          return WordCard(
            key: ValueKey(word.id),
            word: word,
            isNewlyAdded: word.id == newlyAddedId,
            onOpen: () => _openWord(context, word),
            onEdit: () => _openWord(context, word),
            onDelete: () => _confirmDeleteWord(word),
            onToggleFavorite: () => _controller.toggleFavorite(word),
            onPronounce: () =>
                ref.read(ttsServiceProvider).speak(word.headword),
            onTermTap: (term) => _toggleImportantTerm(word, term),
            highlightedTerm:
                state.query.trim().isEmpty ? null : state.query.trim(),
          );
        },
      ),
    );
  }
}

/// Three distinct empty states: onboarding (notebook truly empty), no
/// favorites, and no search matches (with a one-click “add this word”).
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSearching,
    required this.query,
    required this.favoritesOnly,
    this.onAddWord,
    this.onImport,
    this.onQuickCapture,
  });

  final bool isSearching;
  final String query;
  final bool favoritesOnly;
  final VoidCallback? onAddWord;
  final VoidCallback? onImport;
  final ValueChanged<String>? onQuickCapture;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;

    if (isSearching) {
      return _CenteredMessage(
        icon: Icons.search_off,
        title: 'No matches for “$query”',
        body: 'Check the spelling or try a different term.',
        actions: [
          if (onQuickCapture case final capture?)
            FilledButton.tonalIcon(
              onPressed: () => capture(query),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add “$query” to your notebook'),
            ),
        ],
      );
    }

    if (favoritesOnly) {
      return const _CenteredMessage(
        icon: Icons.star_border,
        title: 'No favorites yet',
        body: 'Click the star on any word to pin it here.',
      );
    }

    // First-run onboarding.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VnSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.surfaceRaised,
                border: Border.all(color: tokens.border),
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 52,
                color: tokens.accent,
              ),
            ),
            const SizedBox(height: VnSpacing.x5),
            Text(
              'Your vocabulary notebook is empty.',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VnSpacing.x2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Add a word and the AI fills in its meaning, pronunciation, '
                'and examples — everything is stored offline on this PC.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: tokens.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: VnSpacing.x6),
            if (onAddWord case final addWord?)
              FilledButton.icon(
                onPressed: addWord,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add your first word'),
              ),
            if (onImport case final importAction?) ...[
              const SizedBox(height: VnSpacing.x3),
              OutlinedButton.icon(
                onPressed: importAction,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Import existing vocabulary'),
              ),
            ],
            const SizedBox(height: VnSpacing.x5),
            Text(
              'Tip: press Ctrl+N anywhere to add a word.',
              style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VnSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: tokens.textMuted),
            const SizedBox(height: VnSpacing.x4),
            Text(title, style: textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: VnSpacing.x2),
            Text(
              body,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            for (final action in actions) ...[
              const SizedBox(height: VnSpacing.x4),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VnSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: VnSpacing.x2),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: VnSpacing.x4),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
