/// features/transfer/lib/src/application/backup_service.dart
///
/// Local snapshot backups (Phase 4).
///  * backupNow: consistent snapshot via SQLite `VACUUM INTO` (safe while
///    the database is in use; single compact file, no WAL sidecar).
///  * listBackups: snapshots in the backups directory, newest first.
///  * restore: validates the file, then stages it next to the live database
///    (`vocabnote.db.restore-pending`); the swap happens on next launch,
///    before the Drift connection opens (see core_db `_applyPendingRestore`).
library;

import 'dart:io';

import 'package:core_db/core_db.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sq;

/// A snapshot file in the backups directory.
typedef BackupInfo = ({
  String path,
  String fileName,
  int sizeBytes,
  DateTime modifiedAt,
});

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Keep at most this many snapshots; oldest are pruned after each backup.
const int kMaxBackups = 10;

final class BackupService {
  const BackupService(this._db);

  final AppDatabase _db;

  Future<Directory> _backupsDirectory() async {
    final dataDir = await resolveDataDirectory();
    final dir = Directory(p.join(dataDir.path, 'backups'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Writes a consistent snapshot and prunes old ones. Returns its info.
  Future<BackupInfo> backupNow() async {
    final dir = await _backupsDirectory();
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(':', '-');
    final path = p.join(dir.path, 'vocabnote-backup-$stamp.db');
    final target = File(path);
    if (target.existsSync()) {
      target.deleteSync(); // VACUUM INTO refuses to overwrite.
    }

    try {
      await _db.customStatement('VACUUM INTO ?', [path]);
    } on Exception catch (e) {
      // Disk full, backups folder removed mid-run, or the target locked by
      // another process: surface a readable message instead of a raw
      // SQLite error string.
      throw BackupException('Could not write the backup file: $e');
    }
    await _prune();

    final stat = target.statSync();
    return (
      path: path,
      fileName: p.basename(path),
      sizeBytes: stat.size,
      modifiedAt: stat.modified,
    );
  }

  /// Snapshots in the backups directory, newest first.
  Future<List<BackupInfo>> listBackups() async {
    final dir = await _backupsDirectory();
    final infos = <BackupInfo>[
      for (final entity in dir.listSync())
        if (entity is File && entity.path.endsWith('.db'))
          (
            path: entity.path,
            fileName: p.basename(entity.path),
            sizeBytes: entity.statSync().size,
            modifiedAt: entity.statSync().modified,
          ),
    ];
    infos.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return infos;
  }

  Future<void> _prune() async {
    final backups = await listBackups();
    for (final backup in backups.skip(kMaxBackups)) {
      try {
        File(backup.path).deleteSync();
      } on FileSystemException {
        // Best effort; a locked file is retried on the next prune.
      }
    }
  }

  /// Validates [backupPath] and stages it as the pending restore. The live
  /// database is replaced on the next app launch.
  Future<void> restore(String backupPath) async {
    final source = File(backupPath);
    if (!source.existsSync()) {
      throw const BackupException('That backup file no longer exists.');
    }
    _validateBackup(backupPath);

    final dataDir = await resolveDataDirectory();
    final livePath = p.join(dataDir.path, kDatabaseFileName);
    try {
      source.copySync('$livePath$kRestorePendingSuffix');
    } on FileSystemException catch (e) {
      throw BackupException(
        'Could not stage the restore file: '
        '${e.osError?.message ?? e.message}',
      );
    }
  }

  /// Opens the candidate read-only and verifies it is a healthy VocabNote
  /// database: `PRAGMA quick_check` passes and `words.headword_norm` exists.
  void _validateBackup(String path) {
    final sq.Database db;
    try {
      db = sq.sqlite3.open(path, mode: sq.OpenMode.readOnly);
    } on sq.SqliteException catch (e) {
      throw BackupException(
        'Not a readable SQLite database: ${e.message}',
      );
    }
    try {
      final check = db.select('PRAGMA quick_check');
      final ok = check.isNotEmpty && check.first.values.first == 'ok';
      if (!ok) {
        throw const BackupException(
          'This backup failed the integrity check.',
        );
      }
      final columns = db.select("PRAGMA table_info('words')");
      final hasNorm = columns.any((row) => row['name'] == 'headword_norm');
      if (!hasNorm) {
        throw const BackupException(
          'This file is not a VocabNote 4.x database.',
        );
      }
    } on sq.SqliteException catch (e) {
      throw BackupException('Could not validate the backup: ${e.message}');
    } finally {
      db.dispose();
    }
  }
}
