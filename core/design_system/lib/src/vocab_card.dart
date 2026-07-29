/// core/design_system/lib/src/vocab_card.dart
///
/// The shared vocabulary-card surface: one presentational widget used by
/// the notebook list rows AND by the Typography & Spacing live preview, so
/// the two can never drift apart. Purely visual - it renders pre-formatted
/// strings and never knows about domain entities or persistence.
///
/// Typography contract:
///  * Headword: the only large element (accent color, bold) - the card's
///    primary visual focus. Sized by [VnCardStyle.headwordFontSize].
///  * Section labels ("Meaning", "Bangla", ...): bold, primary text color,
///    body size - visually distinct from values.
///  * Values: secondary grey at body size; the definition uses its own
///    [VnCardStyle.definitionFontSize].
///  * Important synonyms/antonyms: light blue (accentHover) + bold, same
///    size as surrounding terms.
///  * Notes: light blue highlight block tinted with the accent color.
///
/// Layout contract:
///  * Horizontal padding is [VnCardStyle.horizontalCardPadding] (twice the
///    vertical padding) so text never crowds the card edges.
///  * All card text sits inside a [SelectionArea]: it is immediately
///    selectable with a single click-and-drag, like a web page. No other
///    recognizer competes with selection in the gesture arena; opening
///    the card is a double-click, detected with the raw-pointer
///    [VnDoubleClickRegion] so it can never miss.
///  * Synonym/antonym terms are the one deliberate exception: when
///    [VnVocabCard.onTermTap] is set they render as inline buttons
///    (pointer cursor, hover underline, button semantics) so a single
///    click highlights the term without opening the card. Click-drag
///    over a term still selects text - only clean taps activate it.
///  * When [VnVocabCard.onContextMenu] is set, a right-click anywhere on
///    the card fires it with the global pointer position (raw-pointer
///    detection, like [VnDoubleClickRegion], so text selection can never
///    swallow the click) and the [SelectionArea]'s own right-click
///    toolbar is suppressed so exactly one menu appears.
///
/// Accessibility:
///  * When the card can be opened it is keyboard-focusable: Tab reaches
///    it, Enter/Space opens it, and focus shows an accent border ring.
///
/// Every font size and inner spacing is multiplied by [VnCardStyle.zoom],
/// so the toolbar's card-zoom control scales cards only.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'card_style.dart';
import 'double_click_region.dart';
import 'motion.dart';
import 'theme.dart';
import 'tokens.dart';

class VnVocabCard extends StatefulWidget {
  const VnVocabCard({
    required this.headword,
    this.style,
    this.partOfSpeech = '',
    this.pronunciation = '',
    this.meaning = '',
    this.bangla = '',
    this.example = '',
    this.synonyms = const <String>[],
    this.antonyms = const <String>[],
    this.importantSynonyms = const <String>[],
    this.importantAntonyms = const <String>[],
    this.notes = '',
    this.isEnriched = true,
    this.clampLines = true,
    this.onOpen,
    this.onTermTap,
    this.onContextMenu,
    this.highlightedTerm,
    this.trailing = const <Widget>[],
    super.key,
  });

  final String headword;

  /// Explicit style override; defaults to [VnCardStyleScope.of].
  final VnCardStyle? style;

  final String partOfSpeech;

  /// Pre-formatted pronunciation, e.g. "/kaet/" or "kat". Displayed as-is.
  final String pronunciation;

  final String meaning;
  final String bangla;
  final String example;
  final List<String> synonyms;
  final List<String> antonyms;

  /// Subset of [synonyms]/[antonyms] to emphasize (case-insensitive match).
  final List<String> importantSynonyms;
  final List<String> importantAntonyms;

  final String notes;

  /// When false, a "waiting for enrichment" hint replaces the sections.
  final bool isEnriched;

  /// List rows clamp long values with ellipses; the settings preview shows
  /// everything.
  final bool clampLines;

  /// Fired when the card is double-clicked or activated with the keyboard
  /// (Enter/Space while the card is focused) - the open-details affordance.
  ///
  /// Deliberately not a single tap: a single click + drag must always
  /// start text selection immediately, so no card-wide tap recognizer may
  /// compete with [SelectionArea].
  final VoidCallback? onOpen;

  /// When set, every synonym/antonym term becomes an inline button that
  /// fires with the clicked term (single click, no detail view needed).
  final ValueChanged<String>? onTermTap;

  /// Fired with the global pointer position when the card is right-clicked
  /// (secondary mouse button) - the context-menu affordance. When set, the
  /// card suppresses [SelectionArea]'s built-in right-click toolbar so
  /// only the caller's menu appears (Ctrl+C still copies selected text).
  final ValueChanged<Offset>? onContextMenu;

  /// Term rendered as actively highlighted (case-insensitive match),
  /// e.g. a clicked synonym/antonym or the active search query.
  final String? highlightedTerm;

  /// Row-level actions (pronounce, favorite) rendered next to the headword.
  final List<Widget> trailing;

  @override
  State<VnVocabCard> createState() => _VnVocabCardState();
}

class _VnVocabCardState extends State<VnVocabCard> {
  bool _focused = false;

