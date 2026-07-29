/// features/notebook/lib/src/presentation/word_card.dart
///
/// One row in the word list, an always-visible preview card: every word
/// shows its meaning, Bangla translation, example, synonyms/antonyms, and
/// notes without requiring selection.
///
/// This is a thin domain adapter around the shared [VnVocabCard] surface
/// (core_design_system): it maps a [Word] to plain display strings, formats
/// pronunciation according to the active [VnCardStyle], and contributes the
/// row-level actions (pronounce, favorite) plus the right-click context
/// menu (Edit / Copy / Delete Word). All typography and spacing decisions
/// live in [VnVocabCard], so the list rows and the Typography & Spacing
/// live preview can never drift apart.
///
/// Context-menu model: the card is wrapped in a [MenuAnchor] so the
/// right-click menu shares the app-wide menu behavior contract from
/// core_design_system (outside clicks close the menu and are consumed,
/// Esc dismisses, arrow keys traverse, items expose button semantics)
/// instead of a one-off `showMenu` overlay. [VnVocabCard.onContextMenu]
/// reports the global click position; it is converted to the anchor's
/// local space so the menu opens exactly under the pointer.
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/pronunciation.dart';
import '../domain/word.dart';

class WordCard extends StatefulWidget {
  const WordCard({
    required this.word,
    required this.onOpen,
    required this.onToggleFavorite,
    this.onEdit,
    this.onDelete,
    this.onPronounce,
    this.onTermTap,
    this.highlightedTerm,
    super.key,
  });

  final Word word;

  /// Opens the word's detail view; fired when the card is double-clicked.
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;

  /// "Edit Word" context-menu action; falls back to [onOpen] when null
  /// (the detail view is the editing surface).
  final VoidCallback? onEdit;

  /// "Delete Word" context-menu action. The caller owns any confirmation
  /// dialog. When null the menu item is not shown.
  final VoidCallback? onDelete;

  final VoidCallback? onPronounce;

  /// Fired with the clicked synonym/antonym term (toggles the term in the
  /// word's persistent "important" highlight set, shared with the detail
  /// view chips).
  final ValueChanged<String>? onTermTap;

  /// Term to highlight on the card (a clicked synonym/antonym or the
  /// active search query).
  final String? highlightedTerm;

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  final MenuController _contextMenu = MenuController();

  /// Opens the context menu at the right-clicked position. The position
  /// arrives in global coordinates (from the raw-pointer listener inside
  /// [VnVocabCard]) and [MenuController.open] expects the anchor's local
  /// space.
  void _openContextMenu(Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;
    _contextMenu.open(position: renderObject.globalToLocal(globalPosition));
  }

  Future<void> _copyWord() async {
    await Clipboard.setData(ClipboardData(text: widget.word.headword));
    if (mounted) {
      showVnSnackBar(
        context,
        '\u201c${widget.word.headword}\u201d copied to clipboard.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final tokens = VnTheme.of(context).tokens;
    final style = VnCardStyleScope.of(context);

    return MenuAnchor(
      controller: _contextMenu,
      // Matches the app-wide menu contract (see core_design_system/menu):
      // an outside click closes the menu AND is consumed, so it can never
      // trigger the control underneath; Esc dismissal is built in.
      consumeOutsideTap: true,
      menuChildren: [
        MenuItemButton(
          onPressed: widget.onEdit ?? widget.onOpen,
          leadingIcon: Icon(
            Icons.edit_outlined,
            size: 18,
            color: tokens.textSecondary,
          ),
          child: const Text('Edit Word'),
        ),
        MenuItemButton(
          onPressed: _copyWord,
          leadingIcon: Icon(
            Icons.copy_outlined,
            size: 18,
            color: tokens.textSecondary,
          ),
          child: const Text('Copy Word'),
        ),
        if (widget.onDelete case final delete?)
          MenuItemButton(
            onPressed: delete,
            leadingIcon: Icon(
              Icons.delete_outline,
              size: 18,
              color: tokens.danger,
            ),
            child: Text(
              'Delete Word',
              style: TextStyle(color: tokens.danger),
            ),
          ),
      ],
      child: Semantics(
        button: true,
        label: word.headword,
        value: word.isEnriched ? word.meaning : 'Waiting for AI enrichment',
        child: Padding(
          // Half above + half below = [VnCardStyle.verticalSpacing] between
          // neighboring cards.
          padding: EdgeInsets.symmetric(
            horizontal: VnSpacing.x3,
            vertical: style.verticalSpacing / 2,
          ),
          child: VnVocabCard(
            headword: word.headword,
            partOfSpeech: word.partOfSpeech,
            pronunciation: formatPronunciation(
              word.ipa,
              simplified: style.simplifiedPronunciation,
            ),
            meaning: word.meaning,
            bangla: word.banglaMeaning,
            example: word.exampleSentence,
            synonyms: word.synonymList,
            antonyms: word.antonymList,
            importantSynonyms: word.importantSynonymList,
            importantAntonyms: word.importantAntonymList,
            notes: word.notes,
            isEnriched: word.isEnriched,
            onOpen: widget.onOpen,
            onTermTap: widget.onTermTap,
            onContextMenu: _openContextMenu,
            highlightedTerm: widget.highlightedTerm,
            trailing: [
              if (widget.onPronounce case final pronounce?)
                _SmallIconButton(
                  tooltip: 'Pronounce',
                  icon: Icons.volume_up_outlined,
                  color: tokens.textMuted,
                  onPressed: pronounce,
                ),
              _SmallIconButton(
                tooltip: word.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                icon: word.isFavorite ? Icons.star : Icons.star_border,
                color: word.isFavorite ? tokens.favorite : tokens.textMuted,
                onPressed: widget.onToggleFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
