/// core/design_system/lib/src/confirm_dialog.dart
///
/// The one confirmation dialog. Renders exactly the AlertDialog pattern the
/// app previously duplicated in hand-rolled copies (TextButton cancel +
/// FilledButton confirm) and standardizes keyboard behavior:
///  * Enter confirms (the FilledButton is autofocused),
///  * Esc cancels (Flutter's built-in dialog dismissal).
library;

import 'package:flutter/material.dart';

/// Shows a confirmation dialog; resolves to true only on explicit confirm.
Future<bool> showVnConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          // Enter-to-confirm: previously these dialogs had no default
          // action, so Enter did nothing.
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