  /// Raw-pointer right-click detection (see [VnDoubleClickRegion] for the
  /// rationale): a [Listener] never competes in the gesture arena, so the
  /// context menu and text selection can never steal each other's clicks.
  void _handleContextMenuPointerDown(PointerDownEvent event) {
    final onContextMenu = widget.onContextMenu;
    if (onContextMenu == null) return;
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kSecondaryMouseButton) {
      onContextMenu(event.position);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style ?? VnCardStyleScope.of(context);
    final tokens = VnTheme.of(context).tokens;
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    TextStyle sized(
      double size, {
      Color? color,
      FontWeight weight = VnTypeScale.regular,
      FontStyle? fontStyle,
    }) =>
        base.copyWith(
          fontSize: s.zoomed(size),
          height: s.lineHeight,
          color: color ?? tokens.textSecondary,
          fontWeight: weight,
          fontStyle: fontStyle,
        );

    final headwordStyle = sized(
      s.headwordFontSize,
      color: tokens.accent,
      weight: VnTypeScale.bold,
    ).copyWith(height: 1.2);
    final metaStyle = sized(
      s.bodyFontSize,
      color: tokens.textMuted,
      fontStyle: FontStyle.italic,
    );
    final bodyStyle = sized(s.bodyFontSize);
    final definitionStyle = sized(s.definitionFontSize);
    final labelStyle = sized(
      s.bodyFontSize,
      color: tokens.textPrimary,
      weight: VnTypeScale.bold,
    );
    final importantStyle = sized(
      s.bodyFontSize,
      color: tokens.accentHover,
      weight: VnTypeScale.bold,
    );

    final sections = <Widget>[
      if (!widget.isEnriched)
        Text(
          'Waiting for AI enrichment...',
          style: bodyStyle.copyWith(fontStyle: FontStyle.italic),
        )
      else ...[
        if (widget.meaning.isNotEmpty)
          _LabeledLine(
            label: 'Meaning',
            value: widget.meaning,
            labelStyle: labelStyle,
            valueStyle: definitionStyle,
            maxLines: widget.clampLines ? 2 : null,
          ),
        if (widget.bangla.isNotEmpty)
          _LabeledLine(
            label: 'Bangla',
            value: widget.bangla,
            labelStyle: labelStyle,
            valueStyle: bodyStyle,
            maxLines: widget.clampLines ? 1 : null,
          ),
        if (widget.example.isNotEmpty)
          _LabeledLine(
            label: 'Example',
            value: widget.example,
            labelStyle: labelStyle,
            valueStyle: bodyStyle.copyWith(fontStyle: FontStyle.italic),
            maxLines: widget.clampLines ? 2 : null,
          ),
        if (widget.synonyms.isNotEmpty)
          _TermsLine(
            label: 'Synonyms',
            terms: widget.synonyms,
            important: widget.importantSynonyms,
            labelStyle: labelStyle,
            termStyle: bodyStyle,
            importantStyle: importantStyle,
            maxLines: widget.clampLines ? 1 : null,
            onTermTap: widget.onTermTap,
            highlightedTerm: widget.highlightedTerm,
          ),
        if (widget.antonyms.isNotEmpty)
          _TermsLine(
            label: 'Antonyms',
            terms: widget.antonyms,
            important: widget.importantAntonyms,
            labelStyle: labelStyle,
            termStyle: bodyStyle,
            importantStyle: importantStyle,
            maxLines: widget.clampLines ? 1 : null,
            onTermTap: widget.onTermTap,
            highlightedTerm: widget.highlightedTerm,
          ),
      ],
      if (widget.notes.isNotEmpty)
        _NotesHighlight(
          notes: widget.notes,
          style: bodyStyle.copyWith(color: tokens.textPrimary),
          tokens: tokens,
          zoom: s.zoom,
          maxLines: widget.clampLines ? 2 : null,
        ),
    ];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: widget.headword, style: headwordStyle),
                    if (widget.pronunciation.isNotEmpty ||
                        widget.partOfSpeech.isNotEmpty)
                      TextSpan(
                        text: '  ${[
                          if (widget.pronunciation.isNotEmpty)
                            widget.pronunciation,
                          if (widget.partOfSpeech.isNotEmpty)
                            widget.partOfSpeech,
                        ].join('  ')}',
                        style: metaStyle,
                      ),
                  ],
                ),
                maxLines: widget.clampLines ? 1 : null,
                overflow: widget.clampLines ? TextOverflow.ellipsis : null,
              ),
            ),
            ...widget.trailing,
          ],
        ),
        for (final section in sections) ...[
          SizedBox(height: s.zoomed(s.sectionSpacing)),
          section,
        ],
      ],
    );

    final radius = BorderRadius.circular(s.cardRadius);
    Widget card = Material(
      color: tokens.surface,
      borderRadius: radius,
      child: VnDoubleClickRegion(
        onDoubleClick: widget.onOpen,
        child: AnimatedContainer(
          duration: vnMotionDuration(context, VnMotion.fast),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: _focused ? tokens.accent : tokens.border,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: s.zoomed(s.horizontalCardPadding),
            vertical: s.zoomed(s.horizontalCardPadding / 2),
          ),
          // With a card context menu the caller owns right-click, so the
          // selection toolbar is suppressed (only one menu may appear).
          child: widget.onContextMenu == null
              ? SelectionArea(child: content)
              : SelectionArea(
                  contextMenuBuilder: (context, selectableRegionState) =>
                      const SizedBox.shrink(),
                  child: content,
                ),
        ),
      ),
    );

    if (widget.onContextMenu != null) {
      card = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handleContextMenuPointerDown,
        child: card,
      );
    }

    if (widget.onOpen == null) return card;

    // Keyboard path to the double-click affordance: Tab focuses the card
    // (accent border ring), Enter/Space opens it.
    return FocusableActionDetector(
      onShowFocusHighlight: (focused) {
        if (_focused != focused) setState(() => _focused = focused);
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onOpen?.call();
            return null;
          },
        ),
      },
      child: card,
    );
  }
}

