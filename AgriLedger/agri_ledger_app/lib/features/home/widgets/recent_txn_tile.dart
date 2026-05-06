// lib/features/home/widgets/recent_txn_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/local/local_database.dart';

class RecentTxnTile extends StatelessWidget {
  final TransactionsTableData txn;
  const RecentTxnTile({super.key, required this.txn});

  @override
  Widget build(BuildContext context) {
    final color = txnColor(txn.txnType);
    final isIn = txn.direction == 'in';
    final label = AppConstants.txnTypeLabels[txn.txnType]?.split('\n').last ?? txn.txnType;
    final emoji = commodityEmoji(txn.commodity);
    final dateStr = formatDate(DateTime.tryParse(txn.entryDate) ?? DateTime.now());
    final createdAt = tryParseDateTime(txn.createdAt);
    final timeStr = createdAt != null ? formatTime(createdAt) : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                txn.partyId, // Will be replaced with party name via join
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${isIn ? '+' : '-'}${formatRupees(txn.amount)}',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ),
            if (txn.commodity != null) ...[
              const SizedBox(width: 6),
              Text(txn.commodity!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
            if (txn.quantityKg != null) ...[
              const SizedBox(width: 4),
              Text(formatKg(txn.quantityKg!),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
            const Spacer(),
            Text('$dateStr${timeStr.isNotEmpty ? ', $timeStr' : ''}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            if (txn.syncedAt == null)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.cloud_off_rounded, size: 14, color: AppTheme.textHint),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// lib/features/home/widgets/sync_banner.dart
// ─────────────────────────────────────────────────────────────────────

class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(syncCountProvider);
    return countAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: Colors.orange[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: Colors.orange[700], size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count एंट्री sync बाकी है / $count entries pending sync',
                  style: TextStyle(fontSize: 14, color: Colors.orange[800], fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final repo = ref.read(appRepositoryProvider);
                  final result = await repo.syncNow();
                  if (context.mounted) {
                    if (result.success) {
                      showSuccess(context, '${result.pushed} entries synced!');
                    } else {
                      showError(context, result.message ?? 'Sync failed');
                    }
                  }
                },
                child: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Sync icon in AppBar
// ─────────────────────────────────────────────────────────────────────

class SyncIconButton extends ConsumerWidget {
  const SyncIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(syncCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.cloud_sync_rounded, color: Colors.white),
          onPressed: () async {
            final repo = ref.read(appRepositoryProvider);
            final result = await repo.syncNow();
            if (context.mounted) {
              if (result.success && result.pushed > 0) {
                showSuccess(context, '${result.pushed} entries synced!');
              } else if (!result.success) {
                showError(context, 'Offline — data saved locally');
              }
            }
          },
        ),
        if (count > 0)
          Positioned(
            top: 6, right: 6,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: Colors.orange[400],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }
}
