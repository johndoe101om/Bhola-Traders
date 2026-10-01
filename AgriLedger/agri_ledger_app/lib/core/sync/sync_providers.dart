// lib/core/sync/sync_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_engine.dart';
import '../../data/repositories/providers.dart';
import '../theme/app_theme.dart';

// ── PROVIDER ─────────────────────────────────────────────────────────

final syncEngineProvider = ChangeNotifierProvider<SyncEngine>((ref) {
  final repo = ref.watch(appRepositoryProvider);
  final engine = SyncEngine(repo: repo);
  ref.onDispose(engine.dispose);
  return engine;
});

// ── SYNC STATUS BAR WIDGET ────────────────────────────────────────────
// Drop this into any AppBar or screen to show live sync status

class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(syncEngineProvider);
    final state = engine.state;

    Color color;
    IconData icon;

    switch (state.status) {
      case SyncStatus.offline:
        color = Colors.orange[700]!;
        icon = Icons.cloud_off_rounded;
      case SyncStatus.syncing:
        color = Colors.blue[700]!;
        icon = Icons.sync_rounded;
      case SyncStatus.success:
        color = AppTheme.moneyIn;
        icon = Icons.cloud_done_rounded;
      case SyncStatus.failed:
        color = AppTheme.moneyOut;
        icon = Icons.cloud_off_rounded;
      case SyncStatus.idle:
        color = AppTheme.textSecondary;
        icon = Icons.cloud_queue_rounded;
    }

    return GestureDetector(
      onTap: () => engine.syncNow(force: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.status == SyncStatus.syncing)
              SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: color))
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              '${engine.statusTextHindi}  •  ${engine.statusText}',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
            if (state.pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                child: Text('${state.pendingCount} pending',
                  style: const TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── COMPACT SYNC ICON (for AppBar) ───────────────────────────────────

class SyncEngineIconButton extends ConsumerWidget {
  const SyncEngineIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(syncEngineProvider);
    final state = engine.state;

    IconData icon;
    Color color = Colors.white;

    switch (state.status) {
      case SyncStatus.offline:  icon = Icons.cloud_off_rounded;    color = Colors.orange[300]!;
      case SyncStatus.syncing:  icon = Icons.sync_rounded;
      case SyncStatus.success:  icon = Icons.cloud_done_rounded;
      case SyncStatus.failed:   icon = Icons.sync_problem_rounded; color = Colors.red[300]!;
      case SyncStatus.idle:     icon = Icons.cloud_sync_rounded;
    }

    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: state.status == SyncStatus.syncing
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, color: color),
          tooltip: engine.statusText,
          onPressed: () => engine.syncNow(force: true),
        ),
        if (state.pendingCount > 0)
          Positioned(
            top: 6, right: 6,
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(
                color: Colors.orange, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  state.pendingCount > 9 ? '9+' : '${state.pendingCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 9,
                    fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
