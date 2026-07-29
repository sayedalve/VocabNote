// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller for one capture surface (see [CaptureScope]).

@ProviderFor(CaptureController)
final captureControllerProvider = CaptureControllerFamily._();

/// Controller for one capture surface (see [CaptureScope]).
final class CaptureControllerProvider
    extends $NotifierProvider<CaptureController, CaptureState> {
  /// Controller for one capture surface (see [CaptureScope]).
  CaptureControllerProvider._(
      {required CaptureControllerFamily super.from,
      required CaptureScope super.argument})
      : super(
          retry: null,
          name: r'captureControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$captureControllerHash();

  @override
  String toString() {
    return r'captureControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CaptureController create() => CaptureController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CaptureState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CaptureState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CaptureControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$captureControllerHash() => r'0bec51ed649d3f453e16e28d58f375cc51c7050d';

/// Controller for one capture surface (see [CaptureScope]).

final class CaptureControllerFamily extends $Family
    with
        $ClassFamilyOverride<CaptureController, CaptureState, CaptureState,
            CaptureState, CaptureScope> {
  CaptureControllerFamily._()
      : super(
          retry: null,
          name: r'captureControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Controller for one capture surface (see [CaptureScope]).

  CaptureControllerProvider call(
    CaptureScope scope,
  ) =>
      CaptureControllerProvider._(argument: scope, from: this);

  @override
  String toString() => r'captureControllerProvider';
}

/// Controller for one capture surface (see [CaptureScope]).

abstract class _$CaptureController extends $Notifier<CaptureState> {
  late final _$args = ref.$arg as CaptureScope;
  CaptureScope get scope => _$args;

  CaptureState build(
    CaptureScope scope,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CaptureState, CaptureState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CaptureState, CaptureState>,
        CaptureState,
        Object?,
        Object?>;
    return element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
