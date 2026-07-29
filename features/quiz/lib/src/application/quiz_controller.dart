/// features/quiz/lib/src/application/quiz_controller.dart
///
/// Quiz session state machine, rebuilt for parity with the legacy desktop
/// quiz page:
///  * Setup: word source (All Words / per-notebook), question count
///    (10/20/30), question type (Mixed/Meaning/Synonym/Antonym), and
///    provider selection (saved-key providers + an on-device generator).
///  * Active: all questions in one scrollable page, answers toggleable,
///    submit-at-end scoring.
///  * Results: score/percentage/time/provider/source/type plus a full
///    per-question review with explanations.
///  * History: paginated finished attempts (50/page) with open/delete/clear.
///
/// Nothing is persisted until the user submits, so cancelled quizzes leave
/// no orphan rows.
library;

import 'dart:convert';
import 'dart:math';

import 'package:core_ai/core_ai.dart';
import 'package:core_db/core_db.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/quiz_generator.dart';
import '../domain/quiz_models.dart';

part 'quiz_controller.g.dart';

/// Attempts per history page (legacy `HISTORY_PAGE_SIZE`).
const int kQuizHistoryPageSize = 50;

/// Label used when questions were generated without an AI provider.
const String kOnDeviceProviderLabel = 'On-device';

/// Parity copy with the legacy generator error.
const String kNotEnoughWordsError =
    'Not enough usable words for this question type '
    '(need at least $kQuizMinPoolSize with data).';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class QuizState {
  const QuizState();
}

/// Quiz configuration screen.
final class QuizSetup extends QuizState {
  const QuizSetup({
    required this.sources,
    required this.sourceIndex,
    required this.questionCount,
    required this.typeChoice,
    required this.providers,
    required this.providerIndex,
    required this.eligibleCount,
    required this.historyCount,
    this.generating = false,
    this.error,
  });

  final List<QuizSource> sources;
  final int sourceIndex;
  final int questionCount;
  final QuizTypeChoice typeChoice;
  final List<QuizProviderChoice> providers;
  final int providerIndex;

  /// Words usable for the selected source + question type.
  final int eligibleCount;
  final int historyCount;
  final bool generating;
  final String? error;

  QuizSource get source => sources[sourceIndex];
  QuizProviderChoice get provider => providers[providerIndex];
  bool get canStart => !generating && eligibleCount >= kQuizMinPoolSize;

  QuizSetup copyWith({
    List<QuizSource>? sources,
    int? sourceIndex,
    int? questionCount,
    QuizTypeChoice? typeChoice,
    List<QuizProviderChoice>? providers,
    int? providerIndex,
    int? eligibleCount,
    int? historyCount,
    bool? generating,
    String? error,
    bool clearError = false,
  }) =>
      QuizSetup(
        sources: sources ?? this.sources,
        sourceIndex: sourceIndex ?? this.sourceIndex,
        questionCount: questionCount ?? this.questionCount,
        typeChoice: typeChoice ?? this.typeChoice,
        providers: providers ?? this.providers,
        providerIndex: providerIndex ?? this.providerIndex,
        eligibleCount: eligibleCount ?? this.eligibleCount,
        historyCount: historyCount ?? this.historyCount,
        generating: generating ?? this.generating,
        error: clearError ? null : (error ?? this.error),
      );
}

/// A quiz in progress. Answers live in memory until submit.
final class QuizActive extends QuizState {
  const QuizActive({
    required this.questions,
    required this.answers,
    required this.startedAt,
    required this.sourceLabel,
    required this.providerLabel,
    required this.typeChoice,
    required this.notebookId,
    this.accumulatedSecs = 0,
    this.runningSince,
  });

  final List<QuizQuestion> questions;

  /// Chosen option index per question; null = unanswered.
  final List<int?> answers;
  final DateTime startedAt;
  final String sourceLabel;
  final String providerLabel;
  final QuizTypeChoice typeChoice;
  final int? notebookId;

  /// Seconds spent on the quiz before the most recent resume. Pauses
  /// (leaving the Quiz section) never count toward the quiz time.
  final int accumulatedSecs;

