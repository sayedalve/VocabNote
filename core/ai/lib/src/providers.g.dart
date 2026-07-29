// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiHttpClient)
final aiHttpClientProvider = AiHttpClientProvider._();

final class AiHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  AiHttpClientProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'aiHttpClientProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$aiHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return aiHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$aiHttpClientHash() => r'e560ebb39aaa950630d6f3d487852e636c1c7e93';

@ProviderFor(providerSettingsRepository)
final providerSettingsRepositoryProvider =
    ProviderSettingsRepositoryProvider._();

final class ProviderSettingsRepositoryProvider extends $FunctionalProvider<
    ProviderSettingsRepository,
    ProviderSettingsRepository,
    ProviderSettingsRepository> with $Provider<ProviderSettingsRepository> {
  ProviderSettingsRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'providerSettingsRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$providerSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProviderSettingsRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProviderSettingsRepository create(Ref ref) {
    return providerSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProviderSettingsRepository>(value),
    );
  }
}

String _$providerSettingsRepositoryHash() =>
    r'e56ccc4cad6c38c385950cc4367f001b16a9a0c8';

@ProviderFor(aiClient)
final aiClientProvider = AiClientFamily._();

final class AiClientProvider
    extends $FunctionalProvider<AiClient, AiClient, AiClient>
    with $Provider<AiClient> {
  AiClientProvider._(
      {required AiClientFamily super.from,
      required ProviderConfig super.argument})
      : super(
          retry: null,
          name: r'aiClientProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$aiClientHash();

  @override
  String toString() {
    return r'aiClientProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AiClient create(Ref ref) {
    final argument = this.argument as ProviderConfig;
    return aiClient(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiClient>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AiClientProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$aiClientHash() => r'b81984c862a1cd11634ebfc67e2be392ef4d38eb';

final class AiClientFamily extends $Family
    with $FunctionalFamilyOverride<AiClient, ProviderConfig> {
  AiClientFamily._()
      : super(
          retry: null,
          name: r'aiClientProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  AiClientProvider call(
    ProviderConfig config,
  ) =>
      AiClientProvider._(argument: config, from: this);

  @override
  String toString() => r'aiClientProvider';
}
