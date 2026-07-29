/// features/transfer/lib/src/application/transfer_controller.dart
///
/// Orchestrates every flow behind the Data screen:
///  * Import: legacy `vocab_notebook.db` (LegacyImportService), CSV
///    (CsvTransferService), or Word .docx (DocxTransferService).
///  * Export: JSON, CSV, Markdown, Anki, or Word .docx via the platform
///    save dialog (desktop) with a data-directory fallback (platforms
///    without one).
///  * Backups: snapshot now, list snapshots, stage a restore.
library;

import 'dart:io';

import 'package:core_db/core_db.dart';
import 'package:file_selector/file_selector.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'backup_service.dart';
import 'csv_service.dart';
import 'docx_service.dart';
import 'export_service.dart';
import 'legacy_import_service.dart';
import 'text_export_service.dart';

part 'transfer_controller.freezed.dart';
part 'transfer_controller.g.dart';

@freezed
abstract class TransferState with _$TransferState {
  const factory TransferState({
    @Default(false) bool busy,
    String? message,
    String? error,
  }) = _TransferState;
}

/// Snapshots in the backups directory, newest first.
@riverpod
Future<List<BackupInfo>> backupsList(Ref ref) =>
    BackupService(ref.watch(appDatabaseProvider)).listBackups();

@riverpod
class TransferController extends _$TransferController {
  @override
  TransferState build() => const TransferState();

  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<void> importLegacyDatabase() async {
    if (state.busy) return;

    const typeGroup = XTypeGroup(
      label: 'SQLite database',
      extensions: <String>['db', 'sqlite', 'sqlite3'],
    );
    final XFile? file;
    try {
      file = await openFile(acceptedTypeGroups: const [typeGroup]);
    } catch (e) {
      state = TransferState(error: 'Could not open the file picker: $e');
      return;
    }
    if (file == null) return; // Cancelled.

    state = const TransferState(busy: true);
    try {
      final report = await LegacyImportService(_db).importFrom(file.path);
      state = TransferState(message: report.summary);
    } on LegacyImportException catch (e) {
      state = TransferState(error: e.message);
    } catch (e) {
      state = TransferState(error: 'Import failed: $e');
    }
  }

  Future<void> importCsv() async {
    if (state.busy) return;

    const typeGroup = XTypeGroup(
      label: 'CSV',
      extensions: <String>['csv'],
    );
    final XFile? file;
    try {
      file = await openFile(acceptedTypeGroups: const [typeGroup]);
    } catch (e) {
      state = TransferState(error: 'Could not open the file picker: $e');
      return;
    }
    if (file == null) return; // Cancelled.

    state = const TransferState(busy: true);
    try {
      final csvText = await File(file.path).readAsString();
      final report = await CsvTransferService(_db).importFrom(csvText);
      state = TransferState(message: report.summary);
    } on CsvImportException catch (e) {
      state = TransferState(error: e.message);
    } catch (e) {
      state = TransferState(error: 'CSV import failed: $e');
    }
  }

  Future<void> importDocx() async {
    if (state.busy) return;

    const typeGroup = XTypeGroup(
      label: 'Word document',
      extensions: <String>['docx'],
    );
    final XFile? file;
    try {
      file = await openFile(acceptedTypeGroups: const [typeGroup]);
    } catch (e) {
      state = TransferState(error: 'Could not open the file picker: $e');
      return;
    }
    if (file == null) return; // Cancelled.

    state = const TransferState(busy: true);
    try {
      final bytes = await File(file.path).readAsBytes();
      final report = await DocxTransferService(_db).importFrom(bytes);
      state = TransferState(message: report.summary);
    } on DocxImportException catch (e) {
      state = TransferState(error: e.message);
    } catch (e) {
      state = TransferState(error: 'DOCX import failed: $e');
    }
  }

  Future<void> exportJson() => _exportText(
        buildText: () => ExportService(_db).buildJson(),
        extension: 'json',
        typeLabel: 'JSON',
      );

