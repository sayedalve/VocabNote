/// core/storage/lib/src/secure_storage_service.dart
///
/// API-key persistence with **no silent failures**.
///
/// Layers:
///  * [SecureStorageService]        — the seam everything depends on.
///  * [FlutterSecureStorageService] — OS credential vault (Windows DPAPI
///    file store / Keychain / libsecret) via flutter_secure_storage.
///  * [LocalFileKeyStore]           — obfuscated app-data file, used only
///    when the OS vault is unavailable or fails read-after-write
///    verification (a real failure mode on some Windows setups).
///  * [HybridSecureStorage]         — production wiring: vault first,
///    verified writes, automatic fallback, typed [StorageException]s and a
///    [healthCheck] the Settings UI surfaces as a diagnostic.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_service.g.dart';

/// Thrown when a value could not be persisted *and verified*. UI layers must
/// surface this — storage problems are never allowed to be silent.
final class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => 'StorageException: $message';
}

/// Which physical backend is currently serving key storage.
enum StorageBackend { osVault, localFile }

/// Abstract seam so tests and previews can use [InMemorySecureStorage].
abstract interface class SecureStorageService {
  Future<String?> read(String key);

  /// Persists [value]. Implementations must throw [StorageException] when
  /// the write cannot be confirmed.
  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Optional diagnostics surface for storages that can report their health.
abstract interface class DiagnosableStorage {
  /// Round-trips a sentinel value and reports which backend worked, or null
  /// when nothing does.
  Future<StorageBackend?> healthCheck();
}

/// Thin, mockable wrapper over the OS credential vault.
final class FlutterSecureStorageService implements SecureStorageService {
  FlutterSecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              mOptions: MacOsOptions(synchronizable: false),
              // Backward-compatibility mode (the default) reads and writes
              // through two different Windows backends (wincred + DPAPI
              // file) and is a documented source of "write succeeds, read
              // returns null" bugs. We pin the modern file backend only.
              wOptions: WindowsOptions(useBackwardCompatibility: false),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Obfuscated app-data file store. This is a *fallback*, not the primary
/// vault: values are XOR-obfuscated and base64-encoded, which protects
/// against casual inspection but is not OS-grade encryption. It exists so a
/// broken credential vault degrades to "works, with a visible warning in
/// Settings" instead of "silently loses the API key".
final class LocalFileKeyStore implements SecureStorageService {
  LocalFileKeyStore({Future<Directory> Function()? directoryResolver})
      : _directoryResolver =
            directoryResolver ?? getApplicationSupportDirectory;

  static const String _fileName = 'vocabnote.keys';
  static const String _pad = 'vocabnote-local-keystore-v1';

  final Future<Directory> Function() _directoryResolver;

  Future<File> _file() async {
    final dir = await _directoryResolver();
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File(p.join(dir.path, _fileName));
  }

  static String _obfuscate(String value) {
    final bytes = utf8.encode(value);
    final pad = utf8.encode(_pad);
    final out = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ pad[i % pad.length];
    }
    return base64Encode(out);
  }

  static String _deobfuscate(String stored) {
    final bytes = base64Decode(stored);
    final pad = utf8.encode(_pad);
    final out = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ pad[i % pad.length];
    }
    return utf8.decode(out);
  }

  Future<Map<String, String>> _load() async {
    final file = await _file();
    if (!file.existsSync()) return <String, String>{};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return <String, String>{};
      return <String, String>{
        for (final MapEntry(:key, :value) in decoded.entries)
          if (value is String) key: _deobfuscate(value),
      };
    } on Object catch (error) {
      // A corrupt store is treated as empty; the next write rewrites it.
      debugPrint('LocalFileKeyStore: could not parse store file: $error');
      return <String, String>{};
    }
  }

  Future<void> _save(Map<String, String> values) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode(<String, String>{
        for (final MapEntry(:key, :value) in values.entries)
          key: _obfuscate(value),
      }),
      flush: true,
    );
    // Atomic swap so a crash mid-write can never corrupt existing keys.
    await tmp.rename(file.path);
  }

  @override
  Future<String?> read(String key) async => (await _load())[key];

  @override
  Future<void> write(String key, String value) async {
    final values = await _load();
    values[key] = value;
    await _save(values);
  }

  @override
  Future<void> delete(String key) async {
    final values = await _load();
    if (values.remove(key) != null) {
      await _save(values);
    }
  }
}

/// Production storage: OS vault first with read-after-write verification,
/// local file store as an explicit, observable fallback.
final class HybridSecureStorage
    implements SecureStorageService, DiagnosableStorage {
  HybridSecureStorage({
    required SecureStorageService vault,
    required SecureStorageService fallback,
  })  : _vault = vault,
        _fallback = fallback;

  final SecureStorageService _vault;
  final SecureStorageService _fallback;

  static const String _probeKey = 'vocabnote.storage.probe';

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _vault.read(key);
      if (value != null && value.isNotEmpty) return value;
    } on Object catch (error) {
      debugPrint('HybridSecureStorage: vault read failed for "$key": $error');
    }
    try {
      return await _fallback.read(key);
    } on Object catch (error) {
      debugPrint(
        'HybridSecureStorage: fallback read failed for "$key": $error',
      );
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    if (await _writeVerified(_vault, key, value)) {
      // Remove any stale fallback copy so reads cannot resurrect old keys.
      await _deleteQuietly(_fallback, key);
      return;
    }
    debugPrint(
      'HybridSecureStorage: OS vault write for "$key" could not be verified; '
      'falling back to the local key store.',
    );
    if (await _writeVerified(_fallback, key, value)) {
      return;
    }
    throw const StorageException(
      'The value could not be saved: both the OS credential vault and the '
      'local fallback store failed verification.',
    );
  }

  @override
  Future<void> delete(String key) async {
    await _deleteQuietly(_vault, key);
    await _deleteQuietly(_fallback, key);
    if (await read(key) != null) {
      throw const StorageException(
        'The stored value could not be removed from storage.',
      );
    }
  }

  /// Round-trips a sentinel through each backend and reports the first one
  /// that verifiably works.
  @override
  Future<StorageBackend?> healthCheck() async {
    final sentinel = 'ok-${DateTime.now().microsecondsSinceEpoch}';
    if (await _writeVerified(_vault, _probeKey, sentinel)) {
      await _deleteQuietly(_vault, _probeKey);
      return StorageBackend.osVault;
    }
    if (await _writeVerified(_fallback, _probeKey, sentinel)) {
      await _deleteQuietly(_fallback, _probeKey);
      return StorageBackend.localFile;
    }
    return null;
  }

  static Future<bool> _writeVerified(
    SecureStorageService storage,
    String key,
    String value,
  ) async {
    try {
      await storage.write(key, value);
      return await storage.read(key) == value;
    } on Object catch (error) {
      debugPrint('HybridSecureStorage: write for "$key" threw: $error');
      return false;
    }
  }

  static Future<void> _deleteQuietly(
    SecureStorageService storage,
    String key,
  ) async {
    try {
      await storage.delete(key);
    } on Object catch (error) {
      debugPrint('HybridSecureStorage: delete for "$key" threw: $error');
    }
  }
}

/// Test/preview double; never used in production wiring.
final class InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(Ref ref) => HybridSecureStorage(
      vault: FlutterSecureStorageService(),
      fallback: LocalFileKeyStore(),
    );
