/// core/ai/lib/src/providers.dart
///
/// Riverpod wiring for the AI core. `aiClient` is a family keyed by
/// [ProviderConfig]; swapping providers is a config change, not a code change.
library;

import 'package:core_storage/core_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'adapters/gemini_adapter.dart';
import 'adapters/openai_adapter.dart';
import 'ai_client.dart';
import 'provider_config.dart';
import 'provider_settings.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
http.Client aiHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
ProviderSettingsRepository providerSettingsRepository(Ref ref) =>
    ProviderSettingsRepository(ref.watch(secureStorageServiceProvider));

@riverpod
AiClient aiClient(Ref ref, ProviderConfig config) {
  final httpClient = ref.watch(aiHttpClientProvider);
  return switch (config.kind) {
    ProviderKind.gemini =>
      GeminiAdapter(config: config, httpClient: httpClient),
    ProviderKind.openAiCompatible =>
      OpenAiAdapter(config: config, httpClient: httpClient),
  };
}
