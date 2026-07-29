/// core/db/lib/src/daos/enrichment_dao.dart
///
/// Data-level operations for the offline enrichment queue. `capture` is the
/// optimistic-save primitive: the word row and its queue row are committed in
/// one transaction, so the word is safely on disk before any network I/O.
library;

import 'package:drift/drift.dart';

import 'package:core_db/src/database.dart';
import 'package:core_db/src/tables.dart';
import 'package:core_db/src/text_normalization.dart';

part 'enrichment_dao.g.dart';

/// Outcome of capturing a raw headword.
sealed class CaptureOutcome {
  const CaptureOutcome();
}

final class Captured extends CaptureOutcome {
  const Captured({required this.word, required this.pendingId});

  final WordRow word;
  final int pendingId;
}

final class DuplicateHeadword extends CaptureOutcome {
  const DuplicateHeadword({required this.existing});

  final WordRow existing;
}

final class InvalidCapture extends CaptureOutcome {
  const InvalidCapture(this.reason);

  final String reason;
}

/// The sanitized field set an enrichment run produces. Translations are
/// keyed by BCP-47 code (the AI pipeline currently emits `bn`).
typedef EnrichmentPatch = ({
  String meaning,
  String ipa,
  String partOfSpeech,
  String exampleSentence,
  String synonyms,
  String antonyms,
  Map<String, String> translations,
});

/// A queue row joined with the word it belongs to.
typedef PendingWork = ({PendingEnrichmentRow pending, WordRow word});

@DriftAccessor(tables: [Words, WordTranslations, Notebooks, PendingEnrichments])
class EnrichmentDao extends DatabaseAccessor<AppDatabase>
    with _$EnrichmentDaoMixin {
  EnrichmentDao(super.attachedDatabase);

  /// Validates, inserts the bare word, and enqueues it for enrichment —
  /// atomically. Returns a sealed outcome instead of throwing on user error.
  Future<CaptureOutcome> capture({
    required String rawHeadword,
    int? notebookId,
  }) async {
    final normalized = normalizeHeadword(rawHeadword);
    switch (normalized) {
      case InvalidHeadword(:final reason):
        return InvalidCapture(reason);
      case ValidHeadword(:final norm, :final display):
        return transaction(() async {
          final targetNotebookId = notebookId ??
              (await db.notebookDao.ensureDefaultNotebook()).id;

          final existing = await db.wordDao.byNormalizedHeadword(
            notebookId: targetNotebookId,
            norm: norm,
          );
          if (existing != null) {
            return DuplicateHeadword(existing: existing);
          }

          final word = await into(words).insertReturning(
            WordsCompanion.insert(
              notebookId: targetNotebookId,
              headwordNorm: norm,
              headwordDisplay: display,
            ),
          );
          final pendingId = await into(pendingEnrichments).insert(
            PendingEnrichmentsCompanion.insert(wordId: word.id),
          );
          return Captured(word: word, pendingId: pendingId);
        });
    }
  }

  /// Re-enqueues an existing word (manual "regenerate card").
  Future<void> enqueueExisting(int wordId) => into(pendingEnrichments).insert(
        PendingEnrichmentsCompanion.insert(wordId: wordId),
        mode: InsertMode.insertOrIgnore,
      );

  Stream<int> watchPendingCount() {
    final count = pendingEnrichments.id.count();
    final query = selectOnly(pendingEnrichments)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  /// Rows whose backoff window has elapsed, oldest first.
  Future<List<PendingWork>> dueBatch({
    required DateTime now,
    int limit = 5,
  }) async {
    final query = (select(pendingEnrichments)
          ..where((q) => q.nextAttemptAt.isSmallerOrEqualValue(now))
          ..orderBy([(q) => OrderingTerm.asc(q.id)])
          ..limit(limit))
        .join([
      innerJoin(words, words.id.equalsExp(pendingEnrichments.wordId)),
    ]);

    final rows = await query.get();
    return [
      for (final row in rows)
        (
          pending: row.readTable(pendingEnrichments),
          word: row.readTable(words),
        ),
    ];
  }

  /// Records a failed attempt and pushes the next attempt out with quadratic
  /// backoff (30s, 2m, 4m30s, ... capped at 15 minutes).
  Future<void> recordFailure({
    required int pendingId,
    required int previousAttempts,
    required String error,
  }) async {
    final attempts = previousAttempts + 1;
    final delaySeconds = (30 * attempts * attempts).clamp(30, 900);
    await (update(pendingEnrichments)..where((q) => q.id.equals(pendingId)))
        .write(
      PendingEnrichmentsCompanion(
        attempts: Value(attempts),
        lastError: Value(error),
        nextAttemptAt: Value(
          DateTime.now().toUtc().add(Duration(seconds: delaySeconds)),
        ),
      ),
    );
  }

  /// Applies a successful enrichment and clears the queue row atomically.
  Future<void> complete({
    required int wordId,
    required EnrichmentPatch patch,
  }) {
    return transaction(() async {
      await db.wordDao.updateWordFields(
        wordId,
        WordsCompanion(
          meaning: Value(patch.meaning),
          ipa: Value(patch.ipa),
          partOfSpeech: Value(patch.partOfSpeech),
          exampleSentence: Value(patch.exampleSentence),
          synonyms: Value(patch.synonyms),
          antonyms: Value(patch.antonyms),
        ),
      );
      for (final MapEntry(key: lang, value: translation)
          in patch.translations.entries) {
        if (translation.isEmpty) continue;
        await db.wordDao.upsertTranslation(
          wordId: wordId,
          langCode: lang,
          translation: translation,
        );
      }
      await (delete(pendingEnrichments)
            ..where((q) => q.wordId.equals(wordId)))
          .go();
    });
  }
}
