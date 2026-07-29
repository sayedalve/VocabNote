/// core/srs/lib/src/sm2.dart
///
/// Canonical SuperMemo SM-2, ported to match the legacy Python app's
/// scheduler. Pure domain code: deterministic, immutable, no I/O.
///
/// Integration contract (schema-v4 work in the app layer):
///  * persist one [Sm2State] per word (repetitions, ease factor, interval,
///    due date),
///  * after each quiz answer, map the outcome to a 0-5 quality with
///    [Sm2.qualityFrom] and store `Sm2.review(state, quality)`,
///  * a word is due for review when [Sm2State.isDue] is true.
library;

/// Immutable SM-2 scheduling state for one item (word).
final class Sm2State {
  const Sm2State({
    this.repetitions = 0,
    this.easeFactor = Sm2.defaultEaseFactor,
    this.intervalDays = 0,
    this.due,
  })  : assert(repetitions >= 0, 'repetitions must be >= 0'),
        assert(
          easeFactor >= Sm2.minEaseFactor,
          'easeFactor must be >= ${Sm2.minEaseFactor}',
        ),
        assert(intervalDays >= 0, 'intervalDays must be >= 0');

  /// Consecutive successful reviews (quality >= 3).
  final int repetitions;

  /// SM-2 easiness factor; never below [Sm2.minEaseFactor].
  final double easeFactor;

  /// Current inter-review interval in days.
  final int intervalDays;

  /// Next review moment (UTC). Null means "never reviewed": always due.
  final DateTime? due;

  /// Whether this item should be shown for review at [now].
  bool isDue(DateTime now) => due == null || !now.toUtc().isBefore(due!);

  @override
  bool operator ==(Object other) =>
      other is Sm2State &&
      other.repetitions == repetitions &&
      other.easeFactor == easeFactor &&
      other.intervalDays == intervalDays &&
      other.due == due;

  @override
  int get hashCode => Object.hash(repetitions, easeFactor, intervalDays, due);

  @override
  String toString() => 'Sm2State(repetitions: $repetitions, '
      'easeFactor: ${easeFactor.toStringAsFixed(2)}, '
      'intervalDays: $intervalDays, due: $due)';
}

/// The SM-2 algorithm.
abstract final class Sm2 {
  /// Floor for the easiness factor, per the original algorithm.
  static const double minEaseFactor = 1.3;

  /// Starting easiness factor for new items.
  static const double defaultEaseFactor = 2.5;

  /// Safety cap so a corrupt ease factor can never schedule reviews
  /// centuries out (100 years).
  static const int maxIntervalDays = 36500;

  /// Applies one review with [quality] in 0..5 (values outside the range
  /// are clamped) and returns the next scheduling state.
  ///
  /// Canonical SM-2:
  ///  * the ease factor is updated on every review:
  ///    EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)), floored at 1.3;
  ///  * quality < 3 resets the repetition streak and schedules a 1-day
  ///    retry;
  ///  * otherwise the interval is 1 day, then 6 days, then
  ///    round(previousInterval * EF').
  static Sm2State review(Sm2State state, int quality, {DateTime? now}) {
    final q = quality.clamp(0, 5);
    final at = (now ?? DateTime.now()).toUtc();

    final ef = (state.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
        .clamp(minEaseFactor, double.infinity)
        .toDouble();

    if (q < 3) {
      return Sm2State(
        repetitions: 0,
        easeFactor: ef,
        intervalDays: 1,
        due: at.add(const Duration(days: 1)),
      );
    }

    final repetitions = state.repetitions + 1;
    final intervalDays = switch (repetitions) {
      1 => 1,
      2 => 6,
      _ => (state.intervalDays * ef).round().clamp(1, maxIntervalDays),
    };
    return Sm2State(
      repetitions: repetitions,
      easeFactor: ef,
      intervalDays: intervalDays,
      due: at.add(Duration(days: intervalDays)),
    );
  }

  /// Maps a quiz answer onto the SM-2 quality scale: 5 for a confident
  /// correct answer, 4 for a hesitant correct answer, 2 for a wrong answer
  /// ("incorrect, but the correct one felt familiar").
  static int qualityFrom({required bool correct, bool hesitant = false}) =>
      correct ? (hesitant ? 4 : 5) : 2;
}
