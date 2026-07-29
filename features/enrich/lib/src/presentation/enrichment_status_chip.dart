/// features/enrich/lib/src/presentation/enrichment_status_chip.dart
///
/// Compact queue status indicator for the app shell: shows pending count,
/// spinner while draining, and the stall reason (offline / missing key) with
/// a retry affordance.
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/enrichment_queue_controller.dart';

class EnrichmentStatusChip extends ConsumerWidget {
  const EnrichmentStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(enrichmentQueueControllerProvider);
    final tokens = VnTheme.of(context).tokens;

    if (queue.isIdle && queue.stallReason == null) {
      return const SizedBox.shrink();
    }

    final (label, icon) = switch (queue) {
      EnrichmentQueueState(:final stallReason?) => (
          stallReason,
          Icons.cloud_off,
        ),
      EnrichmentQueueState(isProcessing: true, :final pendingCount) => (
          'Enriching $pendingCount word${pendingCount == 1 ? '' : 's'}...',
          Icons.auto_awesome,
        ),
      EnrichmentQueueState(:final pendingCount) => (
          '$pendingCount word${pendingCount == 1 ? '' : 's'} waiting',
          Icons.schedule,
        ),
    };

    return Tooltip(
      message: 'Tap to retry now',
      child: ActionChip(
        avatar: queue.isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 16, color: tokens.textSecondary),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: () =>
            ref.read(enrichmentQueueControllerProvider.notifier).retryNow(),
      ),
    );
  }
}
