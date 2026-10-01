// lib/features/home/widgets/sync_banner.dart
// ─────────────────────────────────────────────────────────────────────
// Shows sync status banner when there are pending offline items
// Drop into any screen's Column children

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_providers.dart';

class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(syncEngineProvider);
    final state = engine.state;

    // Only show banner when there are pending items
    if (state.pendingCount == 0) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color iconColor;
    IconData icon;
    String message;

    switch (state.status) {
      case SyncStatus.syncing:
        bgColor = Colors.blue[50]!;
        iconColor = Colors.blue[700]!;
        icon = Icons.sync_rounded;
        message = 'सिंक हो रहा है... • Syncing...';
      case SyncStatus.failed:
        bgColor = Colors.red[50]!;
        iconColor = Colors.red[700]!;
        icon = Icons.sync_problem_rounded;
        message = 'सिंक फ़ैल • Sync failed';
      case SyncStatus.offline:
        bgColor = Colors.orange[50]!;
        iconColor = Colors.orange[700]!;
        icon = Icons.cloud_off_rounded;
        message = 'ऑफ़लाइन • Offline';
      default:
        bgColor = Colors.orange[50]!;
        iconColor = Colors.orange[700]!;
        icon = Icons.cloud_queue_rounded;
        message = '${state.pendingCount} pending • ${state.pendingCount} बाकी';
    }

    return GestureDetector(
      onTap: () => engine.syncNow(force: true),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            state.status == SyncStatus.syncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: iconColor))
                : Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'टैप करें • Tap to sync',
              style: TextStyle(
                color: iconColor.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
