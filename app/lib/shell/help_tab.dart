/// app/lib/shell/help_tab.dart
///
/// The in-app help center: complete keyboard shortcuts plus a guide
/// organized into collapsible topics (getting started, editing, search,
/// favorites, quiz, AI, import/export, backups, FAQ, troubleshooting).
/// All content is plain widgets \u2014 no network, nothing to load \u2014 and the
/// whole page is wrapped in a SelectionArea so any text can be copied.
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/material.dart';

class HelpTab extends StatelessWidget {
  const HelpTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(VnSpacing.x6),
            children: [
              Text('Help & user guide', style: textTheme.titleLarge),
              const SizedBox(height: VnSpacing.x2),
              Text(
                'Everything you need to get the most out of VocabNote. '
                'Click a topic to expand it.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: tokens.textSecondary),
              ),
              const SizedBox(height: VnSpacing.x5),
              Text('Keyboard shortcuts', style: textTheme.titleMedium),
              const SizedBox(height: VnSpacing.x3),
              const ShortcutsCard(),
              const SizedBox(height: VnSpacing.x5),
              Text('Guide', style: textTheme.titleMedium),
              const SizedBox(height: VnSpacing.x3),
              const _HelpTopic(
                icon: Icons.rocket_launch_outlined,
                title: 'Getting started',
                bullets: [
                  'The Notebook section is home. Use the selector on the '
                      'left of the toolbar to pick a notebook, or open its '
                      'menu to create, rename, and delete notebooks.',
                  'Type a word into \u201cAdd a word...\u201d and press '
                      'Enter. It is saved instantly, and AI enrichment fills '
                      'in the card in the background.',
                  'Click any card to open its full view \u2014 every field '
                      'on the card can be edited there.',
                  'All data lives in a local database on this PC. The app '
                      'works fully offline; only AI enrichment needs a '
                      'network connection.',
                ],
              ),
              const _HelpTopic(
                icon: Icons.edit_note_outlined,
                title: 'Adding & editing words',
                bullets: [
                  'Add words from the toolbar field, or press Ctrl+N '
                      'anywhere to open the quick-add dialog and enter '
                      'several words in a row.',
                  'Open a word and use the small pencil icons to edit the '
                      'meaning, Bangla translation, example, synonyms, '
                      'antonyms, IPA, and part of speech.',
                  'Click a synonym or antonym chip to mark it important '
                      '\u2014 important terms show in bold blue on the card.',
                  'Type into the Notes box and press \u201cSave notes\u201d; '
                      'notes appear on the card in a light blue highlight.',
                  '\u201cRefresh card with AI\u201d regenerates the card '
                      'fields while keeping your notes, favorites, and '
                      'important markers.',
                ],
              ),
              const _HelpTopic(
                icon: Icons.search,
                title: 'Search & filtering tips',
                bullets: [
                  'Press Ctrl+F from anywhere to jump to the search bar.',
                  'Results update as you type and match headwords as well '
                      'as card text (meanings, examples, and your notes).',
                  'Press Enter in the search field to open the first '
                      'match; press Esc to clear the search.',
                  'Each notebook is searched separately \u2014 switch '
                      'notebooks with the toolbar selector. The Favorites '
                      'section searches only starred words.',
                  'No matches? The empty state offers a one-click '
                      '\u201cAdd to your notebook\u201d button for the term '
                      'you typed.',
                ],
              ),
              const _HelpTopic(
                icon: Icons.star_border,
                title: 'Favorites',
                bullets: [
                  'Click the star on any card (or in the word view) to add '
                      'a word to your favorites.',
                  'The Favorites section shows starred words from all '
                      'notebooks, with the same search and card view.',
                  'Click the star again to remove a word from favorites '
                      '\u2014 the word itself is never deleted.',
                ],
              ),
              const _HelpTopic(
                icon: Icons.fact_check_outlined,
                title: 'Quiz',
                bullets: [
                  'The Quiz section builds practice questions from the '
                      'words you have saved \u2014 the more words you add, '
                      'the richer the quizzes.',
                  'Pick your setup, answer the questions, then press '
                      '\u201cSubmit Quiz\u201d to see your score.',
                  'Leaving the Quiz section pauses a running quiz \u2014 '
                      'come back to continue it or start over. Nothing '
                      'ever runs invisibly in the background.',
                  '\u201cQuiz history\u201d keeps your past results so you '
                      'can track progress over time.',
                ],
              ),
              const _HelpTopic(
                icon: Icons.auto_awesome_outlined,
                title: 'AI features',
                bullets: [
                  'Configure a provider under Settings \u2192 AI Provider. '
                      'Built-in presets cover popular services, and the '
                      '\u201cCustom\u201d preset works with any self-hosted '
                      'or OpenAI-compatible endpoint.',
                  'Your API key is stored securely on this PC (Windows '
                      'credential vault when available) and never leaves '
                      'the device except to call your chosen provider.',
                  'New words are enriched automatically. If you are '
                      'offline, they queue up and retry \u2014 watch the '
                      'status chip in the top-right corner.',
                  'Use \u201cTest connection\u201d in settings to verify a '
                      'key before saving it.',
                  'Readable pronunciation (like \u201ckat\u201d) is shown '
                      'by default. Prefer IPA? Turn off \u201cSimplified '
                      'pronunciation\u201d under Settings \u2192 Typography.',
                ],
              ),
              const _HelpTopic(
                icon: Icons.swap_horiz,
                title: 'Import & export',
                bullets: [
                  'Everything lives under Settings \u2192 Data.',
                  'Import: a legacy VocabNote database (.db), a CSV '
                      'spreadsheet, or a .docx file that follows the same '
                      'layout as the app\u2019s export.',
                  'Export: JSON (complete data), CSV (spreadsheets), '
                      'Markdown (notes apps), or an Anki-ready file for '
                      'flashcard review.',
                  'Imports never overwrite silently \u2014 review the '
                      'summary shown after each import.',
                ],
              ),
              const _HelpTopic(
                icon: Icons.settings_backup_restore,
                title: 'Backup & restore',
                bullets: [
                  'Create local snapshot backups under Settings \u2192 '
                      'Data at any time \u2014 each snapshot is a complete '
                      'copy of your data.',
                  'Restoring a backup replaces your current data; the app '
                      'always asks for confirmation first.',
                  'Take a fresh backup before large imports or before '
                      'restoring an old snapshot.',
                ],
              ),
              _HelpTopic(
                icon: Icons.help_outline,
                title: 'Frequently asked questions',
                content: const [
                  _QA(
                    question: 'Does VocabNote need the internet?',
                    answer: 'Only for AI enrichment. Browsing, editing, '
                        'search, favorites, and quizzes all work fully '
                        'offline.',
                  ),
                  _QA(
                    question: 'Where is my data stored?',
                    answer: 'In a local SQLite database inside the '
                        'app\u2019s data folder on this PC. API keys are '
                        'kept in the Windows credential vault when '
                        'available.',
                  ),
                  _QA(
                    question: 'Can I use my own AI server?',
                    answer: 'Yes. Choose the \u201cCustom '
                        '(OpenAI-compatible / self-hosted)\u201d provider '
                        'in Settings and point the base URL at your '
                        'endpoint.',
                  ),
                  _QA(
                    question:
                        'Why does a card say \u201cWaiting for AI '
                        'enrichment\u201d?',
                    answer: 'No provider or API key is configured yet, or '
                        'the app is offline. The card fills in '
                        'automatically once enrichment succeeds.',
                  ),
                  _QA(
                    question: 'How do I change the card size or fonts?',
                    answer: 'Use the zoom control at the right of the '
                        'toolbar for quick scaling, or fine-tune '
                        'everything under Settings \u2192 Typography with '
                        'a live preview.',
                  ),
                ],
              ),
              _HelpTopic(
                icon: Icons.build_outlined,
                title: 'Troubleshooting',
                content: const [
                  _QA(
                    question: 'Cards are never enriched',
                    answer: 'Open Settings \u2192 AI Provider and check '
                        'that a key is stored, then press \u201cTest '
                        'connection\u201d. The enrichment queue retries '
                        'automatically once the connection works.',
                  ),
                  _QA(
                    question: 'My API key does not seem to be saved',
                    answer: 'Look for the status row under the key field. '
                        'If a storage notice appears, the Windows '
                        'credential vault is unavailable and keys are kept '
                        'in a local file instead \u2014 saving still '
                        'works.',
                  ),
                  _QA(
                    question: 'Keyboard shortcuts do not respond',
                    answer: 'Click anywhere inside the VocabNote window '
                        'first so it has keyboard focus, then try again. '
                        'All shortcuts work from every section.',
                  ),
                  _QA(
                    question: 'Search cannot find a word I added',
                    answer: 'Check that the toolbar shows the notebook you '
                        'added the word to \u2014 each notebook is '
                        'searched separately. Press Esc to clear any '
                        'previous search.',
                  ),
                  _QA(
                    question: 'Something looks wrong after an import',
                    answer: 'Restore your latest snapshot from Settings '
                        '\u2192 Data \u2192 Backups, then retry the import '
                        'with a corrected file.',
                  ),
                ],
              ),
              const SizedBox(height: VnSpacing.x8),
            ],
          ),
        ),
      ),
    );
  }
}

