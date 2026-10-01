// lib/features/employees/screens/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/local/local_database.dart';
import '../../../data/repositories/providers.dart';
import '../../../services/attendance_share_service.dart';
import '../widgets/voice_reason_field.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const AttendanceScreen({super.key, this.initialDate});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  late DateTime _date;
  bool _saving = false;

  // Local state for each employee on the selected date: employeeId -> _EmployeeAttendanceState
  final Map<String, _EmpAttState> _empStates = {};

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  void _syncStatesWithData(List<EmployeesTableData> employees,
      List<AttendancesTableData> attendances) {
    final attMap = {for (final a in attendances) a.employeeId: a};

    for (final emp in employees) {
      if (!_empStates.containsKey(emp.id)) {
        final existing = attMap[emp.id];
        _empStates[emp.id] = _EmpAttState(
          status: existing?.status ?? 'present',
          reasonController:
              TextEditingController(text: existing?.absenceReason ?? ''),
          overtimeHours: existing?.overtimeHours ?? 2.0,
        );
      }
    }
  }

  @override
  void dispose() {
    for (final state in _empStates.values) {
      state.reasonController.dispose();
    }
    super.dispose();
  }

  Future<void> _changeDate(DateTime newDate) async {
    for (final state in _empStates.values) {
      state.reasonController.dispose();
    }
    _empStates.clear();
    setState(() => _date = newDate);
  }

  Future<void> _saveAll(List<EmployeesTableData> employees) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(appRepositoryProvider);
      final items = <Map<String, dynamic>>[];

      for (final emp in employees) {
        final state = _empStates[emp.id];
        final status = state?.status ?? 'present';
        final reason = state?.reasonController.text.trim();
        final ot = state?.overtimeHours;

        items.add({
          'employeeId': emp.id,
          'status': status,
          'absenceReason': status == 'absent'
              ? (reason?.isNotEmpty == true ? reason : null)
              : null,
          'voiceRaw': status == 'absent'
              ? (reason?.isNotEmpty == true ? reason : null)
              : null,
          'overtimeHours': status == 'overtime' ? ot : null,
        });
      }

      await repo.bulkMarkAttendance(date: _date, items: items);
      if (mounted) {
        showSuccess(context, 'हाजिरी सेव हो गई / Attendance saved');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, 'त्रुटि / Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider(''));
    final attendanceAsync = ref.watch(attendanceForDateStreamProvider(_date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('हाजिरी भरें / Mark Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'हाजिरी रिपोर्ट शेयर करें / Share Report',
            onPressed: () {
              final emps = employeesAsync.valueOrNull ?? [];
              if (emps.isEmpty) return;
              final statusMap = {
                for (final e in emps) e.id: _empStates[e.id]?.status ?? 'present'
              };
              final reasonMap = {
                for (final e in emps)
                  e.id: _empStates[e.id]?.reasonController.text ?? ''
              };
              final otMap = {
                for (final e in emps)
                  e.id: _empStates[e.id]?.overtimeHours ?? 2.0
              };
              AttendanceShareService.showShareTeamSummaryDialog(
                context: context,
                employees: emps,
                statusMap: statusMap,
                reasonMap: reasonMap,
                otMap: otMap,
                date: _date,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: Colors.white),
            tooltip: 'Change Date',
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (d != null) _changeDate(d);
            },
          ),
        ],
      ),
      body: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('👥', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'कोई कर्मचारी नहीं मिला\nNo active employees found',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return attendanceAsync.when(
            data: (attendances) {
              _syncStatesWithData(employees, attendances);

              // Calculate summary stats
              int presentCount = 0;
              int absentCount = 0;
              int halfDayCount = 0;
              int otCount = 0;
              double wagesToday = 0.0;

              for (final emp in employees) {
                final state = _empStates[emp.id];
                final status = state?.status ?? 'present';
                switch (status) {
                  case 'present':
                    presentCount++;
                    wagesToday += emp.dailyWageRate;
                    break;
                  case 'absent':
                    absentCount++;
                    break;
                  case 'half_day':
                    halfDayCount++;
                    wagesToday += (emp.dailyWageRate * 0.5);
                    break;
                  case 'overtime':
                    otCount++;
                    final ot = state?.overtimeHours ?? 2.0;
                    final hourly = emp.dailyWageRate > 0
                        ? (emp.dailyWageRate / 8.0) * 1.5
                        : 0.0;
                    wagesToday += emp.dailyWageRate + (ot * hourly);
                    break;
                }
              }

              return Column(
                children: [
                  // ── Date & Summary Banner ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event,
                                    color: AppTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'तारीख: ${_date.day}/${_date.month}/${_date.year}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'वेतन: ${formatRupees(wagesToday)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _QuickStat(
                                count: presentCount,
                                label: 'उपस्थित (P)',
                                color: AppTheme.moneyIn),
                            _QuickStat(
                                count: absentCount,
                                label: 'गैरहाजिर (A)',
                                color: AppTheme.moneyOut),
                            _QuickStat(
                                count: halfDayCount,
                                label: 'आधा दिन (H)',
                                color: Colors.orange),
                            _QuickStat(
                                count: otCount,
                                label: 'ओवरटाइम (OT)',
                                color: Colors.blue),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Quick Share Button for Daily Summary
                        InkWell(
                          onTap: () {
                            final statusMap = {
                              for (final e in employees)
                                e.id: _empStates[e.id]?.status ?? 'present'
                            };
                            final reasonMap = {
                              for (final e in employees)
                                e.id: _empStates[e.id]?.reasonController.text ?? ''
                            };
                            final otMap = {
                              for (final e in employees)
                                e.id: _empStates[e.id]?.overtimeHours ?? 2.0
                            };
                            AttendanceShareService.showShareTeamSummaryDialog(
                              context: context,
                              employees: employees,
                              statusMap: statusMap,
                              reasonMap: reasonMap,
                              otMap: otMap,
                              date: _date,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.share,
                                    size: 15, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 6),
                                Text(
                                  'आज की पूरी हाजिरी रिपोर्ट शेयर करें (WhatsApp / SMS)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // ── Employee Attendance Rows ──
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final emp = employees[index];
                        final state = _empStates[emp.id] ??
                            _EmpAttState(
                              status: 'present',
                              reasonController: TextEditingController(),
                            );

                        return _EmployeeAttendanceCard(
                          employee: emp,
                          state: state,
                          date: _date,
                          onStatusChanged: (newStatus) {
                            setState(() {
                              state.status = newStatus;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error loading attendance: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saving
                ? null
                : () {
                    final emps = employeesAsync.valueOrNull ?? [];
                    if (emps.isNotEmpty) _saveAll(emps);
                  },
            child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text(
                    'सभी हाजिरी सेव करें / Save All Attendance',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmpAttState {
  String status;
  final TextEditingController reasonController;
  double overtimeHours;

  _EmpAttState({
    required this.status,
    required this.reasonController,
    this.overtimeHours = 2.0,
  });
}

class _QuickStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _QuickStat(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _EmployeeAttendanceCard extends StatelessWidget {
  final EmployeesTableData employee;
  final _EmpAttState state;
  final DateTime date;
  final ValueChanged<String> onStatusChanged;

  const _EmployeeAttendanceCard({
    required this.employee,
    required this.state,
    required this.date,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAbsent = state.status == 'absent';
    final isPresent = state.status == 'present';
    final isHalfDay = state.status == 'half_day';
    final isOvertime = state.status == 'overtime';

    Color cardBorder = Colors.grey.shade200;
    if (isPresent) cardBorder = AppTheme.moneyIn.withOpacity(0.3);
    if (isAbsent) cardBorder = AppTheme.moneyOut.withOpacity(0.3);
    if (isHalfDay) cardBorder = Colors.orange.withOpacity(0.3);
    if (isOvertime) cardBorder = Colors.blue.withOpacity(0.3);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorder, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Header with Quick WhatsApp & SMS share
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    employee.name.isNotEmpty
                        ? employee.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '₹${employee.dailyWageRate.toStringAsFixed(0)}/दिन • ${AppConstants.employeeTypeLabels[employee.employeeType] ?? employee.employeeType}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Quick WhatsApp Share Button
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      size: 20, color: Color(0xFF25D366)),
                  tooltip: 'WhatsApp पर पर्ची भेजें',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    AttendanceShareService.showShareIndividualDialog(
                      context: context,
                      employee: employee,
                      status: state.status,
                      date: date,
                      absenceReason: state.reasonController.text.trim().isNotEmpty
                          ? state.reasonController.text.trim()
                          : null,
                      overtimeHours: state.status == 'overtime'
                          ? state.overtimeHours
                          : null,
                    );
                  },
                ),
                // Quick SMS / Message Share Button
                IconButton(
                  icon: Icon(Icons.sms_outlined,
                      size: 20, color: Colors.blue.shade700),
                  tooltip: 'SMS संदेश भेजें',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    AttendanceShareService.showShareIndividualDialog(
                      context: context,
                      employee: employee,
                      status: state.status,
                      date: date,
                      absenceReason: state.reasonController.text.trim().isNotEmpty
                          ? state.reasonController.text.trim()
                          : null,
                      overtimeHours: state.status == 'overtime'
                          ? state.overtimeHours
                          : null,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 4 Status Action Buttons
            Row(
              children: [
                _StatusButton(
                  label: 'P • उपस्थित',
                  selected: isPresent,
                  activeColor: AppTheme.moneyIn,
                  onTap: () => onStatusChanged('present'),
                ),
                const SizedBox(width: 6),
                _StatusButton(
                  label: 'A • गैरहाजिर',
                  selected: isAbsent,
                  activeColor: AppTheme.moneyOut,
                  onTap: () => onStatusChanged('absent'),
                ),
                const SizedBox(width: 6),
                _StatusButton(
                  label: 'H • आधा',
                  selected: isHalfDay,
                  activeColor: Colors.orange,
                  onTap: () => onStatusChanged('half_day'),
                ),
                const SizedBox(width: 6),
                _StatusButton(
                  label: 'OT • ओवरटाइम',
                  selected: isOvertime,
                  activeColor: Colors.blue,
                  onTap: () => onStatusChanged('overtime'),
                ),
              ],
            ),

            // Voice Reason Area for Absence
            if (isAbsent) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'अनुपस्थिति का कारण / Absence Reason (माइक दबाकर बोलें):',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    const SizedBox(height: 6),
                    VoiceReasonField(
                      controller: state.reasonController,
                      labelText: 'कारण लिखें या बोलें / Reason',
                      hintText: 'e.g. बीमार था, गाँव गया है...',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],

            // Overtime hours input
            if (isOvertime) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('अतिरिक्त घंटे / Overtime Hours:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    DropdownButton<double>(
                      value: state.overtimeHours,
                      items: const [
                        DropdownMenuItem(
                            value: 1.0, child: Text('1 घंटा / hr')),
                        DropdownMenuItem(
                            value: 2.0, child: Text('2 घंटे / hrs')),
                        DropdownMenuItem(
                            value: 3.0, child: Text('3 घंटे / hrs')),
                        DropdownMenuItem(
                            value: 4.0, child: Text('4 घंटे / hrs')),
                      ],
                      onChanged: (v) {
                        if (v != null) state.overtimeHours = v;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? activeColor : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
