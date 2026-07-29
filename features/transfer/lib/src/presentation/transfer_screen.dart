/// features/transfer/lib/src/presentation/transfer_screen.dart
///
/// The "Data" screen: import (legacy .db or CSV), export (JSON or CSV),
/// and local snapshot backups with restore. Pure presentation over
/// TransferController and backupsListProvider.
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/backup_service.dart';
import '../application/transfer_controller.dart';

class TransferScreen extends ConsumerWidget {
  const TransferScreen({super.key});

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _confirmRestore(
    BuildContext context,
    WidgetRef ref,
    BackupInfo backup,
  ) async {
    final confirmed = await showVnConfirmDialog(
      context,
      title: 'Restore this backup?',
      message: '${backup.fileName}\n\nYour current data will be replaced '
          'the next time VocabNote starts. This cannot be undone.',
      confirmLabel: 'Restore',
    );
    if (confirmed) {
      await ref
          .read(transferControllerProvider.notifier)
          .restoreBackup(backup);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferControllerProvider);
    final controller = ref.read(transferControllerProvider.notifier);
    final backups = ref.watch(backupsListProvider);
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(VnSpacing.x5),
          children: [
            if (state.busy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: VnSpacing.x4),
            ],
            if (state.message != null) ...[
              Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline,
                      color: tokens.accent),
                  title: Text(state.message!),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: controller.dismissMessage,
                  ),
                ),
              ),
              const SizedBox(height: VnSpacing.x4),
            ],
            if (state.error != null) ...[
              Card(
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: tokens.danger),
                  title: Text(state.error!),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: controller.dismissMessage,
                  ),
                ),
              ),
              const SizedBox(height: VnSpacing.x4),
            ],
            Text('Import', style: textTheme.titleMedium),
            const SizedBox(height: VnSpacing.x2),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(VnSpacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VocabNote 3.x (desktop) database',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: VnSpacing.x2),
                    Text(
                      'Bring over your old notebooks, words, Bangla meanings, '
                      'and favorites from vocab_notebook.db. Existing words '
                      'are never overwritten — duplicates are skipped.',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: tokens.textMuted),
                    ),
                    const SizedBox(height: VnSpacing.x4),
                    FilledButton.icon(
                      onPressed:
                          state.busy ? null : controller.importLegacyDatabase,
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('Choose .db file...'),
                    ),
                    const Divider(height: VnSpacing.x8),
                    Text('CSV spreadsheet', style: textTheme.titleSmall),
                    const SizedBox(height: VnSpacing.x2),
                    Text(
                      'Import words from a spreadsheet. Only a "headword" '
                      'column is required; other columns (notebook, meaning, '
                      'bangla_meaning, notes...) are optional. Duplicates are '
                      'skipped.',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: tokens.textMuted),
                    ),
                    const SizedBox(height: VnSpacing.x4),
                    FilledButton.tonalIcon(
                      onPressed: state.busy ? null : controller.importCsv,
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('Choose .csv file...'),
                    ),
                    const Divider(height: VnSpacing.x8),
                    Text('Word document (.docx)',
                        style: textTheme.titleSmall),
                    const SizedBox(height: VnSpacing.x2),
                    Text(
                      'Import words from a Word document: Heading 1 for '
                      'notebooks, Heading 2 for words, "Label: value" lines '
                      'for fields (the same layout the .docx export '
                      'produces), or plain "word - meaning" paragraphs. '
                      'Duplicates are skipped.',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: tokens.textMuted),
                    ),
                    const SizedBox(height: VnSpacing.x4),
                    FilledButton.tonalIcon(
                      onPressed: state.busy ? null : controller.importDocx,
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Choose .docx file...'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: VnSpacing.x6),
            Text('Export', style: textTheme.titleMedium),
            const SizedBox(height: VnSpacing.x2),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(VnSpacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Save a copy of everything',
                        style: textTheme.titleSmall),
                    const SizedBox(height: VnSpacing.x2),
                    Text(
                      'Every notebook and word — including Bangla '
                      'translations and notes — as a human-readable file.',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: tokens.textMuted),
                    ),
                    const SizedBox(height: VnSpacing.x4),
                    Wrap(
                      spacing: VnSpacing.x3,
                      runSpacing: VnSpacing.x2,
                      children: [
                        FilledButton.icon(
                          onPressed:
                              state.busy ? null : controller.exportJson,
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Export JSON...'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              state.busy ? null : controller.exportCsv,
                          icon: const Icon(Icons.table_chart_outlined),
                          label: const Text('Export CSV...'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              state.busy ? null : controller.exportMarkdown,
                          icon: const Icon(Icons.notes_outlined),
                          label: const Text('Export Markdown...'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              state.busy ? null : controller.exportAnki,
                          icon: const Icon(Icons.style_outlined),
                          label: const Text('Export Anki deck...'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              state.busy ? null : controller.exportDocx,
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Export Word (.docx)...'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: VnSpacing.x6),
            Text('Backups', style: textTheme.titleMedium),
            const SizedBox(height: VnSpacing.x2),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(VnSpacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Database snapshots', style: textTheme.titleSmall),
                    const SizedBox(height: VnSpacing.x2),
                    Text(
                      'Snapshots are stored on this device. The latest '
                      '$kMaxBackups are kept. Restoring replaces your data '
                      'on the next launch.',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: tokens.textMuted),
                    ),
                    const SizedBox(height: VnSpacing.x4),
                    FilledButton.icon(
                      onPressed: state.busy ? null : controller.backupNow,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Back up now'),
                    ),
                    const SizedBox(height: VnSpacing.x4),
                    switch (backups) {
                      AsyncData(:final value) when value.isEmpty => Text(
                          'No backups yet.',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: tokens.textMuted),
                        ),
                      AsyncData(:final value) => Column(
                          children: [
                            for (final backup in value)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.history),
                                title: Text(backup.fileName),
                                subtitle: Text(
                                  '${formatVnDateTime(backup.modifiedAt)} · '
                                  '${_formatSize(backup.sizeBytes)}',
                                ),
                                trailing: TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => _confirmRestore(
                                          context, ref, backup),
                                  child: const Text('Restore...'),
                                ),
                              ),
                          ],
                        ),
                      AsyncError() => Text(
                          'Could not read the backups folder.',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: tokens.danger),
                        ),
                      _ => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(VnSpacing.x3),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
