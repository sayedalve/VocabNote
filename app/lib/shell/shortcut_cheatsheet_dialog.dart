/// app/lib/shell/shortcut_cheatsheet_dialog.dart
///
/// Ctrl+/ overlay: the exact shortcuts card the Help section renders,
/// wrapped in the app's standard AlertDialog chrome. Reusing [ShortcutsCard]
/// means the overlay and the Help page can never disagree. Esc dismisses
/// (built-in dialog behavior); Enter closes via the autofocused button.
library;

import 'package:flutter/material.dart';

import 'help_tab.dart';

Future<void> showShortcutCheatsheetDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Keyboard shortcuts'),
      content: const SizedBox(
        width: 520,
        child: SingleChildScrollView(child: ShortcutsCard()),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