/// The complete shortcut reference, matching the bindings owned by the
/// shell (app/lib/shell/adaptive_shell.dart) and the word list screen.
class ShortcutsCard extends StatelessWidget {
  /// Public so the Ctrl+/ cheat-sheet dialog can render the exact same
  /// card (see app/lib/shell/shortcut_cheatsheet_dialog.dart).
  const ShortcutsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(VnRadius.md),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.all(VnSpacing.x4),
      child: const Column(
        children: [
          _ShortcutRow(
            keys: ['Ctrl', 'N'],
            description: 'Add words \u2014 opens the quick-add dialog from '
                'anywhere.',
          ),
          _ShortcutRow(
            keys: ['Ctrl', 'F'],
            description: 'Focus the search bar (switches to the Notebook '
                'when the current section has no search).',
          ),
          _ShortcutRow(
            keys: ['Enter'],
            description: 'In the add-word field: save the word. In the '
                'search field: open the first match.',
          ),
          _ShortcutRow(
            keys: ['Esc'],
            description: 'Clear the search, close the word card, or '
                'dismiss a dialog.',
          ),
          _ShortcutRow(
            keys: ['Ctrl', '+ / \u2212 / 0'],
            description: 'Card zoom in / out / reset on the Notebook and '
                'Favorites sections. The toolbar zoom control also '
                'responds to the mouse wheel.',
          ),
          _ShortcutRow(
            keys: ['Ctrl', '/'],
            description: 'Show this shortcut reference in a dialog, from '
                'anywhere.',
          ),
          _ShortcutRow(
            keys: ['Ctrl', '1\u20136'],
            description: 'Switch sections: Notebook, Quiz, Favorites, '
                'Help, About, Settings (top-row or numpad digits).',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.keys,
    required this.description,
    this.isLast = false,
  });

  final List<String> keys;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : VnSpacing.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Wrap(
              spacing: VnSpacing.x1,
              runSpacing: VnSpacing.x1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < keys.length; i++) ...[
                  if (i > 0)
                    Text(
                      '+',
                      style: textTheme.bodySmall
                          ?.copyWith(color: tokens.textMuted),
                    ),
                  _KeyCap(keys[i]),
                ],
              ],
            ),
          ),
          const SizedBox(width: VnSpacing.x3),
          Expanded(
            child: Text(
              description,
              style: textTheme.bodyMedium
                  ?.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A keyboard-key chip, styled like a physical keycap.
class _KeyCap extends StatelessWidget {
  const _KeyCap(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VnSpacing.x2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(VnRadius.sm),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: tokens.textPrimary,
          fontWeight: VnTypeScale.semiBold,
        ),
      ),
    );
  }
}

