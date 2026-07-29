import 'package:core_design_system/core_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatVnDate', () {
    test('renders day, abbreviated month, and year', () {
      expect(formatVnDate(DateTime(2026, 1, 15)), '15 Jan 2026');
      expect(formatVnDate(DateTime(2026, 12, 3)), '3 Dec 2026');
    });
  });

  group('formatVnDateTime', () {
    test('appends zero-padded 24h time', () {
      expect(
        formatVnDateTime(DateTime(2026, 1, 15, 14, 30)),
        '15 Jan 2026, 14:30',
      );
      expect(
        formatVnDateTime(DateTime(2026, 7, 4, 9, 5)),
        '4 Jul 2026, 09:05',
      );
    });

    test('midnight renders as 00:00', () {
      expect(
        formatVnDateTime(DateTime(2026, 3, 1)),
        '1 Mar 2026, 00:00',
      );
    });
  });
}
