/// features/notebook/lib/src/domain/pronunciation.dart
///
/// Pronunciation display formatting. VocabNote stores IPA (produced by the
/// AI enrichment pipeline); users can choose between raw IPA ("/\u02c8k\u00e6t/") and
/// a simplified readable respelling ("kat", "i-FEM-uh-ruhl") in the
/// Typography & Spacing settings ([VnCardStyle.simplifiedPronunciation]).
///
/// Pure Dart, deterministic, and total: any input produces a printable
/// result, and unknown IPA symbols are dropped rather than leaking through.
library;

/// Formats [ipa] for display.
///
/// Returns an empty string when [ipa] is blank. With [simplified] false the
/// transcription is wrapped in slashes ("/\u02c8k\u00e6t/"); with true it becomes a
/// readable respelling where the stressed syllable is uppercased when the
/// word has more than one syllable ("WAW-tuh", "kat").
String formatPronunciation(String ipa, {required bool simplified}) {
  final trimmed = ipa.trim().replaceAll(RegExp(r'^/+|/+$'), '').trim();
  if (trimmed.isEmpty) return '';
  if (!simplified) return '/$trimmed/';
  final respelled = simplifyIpa(trimmed);
  return respelled.isEmpty ? '/$trimmed/' : respelled;
}

/// Converts an IPA transcription into an approximate English respelling.
///
/// This is intentionally a pragmatic approximation (like dictionary
/// "pro-nun-see-AY-shun" guides), not a phonological transformation:
///  * multi-character IPA sequences are mapped longest-first in a single
///    pass, so replacement output is never re-matched,
///  * stress marks and dots split syllables, joined with "-",
///  * the primary-stressed syllable is uppercased when the word has more
///    than one syllable,
///  * plain ASCII letters pass through; unknown symbols are dropped.
String simplifyIpa(String ipa) {
  final words = ipa
      .split(RegExp(r'\s+'))
      .map(_simplifyWord)
      .where((word) => word.isNotEmpty);
  return words.join(' ');
}

String _simplifyWord(String word) {
  final syllables = <({String text, bool primaryStress})>[];
  var buffer = StringBuffer();
  var stressed = false;

  void pushSyllable() {
    if (buffer.isNotEmpty) {
      syllables.add((text: buffer.toString(), primaryStress: stressed));
    }
    buffer = StringBuffer();
  }

  for (final rune in word.runes) {
    final char = String.fromCharCode(rune);
    if (char == _primaryStress || char == _secondaryStress || char == '.') {
      pushSyllable();
      stressed = char == _primaryStress;
    } else {
      buffer.write(char);
    }
  }
  pushSyllable();

  final respelled = <({String text, bool primaryStress})>[
    for (final syllable in syllables)
      if (_respell(syllable.text) case final text when text.isNotEmpty)
        (text: text, primaryStress: syllable.primaryStress),
  ];
  if (respelled.isEmpty) return '';

  // "kat" stays lowercase; "WAW-tuh" marks the stressed syllable.
  final markStress = respelled.length > 1;
  return respelled
      .map((syllable) => markStress && syllable.primaryStress
          ? syllable.text.toUpperCase()
          : syllable.text)
      .join('-');
}

const String _primaryStress = '\u02c8';
const String _secondaryStress = '\u02cc';

/// Ordered IPA-to-respelling map. Longest patterns first; scanned in a
/// single greedy pass so outputs (e.g. "j" from /d\u0292/) are never re-mapped.
const List<(String, String)> _ipaReplacements = [
  // Three-character sequences.
  ('ju\u02d0', 'yoo'),
  // Diphthongs and long vowels.
  ('e\u026a', 'ay'),
  ('a\u026a', 'igh'),
  ('\u0254\u026a', 'oy'),
  ('a\u028a', 'ow'),
  ('\u0259\u028a', 'oh'),
  ('o\u028a', 'oh'),
  ('\u026a\u0259', 'eer'),
  ('e\u0259', 'air'),
  ('\u028a\u0259', 'oor'),
  ('i\u02d0', 'ee'),
  ('u\u02d0', 'oo'),
  ('\u0251\u02d0', 'ah'),
  ('\u0254\u02d0', 'aw'),
  ('\u025c\u02d0', 'ur'),
  // Affricates and two-character consonants.
  ('t\u0283', 'ch'),
  ('d\u0292', 'j'),
  // Single consonants.
  ('\u0283', 'sh'),
  ('\u0292', 'zh'),
  ('\u03b8', 'th'),
  ('\u00f0', 'th'),
  ('\u014b', 'ng'),
  ('\u0261', 'g'),
  ('\u0279', 'r'),
  ('\u027e', 't'),
  ('\u0294', ''),
  ('j', 'y'),
  // Single vowels.
  ('\u00e6', 'a'),
  ('\u026a', 'i'),
  ('\u028a', 'oo'),
  ('\u028c', 'u'),
  ('\u0252', 'o'),
  ('\u0259', 'uh'),
  ('\u025c', 'ur'),
  ('\u025d', 'ur'),
  ('\u025a', 'er'),
  ('\u025b', 'e'),
  ('\u0251', 'ah'),
  ('\u0254', 'aw'),
  ('i', 'ee'),
  ('u', 'oo'),
  // Length and syllabicity marks contribute nothing on their own.
  ('\u02d0', ''),
  ('\u02d1', ''),
  ('\u0329', ''),
];

/// Single greedy left-to-right pass over [syllable], mapping the longest
/// matching IPA sequence at each position.
String _respell(String syllable) {
  final input = syllable.trim();
  final output = StringBuffer();
  var index = 0;
  outer:
  while (index < input.length) {
    for (final (pattern, replacement) in _ipaReplacements) {
      if (input.startsWith(pattern, index)) {
        output.write(replacement);
        index += pattern.length;
        continue outer;
      }
    }
    final char = input[index];
    // Plain ASCII letters (p, b, t, d, k, s, z, m, n, l, r, w, h, f, v...)
    // pass through; anything else is an unmapped IPA symbol and is dropped.
    if (RegExp(r'[A-Za-z]').hasMatch(char)) {
      output.write(char);
    }
    index++;
  }
  return output.toString();
}
