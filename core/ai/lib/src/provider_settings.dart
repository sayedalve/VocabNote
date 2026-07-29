/// core/ai/lib/src/provider_settings.dart
///
/// Persistence for AI provider selection, per-provider overrides, and API
/// keys. Resolution order ports the legacy `resolve_provider_config`:
/// saved per-provider overrides win, then the preset defaults.
/// All values live in the OS credential vault via [SecureStorageService].
library;

import 'package:core_storage/core_storage.dart';

import 'package:core_ai/src/provider_config.dart';

final class ProviderSettingsRepository {
  const ProviderSettingsRepository(this._storage);

  final SecureStorageService _storage;

  static const String _activeKey = 'ai.active_provider';

  static String _overrideKey(String providerId, String field) =>
      'ai.override.$providerId.$field';

  static String _apiKeyKey(String providerId) => 'ai.key.$providerId';

  Future<String> activeProviderId() async =>
      await _storage.read(_activeKey) ?? kDefaultProviderId;

  Future<void> setActiveProviderId(String providerId) =>
      _storage.write(_activeKey, providerId);

  /// Preset merged with any saved overrides for [providerId]
  /// (or the active provider when omitted).
  Future<ProviderConfig> effectiveConfig([String? providerId]) async {
    final id = providerId ?? await activeProviderId();
    final preset = presetById(id);
    final baseUrl = await _storage.read(_overrideKey(id, 'base_url'));
    final model = await _storage.read(_overrideKey(id, 'model'));
    return preset.copyWith(
      baseUrl: _orDefault(baseUrl, preset.baseUrl),
      model: _orDefault(model, preset.model),
    );
  }

  /// Saves overrides; empty/whitespace values reset that field to the preset.
  Future<void> saveOverrides({
    required String providerId,
    required String baseUrl,
    required String model,
  }) async {
    await _saveOrClear(_overrideKey(providerId, 'base_url'), baseUrl,
        presetById(providerId).baseUrl,);
    await _saveOrClear(
        _overrideKey(providerId, 'model'), model, presetById(providerId).model,);
  }

  Future<String?> apiKey(String providerId) =>
      _storage.read(_apiKeyKey(providerId));

  Future<bool> hasApiKey(String providerId) async {
    final key = await apiKey(providerId);
    return key != null && key.trim().isNotEmpty;
  }

  /// Last four characters of the stored key, for "a key is stored" UI.
  /// Never exposes enough of the key to be sensitive.
  Future<String?> apiKeyHint(String providerId) async {
    final key = (await apiKey(providerId))?.trim() ?? '';
    if (key.isEmpty) return null;
    return key.length <= 4 ? key : key.substring(key.length - 4);
  }

  /// Which storage backend is verifiably working right now, or null when
  /// the storage layer does not support diagnostics.
  Future<StorageBackend?> keyStorageHealth() async {
    final storage = _storage;
    if (storage is DiagnosableStorage) {
      return (storage as DiagnosableStorage).healthCheck();
    }
    return null;
  }

  Future<void> setApiKey(String providerId, String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _storage.delete(_apiKeyKey(providerId));
    } else {
      await _storage.write(_apiKeyKey(providerId), trimmed);
    }
  }

  Future<void> _saveOrClear(
    String storageKey,
    String value,
    String presetValue,
  ) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == presetValue) {
      await _storage.delete(storageKey);
    } else {
      await _storage.write(storageKey, trimmed);
    }
  }

  static String _orDefault(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
