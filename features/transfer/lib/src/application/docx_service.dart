/// features/transfer/lib/src/application/docx_service.dart
///
/// Word (.docx) export/import.
///
///  * Export builds a real OOXML package (no external Word needed): one
///    Heading 1 per notebook, one Heading 2 per word (★ marks favorites),
///    and a bold "Label: value" paragraph per non-empty field.
///  * Import reads the same structure back: Heading 1 = notebook,
///    Heading 2/3 = headword, "Label: value" paragraphs = fields. An
///    unlabeled paragraph right after a headword becomes its meaning.
///    Plain documents without headings fall back to one word per
///    paragraph ("headword - meaning", "headword: meaning", or a bare
///    word). Duplicates (same normalized headword in the same notebook)
///    are skipped, exactly like the CSV and legacy importers.
library;

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:core_db/core_db.dart';
import 'package:drift/drift.dart';
import 'package:xml/xml.dart';

import 'transfer_support.dart';

const String _wNs =
    'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

class DocxImportException implements Exception {
  const DocxImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class DocxTransferService {
  const DocxTransferService(this._db);

  final AppDatabase _db;

  // --------------------------------------------------------------------------
  // Export
  // --------------------------------------------------------------------------

  /// Builds the full-workspace .docx and returns its bytes.
  Future<List<int>> buildDocx() async {
    final notebooks = await _db.select(_db.notebooks).get();
    final words = await _db.select(_db.words).get();
    final translations = await _db.select(_db.wordTranslations).get();

    final banglaByWord = banglaByWordId(translations);

    final body = StringBuffer()
      ..write(_styledParagraph('VocabNote Export', 'Title'));

    for (final notebook in notebooks) {
      final notebookWords = [
        for (final word in words)
          if (word.notebookId == notebook.id) word,
      ]..sort((a, b) => a.headwordNorm.compareTo(b.headwordNorm));
      if (notebookWords.isEmpty) continue;

      body.write(_styledParagraph(notebook.name, 'Heading1'));
      for (final word in notebookWords) {
        final title =
            word.isFavorite ? '${word.headwordDisplay} \u2605' : word.headwordDisplay;
        body.write(_styledParagraph(title, 'Heading2'));

        void field(String label, String value) {
          if (value.trim().isEmpty) return;
          body.write(_fieldParagraph(label, value.trim()));
        }

        field('Part of speech', word.partOfSpeech);
        field('Pronunciation', word.ipa.isEmpty ? '' : '/${word.ipa}/');
        field('Meaning', word.meaning);
        field('Bangla', banglaByWord[word.id] ?? '');
        field('Example', word.exampleSentence);
        field('Synonyms', word.synonyms);
        field('Antonyms', word.antonyms);
        field('Important synonyms', word.importantSynonyms);
        field('Important antonyms', word.importantAntonyms);
        field('Notes', word.notes);
      }
    }

    final documentXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="$_wNs"><w:body>$body<w:sectPr/></w:body>'
        '</w:document>';

    final package = Archive()
      ..addFile(_textFile('[Content_Types].xml', _contentTypesXml))
      ..addFile(_textFile('_rels/.rels', _packageRelsXml))
      ..addFile(_textFile('word/_rels/document.xml.rels', _documentRelsXml))
      ..addFile(_textFile('word/styles.xml', _stylesXml))
      ..addFile(_textFile('word/document.xml', documentXml));

    final List<int>? bytes = ZipEncoder().encode(package);
    if (bytes == null) {
      throw const DocxImportException('Could not build the .docx package.');
    }
    return bytes;
  }

  static ArchiveFile _textFile(String name, String content) {
    final data = utf8.encode(content);
    return ArchiveFile(name, data.length, data);
  }

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _styledParagraph(String text, String style) =>
      '<w:p><w:pPr><w:pStyle w:val="$style"/></w:pPr>'
      '<w:r><w:t xml:space="preserve">${_escape(text)}</w:t></w:r></w:p>';

  static String _fieldParagraph(String label, String value) =>
      '<w:p><w:r><w:rPr><w:b/></w:rPr>'
      '<w:t xml:space="preserve">${_escape(label)}: </w:t></w:r>'
      '<w:r><w:t xml:space="preserve">${_escape(value)}</w:t></w:r></w:p>';

  static const String _contentTypesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
      '</Types>';

  static const String _packageRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';

  static const String _documentRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  static const String _stylesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:styles xmlns:w="$_wNs">'
      '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
      '<w:name w:val="Normal"/>'
      '<w:pPr><w:spacing w:after="60"/></w:pPr>'
      '<w:rPr><w:sz w:val="22"/></w:rPr>'
      '</w:style>'
      '<w:style w:type="paragraph" w:styleId="Title">'
      '<w:name w:val="Title"/><w:basedOn w:val="Normal"/>'
      '<w:pPr><w:spacing w:after="240"/></w:pPr>'
      '<w:rPr><w:b/><w:sz w:val="56"/></w:rPr>'
      '</w:style>'
      '<w:style w:type="paragraph" w:styleId="Heading1">'
      '<w:name w:val="heading 1"/><w:basedOn w:val="Normal"/>'
      '<w:pPr><w:spacing w:before="360" w:after="120"/><w:outlineLvl w:val="0"/></w:pPr>'
      '<w:rPr><w:b/><w:sz w:val="40"/></w:rPr>'
      '</w:style>'
      '<w:style w:type="paragraph" w:styleId="Heading2">'
      '<w:name w:val="heading 2"/><w:basedOn w:val="Normal"/>'
      '<w:pPr><w:spacing w:before="240" w:after="80"/><w:outlineLvl w:val="1"/></w:pPr>'
      '<w:rPr><w:b/><w:sz w:val="30"/></w:rPr>'
      '</w:style>'
      '</w:styles>';

  // --------------------------------------------------------------------------
  // Import
  // --------------------------------------------------------------------------

  /// Imports words from .docx bytes. Only the headword is required;
  /// duplicates are skipped.
  Future<ImportReport> importFrom(List<int> bytes) async {
    final entries = _parseEntries(bytes);
    if (entries.isEmpty) {
      throw const DocxImportException(
        'No words found in this document. Use Heading 2 for each word '
        '(Heading 1 for notebooks), or plain "word - meaning" lines.',
      );
    }

    var wordsImported = 0;
    var wordsSkipped = 0;
    var translationsImported = 0;
    final notebooks = NotebookResolver(_db);

    await _db.transaction(() async {
      for (final entry in entries) {
        final headwordResult = normalizeHeadword(entry.headword);
        if (headwordResult is! ValidHeadword) {
          wordsSkipped++;
          continue;
        }

        final notebookId = await notebooks.resolve(entry.notebook);

        final duplicate = await _db.wordDao.byNormalizedHeadword(
          notebookId: notebookId,
          norm: headwordResult.norm,
        );
        if (duplicate != null) {
          wordsSkipped++;
          continue;
        }

        final inserted = await _db.wordDao.insertWord(
          WordsCompanion.insert(
            notebookId: notebookId,
            headwordNorm: headwordResult.norm,
            headwordDisplay: headwordResult.display,
            meaning: Value(clampField(entry.meaning)),
            ipa: Value(clampField(entry.ipa)),
            partOfSpeech: Value(clampField(entry.partOfSpeech)),
            exampleSentence: Value(clampField(entry.example)),
            synonyms: Value(clampField(entry.synonyms)),
            antonyms: Value(clampField(entry.antonyms)),
            importantSynonyms: Value(clampField(entry.importantSynonyms)),
            importantAntonyms: Value(clampField(entry.importantAntonyms)),
            notes: Value(clampField(entry.notes)),
            isFavorite: Value(entry.isFavorite),
          ),
        );
        wordsImported++;

        final bangla = clampField(entry.bangla);
        if (bangla.isNotEmpty) {
          await _db.wordDao.upsertTranslation(
            wordId: inserted.id,
            langCode: kBanglaLangCode,
            translation: bangla,
          );
          translationsImported++;
        }
      }
    });

    // Bulk import: rebuild FTS once instead of trusting per-row triggers.
    await _db.rebuildSearchIndex();

    return ImportReport(
      notebooksCreated: notebooks.created,
      wordsImported: wordsImported,
      wordsSkipped: wordsSkipped,
      translationsImported: translationsImported,
    );
  }

  /// Unzips the package, parses word/document.xml, and turns its paragraphs
  /// into word entries.
  List<_DocxEntry> _parseEntries(List<int> bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const DocxImportException(
        'This file is not a valid .docx document.',
      );
    }

    final documentEntry = archive.findFile('word/document.xml');
    if (documentEntry == null) {
      throw const DocxImportException(
        'This file is not a valid .docx document '
        '(word/document.xml is missing).',
      );
    }

    final XmlDocument document;
    try {
      document = XmlDocument.parse(
        utf8.decode(documentEntry.content as List<int>),
      );
    } catch (_) {
      throw const DocxImportException(
        'Could not read the contents of this document.',
      );
    }

    // Flatten to (style, text) paragraphs.
    final paragraphs = <({String style, String text})>[];
    for (final paragraph in document.findAllElements('p', namespace: _wNs)) {
      String style = '';
      for (final pStyle
          in paragraph.findAllElements('pStyle', namespace: _wNs)) {
        style = pStyle.getAttribute('val', namespace: _wNs) ?? '';
        break;
      }
      final text = paragraph
          .findAllElements('t', namespace: _wNs)
          .map((t) => t.innerText)
          .join();
      paragraphs.add((
        style: style.toLowerCase().replaceAll(RegExp(r'[\s_-]'), ''),
        text: text.trim(),
      ));
    }

    // Heading-structured documents (our own export format).
    final entries = <_DocxEntry>[];
    var currentNotebook = '';
    _DocxEntry? current;

    for (final paragraph in paragraphs) {
      if (paragraph.text.isEmpty) continue;
      final style = paragraph.style;
      if (style.contains('title')) continue;
      if (style.contains('heading1')) {
        currentNotebook = paragraph.text;
        current = null;
        continue;
      }
      if (style.contains('heading2') || style.contains('heading3')) {
        var headword = paragraph.text;
        var favorite = false;
        if (headword.endsWith('\u2605')) {
          favorite = true;
          headword = headword.substring(0, headword.length - 1).trim();
        }
        current = _DocxEntry(notebook: currentNotebook, headword: headword)
          ..isFavorite = favorite;
        entries.add(current);
        continue;
      }
      if (current != null) {
        _applyParagraph(current, paragraph.text);
      }
    }

    if (entries.isNotEmpty) return entries;

    // Fallback for plain documents: one word per paragraph, either
    // "headword - meaning" / "headword: meaning" or a bare word.
    final splitter = RegExp(r'^(.{1,64}?)\s*(?:[-\u2013\u2014]|:)\s+(.+)$');
    for (final paragraph in paragraphs) {
      if (paragraph.text.isEmpty) continue;
      final match = splitter.firstMatch(paragraph.text);
      if (match != null) {
        entries.add(
          _DocxEntry(notebook: '', headword: match.group(1)!.trim())
            ..meaning = match.group(2)!.trim(),
        );
      } else if (paragraph.text.length <= 64) {
        entries.add(_DocxEntry(notebook: '', headword: paragraph.text));
      }
    }
    return entries;
  }

