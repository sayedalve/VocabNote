/// app/lib/app_info.dart
///
/// Single source of truth for user-facing application metadata (About
/// page, license dialog). Keep [AppInfo.version] in sync with `version:`
/// in app/pubspec.yaml \u2014 Flutter cannot read its own pubspec at runtime
/// without an extra package, and the Melos workspace pubspecs are
/// intentionally left untouched.
library;

abstract final class AppInfo {
  static const String name = 'VocabNote';

  /// Keep in sync with `version:` in app/pubspec.yaml (currently 4.0.0+1).
  static const String version = '4.0.0';
  static const String build = '1';

  static const String description =
      'An offline-first AI vocabulary notebook for Windows. Capture a word '
      'in one keystroke and let AI fill in the meaning, Bangla translation, '
      'pronunciation, example, synonyms, and antonyms \u2014 everything is '
      'stored locally on this PC.';

  static const String developer = 'Md Sayed Alve';
  static const String institution =
      'Shahjalal University of Science and Technology';
  static const String department = 'Civil & Environmental Engineering';
  static const String facebookUrl = 'https://facebook.com/1alve1';
  static const String repositoryUrl =
      'https://github.com/sayedalve/VocabNote';
  static const String releasesUrl =
      'https://github.com/sayedalve/VocabNote/releases';

  static const String copyright = '\u00a9 2026 Md Sayed Alve';
}