  /// When the current running stretch began, or null while paused.
  final DateTime? runningSince;

  /// Paused = the quiz page is not visible; no time is accruing.
  bool get isPaused => runningSince == null;

  /// Total active seconds so far (excludes paused stretches).
  int get elapsedSecs =>
      accumulatedSecs +
      (runningSince == null
          ? 0
          : DateTime.now().difference(runningSince!).inSeconds);

  int get answeredCount => answers.where((a) => a != null).length;

  QuizActive copyWith({
    List<int?>? answers,
    int? accumulatedSecs,
    DateTime? runningSince,
    bool clearRunningSince = false,
  }) =>
      QuizActive(
        questions: questions,
        answers: answers ?? this.answers,
        startedAt: startedAt,
        sourceLabel: sourceLabel,
        providerLabel: providerLabel,
        typeChoice: typeChoice,
        notebookId: notebookId,
        accumulatedSecs: accumulatedSecs ?? this.accumulatedSecs,
        runningSince: clearRunningSince
            ? null
            : (runningSince ?? this.runningSince),
      );

  QuizActive withAnswer(int questionIndex, int? optionIndex) => copyWith(
        answers: [
          for (var i = 0; i < answers.length; i++)
            i == questionIndex ? optionIndex : answers[i],
        ],
      );
}

/// One reviewed question in the results view.
final class QuizResultItem {
  const QuizResultItem({
    required this.word,
    required this.typeLabel,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.chosenIndex,
    required this.explanation,
  });

  final String word;
  final String typeLabel;
  final String question;
  final List<String> options;
  final int correctIndex;
  final int? chosenIndex;
  final String explanation;

  bool get isCorrect => chosenIndex != null && chosenIndex == correctIndex;
}

/// Finished-quiz summary + full review (used for fresh results and history).
final class QuizResults extends QuizState {
  const QuizResults({
    required this.total,
    required this.correct,
    required this.timeTakenSecs,
    required this.providerLabel,
    required this.sourceLabel,
    required this.typeLabel,
    required this.finishedAt,
    required this.items,
    required this.fromHistory,
  });

  final int total;
  final int correct;
  final int timeTakenSecs;
  final String providerLabel;
  final String sourceLabel;
  final String typeLabel;
  final DateTime finishedAt;
  final List<QuizResultItem> items;

  /// True when opened from the history list (back returns to history).
  final bool fromHistory;

  int get incorrect => total - correct;
  double get percentage => total == 0 ? 0 : correct * 100 / total;
}

/// Paginated history of finished attempts.
final class QuizHistory extends QuizState {
  const QuizHistory({
    required this.attempts,
    required this.totalCount,
    required this.page,
  });

  final List<QuizAttemptRow> attempts;
  final int totalCount;
  final int page;

  int get pageCount =>
      totalCount == 0 ? 1 : ((totalCount - 1) ~/ kQuizHistoryPageSize) + 1;
  bool get hasPrev => page > 0;
  bool get hasNext => (page + 1) * kQuizHistoryPageSize < totalCount;
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Keep-alive so an in-progress quiz survives switching tabs. The quiz
/// never RUNS in the background though: the screen pauses the session
/// (freezing its clock) whenever the Quiz page stops being visible, and
/// the user explicitly chooses to continue or discard on return.
@Riverpod(keepAlive: true)
class QuizController extends _$QuizController {
  AppDatabase get _db => ref.read(appDatabaseProvider);
  final Random _random = Random();

  @override
  Future<QuizState> build() => _loadSetup();

  // ---- Setup -------------------------------------------------------------

