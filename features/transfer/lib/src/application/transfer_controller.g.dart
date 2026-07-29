// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Snapshots in the backups directory, newest first.

@ProviderFor(backupsList)
final backupsListProvider = BackupsListProvider._();

/// Snapshots in the backups directory, newest first.

final class BackupsListProvider extends $FunctionalProvider<
        AsyncValue<List<BackupInfo>>,
        List<BackupInfo>,
        FutureOr<List<BackupInfo>>>
    with $FutureModifier<List<BackupInfo>>, $FutureProvider<List<BackupInfo>> {
  /// Snapshots in the backups directory, newest first.
  BackupsListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'backupsListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$backupsListHash();

  @$internal
  @override
  $FutureProviderElement<List<BackupInfo>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<BackupInfo>> create(Ref ref) {
    return backupsList(ref);
  }
}

String _$backupsListHash() => r'6813932641b77c52a583163e381ce265108675bd';

@ProviderFor(TransferController)
final transferControllerProvider = TransferControllerProvider._();

final class TransferControllerProvider
    extends $NotifierProvider<TransferController, TransferState> {
  TransferControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'transferControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$transferControllerHash();

  @$internal
  @override
  TransferController create() => TransferController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransferState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransferState>(value),
    );
  }
}

String _$transferControllerHash() =>
    r'e417f0af9188e50da1af3b79cddc31cdebf05909';

abstract class _$TransferController extends $Notifier<TransferState> {
  TransferState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransferState, TransferState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<TransferState, TransferState>,
        TransferState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
