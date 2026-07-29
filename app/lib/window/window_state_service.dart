/// app/lib/window/window_state_service.dart
///
/// Desktop window behavior:
///  * enforce a minimum window size so the layout can never be crushed
///    below the 640dp rail breakpoint (see shell/adaptive_shell.dart),
///  * restore the last window bounds / maximized state on launch,
///  * persist them as the user resizes or moves the window.
///
/// No-ops on non-desktop platforms. Purely behavioral: nothing rendered
/// inside the window changes.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

const String _kBoundsKey = 'window.bounds';
const String _kMaximizedKey = 'window.maximized';

/// 640 is the shell's rail breakpoint; every layout is designed down to it.
const Size kMinWindowSize = Size(640, 480);

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Applies the minimum size, restores persisted bounds, and starts
/// persisting future changes. Call once from main() after
/// WidgetsFlutterBinding.ensureInitialized().
Future<void> initializeWindow(SharedPreferences prefs) async {
  if (!_isDesktop) return;
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(minimumSize: kMinWindowSize),
    () async {
      await _restoreBounds(prefs);
      await windowManager.show();
      await windowManager.focus();
    },
  );
  windowManager.addListener(_WindowStatePersister(prefs));
}

Future<void> _restoreBounds(SharedPreferences prefs) async {
  if (prefs.getBool(_kMaximizedKey) ?? false) {
    await windowManager.maximize();
    return;
  }
  final raw = prefs.getString(_kBoundsKey);
  if (raw == null) return;
  final parts = [for (final p in raw.split(',')) double.tryParse(p)];
  if (parts.length != 4 || parts.any((p) => p == null || !p.isFinite)) {
    return;
  }
  await windowManager.setBounds(
    Rect.fromLTWH(
      parts[0]!,
      parts[1]!,
      math.max(parts[2]!, kMinWindowSize.width),
      math.max(parts[3]!, kMinWindowSize.height),
    ),
  );
}

/// Persists bounds and maximized state as they change. Writes go through
/// SharedPreferences' in-memory cache, so resize/move events stay cheap.
class _WindowStatePersister with WindowListener {
  _WindowStatePersister(this._prefs);

  final SharedPreferences _prefs;

  @override
  void onWindowResized() {
    _saveBounds();
  }

  @override
  void onWindowMoved() {
    _saveBounds();
  }

  @override
  void onWindowMaximize() {
    _prefs.setBool(_kMaximizedKey, true);
  }

  @override
  void onWindowUnmaximize() {
    _prefs.setBool(_kMaximizedKey, false);
  }

  Future<void> _saveBounds() async {
    // Maximized bounds are screen-sized; keep the last floating bounds so
    // un-maximizing after a restart still looks right.
    if (await windowManager.isMaximized()) return;
    final b = await windowManager.getBounds();
    await _prefs.setString(
      _kBoundsKey,
      '${b.left},${b.top},${b.width},${b.height}',
    );
  }
}