  Future<QuizSetup> _loadSetup({
    int? keepSourceNotebookId,
    int? keepCount,
    QuizTypeChoice? keepType,
    String? keepProviderId,
    bool keepProviderOnDevice = false,
  }) async {
    final notebooks = await _db.notebookDao.watchActive().first;
    final counts = await _db.notebookDao.wordCounts();
    final totalWords = await _db.wordDao.countWords(
        (notebookId: null, favoritesOnly: false),
      );

    final sources = <QuizSource>[
      QuizSource(label: 'All Words', notebookId: null, wordCount: totalWords),
      for (final notebook in notebooks)
        QuizSource(
          label: notebook.name,
          notebookId: notebook.id,
          wordCount: counts[notebook.id] ?? 0,
        ),
    ];
    var sourceIndex = keepSourceNotebookId == null
        ? 0
        : sources.indexWhere((s) => s.notebookId == keepSourceNotebookId);
    if (sourceIndex < 0) sourceIndex = 0;

    final settings = ref.read(providerSettingsRepositoryProvider);
    final providers = <QuizProviderChoice>[];
    for (final preset in kProviderPresets) {
      if (await settings.hasApiKey(preset.id)) {
        providers.add(QuizProviderChoice(id: preset.id, label: preset.label));
      }
    }
    providers.add(
      const QuizProviderChoice(id: null, label: kOnDeviceProviderLabel),
    );

    var providerIndex = 0;
    if (keepProviderOnDevice) {
      providerIndex = providers.length - 1;
    } else {
      final preferredId =
          keepProviderId ?? await settings.activeProviderId();
      final preferred = providers.indexWhere((p) => p.id == preferredId);
      if (preferred >= 0) providerIndex = preferred;
    }

    final typeChoice = keepType ?? QuizTypeChoice.mixed;
    final source = sources[sourceIndex];
    final eligible = await _eligibleCount(source.notebookId, typeChoice);
    final historyCount = await _db.quizDao.countFinishedAttempts();

    return QuizSetup(
      sources: sources,
      sourceIndex: sourceIndex,
      questionCount: keepCount ?? kQuizCountChoices.first,
      typeChoice: typeChoice,
      providers: providers,
      providerIndex: providerIndex,
      eligibleCount: eligible,
      historyCount: historyCount,
    );
  }

  Future<List<QuizWordEntry>> _pool(
    int? notebookId,
    QuizTypeChoice typeChoice, {
    bool shuffle = true,
  }) async {
    final rows = await _db.quizDao.quizPool(
      notebookId: notebookId,
      shuffle: shuffle,
    );
    return [
      for (final row in rows)
        if (_toEntry(row) case final entry
            when entry.usableFor(typeChoice.allowedTypes))
          entry,
    ];
  }

  Future<int> _eligibleCount(int? notebookId, QuizTypeChoice typeChoice) async {
    // Count-only path: skip the ORDER BY RANDOM() shuffle work.
    final pool = await _pool(notebookId, typeChoice, shuffle: false);
    return pool.length;
  }

  QuizWordEntry _toEntry(WordRow row) => QuizWordEntry(
        wordId: row.id,
        word: row.headwordDisplay,
        meaning: row.meaning.trim(),
        synonyms: _splitList(row.synonyms),
        antonyms: _splitList(row.antonyms),
      );

  // Shared rule: core_db's splitTermList (previously duplicated here and
  // in the transfer feature's text export service).
  static List<String> _splitList(String raw) => splitTermList(raw);

  Future<void> _updateSetup(
    QuizSetup Function(QuizSetup) transform, {
    bool recomputeEligible = false,
  }) async {
    final current = state.value;
    if (current is! QuizSetup || current.generating) return;
    var next = transform(current).copyWith(clearError: true);
    if (recomputeEligible) {
      state = AsyncData(next);
      final eligible =
          await _eligibleCount(next.source.notebookId, next.typeChoice);
      final latest = state.value;
      if (latest is! QuizSetup || latest.generating) return;
      next = latest.copyWith(eligibleCount: eligible);
    }
    state = AsyncData(next);
  }

  Future<void> selectSource(int index) => _updateSetup(
        (s) => index >= 0 && index < s.sources.length
            ? s.copyWith(sourceIndex: index)
            : s,
        recomputeEligible: true,
      );

  Future<void> setQuestionCount(int count) =>
      _updateSetup((s) => s.copyWith(questionCount: count));

  Future<void> setTypeChoice(QuizTypeChoice choice) => _updateSetup(
        (s) => s.copyWith(typeChoice: choice),
        recomputeEligible: true,
      );

