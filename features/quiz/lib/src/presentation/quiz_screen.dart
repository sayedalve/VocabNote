/// features/quiz/lib/src/presentation/quiz_screen.dart
///
/// Quiz UI in five phases (setup / active / paused / results / history), a pure
/// function of the sealed QuizState. Parity with the legacy desktop quiz
/// page: source/count/type/provider pickers, all questions on one page,
/// toggleable answers, submit-at-end scoring, colored percentage, stats
/// grid, full review with explanations, and paginated history.
library;

import 'dart:async';

import 'package:core_db/core_db.dart';
import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/quiz_controller.dart';
import '../domain/quiz_models.dart';

String _formatDuration(int totalSecs) {
  final mins = totalSecs ~/ 60;
  final secs = totalSecs % 60;
  return '$mins:${secs.toString().padLeft(2, '0')}';
}

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  /// The shell keeps offstage tab branches mounted with their tickers
  /// disabled, so TickerMode is the authoritative "is the Quiz page
  /// actually visible" signal.
  ValueListenable<bool>? _visibility;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = TickerMode.getNotifier(context);
    if (!identical(notifier, _visibility)) {
      _visibility?.removeListener(_handleVisibilityChanged);
      _visibility = notifier..addListener(_handleVisibilityChanged);
    }
  }

  @override
  void dispose() {
    _visibility?.removeListener(_handleVisibilityChanged);
    super.dispose();
  }

  void _handleVisibilityChanged() {
    if (_visibility?.value == false) _pauseIfHidden();
  }

  /// Pauses a running quiz once the page is hidden. Deferred to the next
  /// frame: visibility flips during build, and providers must not be
  /// mutated mid-build.
  void _pauseIfHidden() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _visibility?.value != false) return;
      final value = ref.read(quizControllerProvider).value;
      if (value is QuizActive && !value.isPaused) {
        ref.read(quizControllerProvider.notifier).pauseQuiz();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Belt and braces: if a quiz somehow starts or resumes while this
    // page is hidden, pause it immediately.
    ref.listen(quizControllerProvider, (previous, next) {
      final value = next.value;
      if (value is QuizActive &&
          !value.isPaused &&
          _visibility?.value == false) {
        _pauseIfHidden();
      }
    });
    final async = ref.watch(quizControllerProvider);
    return switch (async) {
      AsyncData(:final value) => switch (value) {
          final QuizSetup setup => _SetupView(setup: setup),
          final QuizActive active => active.isPaused
              ? _PausedView(state: active)
              : _ActiveView(key: ValueKey(active.startedAt), state: active),
          final QuizResults results => _ResultsView(results: results),
          final QuizHistory history => _HistoryView(history: history),
        },
      AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(VnSpacing.x6),
            child: Text('Something went wrong: $error'),
          ),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

// ---------------------------------------------------------------------------
// Setup
// ---------------------------------------------------------------------------

class _SetupView extends ConsumerWidget {
  const _SetupView({required this.setup});

  final QuizSetup setup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    final controller = ref.read(quizControllerProvider.notifier);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(VnSpacing.x6),
          children: [
            Text('Quiz', style: textTheme.headlineSmall),
            const SizedBox(height: VnSpacing.x2),
            Text(
              'Test yourself with AI-generated multiple-choice questions.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: VnSpacing.x6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(VnSpacing.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PickerRow<int>(
                      label: 'Words from',
                      value: setup.sourceIndex,
                      options: [
                        for (var i = 0; i < setup.sources.length; i++)
                          VnSelectOption(
                            value: i,
                            label: '${setup.sources[i].label} '
                                '(${setup.sources[i].wordCount})',
                          ),
                      ],
                      enabled: !setup.generating,
                      onSelected: controller.selectSource,
                    ),
                    const SizedBox(height: VnSpacing.x4),
                    _PickerRow<int>(
                      label: 'Questions',
                      value: setup.questionCount,
                      options: [
                        for (final count in kQuizCountChoices)
                          VnSelectOption(value: count, label: '$count'),
                      ],
                      enabled: !setup.generating,
                      onSelected: controller.setQuestionCount,
                    ),
                    const SizedBox(height: VnSpacing.x4),
                    _PickerRow<QuizTypeChoice>(
                      label: 'Question type',
                      value: setup.typeChoice,
                      options: [
                        for (final choice in QuizTypeChoice.values)
                          VnSelectOption(value: choice, label: choice.label),
                      ],
                      enabled: !setup.generating,
                      onSelected: controller.setTypeChoice,
                    ),
                    const SizedBox(height: VnSpacing.x4),
                    _PickerRow<int>(
                      label: 'Provider',
                      value: setup.providerIndex,
                      options: [
                        for (var i = 0; i < setup.providers.length; i++)
                          VnSelectOption(
                            value: i,
                            label: setup.providers[i].label,
                          ),
                      ],
                      enabled: !setup.generating,
                      onSelected: controller.selectProvider,
                    ),
                    const SizedBox(height: VnSpacing.x5),
                    Text(
                      setup.eligibleCount >= kQuizMinPoolSize
                          ? '${setup.eligibleCount} words available for '
                              '${setup.typeChoice.label.toLowerCase()} '
                              'questions.'
                          : 'You need at least $kQuizMinPoolSize words with '
                              'usable data for this question type '
                              '(you have ${setup.eligibleCount}). Add words '
                              'and let the AI fill in their details first.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: setup.eligibleCount >= kQuizMinPoolSize
                            ? tokens.textSecondary
                            : tokens.favorite,
                      ),
                    ),
                    if (setup.error != null) ...[
                      const SizedBox(height: VnSpacing.x3),
                      Text(
                        setup.error!,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: tokens.danger),
                      ),
                    ],
                    const SizedBox(height: VnSpacing.x5),
                    FilledButton.icon(
                      onPressed: setup.canStart
                          ? () => controller.startQuiz()
                          : null,
                      icon: setup.generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                        setup.generating
                            ? 'Generating questions...'
                            : 'Start Quiz',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: VnSpacing.x4),
            OutlinedButton.icon(
              onPressed: setup.generating
                  ? null
                  : () => controller.openHistory(),
              icon: const Icon(Icons.history),
              label: Text('Quiz history (${setup.historyCount})'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow<T> extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    required this.enabled,
  });

  final String label;
  final T value;
  final List<VnSelectOption<T>> options;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: tokens.textSecondary),
          ),
        ),
        const SizedBox(width: VnSpacing.x3),
        Expanded(
          child: VnSelect<T>(
            value: value,
            options: options,
            onSelected: onSelected,
            enabled: enabled,
            dense: true,
            semanticLabel: label,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Active quiz
// ---------------------------------------------------------------------------

class _ActiveView extends ConsumerStatefulWidget {
  const _ActiveView({super.key, required this.state});

  final QuizActive state;

  @override
  ConsumerState<_ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends ConsumerState<_ActiveView> {
  Timer? _ticker;
  int _elapsedSecs = 0;

  @override
  void initState() {
    super.initState();
    _syncElapsed();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_syncElapsed);
    });
  }

  @override
  void didUpdateWidget(covariant _ActiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncElapsed();
  }

  void _syncElapsed() {
    // Pause-aware: only time actually spent on the quiz page counts.
    _elapsedSecs = widget.state.elapsedSecs;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showVnConfirmDialog(
      context,
      title: 'Cancel quiz?',
      message: 'Your answers will be discarded and nothing will be saved.',
      confirmLabel: 'Cancel quiz',
      cancelLabel: 'Keep going',
    );
    if (confirmed) {
      await ref.read(quizControllerProvider.notifier).cancelQuiz();
    }
  }

  Future<void> _confirmSubmit() async {
    final unanswered =
        widget.state.questions.length - widget.state.answeredCount;
    if (unanswered > 0) {
      final confirmed = await showVnConfirmDialog(
        context,
        title: 'Submit quiz?',
        message: '$unanswered question${unanswered == 1 ? '' : 's'} '
            '${unanswered == 1 ? 'is' : 'are'} unanswered and will be '
            'marked wrong.',
        confirmLabel: 'Submit',
        cancelLabel: 'Keep answering',
      );
      if (!confirmed) return;
    }
    await ref.read(quizControllerProvider.notifier).submitQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(quizControllerProvider).value;
    if (active is! QuizActive) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    final controller = ref.read(quizControllerProvider.notifier);

    return Column(
      children: [
        Material(
          color: tokens.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VnSpacing.x6,
              vertical: VnSpacing.x3,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${active.typeChoice.label} quiz · '
                    '${active.sourceLabel} · ${active.providerLabel}',
                    style: textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.timer_outlined,
                    size: 18, color: tokens.textSecondary),
                const SizedBox(width: VnSpacing.x1),
                Text(
                  _formatDuration(_elapsedSecs),
                  style: textTheme.bodyMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(width: VnSpacing.x4),
                Text(
                  'Answered ${active.answeredCount}/'
                  '${active.questions.length}',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(VnSpacing.x6),
            itemCount: active.questions.length,
            itemBuilder: (context, index) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _QuestionCard(
                  index: index,
                  question: active.questions[index],
                  chosenIndex: active.answers[index],
                  onToggle: (optionIndex) =>
                      controller.toggleAnswer(index, optionIndex),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(VnSpacing.x4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _confirmCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: VnSpacing.x4),
              FilledButton.icon(
                onPressed: _confirmSubmit,
                icon: const Icon(Icons.check),
                label: const Text('Submit Quiz'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown when an in-progress quiz is paused (after navigating away from
/// the Quiz section). Nothing ticks while this is on screen; the user
/// explicitly continues or discards.
class _PausedView extends ConsumerWidget {
  const _PausedView({required this.state});

  final QuizActive state;

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showVnConfirmDialog(
      context,
      title: 'Discard quiz?',
      message: 'Your answers will be discarded and nothing will be saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep it',
    );
    if (confirmed) {
      await ref.read(quizControllerProvider.notifier).cancelQuiz();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(VnSpacing.x6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  size: 48,
                  color: tokens.accent,
                ),
                const SizedBox(height: VnSpacing.x4),
                Text('Quiz paused', style: textTheme.headlineSmall),
                const SizedBox(height: VnSpacing.x2),
                Text(
                  '${state.answeredCount} of ${state.questions.length} '
                  'questions answered \u00b7 '
                  '${_formatDuration(state.elapsedSecs)} elapsed.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: VnSpacing.x6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => _confirmDiscard(context, ref),
                      child: const Text('Discard quiz'),
                    ),
                    const SizedBox(width: VnSpacing.x4),
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(quizControllerProvider.notifier)
                          .resumeQuiz(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continue quiz'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.chosenIndex,
    required this.onToggle,
  });

  final int index;
  final QuizQuestion question;
  final int? chosenIndex;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;

    return Card(
      margin: const EdgeInsets.only(bottom: VnSpacing.x4),
      child: Padding(
        padding: const EdgeInsets.all(VnSpacing.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1} · ${question.type.label}',
              style:
                  textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: VnSpacing.x2),
            Text(question.question, style: textTheme.titleMedium),
            const SizedBox(height: VnSpacing.x4),
            for (var i = 0; i < question.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: VnSpacing.x2),
                child: _OptionTile(
                  text: question.options[i],
                  selected: chosenIndex == i,
                  onTap: () => onToggle(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VnRadius.sm),
        child: AnimatedContainer(
          duration: vnMotionDuration(context, VnMotion.fast),
          padding: const EdgeInsets.symmetric(
            horizontal: VnSpacing.x4,
            vertical: VnSpacing.x3,
          ),
          decoration: BoxDecoration(
            color: selected
                ? tokens.accent.withValues(alpha: 0.12)
                : tokens.surfaceInput,
            borderRadius: BorderRadius.circular(VnRadius.sm),
            border: Border.all(
              color: selected ? tokens.accent : tokens.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? tokens.accent : tokens.textMuted,
              ),
              const SizedBox(width: VnSpacing.x3),
              Expanded(child: Text(text, style: textTheme.bodyMedium)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.results});

  final QuizResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    final controller = ref.read(quizControllerProvider.notifier);

    final pct = results.percentage;
    final pctColor = pct >= 80
        ? tokens.success
        : pct >= 50
            ? tokens.favorite
            : tokens.danger;

    final stats = <(String, String)>[
      ('Score', '${results.correct}/${results.total}'),
      ('Correct', '${results.correct}'),
      ('Incorrect', '${results.incorrect}'),
      ('Time', _formatDuration(results.timeTakenSecs)),
      ('Provider', results.providerLabel),
      ('Source', results.sourceLabel),
      ('Type', results.typeLabel),
      ('Date', formatVnDateTime(results.finishedAt)),
    ];

    return ListView(
      padding: const EdgeInsets.all(VnSpacing.x6),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(VnSpacing.x6),
                    child: Column(
                      children: [
                        Text(
                          '${pct.round()}%',
                          style: textTheme.displaySmall?.copyWith(
                            color: pctColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: VnSpacing.x4),
                        Wrap(
                          spacing: VnSpacing.x6,
                          runSpacing: VnSpacing.x3,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final (label, value) in stats)
                              Column(
                                children: [
                                  Text(
                                    label.toUpperCase(),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: tokens.textMuted,
                                    ),
                                  ),
                                  Text(value,
                                      style: textTheme.bodyMedium),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: VnSpacing.x5),
                Text('Review', style: textTheme.titleMedium),
                const SizedBox(height: VnSpacing.x3),
                for (final item in results.items)
                  _ReviewCard(item: item),
                const SizedBox(height: VnSpacing.x4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (results.fromHistory)
                      OutlinedButton.icon(
                        onPressed: () => controller.openHistory(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to history'),
                      )
                    else ...[
                      OutlinedButton.icon(
                        onPressed: () => controller.openHistory(),
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                      ),
                      const SizedBox(width: VnSpacing.x4),
                      FilledButton.icon(
                        onPressed: () => controller.backToSetup(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('New Quiz'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item});

  final QuizResultItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;

    return Card(
      margin: const EdgeInsets.only(bottom: VnSpacing.x3),
      child: Padding(
        padding: const EdgeInsets.all(VnSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  color: item.isCorrect ? tokens.success : tokens.danger,
                ),
                const SizedBox(width: VnSpacing.x2),
                Expanded(
                  child: Text(
                    '${item.word} · ${item.typeLabel}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: tokens.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VnSpacing.x2),
            Text(item.question, style: textTheme.bodyMedium),
            const SizedBox(height: VnSpacing.x3),
            for (var i = 0; i < item.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: VnSpacing.x1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      child: i == item.correctIndex
                          ? Icon(Icons.check,
                              size: 16, color: tokens.success)
                          : (item.chosenIndex == i
                              ? Icon(Icons.close,
                                  size: 16, color: tokens.danger)
                              : const SizedBox.shrink()),
                    ),
                    Expanded(
                      child: Text(
                        item.options[i],
                        style: textTheme.bodyMedium?.copyWith(
                          color: i == item.correctIndex
                              ? tokens.success
                              : (item.chosenIndex == i
                                  ? tokens.danger
                                  : tokens.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (item.chosenIndex == null)
              Padding(
                padding: const EdgeInsets.only(top: VnSpacing.x1),
                child: Text(
                  'Not answered',
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textMuted),
                ),
              ),
            if (item.explanation.isNotEmpty) ...[
              const SizedBox(height: VnSpacing.x2),
              Text(
                item.explanation,
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History
// ---------------------------------------------------------------------------

class _HistoryView extends ConsumerWidget {
  const _HistoryView({required this.history});

  final QuizHistory history;

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showVnConfirmDialog(
      context,
      title: 'Clear all history?',
      message: 'Every saved quiz attempt will be permanently deleted.',
      confirmLabel: 'Clear all',
    );
    if (confirmed) {
      await ref.read(quizControllerProvider.notifier).clearHistory();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    final controller = ref.read(quizControllerProvider.notifier);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(VnSpacing.x6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => controller.backToSetup(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: VnSpacing.x2),
                  Expanded(
                    child: Text('Quiz history',
                        style: textTheme.headlineSmall),
                  ),
                  if (history.totalCount > 0)
                    TextButton.icon(
                      onPressed: () => _confirmClear(context, ref),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Clear all'),
                    ),
                ],
              ),
            ),
            if (history.totalCount > 0) const _HistoryStatsCard(),
            Expanded(
              child: history.attempts.isEmpty
                  ? Center(
                      child: Text(
                        'No finished quizzes yet.',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VnSpacing.x6,
                      ),
                      itemCount: history.attempts.length,
                      itemBuilder: (context, index) => _HistoryTile(
                        attempt: history.attempts[index],
                      ),
                    ),
            ),
            if (history.pageCount > 1)
              Padding(
                padding: const EdgeInsets.all(VnSpacing.x4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: history.hasPrev
                          ? () =>
                              controller.openHistory(page: history.page - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      'Page ${history.page + 1} of ${history.pageCount}',
                      style: textTheme.bodyMedium,
                    ),
                    IconButton(
                      onPressed: history.hasNext
                          ? () =>
                              controller.openHistory(page: history.page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Aggregate progress stats shown above the history list. Additive card
/// built entirely from existing patterns (Card + theme text styles +
/// spacing tokens), so it inherits the app's visual language as-is.
final quizHistoryStatsProvider = FutureProvider.autoDispose<
    ({int attemptCount, int questionCount, int correctCount})>(
  (ref) {
    // Recompute whenever quiz state changes (finish/delete/clear).
    ref.watch(quizControllerProvider);
    return ref.read(quizControllerProvider.notifier).historyStats();
  },
);

class _HistoryStatsCard extends ConsumerWidget {
  const _HistoryStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(quizHistoryStatsProvider).value;
    if (stats == null || stats.attemptCount == 0) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    final avgPct = stats.questionCount == 0
        ? 0
        : (stats.correctCount * 100 / stats.questionCount).round();

    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value, style: textTheme.titleLarge),
              const SizedBox(height: VnSpacing.x2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall
                    ?.copyWith(color: tokens.textSecondary),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VnSpacing.x6),
      child: Card(
        margin: const EdgeInsets.only(bottom: VnSpacing.x4),
        child: Padding(
          padding: const EdgeInsets.all(VnSpacing.x4),
          child: Row(
            children: [
              stat('${stats.attemptCount}', 'Quizzes'),
              stat('${stats.questionCount}', 'Questions answered'),
              stat('$avgPct%', 'Average score'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.attempt});

  final QuizAttemptRow attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    final controller = ref.read(quizControllerProvider.notifier);

    final pct = attempt.totalQuestions == 0
        ? 0.0
        : attempt.correctCount * 100 / attempt.totalQuestions;
    final pctColor = pct >= 80
        ? tokens.success
        : pct >= 50
            ? tokens.favorite
            : tokens.danger;
    final typeLabel =
        QuizQuestionType.tryParse(attempt.questionType)?.label ??
            (attempt.questionType == 'mixed' ? 'Mixed' : 'Quiz');

    return Card(
      margin: const EdgeInsets.only(bottom: VnSpacing.x2),
      child: ListTile(
        onTap: () => controller.openHistoryAttempt(attempt.id),
        title: Text(
          '${attempt.correctCount}/${attempt.totalQuestions} · '
          '${pct.round()}% · $typeLabel',
          style: textTheme.bodyMedium?.copyWith(
            color: pctColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${attempt.sourceLabel.isEmpty ? 'All Words' : attempt.sourceLabel}'
          '${attempt.provider.isEmpty ? '' : ' · ${attempt.provider}'} · '
          '${formatVnDateTime(attempt.finishedAt ?? attempt.startedAt)}',
          style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
        ),
        trailing: IconButton(
          tooltip: 'Delete attempt',
          onPressed: () async {
            // Parity with every other destructive action: confirm first.
            final confirmed = await showVnConfirmDialog(
              context,
              title: 'Delete this attempt?',
              message: 'This quiz result will be permanently removed.',
              confirmLabel: 'Delete',
            );
            if (confirmed) {
              await controller.deleteHistoryAttempt(attempt.id);
            }
          },
          icon: const Icon(Icons.delete_outline, size: 20),
        ),
      ),
    );
  }
}
