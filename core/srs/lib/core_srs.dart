/// VocabNote spaced-repetition core: pure-Dart SM-2 scheduling.
///
/// This package restores the SM-2 algorithm the legacy Python app shipped
/// (and the v4 rewrite dropped). It is deliberately dependency-free: no
/// Flutter, no database imports, fully unit-testable.
library core_srs;

export 'src/sm2.dart';
