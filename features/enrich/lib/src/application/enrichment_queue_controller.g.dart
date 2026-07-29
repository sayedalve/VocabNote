// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrichment_queue_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EnrichmentQueueController)
final enrichmentQueueControllerProvider = EnrichmentQueueControllerProvider._();

final class EnrichmentQueueControllerProvider
    extends $NotifierProvider<EnrichmentQueueController, EnrichmentQueueState> {
  EnrichmentQueueControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'enrichmentQueueControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$enrichmentQueueControllerHash();

  @$internal
  @override
  EnrichmentQueueController create() => EnrichmentQueueController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EnrichmentQueueState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EnrichmentQueueState>(value),
    );
  }
}

String _$enrichmentQueueControllerHash() =>
    r'45a2a1d132333a57e2af3f1e26dd6bd5c8975b7c';

abstract class _$EnrichmentQueueController
    extends $Notifier<EnrichmentQueueState> {
  EnrichmentQueueState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EnrichmentQueueState, EnrichmentQueueState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<EnrichmentQueueState, EnrichmentQueueState>,
        EnrichmentQueueState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
