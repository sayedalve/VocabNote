/// features/settings/lib/src/presentation/settings_screen.dart
///
/// AI provider settings. Desktop-first layout (centered 640px column),
/// explicit success/error feedback for every operation, and a storage
/// self-test indicator so "is my key actually saved?" is never a mystery.
///
/// Users can pick a built-in provider or the \u201cCustom\u201d preset for any
/// self-hosted / OpenAI-compatible endpoint; base URL, model, and API key
/// are all editable per provider.
///
/// The body stays mounted while the controller refreshes (`valueOrNull`
/// keeps the previous data during a reload). The old pattern-match swapped
/// the form for a spinner mid-save, disposing the form state and silently
/// aborting the API-key write \u2014 the root cause of "No API key is
/// configured" after pressing Save.
library;

import 'package:core_ai/core_ai.dart';
import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/provider_settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(providerSettingsControllerProvider);
    // valueOrNull keeps previous data during refreshes, so the form is never
    // torn down while a save is in flight.
    final state = settingsAsync.value;
    if (state != null) {
      return _SettingsBody(state: state);
    }
    if (settingsAsync case AsyncError(:final error)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load settings: $error'),
            const SizedBox(height: VnSpacing.x3),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(providerSettingsControllerProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody({required this.state});

  final ProviderSettingsState state;

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  late final TextEditingController _baseUrlController =
      TextEditingController(text: widget.state.config.baseUrl);
  late final TextEditingController _modelController =
      TextEditingController(text: widget.state.config.model);
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _saving = false;
  bool _testing = false;

  @override
  void didUpdateWidget(covariant _SettingsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.config.id != widget.state.config.id) {
      _baseUrlController.text = widget.state.config.baseUrl;
      _modelController.text = widget.state.config.model;
      _apiKeyController.clear();
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  ProviderSettingsController get _controller =>
      ref.read(providerSettingsControllerProvider.notifier);

  void _showSnack(String message, {bool isError = false}) => showVnSnackBar(
        context,
        message,
        isError: isError,
        // Errors linger longer so they can be read and acted upon.
        duration: Duration(seconds: isError ? 6 : 3),
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _controller.saveAll(
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
      apiKey: _apiKeyController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case SaveOk(:final hasApiKey):
        _apiKeyController.clear();
        _showSnack(
          hasApiKey
              ? 'Settings saved \u2014 API key stored and verified.'
              : 'Settings saved.',
        );
      case SaveFailed(:final message):
        _showSnack(message, isError: true);
    }
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final result = await _controller.testConnection(
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
    );
    if (!mounted) return;
    setState(() => _testing = false);
    switch (result) {
      case ConnectionOk(:final detail):
        _showSnack(detail);
      case ConnectionFailed(:final message):
        _showSnack(message, isError: true);
    }
  }

  Future<void> _removeKey() async {
    final result = await _controller.removeApiKey();
    if (!mounted) return;
    switch (result) {
      case SaveOk():
        _showSnack('API key removed.');
      case SaveFailed(:final message):
        _showSnack(message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(VnSpacing.x5),
          children: [
            Text('AI provider', style: textTheme.titleLarge),
            const SizedBox(height: VnSpacing.x2),
            Text(
              'VocabNote works fully offline. An AI provider is only used to '
              'fill in word cards, and your key never leaves this device. '
              'Pick a built-in provider, or choose \u201cCustom\u201d to use '
              'your own self-hosted or OpenAI-compatible API.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: VnSpacing.x5),
            VnSelect<String>(
              label: 'Provider',
              value: state.config.id,
              options: [
                for (final preset in kProviderPresets)
                  VnSelectOption(value: preset.id, label: preset.label),
              ],
              onSelected: (id) => _controller.selectProvider(id),
            ),
            const SizedBox(height: VnSpacing.x4),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                helperText: 'Any OpenAI-compatible endpoint works. HTTPS '
                    'required (plain HTTP allowed for localhost).',
              ),
            ),
            const SizedBox(height: VnSpacing.x4),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'gemini-3.1-flash-lite',
                helperText: 'Default: gemini-3.1-flash-lite',
              ),
            ),
            const SizedBox(height: VnSpacing.x4),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'API key',
                helperText: state.hasApiKey
                    ? 'Enter a new key to replace the stored one.'
                    : 'Paste your key, then press Save.',
                suffixIcon: IconButton(
                  tooltip: _obscureKey ? 'Show key' : 'Hide key',
                  icon: Icon(
                    _obscureKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
            const SizedBox(height: VnSpacing.x3),
            _KeyStatusRow(state: state, onRemove: _removeKey),
            if (state.storageBackend != StorageBackend.osVault) ...[
              const SizedBox(height: VnSpacing.x3),
              _StorageNotice(backend: state.storageBackend),
            ],
            const SizedBox(height: VnSpacing.x6),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
                const SizedBox(width: VnSpacing.x3),
                OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check, size: 18),
                  label: Text(_testing ? 'Testing...' : 'Test connection'),
                ),
              ],
            ),
            const SizedBox(height: VnSpacing.x3),
            Text(
              'Test connection uses the values above as typed \u2014 you can '
              'verify a key before saving it.',
              style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// "A key ending in \u00b7\u00b7\u00b7\u00b7abcd is stored" + Remove, or "No key stored yet".
class _KeyStatusRow extends StatelessWidget {
  const _KeyStatusRow({required this.state, required this.onRemove});

  final ProviderSettingsState state;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;

    if (!state.hasApiKey) {
      return Row(
        children: [
          Icon(Icons.key_off, size: 16, color: tokens.textMuted),
          const SizedBox(width: VnSpacing.x2),
          Text(
            'No API key stored for ${state.config.label} yet.',
            style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
          ),
        ],
      );
    }
    final hint = state.apiKeyHint;
    return Row(
      children: [
        Icon(Icons.check_circle, size: 16, color: tokens.success),
        const SizedBox(width: VnSpacing.x2),
        Expanded(
          child: Text(
            hint == null
                ? 'API key stored and verified.'
                : 'API key stored and verified (ending in \u00b7\u00b7\u00b7\u00b7$hint).',
            style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
          ),
        ),
        TextButton(onPressed: onRemove, child: const Text('Remove key')),
      ],
    );
  }
}

/// Shown when the OS credential vault is not the active backend.
class _StorageNotice extends StatelessWidget {
  const _StorageNotice({required this.backend});

  final StorageBackend? backend;

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    final (icon, message) = switch (backend) {
      StorageBackend.localFile => (
          Icons.info_outline,
          'The Windows credential vault is unavailable on this machine, so '
          'keys are kept in an obfuscated file inside the app data folder.',
        ),
      _ => (
          Icons.warning_amber_rounded,
          'Key storage failed its self-test \u2014 saved keys may not persist. '
          'Try restarting the app; if this persists, check that the app can '
          'write to its data folder.',
        ),
    };
    return Container(
      padding: const EdgeInsets.all(VnSpacing.x3),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(VnRadius.md),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tokens.textSecondary),
          const SizedBox(width: VnSpacing.x2),
          Expanded(
            child: Text(
              message,
              style:
                  textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
