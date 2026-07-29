/// features/settings/lib/src/application/provider_settings_controller.dart
///
/// State + actions for the AI provider settings screen.
///
/// Reliability contract:
///  * A save is a **single atomic operation** ([saveAll]) — the UI never has
///    to sequence multiple awaits across rebuilds (the old design was torn
///    down mid-save when the provider refreshed, silently dropping the key).
///  * Every key write is verified with a read-back before the UI is allowed
///    to report success.
///  * Storage failures surface as [SaveFailed] with a human-readable reason —
///    never a silent no-op.
///  * [testConnection] exercises exactly what is on screen: a typed key,
///    base URL, or model takes precedence over stored values, so "Test" can
///    never claim a key is missing while one is sitting in the field.
library;

import 'package:core_ai/core_ai.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'provider_settings_controller.freezed.dart';
part 'provider_settings_controller.g.dart';

@freezed
abstract class ProviderSettingsState with _$ProviderSettingsState {
  const factory ProviderSettingsState({
    /// The provider currently being edited (== active provider).
    required ProviderConfig config,

    /// Whether an API key is verifiably stored for this provider.
    required bool hasApiKey,

    /// Last four characters of the stored key, for "a key is stored" UI.
    String? apiKeyHint,

    /// Which storage backend passed the round-trip self-test, or null when
    /// no backend is currently working.
    StorageBackend? storageBackend,
  }) = _ProviderSettingsState;
}

/// Result of a save, surfaced to the UI. Never throw past this boundary.
sealed class SettingsSaveResult {
  const SettingsSaveResult();
}

final class SaveOk extends SettingsSaveResult {
  const SaveOk({required this.hasApiKey});

  /// Whether an API key is stored (and read-back verified) after this save.
  final bool hasApiKey;
}

final class SaveFailed extends SettingsSaveResult {
  const SaveFailed(this.message);

  final String message;
}

/// Result of a connection test, surfaced to the UI as a snackbar.
sealed class ConnectionTestResult {
  const ConnectionTestResult();
}

final class ConnectionOk extends ConnectionTestResult {
  const ConnectionOk(this.detail);

  final String detail;
}

final class ConnectionFailed extends ConnectionTestResult {
  const ConnectionFailed(this.message);

  final String message;
}

@riverpod
class ProviderSettingsController extends _$ProviderSettingsController {
  ProviderSettingsRepository get _settings =>
      ref.read(providerSettingsRepositoryProvider);

  @override
  Future<ProviderSettingsState> build() async {
    final config = await _settings.effectiveConfig();
    final (hasKey, hint, backend) = await (
      _settings.hasApiKey(config.id),
      _settings.apiKeyHint(config.id),
      _settings.keyStorageHealth(),
    ).wait;
    return ProviderSettingsState(
      config: config,
      hasApiKey: hasKey,
      apiKeyHint: hint,
      storageBackend: backend,
    );
  }

  Future<void> selectProvider(String providerId) async {
    await _settings.setActiveProviderId(providerId);
    ref.invalidateSelf();
  }

  /// Atomically saves overrides and (when non-empty) the API key, verifying
  /// the key with a read-back before reporting success.
  Future<SettingsSaveResult> saveAll({
    required String baseUrl,
    required String model,
    required String apiKey,
  }) async {
    final current = state.value ?? await future;
    final providerId = current.config.id;

    final trimmedBaseUrl = baseUrl.trim();
    if (trimmedBaseUrl.isNotEmpty && !isBaseUrlAllowed(trimmedBaseUrl)) {
      return const SaveFailed(
        'The base URL must use HTTPS (plain HTTP is allowed only for '
        'localhost). Nothing was saved.',
      );
    }

    try {
      await _settings.saveOverrides(
        providerId: providerId,
        baseUrl: baseUrl,
        model: model,
      );
      final trimmedKey = apiKey.trim();
      if (trimmedKey.isNotEmpty) {
        await _settings.setApiKey(providerId, trimmedKey);
      }
      final hasKey = await _settings.hasApiKey(providerId);
      if (trimmedKey.isNotEmpty && !hasKey) {
        ref.invalidateSelf();
        return const SaveFailed(
          'The API key could not be verified after saving. Check the '
          'storage status shown below and try again.',
        );
      }
      ref.invalidateSelf();
      return SaveOk(hasApiKey: hasKey);
    } on StorageException catch (error) {
      ref.invalidateSelf();
      return SaveFailed(error.message);
    } on Object catch (error) {
      ref.invalidateSelf();
      return SaveFailed('Could not save settings: $error');
    }
  }

  /// Removes the stored API key, verifying the removal.
  Future<SettingsSaveResult> removeApiKey() async {
    final current = state.value ?? await future;
    try {
      await _settings.setApiKey(current.config.id, '');
      final hasKey = await _settings.hasApiKey(current.config.id);
      ref.invalidateSelf();
      return hasKey
          ? const SaveFailed('The API key could not be removed from storage.')
          : const SaveOk(hasApiKey: false);
    } on StorageException catch (error) {
      ref.invalidateSelf();
      return SaveFailed(error.message);
    }
  }

  /// Round-trips a tiny prompt through the provider. Values typed on screen
  /// (key, base URL, model) take precedence over stored ones so the test
  /// always reflects what the user is looking at.
  Future<ConnectionTestResult> testConnection({
    String? apiKey,
    String? baseUrl,
    String? model,
  }) async {
    final current = state.value ?? await future;
    var config = current.config;

    final typedBaseUrl = baseUrl?.trim() ?? '';
    final typedModel = model?.trim() ?? '';
    if (typedBaseUrl.isNotEmpty) config = config.copyWith(baseUrl: typedBaseUrl);
    if (typedModel.isNotEmpty) config = config.copyWith(model: typedModel);

    final typedKey = apiKey?.trim() ?? '';
    final effectiveKey =
        typedKey.isNotEmpty ? typedKey : (await _settings.apiKey(config.id))?.trim() ?? '';
    if (effectiveKey.isEmpty) {
      return const ConnectionFailed(
        'Enter an API key above (or save one first), then test again.',
      );
    }

    final client = ref.read(aiClientProvider(config));
    final result = await client.complete(
      const AiRequest(
        prompt: 'Reply with the single word: OK',
        temperature: 0,
        timeout: Duration(seconds: 10),
      ),
      apiKey: effectiveKey,
    );
    return switch (result) {
      AiOk() => ConnectionOk(
          '${config.label} responded — model “${config.model}” is ready.',
        ),
      AiErr(:final failure) => ConnectionFailed(failure.message),
    };
  }
}
