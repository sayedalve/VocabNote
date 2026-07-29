/// core/db/test/text_normalization_test.dart
///
/// Unit tests for the headword/notebook-name normalization contract that
/// every capture, import, and rename path depends on.
library;

import 'package:core_db/core_db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeHeadword', () {
    test('trims and collapses internal whitespace', () {
      final result = normalizeHeadword('  hello   world  ');
      expect(result, isA<ValidHeadword>());
      final valid = result as ValidHeadword;
      expect(valid.display, 'Hello World');
      expect(valid.norm, 'hello world');
    });

    test('normalizes the lookup key to lowercase and the display to '
        'title case', () {
      final result = normalizeHeadword('jargon') as ValidHeadword;
      expect(result.display, 'Jargon');
      expect(result.norm, 'jargon');
    });

    test('title-cases every word, including all-caps input', () {
      final result = normalizeHeadword('SERENDIPITY') as ValidHeadword;
      expect(result.display, 'Serendipity');
      expect(result.norm, 'serendipity');
    });

    test('title-cases hyphenated compounds', () {
      final result = normalizeHeadword('self-esteem') as ValidHeadword;
      expect(result.display, 'Self-Esteem');
      expect(result.norm, 'self-esteem');
    });

    test('rejects empty input', () {
      expect(normalizeHeadword('   '), isA<InvalidHeadword>());
    });

    test('accepts input at exactly the max length', () {
      final input = 'a' * DbLimits.maxHeadwordLength;
      expect(normalizeHeadword(input), isA<ValidHeadword>());
    });

    test('rejects input over the max length', () {
      final input = 'a' * (DbLimits.maxHeadwordLength + 1);
      expect(normalizeHeadword(input), isA<InvalidHeadword>());
    });

    test('rejects invisible/control characters', () {
      expect(normalizeHeadword('hello\u200Bworld'), isA<InvalidHeadword>());
      expect(normalizeHeadword('hello\u0007world'), isA<InvalidHeadword>());
    });
  });

  group('normalizeNotebookName', () {
    test('trims and collapses internal whitespace', () {
      final result =
          normalizeNotebookName('  My   Notebook  ') as ValidNotebookName;
      expect(result.name, 'My Notebook');
    });

    test('rejects empty input', () {
      expect(normalizeNotebookName(''), isA<InvalidNotebookName>());
    });

    test('accepts input at exactly the max length', () {
      final input = 'a' * DbLimits.maxNotebookNameLength;
      expect(normalizeNotebookName(input), isA<ValidNotebookName>());
    });

    test('rejects input over the max length', () {
      final input = 'a' * (DbLimits.maxNotebookNameLength + 1);
      expect(normalizeNotebookName(input), isA<InvalidNotebookName>());
    });
  });
}
