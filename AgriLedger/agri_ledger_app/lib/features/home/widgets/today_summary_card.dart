// lib/features/home/widgets/today_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/repositories/providers.dart';

class TodaySummaryCard extends ConsumerWidget {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(todaySummaryProvider);
    final bagsAsync = ref.watch(totalOutstandingBagsProvider);

    return summaryAsync.when(
      loading: () => const _SummaryCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        final purchase = summary['purchase'] ?? 0;
        final cashIn = summary['cash_in'] ?? 0;
        final cashOut = summary['cash_out'] ?? 0;
        final net = summary['net'] ?? 0;
        final totalBags = bagsAsync.valueOrNull ?? 0;

        return Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Net balance row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: net >= 0
                      ? AppTheme.moneyIn.withOpacity(0.1)
                      : AppTheme.moneyOut.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('आज का नेट\nNet Today',
                        style: TextStyle(fontSize: 14, height: 1.3,
                          color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      Text(
                        formatRupees(net.abs()),
                        style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold,
                          color: net >= 0 ? AppTheme.moneyIn : AppTheme.moneyOut,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // 4-grid summary
                Row(
                  children: [
                    _SummaryCell('खरीदी\nPurchase', purchase, AppTheme.moneyOut, Icons.download_rounded),
                    _BagSummaryCell('कुल बोरी\nTotal Bags', totalBags, AppTheme.bagColor, Icons.inventory_2_rounded),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SummaryCell('पैसा मिला\nCash In', cashIn, AppTheme.moneyIn, Icons.add_circle_rounded),
                    _SummaryCell('पैसा दिया\nCash Out', cashOut, AppTheme.moneyOut, Icons.remove_circle_rounded),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCell(this.label, this.amount, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: const TextStyle(fontSize: 11, height: 1.2,
                      color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(formatRupees(amount),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BagSummaryCell extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _BagSummaryCell(this.label, this.count, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: const TextStyle(fontSize: 11, height: 1.2,
                      color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$count',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        height: 180,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