  Future<void> selectProvider(int index) => _updateSetup(
        (s) => index >= 0 && index < s.providers.length
            ? s.copyWith(providerIndex: index)
            : s,
      );

  /// Refreshes setup data (word counts, providers) without losing choices.
  Future<void> refreshSetup() async {
    final current = state.value;
    if (current is! QuizSetup || current.generating) return;
    state = AsyncData(
      await _loadSetup(
        keepSourceNotebookId: current.source.notebookId,
        keepCount: current.questionCount,
        keepType: current.typeChoice,
        keepProviderId: current.provider.id,
        keepProviderOnDevice: current.provider.id == null,
      ),
    );
  }

  // ---- Generation --------------------------------------------------------

  Future<void> startQuiz() async {
    final setup = state.value;
    if (setup is! QuizSetup || setup.generating) return;

    final pool = await _pool(setup.source.notebookId, setup.typeChoice);
    if (pool.length < kQuizMinPoolSize) {
      state = AsyncData(
        setup.copyWith(
          eligibleCount: pool.length,
          error: kNotEnoughWordsError,
        ),
      );
      return;
    }

    state = AsyncData(setup.copyWith(generating: true, clearError: true));

    final target = min(setup.questionCount, pool.length);
    final allowedTypes = setup.typeChoice.allowedTypes;
    var providerLabel = setup.provider.label;
    List<QuizQuestion> questions;

    try {
      if (setup.provider.id == null) {
        questions = generateLocalQuestions(
          pool: pool,
          count: target,
          allowedTypes: allowedTypes,
          random: _random,
        );
      } else {
        final aiQuestions = await _generateWithAi(
          providerId: setup.provider.id!,
          pool: pool,
          target: target,
          allowedTypes: allowedTypes,
        );
        if (aiQuestions == null) {
          // AI failed entirely; fall back so the quiz still works offline.
          providerLabel = kOnDeviceProviderLabel;
          questions = generateLocalQuestions(
            pool: pool,
            count: target,
            allowedTypes: allowedTypes,
            random: _random,
          );
        } else {
          questions = aiQuestions;
          if (questions.length < target) {
            // Fill any shortfall locally instead of dropping questions.
            final used = {
              for (final q in questions) q.word.toLowerCase(),
            };
            questions = [
              ...questions,
              ...generateLocalQuestions(
                pool: pool,
                count: target - questions.length,
                allowedTypes: allowedTypes,
                random: _random,
                usedWordsLower: used,
              ),
            ];
          }
        }
      }
    } catch (_) {
      questions = generateLocalQuestions(
        pool: pool,
        count: target,
        allowedTypes: allowedTypes,
        random: _random,
      );
      providerLabel = kOnDeviceProviderLabel;
    }

    if (questions.length < kQuizMinPoolSize) {
      state = AsyncData(
        setup.copyWith(generating: false, error: kNotEnoughWordsError),
      );
      return;
    }

    questions.shuffle(_random);
    final now = DateTime.now();
    state = AsyncData(
      QuizActive(
        questions: questions,
        answers: List<int?>.filled(questions.length, null),
        startedAt: now,
        sourceLabel: setup.source.label,
        providerLabel: providerLabel,
        typeChoice: setup.typeChoice,
        notebookId: setup.source.notebookId,
        runningSince: now,
      ),
    );
  }

