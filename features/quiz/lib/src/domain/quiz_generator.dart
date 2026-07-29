/// features/quiz/lib/src/domain/quiz_generator.dart
///
/// Quiz question generation, ported from the legacy `api/quiz_generator.py`:
///  * AI path: one strict-JSON prompt over up to 120 pool words, hard
///    validation of every returned item, and one top-up round on shortfall.
///  * On-device path: deterministic local generation used when no API key is
///    saved or the AI call fails — the quiz always works offline.
///
/// Both paths share the same contract: every question has exactly four
/// unique options, a valid correct index, no word is used twice, and the
/// number of questions equals min(requested, usable pool size).
library;

import 'dart:convert';
import 'dart:math';

import 'quiz_models.dart';

/// Cap on how many pool words are embedded in one AI prompt (legacy
/// `MAX_WORDS_IN_PROMPT`).
const int kMaxWordsInPrompt = 120;

/// Hard timeout for one AI generation call (legacy `REQUEST_TIMEOUT_SECS`).
const Duration kQuizAiTimeout = Duration(seconds: 75);

/// Sampling temperature for quiz generation (legacy contract).
const double kQuizAiTemperature = 0.6;

/// System message for the AI path (legacy contract).
const String kQuizSystemPrompt =
    'You are a precise quiz generator. You respond with strict JSON only: '
    'no Markdown, no code fences, no commentary before or after the JSON.';

/// Builds the user prompt for one AI generation round.
String buildQuizPrompt({
  required List<QuizWordEntry> pool,
  required int count,
  required List<QuizQuestionType> allowedTypes,
}) {
  final capped = pool.take(kMaxWordsInPrompt).toList(growable: false);
  final wordsJson = jsonEncode([
    for (final entry in capped)
      {
        'word': entry.word,
        if (entry.meaning.isNotEmpty) 'meaning': entry.meaning,
        if (entry.synonyms.isNotEmpty) 'synonyms': entry.synonyms,
        if (entry.antonyms.isNotEmpty) 'antonyms': entry.antonyms,
      },
  ]);
  final typeList = allowedTypes.map((t) => t.dbValue).join(', ');

  return '''
Create exactly $count multiple-choice vocabulary quiz questions from this word list:

$wordsJson

Rules:
- Allowed question types: $typeList.
- "meaning" questions ask for the correct definition of the word.
- "synonym" questions ask for a word with a similar meaning.
- "antonym" questions ask for a word with the opposite meaning.
- Only create a question type for a word if the list shows data for it.
- Each question must be about a different word from the list. Never reuse a word.
- Each question has exactly 4 options: 1 correct and 3 plausible but clearly wrong distractors.
- Options must be unique, non-empty, and free of "all of the above" style choices.
- Add a one-sentence explanation of the correct answer.

Return a single JSON array (no wrapper object) where each item is:
{
  "word": "the word from the list",
  "type": "meaning | synonym | antonym",
  "question": "the question text",
  "options": ["A", "B", "C", "D"],
  "correct_index": 0,
  "explanation": "one sentence"
}

Output the JSON array and nothing else.''';
}

/// Strips code fences / surrounding prose and extracts the outermost JSON
/// array (legacy `_extract_json_array`).
String extractJsonArray(String raw) {
  var text = raw.trim();
  final fence = RegExp('^```[a-zA-Z]*\\s*([\\s\\S]*?)\\s*```\$');
  final match = fence.firstMatch(text);
  if (match != null) text = match.group(1)!.trim();
  final start = text.indexOf('[');
  final end = text.lastIndexOf(']');
  if (start != -1 && end > start) {
    text = text.substring(start, end + 1);
  }
  return text;
}

