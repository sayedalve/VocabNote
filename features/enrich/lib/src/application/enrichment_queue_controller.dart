/// features/enrich/lib/src/application/enrichment_queue_controller.dart
///
/// The offline enrichment worker. Words are committed to SQLite first
/// (optimistic save); this controller drains `pending_enrichments` whenever
/// rows are due, applying quadratic backoff on failure. No connectivity
/// plugin: a failed attempt *is* the offline signal, and the retry timer
/// brings the queue back when the network returns.
library;

import 'dart:async';

import 'package:core_ai/core_ai.dart';
import 'package:core_db/core_db.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/enrichment_prompt.dart';

part 'enrichment_queue_controller.freezed.dart';
part 'enrichment_queue_controller.g.dart';

@freezed
abstract class EnrichmentQueueState with _$EnrichmentQueueState {
  const factory EnrichmentQueueState({
    @Default(0) int pendingCount,
    @Default(false) bool isProcessing,

    /// Human-readable reason the queue is stalled (offline, missing key...),
    /// or null when everything is flowing.
    String? stallReason,
  }) = _EnrichmentQueueState;

  const EnrichmentQueueState._();

  bool get isIdle => pendingCount == 0 && !isProcessing;
}

@Riverpod(keepAlive: true)
class EnrichmentQueueController extends _$EnrichmentQueueController {
  static const Duration _retryInterval = Duration(seconds: 30);
  static const int _batchSize = 3;

  Timer? _retryTimer;
  bool _draining = false;

  @override
  EnrichmentQueueState build() {
    final dao = ref.watch(appDatabaseProvider).enrichmentDao;

    final subscription = dao.watchPendingCount().listen((count) {
      state = state.copyWith(pendingCount: count);
      if (count > 0) {
        _ensureRetryTimer();
        unawaited(processQueue());
      } else {
        _retryTimer?.cancel();
        _retryTimer = null;
      }
    });

    ref.onDispose(() {
      subscription.cancel();
      _retryTimer?.cancel();
    });

    return const EnrichmentQueueState();
  }

  void _ensureRetryTimer() {
    _retryTimer ??= Timer.periodic(_retryInterval, (_) {
      unawaited(processQueue());
    });
  }

  /// Manual retry hook (pull-to-refresh, "Retry now" button, app resume).
  Future<void> retryNow() => processQueue();

  /// Drains all currently-due queue rows. Serialized: concurrent calls are
  /// no-ops while a drain is in flight.
  Future<void> processQueue() async {
    if (_draining) return;
    _draining = true;
    state = state.copyWith(isProcessing: true);
    try {
      final settings = ref.read(providerSettingsRepositoryProvider);
      final config = await settings.effectiveConfig();
      final apiKey = await settings.apiKey(config.id);

      if (apiKey == null || apiKey.trim().isEmpty) {
        state = state.copyWith(
          isProcessing: false,
          stallReason:
              'Add an API key for ${config.label} in Settings to enable '
              'AI enrichment.',
        );
        return;
      }

      final dao = ref.read(appDatabaseProvider).enrichmentDao;
      final client = ref.read(aiClientProvider(config));

      // Non-network failures (bad model name, quota, malformed responses)
      // are recorded per row; surface the most recent one so persistent
      // problems are visible in the status chip instead of failing silently.
      AiFailure? lastFailure;

      while (true) {
        final batch = await dao.dueBatch(
          now: DateTime.now().toUtc(),
          limit: _batchSize,
        );
        if (batch.isEmpty) break;

        var networkDown = false;
        for (final (:pending, :word) in batch) {
          final outcome = await _enrichOne(client, dao, pending, word);
          if (outcome is NetworkFailure) {
            // Offline: stop hammering; the retry timer will try again.
            networkDown = true;
            break;
          }
          if (outcome != null) lastFailure = outcome;
        }
        if (networkDown) {
          state = state.copyWith(
            stallReason: 'Offline — words are saved and will be enriched '
                'automatically when you are back online.',
          );
          return;
        }
      }
      state = state.copyWith(
        stallReason: lastFailure == null
            ? null
            : 'Some words could not be enriched '
                '(${lastFailure.message}) — they will be retried '
                'automatically.',
      );
    } finally {
      _draining = false;
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Enriches a single word. Returns the failure (if any) so the drain loop
  /// can distinguish "offline" from "this row is bad".
  Future<AiFailure?> _enrichOne(
    AiClient client,
    EnrichmentDao dao,
    PendingEnrichmentRow pending,
    WordRow word,
  ) async {
    final settings = ref.read(providerSettingsRepositoryProvider);
    final apiKey = await settings.apiKey(client.config.id) ?? '';

    final completion = await client.complete(
      AiRequest(
        prompt: buildEnrichmentPrompt(word.headwordDisplay),
        system: kEnrichmentSystemPrompt,
      ),
      apiKey: apiKey,
    );

    switch (completion) {
      case AiErr(:final failure):
        await dao.recordFailure(
          pendingId: pending.id,
          previousAttempts: pending.attempts,
          error: failure.message,
        );
        return failure;
      case AiOk(:final value):
        switch (parseEnrichedCard(value)) {
          case AiErr(:final failure):
            await dao.recordFailure(
              pendingId: pending.id,
              previousAttempts: pending.attempts,
              error: failure.message,
            );
            return failure;
          case AiOk(value: final card):
            await dao.complete(
              wordId: word.id,
              patch: (
                meaning: card.meaning,
                ipa: card.ipa,
                partOfSpeech: card.partOfSpeech,
                exampleSentence: card.exampleSentence,
                synonyms: card.synonyms,
                antonyms: card.antonyms,
                translations: {
                  if (card.banglaMeaning.isNotEmpty) 'bn': card.banglaMeaning,
                },
              ),
            );
            return null;
        }
    }
  }
}