  /// One AI round + one top-up round (legacy behavior). Returns null when
  /// the provider fails or produces nothing usable.
  Future<List<QuizQuestion>?> _generateWithAi({
    required String providerId,
    required List<QuizWordEntry> pool,
    required int target,
    required List<QuizQuestionType> allowedTypes,
  }) async {
    final settings = ref.read(providerSettingsRepositoryProvider);
    final config = await settings.effectiveConfig(providerId);
    final apiKey = await settings.apiKey(providerId);
    if (apiKey == null || apiKey.isEmpty) return null;
    final client = ref.read(aiClientProvider(config));

    final used = <String>{};
    final questions = <QuizQuestion>[];
    var roundPool = [...pool]..shuffle(_random);

    for (var round = 0; round < 2 && questions.length < target; round++) {
      final needed = target - questions.length;
      final result = await client.complete(
        AiRequest(
          prompt: buildQuizPrompt(
            pool: roundPool,
            count: needed,
            allowedTypes: allowedTypes,
          ),
          system: kQuizSystemPrompt,
          temperature: kQuizAiTemperature,
          timeout: kQuizAiTimeout,
        ),
        apiKey: apiKey,
      );
      switch (result) {
        case AiOk(:final value):
          questions.addAll(
            parseAiQuestions(
              rawModelOutput: value,
              pool: pool,
              allowedTypes: allowedTypes,
              usedWordsLower: used,
              random: _random,
            ),
          );
        case AiErr():
          return questions.isEmpty ? null : questions;
      }
      // Top-up round only offers unused words.
      roundPool = [
        for (final entry in pool)
          if (!used.contains(entry.word.toLowerCase())) entry,
      ]..shuffle(_random);
      if (roundPool.isEmpty) break;
    }
    return questions.isEmpty ? null : questions;
  }

  // ---- Active quiz -------------------------------------------------------

  /// Selects an option; tapping the selected option again deselects it.
  void toggleAnswer(int questionIndex, int optionIndex) {
    final current = state.value;
    if (current is! QuizActive) return;
    if (questionIndex < 0 || questionIndex >= current.questions.length) return;
    final next = current.answers[questionIndex] == optionIndex
        ? null
        : optionIndex;
    state = AsyncData(current.withAnswer(questionIndex, next));
  }

  /// Freezes the quiz clock; called when the Quiz page stops being
  /// visible. Idempotent, and a no-op outside the active phase.
  void pauseQuiz() {
    final current = state.value;
    if (current is! QuizActive || current.isPaused) return;
    state = AsyncData(
      current.copyWith(
        accumulatedSecs: current.elapsedSecs,
        clearRunningSince: true,
      ),
    );
  }

  /// Restarts the quiz clock after an explicit "Continue quiz".
  void resumeQuiz() {
    final current = state.value;
    if (current is! QuizActive || !current.isPaused) return;
    state = AsyncData(current.copyWith(runningSince: DateTime.now()));
  }

  /// Cancels without saving anything.
  Future<void> cancelQuiz() async {
    if (state.value is! QuizActive) return;
    state = AsyncData(await _loadSetup());
  }

  /// Scores, persists the attempt + questions, and shows results.
  Future<void> submitQuiz() async {
    final current = state.value;
    if (current is! QuizActive) return;

    // Only time actually spent on the quiz page counts; paused
    // stretches (while the user was on other sections) are excluded.
    final timeTakenSecs = current.elapsedSecs;
    var correctCount = 0;
    final items = <QuizResultItem>[];

    // Persist the whole attempt atomically: either the attempt row, all of
    // its questions/answers, and the final score land together, or nothing
    // does. A crash mid-write can no longer leave a half-saved attempt
    // (an "unfinished" row with partial questions) in the history.
    await _db.transaction(() async {
      final attempt = await _db.quizDao.createAttempt(
        notebookId: current.notebookId,
        totalQuestions: current.questions.length,
        questionType: current.typeChoice.dbValue,
        sourceLabel: current.sourceLabel,
        provider: current.providerLabel,
      );

      for (var i = 0; i < current.questions.length; i++) {
        final question = current.questions[i];
        final chosenIndex = current.answers[i];
        final chosen =
            chosenIndex == null ? null : question.options[chosenIndex];
        final isCorrect =
            chosenIndex != null && chosenIndex == question.correctIndex;
        if (isCorrect) correctCount++;

        final row = await _db.quizDao.insertQuestion(
          attemptId: attempt.id,
          wordId: question.wordId,
          prompt: question.word,
          questionText: question.question,
          questionType: question.type.dbValue,
          explanation: question.explanation,
          correctAnswer: question.options[question.correctIndex],
          optionsJson: jsonEncode(question.options),
        );
        await _db.quizDao.recordAnswer(
          questionId: row.id,
          chosen: chosen,
          correct: chosenIndex == null ? null : isCorrect,
        );

        items.add(
          QuizResultItem(
            word: question.word,
            typeLabel: question.type.label,
            question: question.question,
            options: question.options,
            correctIndex: question.correctIndex,
            chosenIndex: chosenIndex,
            explanation: question.explanation,
          ),
        );
      }

      await _db.quizDao.finishAttempt(
        attemptId: attempt.id,
        correctCount: correctCount,
        timeTakenSecs: timeTakenSecs,
      );
    });

    state = AsyncData(
      QuizResults(
        total: current.questions.length,
        correct: correctCount,
        timeTakenSecs: timeTakenSecs,
        providerLabel: current.providerLabel,
        sourceLabel: current.sourceLabel,
        typeLabel: current.typeChoice.label,
        finishedAt: DateTime.now(),
        items: items,
        fromHistory: false,
      ),
    );
  }

