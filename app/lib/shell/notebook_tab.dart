/// app/lib/shell/notebook_tab.dart
///
/// App-level composition of the notebook: the notebook feature's list +
/// the enrich feature's capture input + the notebook (legacy "volume")
/// picker + the settings feature's card zoom control, composed into the
/// word list's single-row toolbar. Lives in the app layer because it is
/// the one place allowed to know about all these features.
///
/// Notebook management mirrors the legacy volume rules:
///  * Names must be unique (case-insensitive) and non-empty.
///  * Only empty notebooks can be deleted; the last one never can.
///
/// Keyboard model:
///  * Ctrl+N — focus the inline capture field (favorites: quick-add dialog).
///  * Ctrl+F / Enter / Esc — handled inside WordListScreen.
///  * Ctrl+= / Ctrl+- / Ctrl+0 — card zoom in / out / reset (the
///    toolbar zoom control also responds to the mouse wheel).
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:feature_enrich/feature_enrich.dart';
import 'package:feature_notebook/feature_notebook.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'quick_add_dialog.dart';

/// Live per-notebook word counts: recomputed whenever any word changes.
final _notebookCountsProvider =
    FutureProvider.autoDispose<Map<int, int>>((ref) {
  final repo = ref.watch(notebookRepositoryProvider);
  final sub = repo.wordChanges.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.notebookWordCounts();
});

class NotebookTab extends ConsumerStatefulWidget {
  const NotebookTab({this.favoritesOnly = false, super.key});

  final bool favoritesOnly;

  @override
  ConsumerState<NotebookTab> createState() => _NotebookTabState();
}

class _NotebookTabState extends ConsumerState<NotebookTab> {
  final FocusNode _captureFocus = FocusNode();

  /// null = all notebooks (legacy "search everywhere" default).
  int? _notebookId;

  @override
  void dispose() {
    _captureFocus.dispose();
    super.dispose();
  }

  NotebookRepository get _repo => ref.read(notebookRepositoryProvider);

  void _selectWord(int id) =>
      ref.read(selectedWordIdProvider.notifier).select(id);

  void _handleWordCaptured(int id, String term) {
    ref.read(searchFocusCoordinatorProvider).requestSearchFocus();
    ref.read(wordListControllerProvider(WordListFilter(
      notebookId: _notebookId,
      favoritesOnly: widget.favoritesOnly,
    )).notifier).setQuery(term);
    ref.read(newlyAddedWordIdProvider.notifier).highlight(id);
    _selectWord(id);
  }

  /// "Add \u201cterm\u201d to your notebook" from the no-matches empty state.
  Future<void> _quickCapture(String term) async {
    final id = await ref
        .read(captureControllerProvider(CaptureScope.toolbar).notifier)
        .capture(term, notebookId: _notebookId);
    if (!mounted) return;
    if (id != null) {
      _handleWordCaptured(id, term);
    }
  }

  void _addWord() {
    if (widget.favoritesOnly) {
      showQuickAddWordDialog(context);
    } else {
      _captureFocus.requestFocus();
    }
  }

  /// Card zoom keyboard shortcuts (desktop convention; mirrors the
  /// toolbar zoom control, including its clamping).
  void _stepZoom(double delta) {
    final zoom = ref.read(cardStyleControllerProvider).value?.zoom ??
        VnCardStyle.defaultZoom;
    ref.read(cardStyleControllerProvider.notifier).setZoom(
          (zoom + delta)
              .clamp(VnCardStyle.minZoom, VnCardStyle.maxZoom)
              .toDouble(),
        );
  }

  void _zoomIn() => _stepZoom(VnCardStyle.zoomStep);

  void _zoomOut() => _stepZoom(-VnCardStyle.zoomStep);

  void _zoomReset() => ref
      .read(cardStyleControllerProvider.notifier)
      .setZoom(VnCardStyle.defaultZoom);

  void _showSnack(String message, {bool isError = false}) =>
      showVnSnackBar(context, message, isError: isError);

  Future<String?> _promptName({
    required String title,
    String initial = '',
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NamePromptDialog(title: title, initial: initial),
    );
    return result?.trim();
  }

  Future<void> _createNotebook() async {
    final name = await _promptName(title: 'New notebook');
    if (name == null || name.isEmpty) return;
    final result = await _repo.createNotebook(name);
    if (!mounted) return;
    switch (result) {
      case NotebookCreated(:final notebook):
        setState(() => _notebookId = notebook.id);
      case NotebookNameRejected(:final reason):
        _showSnack(reason, isError: true);
    }
  }

  Future<void> _renameNotebook(Notebook notebook) async {
    final name = await _promptName(
      title: 'Rename notebook',
      initial: notebook.name,
    );
    if (name == null || name.isEmpty || name == notebook.name) return;
    final result = await _repo.renameNotebook(notebook.id, name);
    if (!mounted) return;
    if (result case NotebookNameRejected(:final reason)) {
      _showSnack(reason, isError: true);
    }
  }

