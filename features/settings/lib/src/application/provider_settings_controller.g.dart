// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProviderSettingsController)
final providerSettingsControllerProvider =
    ProviderSettingsControllerProvider._();

final class ProviderSettingsControllerProvider extends $AsyncNotifierProvider<
    ProviderSettingsController, ProviderSettingsState> {
  ProviderSettingsControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'providerSettingsControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$providerSettingsControllerHash();

  @$internal
  @override
  ProviderSettingsController create() => ProviderSettingsController();
}

String _$providerSettingsControllerHash() =>
    r'5309c49e8db0907f5fced2d6d3a9f0b78eb9c8a5';

abstract class _$ProviderSettingsController
    extends $AsyncNotifier<ProviderSettingsState> {
  FutureOr<ProviderSettingsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<ProviderSettingsState>, ProviderSettingsState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<ProviderSettingsState>, ProviderSettingsState>,
        AsyncValue<ProviderSettingsState>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
