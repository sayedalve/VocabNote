/// core/ai/lib/src/adapters/gemini_adapter.dart
///
/// Adapter for the Google Gemini `generateContent` API (Google AI Studio).
/// The key travels in the `x-goog-api-key` header, never in the URL, so it
/// can never leak into logs — same contract as the legacy transport.
library;

import 'package:http/http.dart' as http;

import '../ai_client.dart';
import '../provider_config.dart';

final class GeminiAdapter extends HttpAiAdapter {
  GeminiAdapter({required ProviderConfig config, required http.Client httpClient})
      : super(config: config, httpClient: httpClient);

  String get _base => config.baseUrl.endsWith('/')
      ? config.baseUrl.substring(0, config.baseUrl.length - 1)
      : config.baseUrl;

  @override
  Uri endpoint() =>
      Uri.parse('$_base/models/${config.model}:generateContent');

  @override
  Map<String, String> headers(String apiKey) => {
        'x-goog-api-key': apiKey,
      };

  @override
  Map<String, Object?> body(AiRequest request) => {
        if (request.system case final system?)
          'system_instruction': {
            'parts': [
              {'text': system},
            ],
          },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': request.prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': request.temperature},
      };

  @override
  String? extractText(Map<String, Object?> json) {
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map) return null;
    final content = first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final text = parts
        .whereType<Map<dynamic, dynamic>>()
        .map((part) => part['text'])
        .whereType<String>()
        .join();
    return text.isEmpty ? null : text;
  }
}
