/// app/lib/main.dart
///
/// Composition root. The app package wires features together; it contains no
/// business logic. Crash logging mirrors the legacy `main.py` contract:
/// every uncaught error is captured before the process dies silently.
/// Errors are persisted via [AppLogger] so release builds (where
/// `debugPrint` is a no-op) still leave a diagnosable trail on disk.
///
/// Startup also restores persisted desktop UI state (window bounds and the
/// last visited section) before the first frame, so the app reopens exactly
/// where the user left it.
library;

import 'dart:async';

import 'package:core_design_system/core_design_system.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router.dart';
import 'telemetry/app_logger.dart';
import 'window/window_state_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.instance.error(
          'FlutterError: ${details.exceptionAsString()}',
          details.exception,
          details.stack,
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.instance.error('Uncaught platform error', error, stack);
        return true;
      };

      // Desktop chrome: minimum window size + restored bounds (no-op on
      // non-desktop platforms), then the last visited section.
      final prefs = await SharedPreferences.getInstance();
      await initializeWindow(prefs);

      final lastRoute = prefs.getString(kLastRouteKey);
      final router = createRouter(
        initialLocation: kShellRoutePaths.contains(lastRoute)
            ? lastRoute!
            : kShellRoutePaths.first,
      );

      runApp(ProviderScope(child: VocabNoteApp(router: router)));
    },
    (error, stack) =>
        AppLogger.instance.error('Uncaught zone error', error, stack),
  );
}

class VocabNoteApp extends ConsumerWidget {
  const VocabNoteApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Legacy zoom parity: one persisted text scale applied app-wide.
    final textScale = ref.watch(appearanceControllerProvider).value ??
        kDefaultTextScale;

    // Card reading preferences (typography, spacing, zoom, pronunciation):
    // injected once here so every vocabulary card - list rows and settings
    // preview alike - restyles instantly when the user changes a setting.
    final cardStyle = ref.watch(cardStyleControllerProvider).value ??
        const VnCardStyle();

    return MaterialApp.router(
      title: 'VocabNote',
      debugShowCheckedModeBanner: false,
      theme: VnThemeFactory.light(),
      darkTheme: VnThemeFactory.dark(),
      // Same layout, stronger contrast tokens; served only when the OS
      // requests high contrast, so normal rendering is unchanged.
      highContrastTheme: VnThemeFactory.lightHighContrast(),
      highContrastDarkTheme: VnThemeFactory.darkHighContrast(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: VnCardStyleScope(
          style: cardStyle,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