String _clean(Object? value) {
  if (value is! String) return '';
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Validates one AI round (legacy `_validate_and_normalize`): known word,
/// allowed + supported type, exactly 4 unique non-empty options, valid
/// correct index, no word reuse. Options are reshuffled locally so the model
/// cannot bias the correct position.
List<QuizQuestion> parseAiQuestions({
  required String rawModelOutput,
  required List<QuizWordEntry> pool,
  required List<QuizQuestionType> allowedTypes,
  required Set<String> usedWordsLower,
  required Random random,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(extractJsonArray(rawModelOutput));
  } on FormatException {
    return const [];
  }
  if (decoded is! List) return const [];

  final poolByWord = <String, QuizWordEntry>{
    for (final entry in pool) entry.word.toLowerCase(): entry,
  };

  final accepted = <QuizQuestion>[];
  for (final item in decoded) {
    if (item is! Map) continue;

    final word = _clean(item['word']);
    final entry = poolByWord[word.toLowerCase()];
    if (entry == null) continue;
    if (usedWordsLower.contains(entry.word.toLowerCase())) continue;

    final type = QuizQuestionType.tryParse(_clean(item['type']));
    if (type == null || !allowedTypes.contains(type)) continue;
    if (!entry.supports(type)) continue;

    final question = _clean(item['question']);
    if (question.isEmpty) continue;

    final rawOptions = item['options'];
    if (rawOptions is! List || rawOptions.length != 4) continue;
    final options = [for (final o in rawOptions) _clean(o)];
    if (options.any((o) => o.isEmpty)) continue;
    final unique = {for (final o in options) o.toLowerCase()};
    if (unique.length != 4) continue;

    final rawIndex = item['correct_index'];
    final correctIndex = rawIndex is int
        ? rawIndex
        : int.tryParse(_clean(rawIndex)) ?? -1;
    if (correctIndex < 0 || correctIndex > 3) continue;

    // Reshuffle so the model cannot bias the answer position.
    final correct = options[correctIndex];
    final shuffled = [...options]..shuffle(random);

    accepted.add(
      QuizQuestion(
        wordId: entry.wordId,
        word: entry.word,
        type: type,
        question: question,
        options: shuffled,
        correctIndex: shuffled.indexOf(correct),
        explanation: _clean(item['explanation']),
      ),
    );
    usedWordsLower.add(entry.word.toLowerCase());
  }
  return accepted;
}

/// On-device question generation. Distractors are drawn from the other pool
/// words' data, so any pool of [kQuizMinPoolSize]+ words always yields four
/// unique options — no question is ever silently dropped.
List<QuizQuestion> generateLocalQuestions({
  required List<QuizWordEntry> pool,
  required int count,
  required List<QuizQuestionType> allowedTypes,
  required Random random,
  Set<String>? usedWordsLower,
}) {
  final used = usedWordsLower ?? <String>{};
  final questions = <QuizQuestion>[];
  final shuffledPool = [...pool]..shuffle(random);

  for (final entry in shuffledPool) {
    if (questions.length >= count) break;
    if (used.contains(entry.word.toLowerCase())) continue;

    final possibleTypes = [
      for (final type in allowedTypes)
        if (entry.supports(type)) type,
    ]..shuffle(random);
    if (possibleTypes.isEmpty) continue;

    QuizQuestion? question;
    for (final type in possibleTypes) {
      question = _buildLocalQuestion(
        entry: entry,
        type: type,
        pool: pool,
        random: random,
      );
      if (question != null) break;
    }
    if (question == null) continue;

    questions.add(question);
    used.add(entry.word.toLowerCase());
  }
  return questions;
}

QuizQuestion? _buildLocalQuestion({
  required QuizWordEntry entry,
  required QuizQuestionType type,
  required List<QuizWordEntry> pool,
  required Random random,
}) {
  final String correct;
  final String questionText;
  final String explanation;

  switch (type) {
    case QuizQuestionType.meaning:
      correct = entry.meaning;
      questionText = 'What is the meaning of “${entry.word}”?';
      explanation = '“${entry.word}” means: ${entry.meaning}';
    case QuizQuestionType.synonym:
      correct = entry.synonyms[random.nextInt(entry.synonyms.length)];
      questionText = 'Which word is a synonym of “${entry.word}”?';
      explanation = '“$correct” is a synonym of “${entry.word}”.';
    case QuizQuestionType.antonym:
      correct = entry.antonyms[random.nextInt(entry.antonyms.length)];
      questionText = 'Which word is an antonym of “${entry.word}”?';
      explanation = '“$correct” is an antonym of “${entry.word}”.';
  }
  if (correct.isEmpty) return null;

  final distractors = _localDistractors(
    entry: entry,
    type: type,
    correct: correct,
    pool: pool,
    random: random,
  );
  if (distractors.length < 3) return null;

  final options = [correct, ...distractors.take(3)]..shuffle(random);
  return QuizQuestion(
    wordId: entry.wordId,
    word: entry.word,
    type: type,
    question: questionText,
    options: options,
    correctIndex: options.indexOf(correct),
    explanation: explanation,
  );
}

/// Wrong-answer candidates for the local path. For meaning questions the
/// primary source is other words' meanings; for synonym/antonym questions it
/// is other words' synonym/antonym terms (plus their headwords as a last
/// resort). Everything the subject word could legitimately match is excluded.
List<String> _localDistractors({
  required QuizWordEntry entry,
  required QuizQuestionType type,
  required String correct,
  required List<QuizWordEntry> pool,
  required Random random,
}) {
  final forbidden = <String>{
    correct.toLowerCase(),
    entry.word.toLowerCase(),
    if (type != QuizQuestionType.meaning) ...[
      for (final s in entry.synonyms) s.toLowerCase(),
      for (final a in entry.antonyms) a.toLowerCase(),
    ],
    if (type == QuizQuestionType.meaning) entry.meaning.toLowerCase(),
  };

  final primary = <String>[];
  final fallback = <String>[];
  for (final other in pool) {
    if (other.wordId == entry.wordId) continue;
    if (type == QuizQuestionType.meaning) {
      if (other.meaning.isNotEmpty) primary.add(other.meaning);
      fallback.addAll(other.synonyms);
      fallback.addAll(other.antonyms);
    } else {
      primary.addAll(other.synonyms);
      primary.addAll(other.antonyms);
      fallback.add(other.word);
      if (other.meaning.isNotEmpty) fallback.add(other.meaning);
    }
  }

  final seen = <String>{};
  List<String> distinct(List<String> source) => [
        for (final candidate in source)
          if (candidate.isNotEmpty &&
              !forbidden.contains(candidate.toLowerCase()) &&
              seen.add(candidate.toLowerCase()))
            candidate,
      ];

  final candidates = distinct(primary..shuffle(random));
  if (candidates.length < 3) {
    candidates.addAll(distinct(fallback..shuffle(random)));
  }
  return candidates;
}
