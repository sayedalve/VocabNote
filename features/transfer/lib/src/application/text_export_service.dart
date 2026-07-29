/// features/transfer/lib/src/application/text_export_service.dart
///
/// Markdown and Anki-TSV exports, ported from the legacy
/// `utils/export_manager.py`:
///  * Markdown: an H2 per notebook, an H3 per word (★ for favorites), and
///    a bullet per non-empty field — important synonyms/antonyms are bolded.
///  * Anki: a tab-separated deck with the standard Anki file header
///    (`#separator:tab`, `#html:true`, `#columns:Front\tBack`); the back of
///    each card is HTML built from the word's fields.
library;

import 'package:core_db/core_db.dart';
import 'package:drift/drift.dart';

import 'transfer_support.dart';

final class TextExportService {
  const TextExportService(this._db);

  final AppDatabase _db;

  /// Word rows grouped by notebook name (insertion order = notebook
  /// position), with the Bangla translation attached.
  Future<List<({String notebook, List<(WordRow, String)> words})>>
      _grouped() async {
    final notebooks = await (_db.select(_db.notebooks)
          ..orderBy([(n) => OrderingTerm.asc(n.position)]))
        .get();
    final words = await (_db.select(_db.words)
          ..orderBy([(w) => OrderingTerm.asc(w.headwordNorm)]))
        .get();
    final translations = await _db.select(_db.wordTranslations).get();

    final banglaByWord = banglaByWordId(translations);
    final byNotebook = <int, List<(WordRow, String)>>{};
    for (final word in words) {
      byNotebook
          .putIfAbsent(word.notebookId, () => [])
          .add((word, banglaByWord[word.id] ?? ''));
    }
    return [
      for (final notebook in notebooks)
        if (byNotebook[notebook.id] case final list?)
          (notebook: notebook.name, words: list),
    ];
  }

  // Shared rule: core_db's splitTermList (previously duplicated here and
  // in the quiz controller).
  static List<String> _split(String csv) => splitTermList(csv);

  /// Comma-joined terms with important ones bolded (legacy quoted-bold).
  static String _mdTerms(String terms, String important) {
    final importantLower = {
      for (final t in _split(important)) t.toLowerCase(),
    };
    return [
      for (final term in _split(terms))
        importantLower.contains(term.toLowerCase()) ? '**$term**' : term,
    ].join(', ');
  }

  Future<String> buildMarkdown() async {
    final groups = await _grouped();
    final buffer = StringBuffer('# VocabNote Export\n');

    for (final group in groups) {
      buffer.write('\n## ${group.notebook}\n');
      for (final (word, bangla) in group.words) {
        buffer.write(
          '\n### ${word.headwordDisplay}'
          '${word.isFavorite ? ' \u2605' : ''}\n',
        );
        if (word.partOfSpeech.isNotEmpty || word.ipa.isNotEmpty) {
          buffer.writeln(
            '- *${[
              if (word.partOfSpeech.isNotEmpty) word.partOfSpeech,
              if (word.ipa.isNotEmpty) '/${word.ipa}/',
            ].join(' · ')}*',
          );
        }
        if (word.meaning.isNotEmpty) {
          buffer.writeln('- **Meaning:** ${word.meaning}');
        }
        if (bangla.isNotEmpty) {
          buffer.writeln('- **Bangla:** $bangla');
        }
        if (word.exampleSentence.isNotEmpty) {
          buffer.writeln('- **Example:** ${word.exampleSentence}');
        }
        if (word.synonyms.isNotEmpty) {
          buffer.writeln(
            '- **Synonyms:** '
            '${_mdTerms(word.synonyms, word.importantSynonyms)}',
          );
        }
        if (word.antonyms.isNotEmpty) {
          buffer.writeln(
            '- **Antonyms:** '
            '${_mdTerms(word.antonyms, word.importantAntonyms)}',
          );
        }
        if (word.notes.isNotEmpty) {
          buffer.writeln('- **Notes:** ${word.notes}');
        }
      }
    }
    return buffer.toString();
  }

  static String _escapeHtml(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// Anki cannot contain raw tabs/newlines inside a TSV field.
  static String _tsvSafe(String text) =>
      text.replaceAll('\t', ' ').replaceAll(RegExp('\r?\n'), '<br>');

  Future<String> buildAnkiTsv() async {
    final groups = await _grouped();
    final buffer = StringBuffer()
      ..writeln('#separator:tab')
      ..writeln('#html:true')
      ..writeln('#columns:Front\tBack');

    for (final group in groups) {
      for (final (word, bangla) in group.words) {
        final back = StringBuffer();
        if (word.meaning.isNotEmpty) {
          back.write('<b>${_escapeHtml(word.meaning)}</b>');
        }
        if (bangla.isNotEmpty) {
          back.write('<br>${_escapeHtml(bangla)}');
        }
        if (word.partOfSpeech.isNotEmpty || word.ipa.isNotEmpty) {
          back.write(
            '<br><i>${_escapeHtml([
              if (word.partOfSpeech.isNotEmpty) word.partOfSpeech,
              if (word.ipa.isNotEmpty) '/${word.ipa}/',
            ].join(' · '))}</i>',
          );
        }
        if (word.exampleSentence.isNotEmpty) {
          back.write('<br><i>${_escapeHtml(word.exampleSentence)}</i>');
        }
        if (word.synonyms.isNotEmpty) {
          back.write('<br>Syn: ${_escapeHtml(word.synonyms)}');
        }
        if (word.antonyms.isNotEmpty) {
          back.write('<br>Ant: ${_escapeHtml(word.antonyms)}');
        }
        buffer.writeln(
          '${_tsvSafe(word.headwordDisplay)}\t${_tsvSafe(back.toString())}',
        );
      }
    }
    return buffer.toString();
  }
}
