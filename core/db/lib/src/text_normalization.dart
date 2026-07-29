/// core/db/lib/src/text_normalization.dart
///
/// Input normalization rules:
///  * trim + collapse internal whitespace runs to single spaces,
///  * enforce max lengths (64 for headwords, 60 for notebook names),
///  * reject control (Cc) and invisible format (Cf) characters so that
///    zero-width/bidi-control payloads can never become lookup keys,
///  * headwords are stored for display in title case ("jargon" ->
///    "Jargon") while the lookup key stays lowercase, so every newly
///    added word renders consistently throughout the app.
library;

import 'tables.dart';

/// Control chars (C0 + DEL + C1) and the common Unicode format chars
/// (zero-width, bidi controls, word joiners, BOM). Mirrors the legacy
/// category Cc/Cf rejection without a full Unicode table dependency.
final RegExp _forbiddenChars = RegExp(
  '[\u0000-\u001F\u007F-\u009F\u00AD\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF]',
);

final RegExp _whitespaceRun = RegExp(r'\s+');

/// Result of validating raw user input for a headword.
sealed class HeadwordResult {
  const HeadwordResult();
}

final class ValidHeadword extends HeadwordResult {
  const ValidHeadword({required this.norm, required this.display});

  /// Normalized lookup key (lowercased).
  final String norm;

  /// Whitespace-normalized text rendered in title case (see
  /// [titleCaseHeadword]) - the casing shown throughout the app.
  final String display;
}

final class InvalidHeadword extends HeadwordResult {
  const InvalidHeadword(this.reason);

  final String reason;
}

/// Renders a headword in title case for display: the first letter of each
/// space- or hyphen-separated part is uppercased and the rest lowercased,
/// so "jargon" -> "Jargon", "de facto" -> "De Facto", and "self-esteem" ->
/// "Self-Esteem". Characters without a case mapping (digits, Bangla, ...)
/// pass through unchanged.
String titleCaseHeadword(String text) {
  final buffer = StringBuffer();
  var startOfWord = true;
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (char == ' ' || char == '-') {
      buffer.write(char);
      startOfWord = true;
      continue;
    }
    buffer.write(startOfWord ? char.toUpperCase() : char.toLowerCase());
    startOfWord = false;
  }
  return buffer.toString();
}

/// Validates and normalizes a raw headword.
HeadwordResult normalizeHeadword(String raw) {
  final collapsed = raw.trim().replaceAll(_whitespaceRun, ' ');
  if (collapsed.isEmpty) {
    return const InvalidHeadword('Enter a word first.');
  }
  if (collapsed.length > DbLimits.maxHeadwordLength) {
    return InvalidHeadword(
      'Words are limited to ${DbLimits.maxHeadwordLength} characters.',
    );
  }
  if (_forbiddenChars.hasMatch(collapsed)) {
    return const InvalidHeadword('That word contains invisible characters.');
  }
  return ValidHeadword(
    norm: collapsed.toLowerCase(),
    display: titleCaseHeadword(collapsed),
  );
}

/// Result of validating a notebook name.
sealed class NotebookNameResult {
  const NotebookNameResult();
}

final class ValidNotebookName extends NotebookNameResult {
  const ValidNotebookName(this.name);

  final String name;
}

final class InvalidNotebookName extends NotebookNameResult {
  const InvalidNotebookName(this.reason);

  final String reason;
}

/// Validates and normalizes a notebook name.
NotebookNameResult normalizeNotebookName(String raw) {
  final collapsed = raw.trim().replaceAll(_whitespaceRun, ' ');
  if (collapsed.isEmpty) {
    return const InvalidNotebookName('Enter a notebook name first.');
  }
  if (collapsed.length > DbLimits.maxNotebookNameLength) {
    return InvalidNotebookName(
      'Notebook names are limited to '
      '${DbLimits.maxNotebookNameLength} characters.',
    );
  }
  if (_forbiddenChars.hasMatch(collapsed)) {
    return const InvalidNotebookName(
      'That name contains invisible characters.',
    );
  }
  return ValidNotebookName(collapsed);
}

/// Splits a comma/semicolon-separated term list ("big, large; huge") into
/// trimmed, non-empty parts. Single home for a rule that previously existed
/// as private copies in the quiz controller and the text export service.
List<String> splitTermList(String raw) => [
      for (final part in raw.split(RegExp('[,;]')))
        if (part.trim().isNotEmpty) part.trim(),
    ];
