/// VocabNote AI core.
///
/// Provider-agnostic LLM transport with strict output sanitization.
/// Adding a provider means adding one adapter class + one preset entry —
/// nothing outside this package changes.
library core_ai;

export 'package:core_storage/core_storage.dart'
    show DiagnosableStorage, StorageBackend, StorageException;

export 'src/adapters/gemini_adapter.dart';
export 'src/adapters/openai_adapter.dart';
export 'src/ai_client.dart';
export 'src/provider_config.dart';
export 'src/provider_settings.dart';
export 'src/providers.dart';
export 'src/sanitizer.dart';