  // ---- Results / history -------------------------------------------------

  Future<void> backToSetup() async {
    state = AsyncData(await _loadSetup());
  }

  Future<void> openHistory({int page = 0}) async {
    final totalCount = await _db.quizDao.countFinishedAttempts();
    final maxPage = totalCount == 0
        ? 0
        : (totalCount - 1) ~/ kQuizHistoryPageSize;
    final safePage = page.clamp(0, maxPage);
    final attempts = await _db.quizDao.attemptsPage(
      limit: kQuizHistoryPageSize,
      offset: safePage * kQuizHistoryPageSize,
    );
    state = AsyncData(
      QuizHistory(attempts: attempts, totalCount: totalCount, page: safePage),
    );
  }

  /// Aggregate history stats for the header card (see _HistoryStatsCard in
  /// quiz_screen.dart). Computed in SQL by the DAO.
  Future<({int attemptCount, int questionCount, int correctCount})>
      historyStats() => _db.quizDao.historyStats();

  Future<void> openHistoryAttempt(int attemptId) async {
    final detail = await _db.quizDao.attemptDetail(attemptId);
    if (detail == null) return;
    final attempt = detail.attempt;

    final items = <QuizResultItem>[];
    for (final row in detail.questions) {
      List<String> options;
      try {
        options = [
          for (final o in jsonDecode(row.optionsJson) as List) o.toString(),
        ];
      } on FormatException {
        options = const [];
      }
      final correctIndex = options.indexOf(row.correctAnswer);
      final chosenIndex = row.chosenAnswer == null
          ? null
          : options.indexOf(row.chosenAnswer!);
      items.add(
        QuizResultItem(
          word: row.prompt,
          typeLabel:
              QuizQuestionType.tryParse(row.questionType)?.label ?? 'Meaning',
          question: row.questionText.isNotEmpty
              ? row.questionText
              : 'What is the meaning of “${row.prompt}”?',
          options: options,
          correctIndex: correctIndex < 0 ? 0 : correctIndex,
          chosenIndex:
              chosenIndex != null && chosenIndex < 0 ? null : chosenIndex,
          explanation: row.explanation,
        ),
      );
    }

    state = AsyncData(
      QuizResults(
        total: attempt.totalQuestions,
        correct: attempt.correctCount,
        timeTakenSecs: attempt.timeTakenSecs,
        providerLabel: attempt.provider.isEmpty ? '—' : attempt.provider,
        sourceLabel: attempt.sourceLabel.isEmpty ? 'All Words' : attempt.sourceLabel,
        typeLabel: QuizQuestionType.tryParse(attempt.questionType)?.label ??
            (attempt.questionType == 'mixed' ? 'Mixed' : 'Meaning'),
        finishedAt: (attempt.finishedAt ?? attempt.startedAt).toLocal(),
        items: items,
        fromHistory: true,
      ),
    );
  }

  Future<void> deleteHistoryAttempt(int attemptId) async {
    final current = state.value;
    await _db.quizDao.deleteAttempt(attemptId);
    await openHistory(page: current is QuizHistory ? current.page : 0);
  }

  Future<void> clearHistory() async {
    await _db.quizDao.clearHistory();
    await openHistory();
  }
}