  /// Applies one "Label: value" paragraph to [entry]. Unlabeled paragraphs
  /// become the meaning (first) or are appended to notes.
  static void _applyParagraph(_DocxEntry entry, String text) {
    final colon = text.indexOf(':');
    if (colon > 0 && colon <= 24) {
      final label = text
          .substring(0, colon)
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[\s_-]+'), ' ');
      final value = text.substring(colon + 1).trim();
      switch (label) {
        case 'meaning' || 'definition':
          entry.meaning = value;
          return;
        case 'bangla' || 'bangla meaning' || 'translation':
          entry.bangla = value;
          return;
        case 'pronunciation' || 'ipa':
          entry.ipa = _stripSlashes(value);
          return;
        case 'part of speech' || 'pos':
          entry.partOfSpeech = value;
          return;
        case 'example' || 'example sentence':
          entry.example = value;
          return;
        case 'synonyms' || 'synonym':
          entry.synonyms = value;
          return;
        case 'antonyms' || 'antonym':
          entry.antonyms = value;
          return;
        case 'important synonyms':
          entry.importantSynonyms = value;
          return;
        case 'important antonyms':
          entry.importantAntonyms = value;
          return;
        case 'notes' || 'note':
          entry.notes = entry.notes.isEmpty ? value : '${entry.notes}\n$value';
          return;
        case 'favorite' || 'favourite':
          final v = value.toLowerCase();
          entry.isFavorite = v == 'yes' || v == 'true' || v == '1';
          return;
      }
    }
    // Unlabeled paragraph: meaning first, then notes.
    if (entry.meaning.isEmpty) {
      entry.meaning = text;
    } else {
      entry.notes = entry.notes.isEmpty ? text : '${entry.notes}\n$text';
    }
  }

  static String _stripSlashes(String value) {
    var v = value.trim();
    if (v.startsWith('/')) v = v.substring(1);
    if (v.endsWith('/')) v = v.substring(0, v.length - 1);
    return v.trim();
  }
}

/// Mutable accumulator for one word parsed out of the document.
class _DocxEntry {
  _DocxEntry({required this.notebook, required this.headword});

  final String notebook;
  final String headword;

  String meaning = '';
  String bangla = '';
  String ipa = '';
  String partOfSpeech = '';
  String example = '';
  String synonyms = '';
  String antonyms = '';
  String importantSynonyms = '';
  String importantAntonyms = '';
  String notes = '';
  bool isFavorite = false;
}
