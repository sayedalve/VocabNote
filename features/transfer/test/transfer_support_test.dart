import 'package:core_db/core_db.dart';
import 'package:feature_transfer/src/application/transfer_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportReport.summary', () {
    test('includes every counter', () {
      const report = ImportReport(
        notebooksCreated: 2,
        wordsImported: 10,
        wordsSkipped: 3,
        translationsImported: 7,
      );
      expect(
        report.summary,
        'Imported 10 words (7 Bangla translations, 2 new notebooks). '
        'Skipped 3 duplicates/empty rows.',
      );
    });
  });

  group('clampField', () {
    test('trims surrounding whitespace', () {
      expect(clampField('  hello  '), 'hello');
    });

    test('keeps values at or under the limit unchanged', () {
      final value = 'a' * DbLimits.maxFieldLength;
      expect(clampField(value), value);
    });

    test('clamps values over the limit', () {
      final value = 'a' * (DbLimits.maxFieldLength + 100);
      expect(clampField(value).length, DbLimits.maxFieldLength);
    });
  });
}