  Future<void> _deleteNotebook(Notebook notebook) async {
    final confirmed = await showVnConfirmDialog(
      context,
      title: 'Delete \u201c${notebook.name}\u201d?',
      message: 'Only empty notebooks can be deleted. This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    final error = await _repo.deleteNotebook(notebook.id);
    if (!mounted) return;
    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      setState(() => _notebookId = null);
    }
  }

  /// Compact notebook picker, visually matched to the toolbar's input
  /// fields (same fill, border, and radius) so the row reads as one
  /// unified control area.
  Widget _notebookPicker(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    final notebooksAsync = ref.watch(notebooksProvider);
    final notebooks = notebooksAsync.value ?? const <Notebook>[];
    final counts = ref.watch(_notebookCountsProvider).value ??
        const <int, int>{};

    // The selected notebook may have been deleted elsewhere.
    if (notebooksAsync.hasValue &&
        _notebookId != null &&
        notebooks.every((n) => n.id != _notebookId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _notebookId = null);
      });
    }

    final selected = notebooks
        .where((n) => n.id == _notebookId)
        .firstOrNull;
    final totalCount =
        counts.values.fold<int>(0, (sum, count) => sum + count);

    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: VnSpacing.x3),
      decoration: BoxDecoration(
        color: tokens.surfaceInput,
        borderRadius: BorderRadius.circular(VnRadius.md),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined, size: 16, color: tokens.textMuted),
          const SizedBox(width: VnSpacing.x2),
          Flexible(
            child: VnSelect<int>(
              variant: VnSelectVariant.bare,
              // -1 = all notebooks (the picker needs a non-null value).
              value: _notebookId ?? -1,
              semanticLabel: 'Notebook',
              tooltip: 'Choose which notebook to show',
              textStyle: textTheme.bodyMedium
                  ?.copyWith(color: tokens.textPrimary),
              options: [
                VnSelectOption(
                  value: -1,
                  label: 'All notebooks ($totalCount)',
                ),
                for (final notebook in notebooks)
                  VnSelectOption(
                    value: notebook.id,
                    label: '${notebook.name} (${counts[notebook.id] ?? 0})',
                  ),
              ],
              onSelected: (value) => setState(
                () => _notebookId = value == -1 ? null : value,
              ),
            ),
          ),
          VnOverflowMenuButton(
            tooltip: 'Manage notebooks',
            iconSize: 18,
            dense: true,
            actions: [
              VnMenuAction(
                label: 'New notebook\u2026',
                icon: Icons.add,
                onSelected: _createNotebook,
              ),
              VnMenuAction(
                label: 'Rename selected\u2026',
                icon: Icons.drive_file_rename_outline,
                enabled: selected != null,
                onSelected: () {
                  if (selected != null) _renameNotebook(selected);
                },
              ),
              VnMenuAction(
                label: 'Delete selected\u2026',
                icon: Icons.delete_outline,
                enabled: selected != null,
                destructive: true,
                onSelected: () {
                  if (selected != null) _deleteNotebook(selected);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Toolbar leading slot: notebook picker + capture input on one row.
  Widget _toolbarLeading(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
            child: _notebookPicker(context),
          ),
        ),
        const SizedBox(width: VnSpacing.x2),
        Expanded(
          child: CaptureInput(
            notebookId: _notebookId,
            focusNode: _captureFocus,
            autofocus: true,
            onCaptured: _handleWordCaptured,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Overrides the shell-level Ctrl+N: on the notebook tab the inline
        // capture field is faster than a dialog.
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _addWord,
        // Card zoom, matching the toolbar zoom control (and the desktop
        // convention of Ctrl+= / Ctrl+- / Ctrl+0).
        const SingleActivator(LogicalKeyboardKey.equal, control: true):
            _zoomIn,
        const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true):
            _zoomIn,
        const SingleActivator(LogicalKeyboardKey.minus, control: true):
            _zoomOut,
        const SingleActivator(
          LogicalKeyboardKey.numpadSubtract,
          control: true,
        ): _zoomOut,
        const SingleActivator(LogicalKeyboardKey.digit0, control: true):
            _zoomReset,
        const SingleActivator(LogicalKeyboardKey.numpad0, control: true):
            _zoomReset,
      },
      child: WordListScreen(
        filter: WordListFilter(
          notebookId: _notebookId,
          favoritesOnly: widget.favoritesOnly,
        ),
        toolbarLeading:
            widget.favoritesOnly ? null : _toolbarLeading(context),
        toolbarTrailing: const CardZoomControl(),
        onAddWord: _addWord,
        onImport: () => context.go('/settings?tab=data'),
        onQuickCapture: widget.favoritesOnly ? null : _quickCapture,
      ),
    );
  }
}

/// Name-entry dialog that owns its [TextEditingController] so the
/// controller's lifetime matches the dialog's element lifetime. Disposing
/// a controller from the caller immediately after `showDialog` returns is
/// unsafe: the route's exit transition may still be rendering the field.
class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
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
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Notebook name'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
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
