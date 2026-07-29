/// core/ai/lib/src/sanitizer.dart
///
/// LLM output is untrusted input. This pipeline ports the legacy
/// `_clean_json_response` + `_sanitize_card_fields` contract:
///  * strip Markdown code fences and any prose around the JSON object,
///  * accept only whitelisted fields,
///  * coerce lists to comma-joined strings, scalars to strings,
///  * collapse whitespace and cap every field at 2000 chars,
///  * never throw on malformed model output — return a typed failure.
library;

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core_ai/src/ai_client.dart';

part 'sanitizer.freezed.dart';

/// Maximum length of any single sanitized field (legacy contract).
const int kMaxFieldLength = 2000;

/// The structured card an enrichment run produces. `banglaMeaning` maps to a
/// `word_translations` row with lang code `bn` at the persistence layer.
@freezed
abstract class EnrichedCard with _$EnrichedCard {
  const factory EnrichedCard({
    @Default('') String meaning,
    @Default('') String banglaMeaning,
    @Default('') String ipa,
    @Default('') String partOfSpeech,
    @Default('') String exampleSentence,
    @Default('') String synonyms,
    @Default('') String antonyms,
  }) = _EnrichedCard;
}

/// Strips code fences and extracts the outermost JSON object.
String cleanJsonPayload(String raw) {
  var text = raw.trim();
  final fence = RegExp(r'^```[a-zA-Z]*\s*([\s\S]*?)\s*```$');
  final fenceMatch = fence.firstMatch(text);
  if (fenceMatch != null) {
    text = fenceMatch.group(1)!.trim();
  }
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start != -1 && end > start) {
    text = text.substring(start, end + 1);
  }
  return text;
}

String _sanitizeValue(Object? value) {
  final text = switch (value) {
    null => '',
    final String s => s,
    final List<dynamic> items => items
        .map(_sanitizeValue)
        .where((item) => item.isNotEmpty)
        .join(', '),
    final num n => n.toString(),
    final bool b => b.toString(),
    _ => '',
  };
  final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return collapsed.length <= kMaxFieldLength
      ? collapsed
      : collapsed.substring(0, kMaxFieldLength);
}

/// Parses raw model output into a sanitized [EnrichedCard].
AiResult<EnrichedCard> parseEnrichedCard(String rawModelOutput) {
  final Object? decoded;
  try {
    decoded = jsonDecode(cleanJsonPayload(rawModelOutput));
  } on FormatException catch (e) {
    return AiErr(InvalidResponse('Model did not return JSON: ${e.message}'));
  }
  if (decoded is! Map) {
    return const AiErr(InvalidResponse('Model JSON is not an object'));
  }

  final card = EnrichedCard(
    meaning: _sanitizeValue(decoded['meaning']),
    banglaMeaning: _sanitizeValue(decoded['bangla_meaning']),
    ipa: _sanitizeValue(decoded['ipa']),
    partOfSpeech: _sanitizeValue(decoded['part_of_speech']),
    exampleSentence: _sanitizeValue(decoded['example_sentence']),
    synonyms: _sanitizeValue(decoded['synonyms']),
    antonyms: _sanitizeValue(decoded['antonyms']),
  );

  if (card.meaning.isEmpty) {
    return const AiErr(
      InvalidResponse('Model JSON is missing the required "meaning" field'),
    );
  }
  return AiOk(card);
}
