// lib/features/employees/screens/attendance_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/local_database.dart';
import '../../../data/repositories/providers.dart';
import 'attendance_screen.dart';

class AttendanceCalendarScreen extends ConsumerStatefulWidget {
  final String? initialEmployeeId;
  const AttendanceCalendarScreen({super.key, this.initialEmployeeId});

  @override
  ConsumerState<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  late DateTime _selectedMonth;
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _selectedEmployeeId = widget.initialEmployeeId;
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider(''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('हाजिरी कैलेंडर / Attendance Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
            tooltip: 'Mark Attendance',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Employee Filter & Month Navigator ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                // Employee dropdown selector
                employeesAsync.when(
                  data: (employees) {
                    if (employees.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedEmployeeId,
                          isExpanded: true,
                          hint: const Text('सभी कर्मचारी / All Employees'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('सभी कर्मचारी / All Employees',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            ...employees.map((e) => DropdownMenuItem<String?>(
                                  value: e.id,
                                  child: Row(
                                    children: [
                                      Text(e.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.primary.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          AppConstants.employeeTypeLabels[
                                                  e.employeeType] ??
                                              e.employeeType,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedEmployeeId = val);
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),

                // Month Navigator Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      onPressed: _prevMonth,
                    ),
                    Text(
                      _formatMonthYear(_selectedMonth),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Calendar Grid ──
          Expanded(
            child: _CalendarGrid(
              month: _selectedMonth,
              employeeId: _selectedEmployeeId,
            ),
          ),

          // ── Legend Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(color: AppTheme.moneyIn, label: 'उपस्थित (P)'),
                _LegendItem(color: AppTheme.moneyOut, label: 'गैरहाजिर (A)'),
                _LegendItem(color: Colors.orange, label: 'आधा दिन (H)'),
                _LegendItem(color: Colors.blue, label: 'ओवरटाइम (OT)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime d) {
    const months = [
      'January / जनवरी',
      'February / फ़रवरी',
      'March / मार्च',
      'April / अप्रैल',
      'May / मई',
      'June / जून',
      'July / जुलाई',
      'August / अगस्त',
      'September / सितंबर',
      'October / अक्टूबर',
      'November / नवंबर',
      'December / दिसंबर'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _CalendarGrid extends ConsumerWidget {
  final DateTime month;
  final String? employeeId;
  const _CalendarGrid({required this.month, this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appRepositoryProvider);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday =
        DateTime(month.year, month.month, 1).weekday % 7; // 0 = Sun, 1 = Mon...

    final fromStr =
        DateTime(month.year, month.month, 1).toIso8601String().substring(0, 10);
    final toStr = DateTime(month.year, month.month, daysInMonth)
        .toIso8601String()
        .substring(0, 10);

    return FutureBuilder<List<AttendancesTableData>>(
      future: repo.getAttendanceInRange(
        employeeId: employeeId,
        from: DateTime.parse(fromStr),
        to: DateTime.parse(toStr),
      ),
      builder: (context, snapshot) {
        final attendances = snapshot.data ?? [];

        // Group attendances by day
        final dayMap = <int, List<AttendancesTableData>>{};
        for (final a in attendances) {
          final day = int.tryParse(a.attendanceDate.split('-').last) ?? 0;
          if (day > 0) {
            dayMap.putIfAbsent(day, () => []).add(a);
          }
        }

        const weekdays = [
          'रवि / Su',
          'सोम / Mo',
          'मंगल / Tu',
          'बुध / We',
          'गुरु / Th',
          'शुक्र / Fr',
          'शनि / Sa'
        ];

        return Column(
          children: [
            // Weekday headers
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: weekdays
                    .map((w) => Expanded(
                          child: Text(
                            w,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: w.startsWith('रवि')
                                  ? Colors.red.shade400
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const Divider(height: 1),

            // Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: firstWeekday + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < firstWeekday) {
                    return const SizedBox.shrink();
                  }

                  final day = index - firstWeekday + 1;
                  final dayDate = DateTime(month.year, month.month, day);
                  final isToday = DateTime.now().year == dayDate.year &&
                      DateTime.now().month == dayDate.month &&
                      DateTime.now().day == dayDate.day;
                  final isSunday = dayDate.weekday == DateTime.sunday;
                  final isFuture = dayDate.isAfter(DateTime.now());

                  final dayRecords = dayMap[day] ?? [];

                  // Compute dominant color / badge
                  Color? badgeColor;
                  String? badgeText;

                  if (employeeId != null) {
                    // Single employee view
                    if (dayRecords.isNotEmpty) {
                      final att = dayRecords.first;
                      switch (att.status) {
                        case 'present':
                          badgeColor = AppTheme.moneyIn;
                          badgeText = 'P';
                          break;
                        case 'absent':
                          badgeColor = AppTheme.moneyOut;
                          badgeText = 'A';
                          break;
                        case 'half_day':
                          badgeColor = Colors.orange;
                          badgeText = 'H';
                          break;
                        case 'overtime':
                          badgeColor = Colors.blue;
                          badgeText = 'OT';
                          break;
                        case 'holiday':
                          badgeColor = Colors.purple;
                          badgeText = 'OFF';
                          break;
                      }
                    }
                  } else {
                    // Multi-employee aggregate view
                    if (dayRecords.isNotEmpty) {
                      final pCount =
                          dayRecords.where((a) => a.status == 'present').length;
                      final aCount =
                          dayRecords.where((a) => a.status == 'absent').length;
                      badgeColor = aCount > 0
                          ? (pCount > 0 ? Colors.orange : AppTheme.moneyOut)
                          : AppTheme.moneyIn;
                      badgeText = '$pCount P';
                    }
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        _showDayDetailSheet(context, dayDate, dayRecords),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppTheme.primary.withOpacity(0.08)
                            : (badgeColor != null
                                ? badgeColor.withOpacity(0.06)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isToday
                              ? AppTheme.primary
                              : (badgeColor != null
                                  ? badgeColor.withOpacity(0.3)
                                  : Colors.grey.shade200),
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isToday ? FontWeight.w900 : FontWeight.w600,
                              color: isSunday
                                  ? Colors.red.shade400
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (badgeColor != null && badgeText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (isFuture)
                            const Text('-',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.black26))
                          else if (isSunday)
                            const Text('Sun',
                                style: TextStyle(
                                    fontSize: 9, color: Colors.black38))
                          else
                            const Text('•',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDayDetailSheet(
      BuildContext context, DateTime date, List<AttendancesTableData> records) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final employeesAsync = ref.watch(employeesStreamProvider(''));

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'तारीख: ${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('हाजिरी भरें / Edit'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AttendanceScreen(initialDate: date)),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  if (records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'इस तारीख की कोई हाजिरी दर्ज नहीं है\nNo attendance marked for this date',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...records.map((r) {
                      final empName = employeesAsync.maybeWhen(
                        data: (list) =>
                            list
                                .where((e) => e.id == r.employeeId)
                                .firstOrNull
                                ?.name ??
                            'Employee',
                        orElse: () => 'Employee',
                      );

                      final isPresent = r.status == 'present';
                      final isAbsent = r.status == 'absent';
                      final color = isPresent
                          ? AppTheme.moneyIn
                          : (isAbsent ? AppTheme.moneyOut : Colors.orange);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                AppConstants.attendanceStatusLabels[r.status] ??
                                    r.status,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(empName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  if (r.absenceReason != null &&
                                      r.absenceReason!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'कारण: ${r.absenceReason}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
