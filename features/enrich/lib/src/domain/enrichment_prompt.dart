/// features/enrich/lib/src/domain/enrichment_prompt.dart
///
/// Prompt construction, ported from the legacy `api/api.py` card prompt.
/// The model is instructed to return strict JSON matching the whitelist the
/// sanitizer (core_ai) enforces — prompt and sanitizer evolve together.
library;

/// System instruction shared by every enrichment call.
const String kEnrichmentSystemPrompt =
    'You are a precise bilingual (English/Bengali) lexicographer. '
    'You respond with strict JSON only: no Markdown, no code fences, '
    'no commentary before or after the JSON object.';

/// Builds the user prompt for one headword.
String buildEnrichmentPrompt(String headword) {
  final escaped = headword.replaceAll('"', r'\"');
  return '''
Create a vocabulary card for the English word "$escaped".

Return a single JSON object with exactly these keys:
{
  "meaning": "concise English definition (1-2 sentences)",
  "bangla_meaning": "natural Bengali translation of the meaning",
  "ipa": "IPA transcription without surrounding slashes",
  "part_of_speech": "noun | verb | adjective | adverb | preposition | conjunction | interjection | pronoun",
  "example_sentence": "one natural example sentence using the word",
  "synonyms": ["up to 6 close synonyms"],
  "antonyms": ["up to 6 antonyms, or an empty array"]
}

Rules:
- Use plain strings and arrays of strings only.
- If the word is misspelled, define the most likely intended word.
- If a field is unknown, use an empty string or empty array.
- Output the JSON object and nothing else.''';
}
