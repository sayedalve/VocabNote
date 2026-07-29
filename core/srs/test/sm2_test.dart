import 'package:core_srs/core_srs.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);

  group('Sm2.review', () {
    test('first correct answer schedules a 1-day interval', () {
      final next = Sm2.review(const Sm2State(), 5, now: now);
      expect(next.repetitions, 1);
      expect(next.intervalDays, 1);
      expect(next.easeFactor, closeTo(2.6, 1e-9));
      expect(next.due, now.add(const Duration(days: 1)));
    });

    test('second correct answer schedules a 6-day interval', () {
      var s = Sm2.review(const Sm2State(), 5, now: now);
      s = Sm2.review(s, 5, now: now);
      expect(s.repetitions, 2);
      expect(s.intervalDays, 6);
      expect(s.easeFactor, closeTo(2.7, 1e-9));
    });

    test('third correct answer multiplies by the updated ease factor', () {
      var s = Sm2.review(const Sm2State(), 5, now: now);
      s = Sm2.review(s, 5, now: now);
      s = Sm2.review(s, 5, now: now);
      // EF after three q=5 reviews: 2.8; interval = round(6 * 2.8) = 17.
      expect(s.repetitions, 3);
      expect(s.easeFactor, closeTo(2.8, 1e-9));
      expect(s.intervalDays, (6 * 2.8).round());
    });

    test('failure resets the streak and schedules a 1-day retry', () {
      var s = Sm2.review(const Sm2State(), 5, now: now);
      s = Sm2.review(s, 5, now: now);
      s = Sm2.review(s, 2, now: now);
      // EF drop for q=2: 2.7 + (0.1 - 3 * (0.08 + 3 * 0.02)) = 2.38.
      expect(s.repetitions, 0);
      expect(s.intervalDays, 1);
      expect(s.easeFactor, closeTo(2.38, 1e-9));
      expect(s.due, now.add(const Duration(days: 1)));
    });

    test('ease factor never drops below the 1.3 floor', () {
      var s = const Sm2State();
      for (var i = 0; i < 20; i++) {
        s = Sm2.review(s, 0, now: now);
      }
      expect(s.easeFactor, Sm2.minEaseFactor);
    });

    test('quality is clamped into 0..5', () {
      final low = Sm2.review(const Sm2State(), -7, now: now);
      final high = Sm2.review(const Sm2State(), 42, now: now);
      expect(low.repetitions, 0);
      expect(high.repetitions, 1);
      expect(high.easeFactor, closeTo(2.6, 1e-9));
    });
  });

  group('Sm2State.isDue', () {
    test('never-reviewed items are always due', () {
      expect(const Sm2State().isDue(now), isTrue);
    });

    test('items become due once the due moment passes', () {
      final s = Sm2.review(const Sm2State(), 5, now: now);
      expect(s.isDue(now), isFalse);
      expect(s.isDue(now.add(const Duration(days: 1))), isTrue);
    });
  });

  group('Sm2.qualityFrom', () {
    test('maps quiz outcomes onto the 0-5 scale', () {
      expect(Sm2.qualityFrom(correct: true), 5);
      expect(Sm2.qualityFrom(correct: true, hesitant: true), 4);
      expect(Sm2.qualityFrom(correct: false), 2);
    });
  });
}
