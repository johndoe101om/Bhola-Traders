// lib/features/employees/screens/employees_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/repositories/providers.dart';
import '../../../services/printing/print_service.dart';
import '../../receipts/screens/printer_setup_screen.dart';
import '../widgets/employee_tile.dart';
import 'add_employee_screen.dart';
import 'attendance_calendar_screen.dart';
import 'attendance_screen.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});
  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  final _tabs = [
    (label: 'सभी\nAll', type: ''),
    (label: 'मज़दूर\nLabour', type: 'labour'),
    (label: 'ड्राइवर\nDriver', type: 'driver'),
    (label: 'सुपरवाइज़र\nSupervisor', type: 'supervisor'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateMonthlyReport(BuildContext context) async {
    showLoadingDialog(context,
        message: 'रिपोर्ट तैयार हो रही है / Generating Monthly Report...');
    try {
      final repo = ref.read(appRepositoryProvider);
      final employees = await repo.getEmployees();
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0);

      final attendances = await repo.getAttendanceInRange(from: from, to: to);
      final payments = await repo.getAllPaymentsInRange(from: from, to: to);

      final printer = ref.read(thermalPrinterProvider);
      final printService = PrintService(thermalPrinter: printer);

      if (context.mounted) {
        Navigator.pop(context); // close loading dialog
        await printService.printMonthlyWorkforceReport(
          context: context,
          month: now.month,
          year: now.year,
          employees: employees,
          attendances: attendances,
          payments: payments,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showError(context, 'Error generating report: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'नाम या फोन खोजें...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() {}),
              )
            : const Text('स्टाफ / Employees'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search_rounded,
                color: Colors.white),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) _searchCtrl.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.checklist_rtl_rounded, color: Colors.white),
            tooltip: 'Mark Attendance',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (val) {
              if (val == 'report') {
                _generateMonthlyReport(context);
              } else if (val == 'calendar') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AttendanceCalendarScreen()),
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('मासिक रिपोर्ट / Monthly Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'calendar',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('कैलेंडर / Calendar'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: _tabs
              .map((t) => Tab(
                    child: Text(t.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, height: 1.3)),
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((t) => _EmployeeList(type: t.type, search: _searchCtrl.text))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('नया स्टाफ / Add New',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EmployeeList extends ConsumerWidget {
  final String type;
  final String search;

  const _EmployeeList({required this.type, required this.search});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(employeesStreamProvider(type));

    return stream.when(
      data: (employees) {
        var filtered = employees;
        if (search.trim().isNotEmpty) {
          final query = search.trim().toLowerCase();
          filtered = filtered.where((e) {
            final nameMatch = e.name.toLowerCase().contains(query);
            final phoneMatch = e.phone?.toLowerCase().contains(query) ?? false;
            final teamMatch =
                e.teamGroup?.toLowerCase().contains(query) ?? false;
            return nameMatch || phoneMatch || teamMatch;
          }).toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📋', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  search.isEmpty
                      ? 'कोई स्टाफ नहीं\nNo employees yet'
                      : 'कोई परिणाम नहीं\nNo employees found for "$search"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, color: AppTheme.textSecondary, height: 1.4),
                ),
                if (search.isEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddEmployeeScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('पहला स्टाफ जोड़ें / Add First Staff'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return EmployeeTile(employee: filtered[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading employees: $e')),
    );
  }
}
