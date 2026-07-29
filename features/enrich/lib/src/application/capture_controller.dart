/// features/enrich/lib/src/application/capture_controller.dart
library;

import 'dart:async';

import 'package:core_db/core_db.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'enrichment_queue_controller.dart';

part 'capture_controller.freezed.dart';
part 'capture_controller.g.dart';

/// Identifies which UI surface owns a capture flow. Each scope receives an
/// independent [CaptureController] instance with its own [CaptureState].
enum CaptureScope {
  /// The inline capture field in the notebook toolbar.
  toolbar,

  /// The global quick-add dialog (Ctrl+N).
  dialog,
}

/// UI state for the capture input.
@freezed
sealed class CaptureState with _$CaptureState {
  const factory CaptureState.idle() = CaptureIdle;

  const factory CaptureState.saving() = CaptureSaving;

  /// Word committed locally; [wordId] lets the UI select/scroll to it.
  const factory CaptureState.saved({
    required int wordId,
    required String headword,
  }) = CaptureSaved;

  const factory CaptureState.rejected({required String reason}) = CaptureRejected;
}

/// Controller for one capture surface (see [CaptureScope]).
@riverpod
class CaptureController extends _$CaptureController {
  @override
  CaptureState build(CaptureScope scope) => const CaptureState.idle();

  /// Captures a raw headword into [notebookId] (or the default notebook).
  /// Returns the new word id on success, null otherwise.
  Future<int?> capture(String rawHeadword, {int? notebookId}) async {
    if (state is CaptureSaving) return null;
    state = const CaptureState.saving();

    final dao = ref.read(appDatabaseProvider).enrichmentDao;
    final outcome = await dao.capture(
      rawHeadword: rawHeadword,
      notebookId: notebookId,
    );

    switch (outcome) {
      case InvalidCapture(:final reason):
        state = CaptureState.rejected(reason: reason);
        return null;
      case DuplicateHeadword(:final existing):
        state = CaptureState.rejected(
          reason: '"${existing.headwordDisplay}" is already in this notebook.',
        );
        return existing.id;
      case Captured(:final word):
        state = CaptureState.saved(
          wordId: word.id,
          headword: word.headwordDisplay,
        );
        // Fire-and-forget: the queue worker picks the row up immediately.
        unawaited(
          ref.read(enrichmentQueueControllerProvider.notifier).processQueue(),
        );
        return word.id;
    }
  }

  /// Clears any transient rejection/saved state back to idle.
  void reset() => state = const CaptureState.idle();
}