/// One "Label:  value" line rendered as a single wrapping rich text so
/// long values indent naturally under the label.
class _LabeledLine extends StatelessWidget {
  const _LabeledLine({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    this.maxLines,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label:  ', style: labelStyle),
          TextSpan(text: value, style: valueStyle),
        ],
      ),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// One "Synonyms:  a, b, c" line. Every term shares the same size;
/// important terms render light blue + bold (case-insensitive match).
/// When [onTermTap] is provided each term becomes an inline button
/// (pointer cursor, hover underline, button semantics) that toggles the
/// term's highlight; the term matching [highlightedTerm] gets an accent
/// highlight pill.
class _TermsLine extends StatelessWidget {
  const _TermsLine({
    required this.label,
    required this.terms,
    required this.important,
    required this.labelStyle,
    required this.termStyle,
    required this.importantStyle,
    this.maxLines,
    this.onTermTap,
    this.highlightedTerm,
  });

  final String label;
  final List<String> terms;
  final List<String> important;
  final TextStyle labelStyle;
  final TextStyle termStyle;
  final TextStyle importantStyle;
  final int? maxLines;
  final ValueChanged<String>? onTermTap;
  final String? highlightedTerm;

  @override
  Widget build(BuildContext context) {
    final importantLower = {
      for (final term in important) term.toLowerCase(),
    };
    final highlightedLower = highlightedTerm?.trim().toLowerCase();
    final onTap = onTermTap;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label:  ', style: labelStyle),
          for (var i = 0; i < terms.length; i++) ...[
            if (onTap == null)
              TextSpan(
                text: terms[i],
                style: importantLower.contains(terms[i].toLowerCase())
                    ? importantStyle
                    : termStyle,
              )
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: _InlineTerm(
                  term: terms[i],
                  style: importantLower.contains(terms[i].toLowerCase())
                      ? importantStyle
                      : termStyle,
                  active: highlightedLower != null &&
                      highlightedLower == terms[i].toLowerCase(),
                  onTap: () => onTap(terms[i]),
                ),
              ),
            if (i < terms.length - 1)
              TextSpan(text: ', ', style: termStyle),
          ],
        ],
      ),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// One clickable synonym/antonym rendered inline with surrounding text.
/// A clean single click fires [onTap] (highlight toggle); click-drag
/// still selects text. Hover shows a pointer cursor and accent underline;
/// the active term gets an accent highlight pill.
class _InlineTerm extends StatefulWidget {
  const _InlineTerm({
    required this.term,
    required this.style,
    required this.active,
    required this.onTap,
  });

  final String term;
  final TextStyle style;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_InlineTerm> createState() => _InlineTermState();
}

class _InlineTermState extends State<_InlineTerm> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    var style = widget.style;
    if (widget.active) {
      style = style.copyWith(
        color: tokens.accent,
        fontWeight: VnTypeScale.bold,
      );
    } else if (_hovered) {
      style = style.copyWith(
        color: tokens.accent,
        decoration: TextDecoration.underline,
        decorationColor: tokens.accent,
      );
    }
    return Semantics(
      button: true,
      label: 'Highlight \u201c${widget.term}\u201d',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.active
                  ? tokens.accent.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(VnRadius.sm / 2),
            ),
            child: Padding(
              padding: widget.active
                  ? const EdgeInsets.symmetric(horizontal: 3)
                  : EdgeInsets.zero,
              child: Text(widget.term, style: style),
            ),
          ),
        ),
      ),
    );
  }
}

/// The notes block: an accent-tinted highlight bar, visually distinct
/// from the labeled sections above it.
class _NotesHighlight extends StatelessWidget {
  const _NotesHighlight({
    required this.notes,
    required this.style,
    required this.tokens,
    required this.zoom,
    this.maxLines,
  });

  final String notes;
  final TextStyle style;
  final VnColorTokens tokens;
  final double zoom;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: VnSpacing.x3 * zoom,
        vertical: VnSpacing.x2 * zoom,
      ),
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(VnRadius.sm),
        border: Border(
          left: BorderSide(color: tokens.accent, width: 3),
        ),
      ),
      child: Text(
        notes,
        style: style,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      ),
    );
  }
}