  Future<void> exportCsv() => _exportText(
        buildText: () => CsvTransferService(_db).buildCsv(),
        extension: 'csv',
        typeLabel: 'CSV',
      );

  /// Markdown export grouped by notebook (legacy export_manager parity).
  Future<void> exportMarkdown() => _exportText(
        buildText: () => TextExportService(_db).buildMarkdown(),
        extension: 'md',
        typeLabel: 'Markdown',
      );

  /// Anki-importable tab-separated deck (legacy export_manager parity).
  Future<void> exportAnki() => _exportText(
        buildText: () => TextExportService(_db).buildAnkiTsv(),
        extension: 'txt',
        typeLabel: 'Anki TSV',
      );

  /// Word document export grouped by notebook, re-importable via
  /// [importDocx].
  Future<void> exportDocx() => _exportBytes(
        buildBytes: () => DocxTransferService(_db).buildDocx(),
        extension: 'docx',
        typeLabel: 'Word document',
      );

  Future<void> _exportText({
    required Future<String> Function() buildText,
    required String extension,
    required String typeLabel,
  }) async {
    if (state.busy) return;
    state = const TransferState(busy: true);

    try {
      final text = await buildText();
      final path = await _pickExportPath(
        extension: extension,
        typeLabel: typeLabel,
      );
      if (path == null) {
        state = const TransferState(); // Cancelled.
        return;
      }
      await File(path).writeAsString(text);
      state = TransferState(message: 'Exported to $path');
    } catch (e) {
      state = TransferState(error: 'Export failed: $e');
    }
  }

  /// Binary twin of [_exportText] (used by the .docx export).
  Future<void> _exportBytes({
    required Future<List<int>> Function() buildBytes,
    required String extension,
    required String typeLabel,
  }) async {
    if (state.busy) return;
    state = const TransferState(busy: true);

    try {
      final bytes = await buildBytes();
      final path = await _pickExportPath(
        extension: extension,
        typeLabel: typeLabel,
      );
      if (path == null) {
        state = const TransferState(); // Cancelled.
        return;
      }
      await File(path).writeAsBytes(bytes, flush: true);
      state = TransferState(message: 'Exported to $path');
    } catch (e) {
      state = TransferState(error: 'Export failed: $e');
    }
  }

  /// Shows the save dialog (with a data-directory fallback on platforms
  /// without one) and returns the chosen path, or null when cancelled.
  Future<String?> _pickExportPath({
    required String extension,
    required String typeLabel,
  }) async {
    final date =
        DateTime.now().toUtc().toIso8601String().split('T').first;
    final suggestedName = 'vocabnote_export_$date.$extension';

    String? path;
    var pickerAvailable = true;
    try {
      final location = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          XTypeGroup(label: typeLabel, extensions: <String>[extension]),
        ],
      );
      path = location?.path;
    } on UnimplementedError {
      // No native save dialog on this platform (e.g. Android):
      // fall back to the app data directory.
      pickerAvailable = false;
    }

    if (pickerAvailable && path == null) return null; // Cancelled.

    return path ?? p.join((await resolveDataDirectory()).path, suggestedName);
  }

  Future<void> backupNow() async {
    if (state.busy) return;
    state = const TransferState(busy: true);
    try {
      final info = await BackupService(_db).backupNow();
      ref.invalidate(backupsListProvider);
      state = TransferState(message: 'Backed up to ${info.fileName}');
    } on BackupException catch (e) {
      state = TransferState(error: e.message);
    } catch (e) {
      state = TransferState(error: 'Backup failed: $e');
    }
  }

  Future<void> restoreBackup(BackupInfo backup) async {
    if (state.busy) return;
    state = const TransferState(busy: true);
    try {
      await BackupService(_db).restore(backup.path);
      state = TransferState(
        message: 'Restore staged: ${backup.fileName} will replace your '
            'data the next time VocabNote starts.',
      );
    } on BackupException catch (e) {
      state = TransferState(error: e.message);
    } catch (e) {
      state = TransferState(error: 'Restore failed: $e');
    }
  }

  void dismissMessage() {
    state = const TransferState();
  }
}