/// One collapsible help topic. Provide either [bullets] (plain bullet
/// lines) or [content] (custom widgets such as [_QA] entries).
class _HelpTopic extends StatelessWidget {
  const _HelpTopic({
    required this.icon,
    required this.title,
    this.bullets = const [],
    this.content = const [],
  });

  final IconData icon;
  final String title;
  final List<String> bullets;
  final List<Widget> content;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: VnSpacing.x3),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(VnRadius.md),
        border: Border.all(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(icon, size: 20, color: tokens.accent),
        title: Text(title, style: textTheme.titleSmall),
        childrenPadding: const EdgeInsets.fromLTRB(
          VnSpacing.x4,
          0,
          VnSpacing.x4,
          VnSpacing.x4,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final bullet in bullets) _Bullet(bullet),
          ...content,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    final style =
        textTheme.bodyMedium?.copyWith(color: tokens.textSecondary);
    return Padding(
      padding: const EdgeInsets.only(bottom: VnSpacing.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\u2022  ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

/// A question-and-answer entry for the FAQ and troubleshooting topics.
class _QA extends StatelessWidget {
  const _QA({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: VnSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: VnTypeScale.semiBold,
            ),
          ),
          const SizedBox(height: VnSpacing.x1),
          Text(
            answer,
            style:
                textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
