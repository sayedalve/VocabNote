/// core/db/lib/src/daos/tag_dao.dart
///
/// Relational tags (Phase 4). Tags are workspace-global, case-insensitive
/// labels attached to words through the WordTags join table. Removing the
/// last link to a tag garbage-collects the tag row itself.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'tag_dao.g.dart';

/// A tag plus how many words currently use it.
typedef TagWithCount = ({TagRow tag, int wordCount});

@DriftAccessor(tables: [Tags, WordTags, Words])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.attachedDatabase);

  /// Hard cap on tag label length (the UI enforces it too).
  static const int maxTagLength = 40;

  /// Canonical form stored and compared: trimmed, single-spaced.
  static String normalizeTagName(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Live list of tags attached to [wordId], sorted by name.
  Stream<List<TagRow>> watchTagsForWord(int wordId) {
    final query = select(tags).join([
      innerJoin(wordTags, wordTags.tagId.equalsExp(tags.id)),
    ])
      ..where(wordTags.wordId.equals(wordId))
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.watch().map(
          (rows) => [for (final row in rows) row.readTable(tags)],
        );
  }

  /// Every tag in the workspace with usage counts, most used first.
  Future<List<TagWithCount>> allTagsWithCounts() async {
    final countExp = wordTags.wordId.count();
    final query = select(tags).join([
      leftOuterJoin(wordTags, wordTags.tagId.equalsExp(tags.id)),
    ])
      ..addColumns([countExp])
      ..groupBy([tags.id])
      ..orderBy([OrderingTerm.desc(countExp), OrderingTerm.asc(tags.name)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (tag: row.readTable(tags), wordCount: row.read(countExp) ?? 0),
    ];
  }

  /// Attaches a tag (creating it if needed) to a word and returns the tag
  /// row. Matching is case-insensitive (tags.name is COLLATE NOCASE UNIQUE).
  Future<TagRow> addTagToWord({
    required int wordId,
    required String name,
  }) async {
    final normalized = normalizeTagName(name);
    if (normalized.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Tag name must not be blank');
    }
    if (normalized.length > maxTagLength) {
      throw ArgumentError.value(
        name,
        'name',
        'Tag name must be at most $maxTagLength characters',
      );
    }

    return transaction(() async {
      final existing = await (select(tags)
            ..where(
              (t) => t.name.collate(Collate.noCase).equals(normalized),
            ))
          .getSingleOrNull();
      final tag = existing ??
          await into(tags).insertReturning(
            TagsCompanion.insert(name: normalized),
          );
      await into(wordTags).insert(
        WordTagsCompanion.insert(wordId: wordId, tagId: tag.id),
        mode: InsertMode.insertOrIgnore,
      );
      return tag;
    });
  }

  /// Detaches [tagId] from [wordId]; deletes the tag itself when no other
  /// word still uses it (orphan garbage collection).
  Future<void> removeTagFromWord({
    required int wordId,
    required int tagId,
  }) async {
    await transaction(() async {
      await (delete(wordTags)
            ..where((t) => t.wordId.equals(wordId) & t.tagId.equals(tagId)))
          .go();
      final stillUsed = await (select(wordTags)
            ..where((t) => t.tagId.equals(tagId))
            ..limit(1))
          .getSingleOrNull();
      if (stillUsed == null) {
        await (delete(tags)..where((t) => t.id.equals(tagId))).go();
      }
    });
  }
}
