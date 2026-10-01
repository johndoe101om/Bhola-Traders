// lib/features/employees/widgets/workforce_dashboard_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/repositories/providers.dart';
import '../screens/attendance_screen.dart';

class WorkforceDashboardCard extends ConsumerWidget {
  const WorkforceDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todayWorkforceStatsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AttendanceScreen()));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.people_alt_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'आज का स्टाफ / Today\'s Workforce',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'हाजिरी भरें',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: AppTheme.primary),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              statsAsync.when(
                data: (stats) {
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCell(
                          title: 'कुल / Total',
                          value: '${stats.totalEmployees}',
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Expanded(
                        child: _StatCell(
                          title: 'उपस्थित / Present',
                          value: '${stats.presentCount}',
                          color: AppTheme.moneyIn,
                        ),
                      ),
                      Expanded(
                        child: _StatCell(
                          title: 'गैरहाजिर / Absent',
                          value: '${stats.absentCount}',
                          color: stats.absentCount > 0
                              ? AppTheme.moneyOut
                              : Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: _StatCell(
                          title: 'वेतन / Wages',
                          value: formatRupees(stats.totalWagesToday),
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                ),
                error: (_, __) => const Row(
                  children: [
                    Expanded(
                        child: _StatCell(
                            title: 'Total', value: '-', color: Colors.blue)),
                    Expanded(
                        child: _StatCell(
                            title: 'Present',
                            value: '-',
                            color: AppTheme.moneyIn)),
                    Expanded(
                        child: _StatCell(
                            title: 'Absent',
                            value: '-',
                            color: AppTheme.moneyOut)),
                    Expanded(
                        child: _StatCell(
                            title: 'Wages', value: '-', color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCell(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 3),
        Text(title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}
