/// app/lib/shell/quick_add_dialog.dart
///
/// Global quick-add dialog, reachable from anywhere via Ctrl+N. Stays open
/// for rapid multi-word entry: Enter adds a word and keeps focus, Esc (or
/// Done) closes.
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:feature_enrich/feature_enrich.dart';
import 'package:flutter/material.dart';

Future<void> showQuickAddWordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const QuickAddWordDialog(),
  );
}

class QuickAddWordDialog extends StatelessWidget {
  const QuickAddWordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Add words'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CaptureInput(autofocus: true, scope: CaptureScope.dialog),
            const SizedBox(height: VnSpacing.x3),
            Text(
              'Press Enter to add each word \u2014 AI fills in the card in '
              'the background. Press Esc when you are done.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
