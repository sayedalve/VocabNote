/// features/transfer/test/csv_codec_test.dart
///
/// Unit tests for the pure RFC-4180 codec used by CSV import/export.
library;

import 'package:feature_transfer/feature_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeCsv', () {
    test('writes plain fields separated by commas with CRLF rows', () {
      expect(
        encodeCsv([
          ['a', 'b'],
          ['c', 'd'],
        ]),
        'a,b\r\nc,d\r\n',
      );
    });

    test('quotes fields containing commas, quotes, and newlines', () {
      expect(
        encodeCsv([
          ['a,b', 'say "hi"', 'line1\nline2'],
        ]),
        '"a,b","say ""hi""","line1\nline2"\r\n',
      );
    });
  });

  group('decodeCsv', () {
    test('parses simple rows with LF, CRLF, and no trailing newline', () {
      expect(
        decodeCsv('a,b\r\nc,d\ne,f'),
        [
          ['a', 'b'],
          ['c', 'd'],
          ['e', 'f'],
        ],
      );
    });

    test('parses quoted fields with embedded delimiters', () {
      expect(
        decodeCsv('"a,b","say ""hi""","line1\nline2"'),
        [
          ['a,b', 'say "hi"', 'line1\nline2'],
        ],
      );
    });

    test('keeps empty leading and trailing fields', () {
      expect(
        decodeCsv(',plain,\r\n'),
        [
          ['', 'plain', ''],
        ],
      );
    });

    test('round-trips through encodeCsv', () {
      final rows = [
        ['notebook', 'headword', 'notes'],
        ['My Notebook', 'serendipity', 'has, commas "quotes"\nand lines'],
        ['', 'plain', ''],
      ];
      expect(decodeCsv(encodeCsv(rows)), rows);
    });

    test('empty input decodes to no rows', () {
      expect(decodeCsv(''), isEmpty);
    });
  });
}
