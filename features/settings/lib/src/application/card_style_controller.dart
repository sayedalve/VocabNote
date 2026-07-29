/// features/settings/lib/src/application/card_style_controller.dart
///
/// Persisted reading-experience settings for vocabulary cards
/// ([VnCardStyle]): typography sizes, spacing, corner radius, live card
/// zoom, and pronunciation display. Values apply instantly (optimistic
/// state update) and persist as a single JSON blob; parsing is tolerant so
/// corrupt or older stored data falls back to defaults instead of crashing
/// startup.
///
/// Storage: SharedPreferences. A plain UI preference does not belong in the
/// OS credential vault; a one-time migration moves any previously stored
/// blob out of secure storage.
///
/// Hand-written (non-codegen) notifier, mirroring `appearance_controller`:
/// this keeps the setting readable from `app/` without a build step.
library;

import 'dart:convert';

import 'package:core_design_system/core_design_system.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kCardStyleStorageKey = 'ui.card_style';

final cardStyleControllerProvider =
    AsyncNotifierProvider<CardStyleController, VnCardStyle>(
  CardStyleController.new,
);

class CardStyleController extends AsyncNotifier<VnCardStyle> {
  @override
  Future<VnCardStyle> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kCardStyleStorageKey) ??
        await _migrateFromSecureStorage(prefs);
    if (raw == null || raw.isEmpty) return const VnCardStyle();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return VnCardStyle.fromJson(decoded);
      }
    } on FormatException {
      // Fall through to defaults: a corrupt blob must never crash startup.
    }
    return const VnCardStyle();
  }

  /// One-time move out of the OS credential vault (the pre-4.1 location).
  /// Best-effort: any failure just falls back to defaults.
  Future<String?> _migrateFromSecureStorage(SharedPreferences prefs) async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final legacy = await storage.read(kCardStyleStorageKey);
      if (legacy != null) {
        await prefs.setString(kCardStyleStorageKey, legacy);
        await storage.delete(kCardStyleStorageKey);
      }
      return legacy;
    } on Object {
      return null;
    }
  }

  /// Applies [style] immediately (optimistic) and persists in the
  /// background. Values are normalized (clamped) before use.
  Future<void> save(VnCardStyle style) async {
    final normalized = style.normalized();
    state = AsyncData(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kCardStyleStorageKey,
      jsonEncode(normalized.toJson()),
    );
  }

  /// Convenience for the toolbar zoom control.
  Future<void> setZoom(double zoom) async {
    final current = state.value ?? await future;
    await save(current.copyWith(zoom: zoom));
  }

  /// Restores every card-style value to its default.
  Future<void> reset() => save(const VnCardStyle());
}
