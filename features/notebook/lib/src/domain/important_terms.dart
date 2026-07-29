/// features/notebook/lib/src/domain/important_terms.dart
///
/// The single source of truth for the permanent synonym/antonym highlight:
/// a clicked term is toggled in or out of the word's persisted "important"
/// set (Words.importantSynonyms / Words.importantAntonyms). Used by BOTH
/// the detail view chips and the notebook card terms, so the two surfaces
/// can never behave differently: highlights accumulate, persist across
/// restarts, and only clicking an already-highlighted term removes it.
library;

import 'word.dart';

/// Builds the [WordFieldPatch] that toggles [term] in or out of [word]'s
/// persistent "important" highlight set.
///
/// Pass [synonym] when the caller already knows the section (the detail
/// view chips do); otherwise the section is inferred from the word's
/// synonym/antonym lists. Returns null when the term is blank or is not
/// one of the word's synonyms/antonyms (nothing to toggle).
WordFieldPatch? toggleImportantTermPatch(
  Word word,
  String term, {
  bool? synonym,
}) {
  final trimmed = term.trim();
  final lower = trimmed.toLowerCase();
  if (lower.isEmpty) return null;

  bool contains(List<String> terms) =>
      terms.any((t) => t.toLowerCase() == lower);
  List<String> toggled(List<String> current) => contains(current)
      ? [
          for (final t in current)
            if (t.toLowerCase() != lower) t,
        ]
      : [...current, trimmed];

  final bool? isSynonym = synonym ??
      (contains(word.synonymList)
          ? true
          : contains(word.antonymList)
              ? false
              : null);
  return switch (isSynonym) {
    true => WordFieldPatch(
        importantSynonyms: toggled(word.importantSynonymList).join(', '),
      ),
    false => WordFieldPatch(
        importantAntonyms: toggled(word.importantAntonymList).join(', '),
      ),
    null => null,
  };
}
