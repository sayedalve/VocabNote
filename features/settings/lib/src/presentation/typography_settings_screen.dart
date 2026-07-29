/// features/settings/lib/src/presentation/typography_settings_screen.dart
///
/// Typography & Spacing settings: every knob for the vocabulary-card
/// reading experience, with a live preview card that re-renders on each
/// slider tick. Values persist via [cardStyleControllerProvider] and apply
/// instantly across the whole app (no restart) through [VnCardStyleScope].
///
/// The app-wide text size slider also lives here (moved out of the AI
/// Provider screen) so every text-appearance setting shares one home.
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/appearance_controller.dart';
import '../application/card_style_controller.dart';

class TypographySettingsScreen extends ConsumerWidget {
  const TypographySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final style = ref.watch(cardStyleControllerProvider).value ??
        const VnCardStyle();
    final controller = ref.read(cardStyleControllerProvider.notifier);

    void update(VnCardStyle updated) => controller.save(updated);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(VnSpacing.x5),
          children: [
            Text('Typography & Spacing', style: textTheme.titleLarge),
            const SizedBox(height: VnSpacing.x2),
            Text(
              'Customize how vocabulary cards read. Every change applies '
              'instantly \u2014 the preview below updates in real time.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: VnSpacing.x4),
            _PreviewCard(style: style),
            const SizedBox(height: VnSpacing.x6),
            Text('Card typography', style: textTheme.titleMedium),
            const SizedBox(height: VnSpacing.x2),
            _StyleSlider(
              label: 'Card font size',
              value: style.bodyFontSize,
              min: VnCardStyle.minBodyFontSize,
              max: VnCardStyle.maxBodyFontSize,
              divisions: 9,
              display: '${style.bodyFontSize.round()} px',
              onChanged: (value) =>
                  update(style.copyWith(bodyFontSize: value)),
            ),
            _StyleSlider(
              label: 'Main word size',
              value: style.headwordFontSize,
              min: VnCardStyle.minHeadwordFontSize,
              max: VnCardStyle.maxHeadwordFontSize,
              divisions: 18,
              display: '${style.headwordFontSize.round()} px',
              onChanged: (value) =>
                  update(style.copyWith(headwordFontSize: value)),
            ),
            _StyleSlider(
              label: 'Definition size',
              value: style.definitionFontSize,
              min: VnCardStyle.minDefinitionFontSize,
              max: VnCardStyle.maxDefinitionFontSize,
              divisions: 11,
              display: '${style.definitionFontSize.round()} px',
              onChanged: (value) =>
                  update(style.copyWith(definitionFontSize: value)),
            ),
            _StyleSlider(
              label: 'Line spacing',
              value: style.lineHeight,
              min: VnCardStyle.minLineHeight,
              max: VnCardStyle.maxLineHeight,
              divisions: 18,
              display: '${style.lineHeight.toStringAsFixed(2)}\u00d7',
              onChanged: (value) => update(style.copyWith(lineHeight: value)),
            ),
            const SizedBox(height: VnSpacing.x4),
            Text('Card spacing', style: textTheme.titleMedium),
            const SizedBox(height: VnSpacing.x2),
            _StyleSlider(
              label: 'Card padding (sides / top-bottom)',
              value: style.cardPadding,
              min: VnCardStyle.minCardPadding,
              max: VnCardStyle.maxCardPadding,
              divisions: 20,
              display:
                  '${style.horizontalCardPadding.round()} / ${style.cardPadding.round()} px',
              onChanged: (value) =>
                  update(style.copyWith(cardPadding: value)),
            ),
            _StyleSlider(
              label: 'Vertical spacing between cards',
              value: style.verticalSpacing,
              min: VnCardStyle.minVerticalSpacing,
              max: VnCardStyle.maxVerticalSpacing,
              divisions: 18,
              display: '${style.verticalSpacing.round()} px',
              onChanged: (value) =>
                  update(style.copyWith(verticalSpacing: value)),
            ),
            _StyleSlider(
              label: 'Section spacing inside cards',
              value: style.sectionSpacing,
              min: VnCardStyle.minSectionSpacing,
              max: VnCardStyle.maxSectionSpacing,
              divisions: 18,
              display: '${style.sectionSpacing.round()} px',
              onChanged: (value) =>
                  update(style.copyWith(sectionSpacing: value)),
            ),
            _StyleSlider(
              label: 'Card corner radius',
              value: style.cardRadius,
              min: VnCardStyle.minCardRadius,
              max: VnCardStyle.maxCardRadius,
              divisions: 24,
              display: '${style.cardRadius.round()} px',
              onChanged: (value) => update(style.copyWith(cardRadius: value)),
            ),
            const SizedBox(height: VnSpacing.x4),
            Text('Pronunciation', style: textTheme.titleMedium),
            const SizedBox(height: VnSpacing.x1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Simplified pronunciation'),
              subtitle: const Text(
                'Show readable phonetics like \u201ckat\u201d instead of IPA '
                'like /k\u00e6t/.',
              ),
              value: style.simplifiedPronunciation,
              onChanged: (value) =>
                  update(style.copyWith(simplifiedPronunciation: value)),
            ),
            const SizedBox(height: VnSpacing.x4),
            Text('App text size', style: textTheme.titleMedium),
            const SizedBox(height: VnSpacing.x1),
            Text(
              'Scales all text in the app, not just cards. Remembered '
              'across restarts.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: VnSpacing.x2),
            const _TextScaleRow(),
            const SizedBox(height: VnSpacing.x6),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: controller.reset,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Reset card style to defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live preview: the exact same [VnVocabCard] widget the notebook list
/// uses, rendered with the style being edited, so what you see here is
/// pixel-identical to the real list.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.style});

  final VnCardStyle style;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(VnSpacing.x3),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(VnRadius.md),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIVE PREVIEW',
            style: textTheme.labelSmall?.copyWith(color: tokens.textMuted),
          ),
          const SizedBox(height: VnSpacing.x2),
          VnVocabCard(
            style: style,
            headword: 'Ephemeral',
            partOfSpeech: 'adjective',
            pronunciation: style.simplifiedPronunciation
                ? 'i-FEM-uh-ruhl'
                : '/\u026a\u02c8fem\u0259r\u0259l/',
            meaning: 'Lasting for a very short time.',
            bangla: '\u0995\u09cd\u09b7\u09a3\u09b8\u09cd\u09a5\u09be\u09df\u09c0',
            example: 'The beauty of a sunset is ephemeral, fading into '
                'darkness within minutes.',
            synonyms: const ['transient', 'fleeting', 'momentary'],
            importantSynonyms: const ['fleeting'],
            antonyms: const ['permanent', 'enduring'],
            importantAntonyms: const ['permanent'],
            notes: 'Often describes feelings, fashion, and trends.',
            clampLines: false,
          ),
        ],
      ),
    );
  }
}

