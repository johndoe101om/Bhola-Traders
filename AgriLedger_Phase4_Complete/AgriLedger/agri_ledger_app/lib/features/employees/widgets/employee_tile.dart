// lib/features/employees/widgets/employee_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/local/local_database.dart';
import '../../../data/repositories/providers.dart';
import '../screens/add_employee_screen.dart';
import '../screens/attendance_calendar_screen.dart';
import '../screens/employee_detail_screen.dart';
import '../screens/employee_payment_screen.dart';

class EmployeeTile extends ConsumerWidget {
  final EmployeesTableData employee;
  final VoidCallback? onRefresh;

  const EmployeeTile({super.key, required this.employee, this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeDetailScreen(employeeId: employee.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    employee.name.isNotEmpty
                        ? employee.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name + Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    if (employee.phone != null && employee.phone!.isNotEmpty)
                      Text(
                        employee.phone!,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppConstants.employeeTypeLabels[
                                    employee.employeeType] ??
                                employee.employeeType,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (employee.teamGroup != null &&
                            employee.teamGroup!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              employee.teamGroup!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Wage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupees(employee.dailyWageRate),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.moneyIn),
                  ),
                  const Text('प्रति दिन / Day',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary)),
                ],
              ),

              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.textHint),
                onSelected: (val) async {
                  if (val == 'detail') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EmployeeDetailScreen(employeeId: employee.id),
                      ),
                    );
                  } else if (val == 'attendance') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceCalendarScreen(
                            initialEmployeeId: employee.id),
                      ),
                    );
                  } else if (val == 'pay') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeePaymentScreen(
                            initialEmployeeId: employee.id),
                      ),
                    );
                  } else if (val == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEmployeeScreen(employeeTableData: employee),
                      ),
                    );
                  } else if (val == 'delete') {
                    final confirm = await confirmDialog(
                      context,
                      title: 'हटाएं? / Delete?',
                      message:
                          'क्या आप वाकई ${employee.name} को हटाना चाहते हैं?',
                    );
                    if (confirm) {
                      await ref
                          .read(appRepositoryProvider)
                          .deleteEmployee(employee.id);
                      if (context.mounted) {
                        showSuccess(context, 'हटा दिया गया / Deleted');
                      }
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'detail', child: Text('विवरण / Details')),
                  PopupMenuItem(
                      value: 'attendance',
                      child: Text('हाजिरी कैलेंडर / Attendance')),
                  PopupMenuItem(
                      value: 'pay',
                      child: Text('भुगतान दर्ज करें / Record Payment')),
                  PopupMenuItem(value: 'edit', child: Text('एडिट करें / Edit')),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('हटाएं / Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
