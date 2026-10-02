// lib/features/employees/screens/employee_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/voice_text_field.dart';
import '../../../data/local/local_database.dart';
import '../../../data/repositories/providers.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/attendance_share_service.dart';
import '../../receipts/screens/printer_setup_screen.dart';
import 'add_employee_screen.dart';
import 'attendance_calendar_screen.dart';
import 'employee_payment_screen.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final String employeeId;
  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPayslipDialog(BuildContext context, EmployeesTableData employee) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'वेतन पर्ची अवधि / Payslip Period',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.calendar_today, color: AppTheme.primary),
                title: const Text('इस महीने का हिसाब / This Month'),
                subtitle:
                    Text('${DateTime.now().month}/${DateTime.now().year}'),
                onTap: () {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  final from = DateTime(now.year, now.month, 1);
                  final to = DateTime(now.year, now.month + 1, 0);
                  _generateAndPrintPayslip(context, employee, from, to);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('पिछले महीने का हिसाब / Last Month'),
                subtitle: Text(
                    '${DateTime.now().month == 1 ? 12 : DateTime.now().month - 1}/${DateTime.now().month == 1 ? DateTime.now().year - 1 : DateTime.now().year}'),
                onTap: () {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  final from = DateTime(now.year, now.month - 1, 1);
                  final to = DateTime(now.year, now.month, 0);
                  _generateAndPrintPayslip(context, employee, from, to);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.green),
                title: const Text('कस्टम तारीख / Custom Date Range'),
                subtitle: const Text('शुरू और अंतिम तारीख चुनें'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    initialDateRange: DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 30)),
                      end: DateTime.now(),
                    ),
                  );
                  if (range != null && context.mounted) {
                    _generateAndPrintPayslip(
                        context, employee, range.start, range.end);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareWorkerSummaryDialog(
    BuildContext context,
    EmployeesTableData employee,
    Map<String, dynamic>? ledger,
  ) {
    final earned = (ledger?['grossEarned'] ?? 0.0) as double;
    final paid = (ledger?['totalPaid'] ?? 0.0) as double;
    final balance = (ledger?['balance'] ?? 0.0) as double;
    final daysPresent = ledger?['daysPresent'] ?? 0;
    final halfDays = ledger?['halfDays'] ?? 0;

    final buffer = StringBuffer();
    buffer.writeln('🌾 *भोला ट्रेडर्स / BHOLA TRADERS* 🌾');
    buffer.writeln('📋 *कर्मचारी खाता व हाजिरी विवरण*');
    buffer.writeln('--------------------------------');
    buffer.writeln('👤 *नाम:* ${employee.name}');
    if (employee.phone != null && employee.phone!.isNotEmpty) {
      buffer.writeln('📞 *फ़ोन:* ${employee.phone}');
    }
    buffer.writeln(
        '💰 *दैनिक वेतन दर:* ₹${employee.dailyWageRate.toStringAsFixed(0)}/दिन');
    buffer.writeln('--------------------------------');
    buffer.writeln('📊 *हाजिरी सारांश:*');
    buffer.writeln('✅ उपस्थित दिन: $daysPresent');
    if (halfDays > 0) buffer.writeln('⏳ आधा दिन: $halfDays');
    buffer.writeln('💵 कुल अर्जित वेतन: ₹${earned.toStringAsFixed(0)}');
    buffer.writeln('💸 दिया गया भुगतान: ₹${paid.toStringAsFixed(0)}');
    buffer.writeln('--------------------------------');
    if (balance > 0) {
      buffer.writeln('📌 *बकाया देना है (Due):* ₹${balance.toStringAsFixed(0)}');
    } else if (balance < 0) {
      buffer.writeln(
          '📌 *एडवांस बाकी है (Advance):* ₹${balance.abs().toStringAsFixed(0)}');
    } else {
      buffer.writeln('📌 *हिसाब बराबर (Settled)*');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('भोला ट्रेडर्स  (विश्वकर्मा चौक)');
    buffer.write('📞 +91 9582863135     किसी भी प्रश्न के लिए संपर्क करें।');

    final message = buffer.toString();
    final phone = employee.phone;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'खाता विवरण शेयर करें / Share Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                '${employee.name} ${phone != null ? '($phone)' : ''}',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(
                        fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('WhatsApp',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        AttendanceShareService.sendViaWhatsApp(
                            phone: phone, message: message);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.sms_outlined, size: 18),
                      label: const Text('SMS / संदेश',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        AttendanceShareService.sendViaSms(
                            phone: phone, message: message);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('अन्य ऐप में भेजें / Other Apps',
                      style: TextStyle(fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.share(message);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndPrintPayslip(
    BuildContext context,
    EmployeesTableData employee,
    DateTime from,
    DateTime to,
  ) async {
    showLoadingDialog(context,
        message: 'पर्ची तैयार हो रही है / Generating Payslip...');
    try {
      final repo = ref.read(appRepositoryProvider);
      final attendances = await repo.getAttendanceInRange(
          employeeId: employee.id, from: from, to: to);
      final payments =
          await repo.getPaymentsForEmployee(employee.id, from: from, to: to);

      final printer = ref.read(thermalPrinterProvider);
      final printService = PrintService(thermalPrinter: printer);

      if (context.mounted) {
        Navigator.pop(context); // close loading

        if (printer.isConnected) {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (bCtx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('प्रिंट विकल्प / Print Option',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.print, color: AppTheme.primary),
                      title: const Text(
                          'थर्मल प्रिंटर पर्ची (58mm) / Thermal Slip'),
                      subtitle:
                          const Text('ब्लूटूथ प्रिंटर से तुरंत पर्ची निकालें'),
                      onTap: () async {
                        Navigator.pop(bCtx);
                        final ok =
                            await printService.printEmployeePayslipThermal(
                          employee: employee,
                          attendances: attendances,
                          payments: payments,
                          from: from,
                          to: to,
                        );
                        if (context.mounted) {
                          if (ok) {
                            showSuccess(context,
                                'थर्मल पर्ची प्रिंट हो गई / Payslip Printed!');
                          } else {
                            showError(
                                context, 'प्रिंट विफल रहा / Print failed');
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: const Text('A4 PDF / WhatsApp पर्ची'),
                      subtitle:
                          const Text('व्हाट्सएप पर भेजें या PDF सेव करें'),
                      onTap: () async {
                        Navigator.pop(bCtx);
                        await printService.printEmployeePayslip(
                          context: context,
                          employee: employee,
                          attendances: attendances,
                          payments: payments,
                          from: from,
                          to: to,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          await printService.printEmployeePayslip(
            context: context,
            employee: employee,
            attendances: attendances,
            payments: payments,
            from: from,
            to: to,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading
        showError(context, 'Error generating payslip: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider(''));
    final ledgerAsync = ref.watch(employeeLedgerProvider(widget.employeeId));

    final employee = employeesAsync.maybeWhen(
      data: (list) => list.where((e) => e.id == widget.employeeId).firstOrNull,
      orElse: () => null,
    );

    if (employee == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('स्टाफ विवरण / Employee Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(employee.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
            tooltip: 'वेतन पर्ची / Payslip',
            onPressed: () => _showPayslipDialog(context, employee),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            tooltip: 'Attendance Calendar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AttendanceCalendarScreen(initialEmployeeId: employee.id),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddEmployeeScreen(employeeTableData: employee)),
              );
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Employee Profile Card ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primary.withOpacity(0.12),
                            child: Text(
                              employee.name.isNotEmpty
                                  ? employee.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        employee.name,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        AppConstants.employeeTypeLabels[
                                                employee.employeeType] ??
                                            employee.employeeType,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (employee.phone != null &&
                                    employee.phone!.isNotEmpty)
                                  Text(
                                    '📞 ${employee.phone}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  'दैनिक वेतन: ₹${employee.dailyWageRate.toStringAsFixed(0)} / दिन',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Quick Action Row (WhatsApp, Pay)
                      Row(
                        children: [
                          if (employee.phone != null &&
                              employee.phone!.isNotEmpty) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.share,
                                    size: 16, color: Color(0xFF25D366)),
                                label: const Text('WhatsApp / SMS',
                                    style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  _showShareWorkerSummaryDialog(
                                      context, employee, ledgerAsync.valueOrNull);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text('भुगतान / Pay',
                                  style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EmployeePaymentScreen(
                                        initialEmployeeId: employee.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Financial Ledger Summary Card ──
                ledgerAsync.when(
                  data: (data) {
                    final earned = (data['grossEarned'] ?? 0.0) as double;
                    final paid = (data['totalPaid'] ?? 0.0) as double;
                    final balance = (data['balance'] ?? 0.0) as double;
                    final daysPresent = data['daysPresent'] ?? 0;
                    final halfDays = data['halfDays'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('कुल बकाया वेतन / Balance Due',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary)),
                              Text(
                                formatRupees(balance.abs()),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: balance > 0
                                      ? AppTheme.moneyOut
                                      : (balance < 0
                                          ? Colors.blue
                                          : AppTheme.moneyIn),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              _LedgerMetric(
                                  label: 'हाजिरी / Days',
                                  value: '$daysPresent P + $halfDays H'),
                              _LedgerMetric(
                                  label: 'कुल कमाई / Earned',
                                  value: formatRupees(earned),
                                  color: AppTheme.moneyIn),
                              _LedgerMetric(
                                  label: 'कुल भुगतान / Paid',
                                  value: formatRupees(paid),
                                  color: Colors.blue.shade700),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.receipt_long_rounded,
                                      size: 16),
                                  label: const Text('वेतन पर्ची / Payslip',
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: () =>
                                      _showPayslipDialog(context, employee),
                                ),
                              ),
                              if (balance > 0) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.moneyOut,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.check_circle_outline,
                                        size: 16),
                                    label: const Text('हिसाब चुकता / Settle',
                                        style: TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EmployeePaymentScreen(
                                            initialEmployeeId: employee.id,
                                            initialAmount: balance,
                                            initialType: 'settlement',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                tabs: const [
                  Tab(text: 'हाजिरी / Attendance'),
                  Tab(text: 'भुगतान / Payments'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 1: Attendance List ──
            _EmployeeAttendanceTab(employeeId: employee.id),

            // ── Tab 2: Payments List ──
            _EmployeePaymentsTab(employeeId: employee.id),
          ],
        ),
      ),
    );
  }
}

class _LedgerMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _LedgerMetric({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color ?? AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _EmployeeAttendanceTab extends ConsumerWidget {
  final String employeeId;
  const _EmployeeAttendanceTab({required this.employeeId});

  void _showAttendanceActions(
    BuildContext context,
    WidgetRef ref,
    AttendancesTableData record,
  ) {
    final employeesAsync = ref.read(employeesStreamProvider(''));
    final employee = employeesAsync.maybeWhen(
      data: (list) => list.where((e) => e.id == employeeId).firstOrNull,
      orElse: () => null,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '${record.attendanceDate} — ${AppConstants.attendanceStatusLabels[record.status] ?? record.status}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
                title: const Text('बदलें / Edit',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('हाजिरी स्थिति बदलें'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditAttendanceDialog(context, ref, record);
                },
              ),
              ListTile(
                leading: Icon(Icons.share_rounded, color: Colors.blue.shade700),
                title: const Text('शेयर करें / Share',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('WhatsApp / SMS से भेजें'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (employee != null) {
                    final date = DateTime.tryParse(record.attendanceDate) ??
                        DateTime.now();
                    AttendanceShareService.showShareIndividualDialog(
                      context: context,
                      employee: employee,
                      status: record.status,
                      date: date,
                      absenceReason: record.absenceReason,
                      overtimeHours: record.overtimeHours,
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('हटाएं / Delete',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.red)),
                subtitle: const Text('यह हाजिरी रिकॉर्ड हटाएं'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await confirmDialog(
                    context,
                    title: 'हाजिरी हटाएं? / Delete Attendance?',
                    message:
                        '${record.attendanceDate} की हाजिरी हटा दी जाएगी। यह कार्य वापस नहीं होगा।\n\nAttendance for ${record.attendanceDate} will be deleted permanently.',
                  );
                  if (ok && context.mounted) {
                    try {
                      await ref
                          .read(appRepositoryProvider)
                          .deleteAttendance(record.id);
                      if (context.mounted) {
                        showSuccess(context, 'हाजिरी हटा दी गई / Attendance deleted');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showError(context, 'हटाने में त्रुटि / Delete failed');
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAttendanceDialog(
    BuildContext context,
    WidgetRef ref,
    AttendancesTableData record,
  ) {
    String selectedStatus = record.status;
    final reasonCtrl =
        TextEditingController(text: record.absenceReason ?? '');
    double otHours = record.overtimeHours ?? 2.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'हाजिरी बदलें / Edit (${record.attendanceDate})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final status in ['present', 'absent', 'half_day', 'overtime'])
                      ChoiceChip(
                        label: Text(
                          AppConstants.attendanceStatusLabels[status] ?? status,
                          style: TextStyle(
                            fontSize: 13,
                            color: selectedStatus == status
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                        selected: selectedStatus == status,
                        selectedColor: AppTheme.primary,
                        onSelected: (sel) {
                          if (sel) {
                            setModalState(() => selectedStatus = status);
                          }
                        },
                      ),
                  ],
                ),
                if (selectedStatus == 'absent') ...[
                  const SizedBox(height: 12),
                  VoiceTextFormField(
                    controller: reasonCtrl,
                    labelText: 'कारण / Reason',
                    hintText: 'अनुपस्थिति का कारण',
                  ),
                ],
                if (selectedStatus == 'overtime') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('OT घंटे: ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Slider(
                          value: otHours,
                          min: 0.5,
                          max: 8.0,
                          divisions: 15,
                          label: '${otHours.toStringAsFixed(1)}h',
                          onChanged: (v) =>
                              setModalState(() => otHours = v),
                        ),
                      ),
                      Text('${otHours.toStringAsFixed(1)}h',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('सेव करें / Save',
                        style: TextStyle(fontSize: 15)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final date =
                            DateTime.tryParse(record.attendanceDate) ??
                                DateTime.now();
                        await ref.read(appRepositoryProvider).markAttendance(
                              employeeId: employeeId,
                              date: date,
                              status: selectedStatus,
                              absenceReason: selectedStatus == 'absent'
                                  ? reasonCtrl.text.trim()
                                  : null,
                              overtimeHours: selectedStatus == 'overtime'
                                  ? otHours
                                  : null,
                            );
                        if (context.mounted) {
                          showSuccess(context,
                              'हाजिरी अपडेट हो गई / Attendance updated');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showError(context,
                              'अपडेट में त्रुटि / Update failed');
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareAttendanceRecord(
    BuildContext context,
    WidgetRef ref,
    AttendancesTableData record,
  ) {
    final employeesAsync = ref.read(employeesStreamProvider(''));
    final employee = employeesAsync.maybeWhen(
      data: (list) => list.where((e) => e.id == employeeId).firstOrNull,
      orElse: () => null,
    );
    if (employee != null) {
      final date =
          DateTime.tryParse(record.attendanceDate) ?? DateTime.now();
      AttendanceShareService.showShareIndividualDialog(
        context: context,
        employee: employee,
        status: record.status,
        date: date,
        absenceReason: record.absenceReason,
        overtimeHours: record.overtimeHours,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync =
        ref.watch(employeeAttendanceStreamProvider(employeeId));

    return attendanceAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Text(
              'कोई हाजिरी दर्ज नहीं है\nNo attendance records yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final r = records[index];
            final isPresent = r.status == 'present';
            final isAbsent = r.status == 'absent';
            final color = isPresent
                ? AppTheme.moneyIn
                : (isAbsent ? AppTheme.moneyOut : Colors.orange);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showAttendanceActions(context, ref, r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isPresent
                              ? 'P'
                              : (isAbsent
                                  ? 'A'
                                  : (r.status == 'half_day' ? 'H' : 'OT')),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.attendanceDate,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppConstants.attendanceStatusLabels[r.status] ??
                                  r.status,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r.status == 'present'
                                ? 'पूरा दिन'
                                : (r.status == 'half_day' ? '0.5 दिन' : ''),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () =>
                                _shareAttendanceRecord(context, ref, r),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.share_rounded,
                                  size: 16, color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _EmployeePaymentsTab extends ConsumerWidget {
  final String employeeId;
  const _EmployeePaymentsTab({required this.employeeId});

  void _showPaymentActions(
    BuildContext context,
    WidgetRef ref,
    EmployeePaymentsTableData payment,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '${formatRupees(payment.amount)} — ${payment.paymentDate}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${payment.paymentMode.toUpperCase()} • ${AppConstants.employeePaymentTypeLabels[payment.paymentType] ?? payment.paymentType}',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
                title: const Text('बदलें / Edit',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('भुगतान विवरण बदलें'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditPaymentDialog(context, ref, payment);
                },
              ),
              ListTile(
                leading: Icon(Icons.share_rounded, color: Colors.blue.shade700),
                title: const Text('शेयर करें / Share',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('WhatsApp / SMS से भेजें'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sharePaymentRecord(context, ref, payment);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('हटाएं / Delete',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.red)),
                subtitle: const Text('यह भुगतान रिकॉर्ड हटाएं'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await confirmDialog(
                    context,
                    title: 'भुगतान हटाएं? / Delete Payment?',
                    message:
                        '${formatRupees(payment.amount)} (${payment.paymentDate}) का भुगतान हटा दिया जाएगा। यह कार्य वापस नहीं होगा।\n\nPayment of ${formatRupees(payment.amount)} on ${payment.paymentDate} will be deleted permanently.',
                  );
                  if (ok && context.mounted) {
                    try {
                      await ref
                          .read(appRepositoryProvider)
                          .deleteEmployeePayment(payment.id);
                      if (context.mounted) {
                        showSuccess(
                            context, 'भुगतान हटा दिया गया / Payment deleted');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showError(context, 'हटाने में त्रुटि / Delete failed');
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    EmployeePaymentsTableData payment,
  ) {
    final amountCtrl =
        TextEditingController(text: payment.amount.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: payment.notes ?? '');
    final refCtrl =
        TextEditingController(text: payment.referenceNumber ?? '');
    String selectedMode = payment.paymentMode;
    String selectedType = payment.paymentType;
    DateTime payDate =
        DateTime.tryParse(payment.paymentDate) ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'भुगतान बदलें / Edit Payment',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  VoiceTextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    isNumeric: true,
                    labelText: 'राशि / Amount (₹)',
                    prefixText: '₹ ',
                    hintText: '0',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('तारीख: ',
                          style: TextStyle(fontSize: 14)),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                            '${payDate.year}-${payDate.month.toString().padLeft(2, '0')}-${payDate.day.toString().padLeft(2, '0')}'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: payDate,
                            firstDate: DateTime(2020),
                            lastDate:
                                DateTime.now().add(const Duration(days: 1)),
                          );
                          if (picked != null) {
                            setModalState(() => payDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final mode in ['cash', 'upi', 'bank'])
                        ChoiceChip(
                          label: Text(mode.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: selectedMode == mode
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              )),
                          selected: selectedMode == mode,
                          selectedColor: AppTheme.primary,
                          onSelected: (sel) {
                            if (sel) {
                              setModalState(() => selectedMode = mode);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final type
                          in AppConstants.employeePaymentTypes)
                        ChoiceChip(
                          label: Text(
                            AppConstants.employeePaymentTypeLabels[type] ??
                                type,
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedType == type
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          selected: selectedType == type,
                          selectedColor: AppTheme.primary,
                          onSelected: (sel) {
                            if (sel) {
                              setModalState(() => selectedType = type);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  VoiceTextFormField(
                    controller: notesCtrl,
                    labelText: 'नोट / Notes',
                    hintText: 'कोई जरूरी जानकारी...',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('सेव करें / Save',
                          style: TextStyle(fontSize: 15)),
                      onPressed: () async {
                        final amount =
                            double.tryParse(amountCtrl.text.trim());
                        if (amount == null || amount <= 0) {
                          showError(ctx, 'कृपया सही राशि दें / Enter valid amount');
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await ref
                              .read(appRepositoryProvider)
                              .updateEmployeePayment(
                                id: payment.id,
                                employeeId: employeeId,
                                paymentDate: payDate,
                                amount: amount,
                                paymentMode: selectedMode,
                                paymentType: selectedType,
                                referenceNumber: refCtrl.text.trim().isEmpty
                                    ? null
                                    : refCtrl.text.trim(),
                                notes: notesCtrl.text.trim().isEmpty
                                    ? null
                                    : notesCtrl.text.trim(),
                              );
                          if (context.mounted) {
                            showSuccess(context,
                                'भुगतान अपडेट हो गया / Payment updated');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showError(context,
                                'अपडेट में त्रुटि / Update failed');
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sharePaymentRecord(
    BuildContext context,
    WidgetRef ref,
    EmployeePaymentsTableData payment,
  ) {
    final employeesAsync = ref.read(employeesStreamProvider(''));
    final employee = employeesAsync.maybeWhen(
      data: (list) => list.where((e) => e.id == employeeId).firstOrNull,
      orElse: () => null,
    );

    final buffer = StringBuffer();
    buffer.writeln('🌾 *भोला ट्रेडर्स / BHOLA TRADERS* 🌾');
    buffer.writeln('💳 *भुगतान रसीद / Payment Receipt*');
    buffer.writeln('--------------------------------');
    if (employee != null) {
      buffer.writeln('👤 *कर्मचारी / Staff:* ${employee.name}');
      if (employee.phone != null && employee.phone!.isNotEmpty) {
        buffer.writeln('📞 *फ़ोन:* ${employee.phone}');
      }
    }
    buffer.writeln('📅 *तारीख / Date:* ${payment.paymentDate}');
    buffer.writeln(
        '💰 *राशि / Amount:* ₹${payment.amount.toStringAsFixed(0)}');
    buffer.writeln(
        '💳 *भुगतान माध्यम / Mode:* ${payment.paymentMode.toUpperCase()}');
    buffer.writeln(
        '📌 *प्रकार / Type:* ${AppConstants.employeePaymentTypeLabels[payment.paymentType] ?? payment.paymentType}');
    if (payment.notes != null && payment.notes!.isNotEmpty) {
      buffer.writeln('📝 *नोट / Notes:* ${payment.notes}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('भोला ट्रेडर्स  (विश्वकर्मा चौक)');
    buffer.write('📞 +91 9582863135     किसी भी प्रश्न के लिए संपर्क करें।');

    final message = buffer.toString();
    final phone = employee?.phone;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'भुगतान रसीद शेयर करें / Share Receipt',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(
                        fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('WhatsApp',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        AttendanceShareService.sendViaWhatsApp(
                            phone: phone, message: message);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.sms_outlined, size: 18),
                      label: const Text('SMS / संदेश',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        AttendanceShareService.sendViaSms(
                            phone: phone, message: message);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('अन्य ऐप में भेजें / Other Apps',
                      style: TextStyle(fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.share(message);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(employeePaymentsStreamProvider(employeeId));

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'कोई भुगतान दर्ज नहीं है\nNo payments recorded yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('भुगतान दर्ज करें / Record Payment'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EmployeePaymentScreen(
                              initialEmployeeId: employeeId)),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final p = payments[index];
            final isDeduction = p.paymentType == 'deduction';
            final color = isDeduction ? Colors.red : Colors.green.shade700;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showPaymentActions(context, ref, p),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(
                          p.paymentMode == 'cash'
                              ? Icons.money_rounded
                              : Icons.phone_android_rounded,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatRupees(p.amount),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: color),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.paymentDate} • ${p.paymentMode.toUpperCase()} • ${AppConstants.employeePaymentTypeLabels[p.paymentType] ?? p.paymentType}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                            if (p.notes != null && p.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  p.notes!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            _sharePaymentRecord(context, ref, p),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.share_rounded,
                              size: 16, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