/// One labeled slider row: name on the left, live value readout on the
/// right, whole-step divisions.
class _StyleSlider extends StatelessWidget {
  const _StyleSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: Text(
            label,
            style: textTheme.bodyMedium
                ?.copyWith(color: tokens.textSecondary),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            label: display,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            display,
            textAlign: TextAlign.end,
            style: textTheme.bodySmall
                ?.copyWith(color: tokens.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Text-size slider (legacy zoom parity), applied app-wide via
/// `MediaQuery.textScaler` in the app shell.
class _TextScaleRow extends ConsumerWidget {
  const _TextScaleRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    final scale = ref.watch(appearanceControllerProvider).value ??
        kDefaultTextScale;

    return Row(
      children: [
        Icon(Icons.text_fields, size: 18, color: tokens.textMuted),
        Expanded(
          child: Slider(
            value: scale.clamp(kMinTextScale, kMaxTextScale).toDouble(),
            min: kMinTextScale,
            max: kMaxTextScale,
            divisions: 14,
            label: '${(scale * 100).round()}%',
            onChanged: (value) => ref
                .read(appearanceControllerProvider.notifier)
                .setTextScale(value),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${(scale * 100).round()}%',
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium
                ?.copyWith(color: tokens.textSecondary),
          ),
        ),
      ],
    );
  }
}
