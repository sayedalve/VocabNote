/// features/settings/lib/src/application/appearance_controller.dart
///
/// Global UI text scale (parity with the legacy app's card zoom, which was
/// persisted in QSettings and ranged 0.5-1.5). Flutter applies the scale
/// app-wide through `MediaQuery.textScaler` in `main.dart`, so the range is
/// kept to 0.8-1.5 where every layout remains usable.
///
/// Storage: SharedPreferences. A plain UI preference does not belong in the
/// OS credential vault (it bloats the vault and pays keychain/DPAPI costs
/// on every read); a one-time migration moves any previously stored value
/// out of secure storage.
///
/// Hand-written (non-codegen) notifier: this keeps the setting readable from
/// `app/` without a build step and mirrors how simple it is.
library;

import 'package:core_storage/core_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kTextScaleStorageKey = 'ui.text_scale';
const kMinTextScale = 0.8;
const kMaxTextScale = 1.5;
const kDefaultTextScale = 1.0;

final appearanceControllerProvider =
    AsyncNotifierProvider<AppearanceController, double>(
  AppearanceController.new,
);

class AppearanceController extends AsyncNotifier<double> {
  @override
  Future<double> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kTextScaleStorageKey) ??
        await _migrateFromSecureStorage(prefs);
    final parsed = double.tryParse(raw ?? '');
    if (parsed == null) return kDefaultTextScale;
    return parsed.clamp(kMinTextScale, kMaxTextScale).toDouble();
  }

  /// One-time move out of the OS credential vault (the pre-4.1 location).
  /// Best-effort: any failure just falls back to the default value.
  Future<String?> _migrateFromSecureStorage(SharedPreferences prefs) async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final legacy = await storage.read(kTextScaleStorageKey);
      if (legacy != null) {
        await prefs.setString(kTextScaleStorageKey, legacy);
        await storage.delete(kTextScaleStorageKey);
      }
      return legacy;
    } on Object {
      return null;
    }
  }

  /// Applies immediately (optimistic) and persists in the background.
  Future<void> setTextScale(double value) async {
    final clamped = value.clamp(kMinTextScale, kMaxTextScale).toDouble();
    state = AsyncData(clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kTextScaleStorageKey, clamped.toStringAsFixed(2));
  }
}
