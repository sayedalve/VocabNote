/// core/ai/test/sanitizer_test.dart
///
/// Unit tests for the LLM-output sanitization pipeline. This is the only
/// boundary between untrusted model output and the local database, so its
/// edge cases matter more than most.
library;

import 'package:core_ai/core_ai.dart';
import 'package:test/test.dart';

void main() {
  group('parseEnrichedCard', () {
    test('parses a well-formed JSON object', () {
      const raw = '''
{
  "meaning": "a feeling of great happiness",
  "bangla_meaning": "\u0996\u09c1\u09b6\u09c0",
  "ipa": "d\u0292\u0254\u026a",
  "part_of_speech": "noun",
  "example_sentence": "Her face lit up with joy.",
  "synonyms": ["delight", "happiness"],
  "antonyms": ["sorrow"]
}''';
      final result = parseEnrichedCard(raw);
      switch (result) {
        case AiOk(:final value):
          expect(value.meaning, 'a feeling of great happiness');
          expect(value.synonyms, 'delight, happiness');
          expect(value.antonyms, 'sorrow');
        case AiErr():
          fail('Expected AiOk, got $result');
      }
    });

    test('strips Markdown code fences before parsing', () {
      const raw = '```json\n{"meaning": "test"}\n```';
      final result = parseEnrichedCard(raw);
      expect(result, isA<AiOk<EnrichedCard>>());
    });

    test('fails when the required "meaning" field is missing', () {
      final result = parseEnrichedCard('{"ipa": "x"}');
      expect(result, isA<AiErr<EnrichedCard>>());
    });

    test('fails on malformed JSON instead of throwing', () {
      final result = parseEnrichedCard('not json at all');
      expect(result, isA<AiErr<EnrichedCard>>());
    });
  });

  group('cleanJsonPayload', () {
    test('extracts the JSON object from surrounding prose', () {
      const raw = 'Sure! Here you go:\n{"meaning": "x"}\nHope that helps.';
      expect(cleanJsonPayload(raw), '{"meaning": "x"}');
    });
  });
}
