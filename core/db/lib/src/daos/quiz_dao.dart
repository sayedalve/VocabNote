/// core/db/lib/src/daos/quiz_dao.dart
///
/// Persistence for quiz attempts and questions, plus the word-pool queries
/// the quiz generator needs.
///
/// Eligibility contract (ported from the legacy `quiz_db.get_words_for_quiz`
/// + `quiz_generator._build_word_pool`): a word can be quizzed as soon as it
/// has *any* usable data for the selected question type — a meaning, at
/// least one synonym, or at least one antonym. The old Flutter-only rule
/// (`meaning != ''` plus three distinct distractor meanings) silently shrank
/// the pool and dropped questions; it is gone.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'quiz_dao.g.dart';

/// An attempt joined with its ordered questions (history detail view).
typedef QuizAttemptDetail = ({
  QuizAttemptRow attempt,
  List<QuizQuestionRow> questions,
});

@DriftAccessor(tables: [QuizAttempts, QuizQuestions, Words, Notebooks])
class QuizDao extends DatabaseAccessor<AppDatabase> with _$QuizDaoMixin {
  QuizDao(super.attachedDatabase);

  /// Every word with any quizzable data (meaning, synonyms, or antonyms),
  /// optionally restricted to one notebook. The generator filters further by
  /// question type; this query must stay permissive so no eligible word is
  /// ever hidden from the quiz.
  ///
  /// Pass `shuffle: false` for count-only callers (the setup screen's live
  /// eligibility counter) so SQLite skips the `ORDER BY RANDOM()` sort work.
  Future<List<WordRow>> quizPool({int? notebookId, bool shuffle = true}) {
    final query = select(words)
      ..where((w) {
        var usable = w.meaning.equals('').not() |
            w.synonyms.equals('').not() |
            w.antonyms.equals('').not();
        if (notebookId != null) {
          usable = usable & w.notebookId.equals(notebookId);
        }
        return usable;
      });
    if (shuffle) {
      query.orderBy([
        (w) => OrderingTerm(
              expression: const CustomExpression<int>('RANDOM()'),
            ),
      ]);
    }
    return query.get();
  }

  Future<QuizAttemptRow> createAttempt({
    int? notebookId,
    required int totalQuestions,
    required String questionType,
    required String sourceLabel,
    required String provider,
  }) =>
      into(quizAttempts).insertReturning(
        QuizAttemptsCompanion.insert(
          notebookId: Value(notebookId),
          totalQuestions: totalQuestions,
          questionType: Value(questionType),
          sourceLabel: Value(sourceLabel),
          provider: Value(provider),
        ),
      );

  Future<QuizQuestionRow> insertQuestion({
    required int attemptId,
    required int wordId,
    required String prompt,
    required String questionText,
    required String questionType,
    required String explanation,
    required String correctAnswer,
    required String optionsJson,
  }) =>
      into(quizQuestions).insertReturning(
        QuizQuestionsCompanion.insert(
          attemptId: attemptId,
          wordId: wordId,
          prompt: prompt,
          questionText: Value(questionText),
          questionType: Value(questionType),
          explanation: Value(explanation),
          correctAnswer: correctAnswer,
          optionsJson: optionsJson,
        ),
      );

  Future<void> recordAnswer({
    required int questionId,
    required String? chosen,
    required bool? correct,
  }) async {
    await (update(quizQuestions)..where((q) => q.id.equals(questionId))).write(
      QuizQuestionsCompanion(
        chosenAnswer: Value(chosen),
        wasCorrect: Value(correct),
        answeredAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> finishAttempt({
    required int attemptId,
    required int correctCount,
    required int timeTakenSecs,
  }) async {
    await (update(quizAttempts)..where((a) => a.id.equals(attemptId))).write(
      QuizAttemptsCompanion(
        correctCount: Value(correctCount),
        timeTakenSecs: Value(timeTakenSecs),
        finishedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Deletes an unfinished attempt (cancelled quiz) and its questions.
  Future<void> discardAttempt(int attemptId) async {
    await (delete(quizAttempts)..where((a) => a.id.equals(attemptId))).go();
  }

  // ---- History -----------------------------------------------------------

  /// Finished attempts, newest first (legacy `get_quiz_history`).
  Future<List<QuizAttemptRow>> attemptsPage({
    required int limit,
    int offset = 0,
  }) {
    final query = select(quizAttempts)
      ..where((a) => a.finishedAt.isNotNull())
      ..orderBy([(a) => OrderingTerm.desc(a.startedAt)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<int> countFinishedAttempts() async {
    final count = quizAttempts.id.count();
    final query = selectOnly(quizAttempts)
      ..addColumns([count])
      ..where(quizAttempts.finishedAt.isNotNull());
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Aggregate stats across all finished attempts, computed in SQL (one
  /// SELECT with aggregates; never materializes attempt rows). Feeds the
  /// history header card.
  Future<({int attemptCount, int questionCount, int correctCount})>
      historyStats() async {
    final attemptCount = quizAttempts.id.count();
    final questionSum = quizAttempts.totalQuestions.sum();
    final correctSum = quizAttempts.correctCount.sum();
    final query = selectOnly(quizAttempts)
      ..addColumns([attemptCount, questionSum, correctSum])
      ..where(quizAttempts.finishedAt.isNotNull());
    final row = await query.getSingle();
    return (
      attemptCount: row.read(attemptCount) ?? 0,
      questionCount: row.read(questionSum) ?? 0,
      correctCount: row.read(correctSum) ?? 0,
    );
  }

  /// One attempt with its questions in insertion order
  /// (legacy `get_quiz_attempt_detail`).
  Future<QuizAttemptDetail?> attemptDetail(int attemptId) async {
    final attempt = await (select(quizAttempts)
          ..where((a) => a.id.equals(attemptId)))
        .getSingleOrNull();
    if (attempt == null) return null;
    final questionRows = await (select(quizQuestions)
          ..where((q) => q.attemptId.equals(attemptId))
          ..orderBy([(q) => OrderingTerm.asc(q.id)]))
        .get();
    return (attempt: attempt, questions: questionRows);
  }

  /// Deletes one attempt (questions cascade).
  Future<void> deleteAttempt(int attemptId) async {
    await (delete(quizAttempts)..where((a) => a.id.equals(attemptId))).go();
  }

  /// Clears all history (legacy `clear_quiz_history`).
  Future<void> clearHistory() async {
    await delete(quizAttempts).go();
  }
}
