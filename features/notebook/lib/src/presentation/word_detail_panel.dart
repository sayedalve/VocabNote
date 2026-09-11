/// features/notebook/lib/src/presentation/word_detail_panel.dart
///
/// The card detail view. Used docked (side panel) on wide layouts and as a
/// pushed screen ([WordDetailScreen]) on narrow layouts. Reactive: it watches
/// the word row, so AI enrichment completing updates it live.
///
/// Parity with the legacy desktop card: every card field is editable via a
/// small per-section edit action, synonyms/antonyms can be marked important
/// by clicking their chips (accented, like the legacy ACCENT-bold tags), and
/// the card can be re-enriched with AI without losing notes or favorites.
library;

import 'package:core_db/core_db.dart';
import 'package:core_design_system/core_design_system.dart';
import 'package:core_tts/core_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/important_terms.dart';
import '../domain/pronunciation.dart';
import '../domain/word.dart';

class WordDetailScreen extends StatelessWidget {
  const WordDetailScreen({required this.wordId, super.key});

  final int wordId;

  @override
  Widget build(BuildContext context) {
    // Esc closes the card, mirroring the search field's Esc behavior on
    // the list screen.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: Scaffold(
          appBar: AppBar(title: const Text('Word')),
          body: SafeArea(child: WordDetailPanel(wordId: wordId)),
        ),
      ),
    );
  }
}

class WordDetailPanel extends ConsumerWidget {
  const WordDetailPanel({required this.wordId, super.key});

  final int wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordAsync = ref.watch(wordDetailProvider(wordId));
    final translations =
        ref.watch(wordTranslationsProvider(wordId)).value ??
            const <String, String>{};

