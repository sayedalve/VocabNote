/// core/design_system/lib/src/snackbar.dart
///
/// Shared snackbar helper so every feature surfaces feedback with identical
/// styling. Centralizing the error treatment (danger background + readable
/// foreground) removes per-screen copies that had already started to
/// drift apart.
library;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Shows an app-styled snackbar, replacing any snackbar currently shown.
///
/// [isError] applies the danger treatment from the active [VnTheme] tokens.
void showVnSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final tokens = VnTheme.of(context).tokens;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError ? TextStyle(color: tokens.onDanger) : null,
        ),
        backgroundColor: isError ? tokens.danger : null,
        duration: duration,
      ),
    );
}
