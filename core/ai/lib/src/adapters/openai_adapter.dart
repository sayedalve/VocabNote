/// core/ai/lib/src/adapters/openai_adapter.dart
///
/// Adapter for every OpenAI-compatible `/chat/completions` provider
/// (Groq, Mistral, GitHub Models, OpenRouter, Hugging Face, Ollama, ...).
library;

import 'package:http/http.dart' as http;

import '../ai_client.dart';
import '../provider_config.dart';

final class OpenAiAdapter extends HttpAiAdapter {
  OpenAiAdapter({required ProviderConfig config, required http.Client httpClient})
      : super(config: config, httpClient: httpClient);

  String get _base => config.baseUrl.endsWith('/')
      ? config.baseUrl.substring(0, config.baseUrl.length - 1)
      : config.baseUrl;

  @override
  Uri endpoint() => Uri.parse('$_base/chat/completions');

  @override
  Map<String, String> headers(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
      };

  @override
  Map<String, Object?> body(AiRequest request) => {
        'model': config.model,
        'temperature': request.temperature,
        'messages': [
          if (request.system case final system?)
            {'role': 'system', 'content': system},
          {'role': 'user', 'content': request.prompt},
        ],
      };

  @override
  String? extractText(Map<String, Object?> json) {
    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    // Some providers return a string; others return a list of content parts.
    return switch (content) {
      final String text => text,
      final List<dynamic> parts => parts
          .whereType<Map<dynamic, dynamic>>()
          .map((part) => part['text'])
          .whereType<String>()
          .join(),
      _ => null,
    };
  }
}