    return switch (wordAsync) {
      // SelectionArea: all card text is immediately selectable.
      AsyncData(value: final Word word) => SelectionArea(
          child: _WordDetailBody(word: word, translations: translations),
        ),
      AsyncData() => const Center(child: Text('This word was deleted.')),
      AsyncError() => const Center(child: Text('Could not load this word.')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _WordDetailBody extends ConsumerStatefulWidget {
  const _WordDetailBody({required this.word, required this.translations});

  final Word word;
  final Map<String, String> translations;

  @override
  ConsumerState<_WordDetailBody> createState() => _WordDetailBodyState();
}

class _WordDetailBodyState extends ConsumerState<_WordDetailBody> {
  late final TextEditingController _notesController =
      TextEditingController(text: widget.word.notes);
  bool _notesDirty = false;

  @override
  void didUpdateWidget(covariant _WordDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word.id != widget.word.id) {
      _notesController.text = widget.word.notes;
      _notesDirty = false;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    await ref.read(notebookRepositoryProvider).updateWordFields(
          widget.word.id,
          WordFieldPatch(notes: _notesController.text.trim()),
        );
    if (mounted) setState(() => _notesDirty = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showVnConfirmDialog(
      context,
      title: 'Delete \u201c${widget.word.headword}\u201d?',
      message: 'This removes the word and its card.',
      confirmLabel: 'Delete',
    );
    if (confirmed) {
      await ref.read(notebookRepositoryProvider).deleteWord(widget.word.id);
      ref.read(selectedWordIdProvider.notifier).select(null);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Generic single-field edit dialog. Returns the trimmed new value, or
  /// null when cancelled.
  Future<String?> _promptEdit({
    required String title,
    required String initial,
    String hint = '',
    int maxLines = 1,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditPromptDialog(
        title: title,
        initial: initial,
        hint: hint,
        maxLines: maxLines,
      ),
    );
    return result?.trim();
  }

  Future<void> _patch(WordFieldPatch patch) => ref
      .read(notebookRepositoryProvider)
      .updateWordFields(widget.word.id, patch);

  Future<void> _editMeaning() async {
    final value = await _promptEdit(
      title: 'Edit meaning',
      initial: widget.word.meaning,
      maxLines: 4,
    );
    if (value != null) await _patch(WordFieldPatch(meaning: value));
  }

  Future<void> _editExample() async {
    final value = await _promptEdit(
      title: 'Edit example sentence',
      initial: widget.word.exampleSentence,
      maxLines: 4,
    );
    if (value != null) await _patch(WordFieldPatch(exampleSentence: value));
  }

  Future<void> _editSynonyms() async {
    final value = await _promptEdit(
      title: 'Edit synonyms',
      initial: widget.word.synonyms,
      hint: 'Comma-separated, e.g. quick, rapid, swift',
      maxLines: 3,
    );
    if (value != null) await _patch(WordFieldPatch(synonyms: value));
  }

  Future<void> _editAntonyms() async {
    final value = await _promptEdit(
      title: 'Edit antonyms',
      initial: widget.word.antonyms,
      hint: 'Comma-separated, e.g. slow, sluggish',
      maxLines: 3,
    );
    if (value != null) await _patch(WordFieldPatch(antonyms: value));
  }

  Future<void> _editBangla() async {
    final value = await _promptEdit(
      title: 'Edit Bangla meaning',
      initial: widget.translations['bn'] ?? '',
      maxLines: 3,
    );
    if (value != null) {
      await ref.read(appDatabaseProvider).wordDao.upsertTranslation(
            wordId: widget.word.id,
            langCode: 'bn',
            translation: value,
          );
    }
  }

  Future<void> _editIpaAndPos() async {
    final ipa = await _promptEdit(
      title: 'Edit IPA (pronunciation)',
      initial: widget.word.ipa,
      hint: 'e.g. \u02c8w\u0254\u02d0t\u0259',
    );
    if (ipa == null || !mounted) return;
    final pos = await _promptEdit(
      title: 'Edit part of speech',
      initial: widget.word.partOfSpeech,
      hint: 'e.g. noun, verb, adjective',
    );
    await _patch(
      WordFieldPatch(ipa: ipa, partOfSpeech: pos),
    );
  }

  /// Toggles a synonym/antonym term in or out of the "important" set
  /// (legacy accent-bold tags). The toggle logic lives in
  /// [toggleImportantTermPatch], shared with the notebook cards so both
  /// surfaces use the exact same persistent-highlight behavior.
  Future<void> _toggleImportant({
    required String term,
    required bool synonym,
  }) async {
    final patch =
        toggleImportantTermPatch(widget.word, term, synonym: synonym);
    if (patch != null) await _patch(patch);
  }

  /// Re-runs AI enrichment for this card. Notes, favorite status, and
  /// important markers are preserved (the enrichment pipeline only writes
  /// card fields).
  Future<void> _refreshWithAi() async {
    final confirmed = await showVnConfirmDialog(
      context,
      title: 'Refresh card with AI?',
      message:
          'The meaning, Bangla, IPA, part of speech, example, synonyms, and '
          'antonyms will be regenerated. Your notes, favorites, and '
          'important markers are kept.',
      confirmLabel: 'Refresh',
    );
    if (!confirmed || !mounted) return;
    await ref
        .read(appDatabaseProvider)
        .enrichmentDao
        .enqueueExisting(widget.word.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Re-enriching \u201c${widget.word.headword}\u201d...'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    final bangla = widget.translations['bn'] ?? '';
    final pronunciation = formatPronunciation(
      word.ipa,
      simplified: VnCardStyleScope.of(context).simplifiedPronunciation,
    );

    return ListView(
      padding: const EdgeInsets.all(VnSpacing.x5),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.headword, style: textTheme.headlineSmall),
                  if (pronunciation.isNotEmpty ||
                      word.partOfSpeech.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: VnSpacing.x1),
                      child: Text(
                        [
                          if (pronunciation.isNotEmpty) pronunciation,
                          if (word.partOfSpeech.isNotEmpty) word.partOfSpeech,
                        ].join('  \u00b7  '),
                        style: textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit IPA / part of speech',
              onPressed: _editIpaAndPos,
              icon: Icon(Icons.edit_outlined, color: tokens.textMuted),
            ),
            IconButton(
              tooltip: 'Refresh card with AI',
              onPressed: _refreshWithAi,
              icon: Icon(Icons.auto_awesome, color: tokens.textMuted),
            ),
            IconButton(
              tooltip: 'Pronounce',
              onPressed: () =>
                  ref.read(ttsServiceProvider).speak(word.headword),
              icon: Icon(Icons.volume_up_outlined, color: tokens.textMuted),
            ),
            IconButton(
              tooltip: word.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              onPressed: () => ref
                  .read(notebookRepositoryProvider)
                  .setFavorite(word.id, value: !word.isFavorite),
              icon: Icon(
                word.isFavorite ? Icons.star : Icons.star_border,
                color: word.isFavorite ? tokens.favorite : tokens.textMuted,
              ),
            ),
            IconButton(
              tooltip: 'Delete word',
              onPressed: _confirmDelete,
              icon: Icon(Icons.delete_outline, color: tokens.danger),
            ),
          ],
        ),
        const SizedBox(height: VnSpacing.x4),
        if (!word.isEnriched)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(VnSpacing.x4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: VnSpacing.x3),
                  Expanded(
                    child: Text(
                      'Saved locally. The card will fill in automatically '
                      'when enrichment completes.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (word.meaning.isNotEmpty || word.isEnriched)
          _DetailSection(
            title: 'Meaning',
            onEdit: _editMeaning,
            child: Text(word.meaning.isEmpty ? '\u2014' : word.meaning),
          ),
        if (bangla.isNotEmpty || word.isEnriched)
          _DetailSection(
            title: 'Bangla',
            onEdit: _editBangla,
            child: Text(
              bangla.isEmpty ? '\u2014' : bangla,
              style: textTheme.bodyLarge,
            ),
          ),
        if (word.exampleSentence.isNotEmpty || word.isEnriched)
          _DetailSection(
            title: 'Example',
            onEdit: _editExample,
            child: Text(
              word.exampleSentence.isEmpty ? '\u2014' : word.exampleSentence,
              style: textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        // Important terms (legacy accent-bold tags) are merged into the main
        // chip lists: click a chip to toggle its importance.
        if (word.synonymList.isNotEmpty || word.isEnriched)
          _DetailSection(
            title: 'Synonyms',
            subtitle: word.synonymList.isEmpty
                ? null
                : 'Click a chip to mark it important',
            onEdit: _editSynonyms,
            child: _TermChips(
              terms: word.synonymList,
              important: word.importantSynonymList,
              onToggle: (term) =>
                  _toggleImportant(term: term, synonym: true),
            ),
          ),
        if (word.antonymList.isNotEmpty || word.isEnriched)
          _DetailSection(
            title: 'Antonyms',
            subtitle: word.antonymList.isEmpty
                ? null
                : 'Click a chip to mark it important',
            onEdit: _editAntonyms,
            child: _TermChips(
              terms: word.antonymList,
              important: word.importantAntonymList,
              onToggle: (term) =>
                  _toggleImportant(term: term, synonym: false),
            ),
          ),
        _DetailSection(
          title: 'Notes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 6,
                decoration:
                    const InputDecoration(hintText: 'Add your own notes...'),
                onChanged: (_) {
                  if (!_notesDirty) setState(() => _notesDirty = true);
                },
              ),
              if (_notesDirty)
                Padding(
                  padding: const EdgeInsets.only(top: VnSpacing.x2),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _saveNotes,
                      child: const Text('Save notes'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.onEdit,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: VnSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title.toUpperCase(), style: textTheme.labelSmall),
              if (onEdit != null) ...[
                const SizedBox(width: VnSpacing.x1),
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(VnRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: tokens.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle case final sub?)
            Text(
              sub,
              style: textTheme.labelSmall?.copyWith(color: tokens.textMuted),
            ),
          const SizedBox(height: VnSpacing.x2),
          child,
        ],
      ),
    );
  }
}

/// Synonym/antonym chips. Important terms render accented (legacy
/// ACCENT-bold treatment); clicking a chip toggles importance.
class _TermChips extends StatelessWidget {
  const _TermChips({
    required this.terms,
    this.important = const [],
    this.onToggle,
  });

  final List<String> terms;
  final List<String> important;
  final ValueChanged<String>? onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final importantLower = {for (final t in important) t.toLowerCase()};
    if (terms.isEmpty) return const Text('\u2014');
    return Wrap(
      spacing: VnSpacing.x2,
      runSpacing: VnSpacing.x2,
      children: [
        for (final term in terms)
          FilterChip(
            label: Text(term),
            selected: importantLower.contains(term.toLowerCase()),
            selectedColor: tokens.accent.withValues(alpha: 0.18),
            checkmarkColor: tokens.accent,
            onSelected:
                onToggle == null ? null : (_) => onToggle!(term),
          ),
      ],
    );
  }
}

/// Single-field edit dialog that owns its [TextEditingController] so the
/// controller's lifetime matches the dialog's element lifetime. Disposing
/// a controller from the caller immediately after `showDialog` returns is
/// unsafe: the route's exit transition may still be rendering the field.
class _EditPromptDialog extends StatefulWidget {
  const _EditPromptDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.maxLines,
  });

  final String title;
  final String initial;
  final String hint;
  final int maxLines;

  @override
  State<_EditPromptDialog> createState() => _EditPromptDialogState();
}

class _EditPromptDialogState extends State<_EditPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          autofocus: true,
          minLines: widget.maxLines > 1 ? 2 : 1,
          maxLines: widget.maxLines,
          decoration: InputDecoration(hintText: widget.hint),
          onSubmitted: widget.maxLines == 1
              ? (value) => Navigator.of(context).pop(value)
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
