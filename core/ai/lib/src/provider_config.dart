/// core/ai/lib/src/provider_config.dart
///
/// Provider identity + presets, ported from the legacy `api/providers.py`.
/// Only two transport shapes exist: Gemini `generateContent` and the
/// OpenAI-compatible `/chat/completions` contract \u2014 every preset maps to one
/// of them. The \u201cCustom\u201d preset lets users point the app at any
/// self-hosted or OpenAI-compatible endpoint; base URL, model, and API key
/// are all user-overridable per provider in Settings.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'provider_config.freezed.dart';

/// Transport shape, not vendor. New vendors that speak an existing shape are
/// preset-only additions.
enum ProviderKind { openAiCompatible, gemini }

@freezed
abstract class ProviderConfig with _$ProviderConfig {
  const factory ProviderConfig({
    /// Stable identifier used as the secure-storage key suffix.
    required String id,

    /// Human-readable label shown in Settings.
    required String label,
    required ProviderKind kind,
    required String baseUrl,
    required String model,
  }) = _ProviderConfig;
}

/// Security contract ported from the legacy `is_base_url_allowed`:
/// HTTPS everywhere; plain HTTP only for loopback (Ollama, llama.cpp, LM
/// Studio and other local runtimes).
bool isBaseUrlAllowed(String baseUrl) {
  final uri = Uri.tryParse(baseUrl.trim());
  if (uri == null || uri.host.isEmpty) {
    return false;
  }
  return switch (uri.scheme) {
    'https' => true,
    'http' => const {'localhost', '127.0.0.1', '::1', '[::1]'}
        .contains(uri.host),
    _ => false,
  };
}

const String kDefaultProviderId = 'google_ai_studio';

/// Built-in presets. Base URL and model are user-overridable per provider in
/// Settings; the id is the stable join key for stored overrides and API keys.
const List<ProviderConfig> kProviderPresets = <ProviderConfig>[
  ProviderConfig(
    id: 'google_ai_studio',
    label: 'Google AI Studio',
    kind: ProviderKind.gemini,
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    // Product default. The Settings screen's hint/helper text must always
    // match this value (it previously drifted to a different model name).
    model: 'gemini-3.1-flash-lite',
  ),
  ProviderConfig(
    id: 'groq',
    label: 'Groq',
    kind: ProviderKind.openAiCompatible,
    baseUrl: 'https://api.groq.com/openai/v1',
    model: 'llama-3.3-70b-versatile',
  ),
  ProviderConfig(
    id: 'mistral',
    label: 'Mistral',
    kind: ProviderKind.openAiCompatible,
    baseUrl: 'https://api.mistral.ai/v1',
    model: 'mistral-small-latest',
  ),
  ProviderConfig(
    id: 'github_models',
    label: 'GitHub Models',
    kind: ProviderKind.openAiCompatible,
    baseUrl: 'https://models.inference.ai.azure.com',
    model: 'gpt-4o-mini',
  ),
  ProviderConfig(
    id: 'openrouter',
    label: 'OpenRouter',
    kind: ProviderKind.openAiCompatible,
    baseUrl: 'https://openrouter.ai/api/v1',
    model: 'meta-llama/llama-3.3-70b-instruct',
  ),
  ProviderConfig(
    id: 'huggingface',
    label: 'Hugging Face',
    kind: ProviderKind.openAiCompatible,
    baseUrl: 'https://router.huggingface.co/v1',
    model: 'meta-llama/Llama-3.3-70B-Instruct',
  ),
  ProviderConfig(
    id: 'local_openai',
    label: 'Local (Ollama / llama.cpp)',
    kind: ProviderKind.openAiCompatible,
    baseUrl: 'http://localhost:11434/v1',
    model: 'llama3.2',
  ),
  ProviderConfig(
    id: 'custom_openai',
    label: 'Custom (OpenAI-compatible / self-hosted)',
    kind: ProviderKind.openAiCompatible,
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-4o-mini',
  ),
];

ProviderConfig presetById(String id) => kProviderPresets.firstWhere(
      (p) => p.id == id,
      orElse: () => kProviderPresets.first,
    );
