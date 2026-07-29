/// app/lib/telemetry/app_logger.dart
///
/// Production crash/event logging. In release builds `debugPrint` is a
/// no-op, so uncaught errors used to vanish silently. [AppLogger] persists
/// every captured error to a rotating log file under the OS-appropriate
/// application-data directory so failures in the field are diagnosable.
///
/// Design constraints:
/// - Zero additional dependencies (pure `dart:io`).
/// - Logging must never crash or block the app: all failures are swallowed
///   and writes are fire-and-forget appends.
/// - Bounded disk usage: simple size-based rotation (current + one backup).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

/// Severity levels for [AppLogger] entries.
enum LogLevel { debug, info, warning, error }

/// File-backed application logger.
///
/// Usage:
/// ```dart
/// AppLogger.instance.error('Uncaught zone error', error, stack);
/// ```
final class AppLogger {
  AppLogger._();

  /// Shared singleton instance.
  static final AppLogger instance = AppLogger._();

  /// Rotate when the active log exceeds this size (1 MiB).
  static const int _maxLogBytes = 1024 * 1024;

  File? _logFile;
  bool _initialized = false;

  /// Serialized async appends for routine entries: keeps lines ordered
  /// without blocking the UI thread on a flushed disk write.
  Future<void> _pending = Future<void>.value();

  /// Resolves the log file location. Called lazily on first write so app
  /// startup never pays filesystem costs on the critical path.
  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    try {
      final dir = _resolveLogDirectory();
      dir.createSync(recursive: true);
      _logFile = File('${dir.path}${Platform.pathSeparator}vocabnote.log');
    } on Object {
      // Logging is best-effort: never propagate filesystem failures.
      _logFile = null;
    }
  }

  /// Windows: %APPDATA%\VocabNote\logs. Other platforms fall back to the
  /// home directory or the system temp directory so tests and future ports
  /// keep working without conditional imports.
  Directory _resolveLogDirectory() {
    final sep = Platform.pathSeparator;
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory('$appData${sep}VocabNote${sep}logs');
    }
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory('$home$sep.vocabnote${sep}logs');
    }
    return Directory('${Directory.systemTemp.path}${sep}vocabnote${sep}logs');
  }

  /// Logs a message with optional [error] and [stackTrace] detail.
  void log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final line = StringBuffer()
      ..write(DateTime.now().toIso8601String())
      ..write(' [')
      ..write(level.name.toUpperCase())
      ..write('] ')
      ..write(message);
    if (error != null) line.write('\n  error: $error');
    if (stackTrace != null) line.write('\n  stack: $stackTrace');

    // Keep developer visibility in debug builds.
    if (kDebugMode) debugPrint(line.toString());

    // Error-level entries keep the synchronous flushed write so the line
    // reaches disk even if the process dies immediately afterwards.
    _write('$line\n', urgent: level == LogLevel.error);
  }

  /// Convenience: informational event.
  void info(String message) => log(LogLevel.info, message);

  /// Convenience: recoverable warning.
  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      log(LogLevel.warning, message, error, stackTrace);

  /// Convenience: captured error/crash.
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      log(LogLevel.error, message, error, stackTrace);

  void _write(String line, {bool urgent = false}) {
    try {
      _ensureInitialized();
      final file = _logFile;
      if (file == null) return;
      _rotateIfNeeded(file);
      if (urgent) {
        file.writeAsStringSync(line, mode: FileMode.append, flush: true);
        return;
      }
      _pending = _pending
          .then((_) => file.writeAsString(line, mode: FileMode.append))
          .then((_) {})
          .catchError((Object _) {});
    } on Object {
      // Never let logging failures affect the app.
    }
  }

  void _rotateIfNeeded(File file) {
    try {
      if (!file.existsSync() || file.lengthSync() < _maxLogBytes) return;
      final backup = File('${file.path}.1');
      if (backup.existsSync()) backup.deleteSync();
      file.renameSync(backup.path);
    } on Object {
      // Rotation is best-effort.
    }
  }
}
