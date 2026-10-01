// lib/data/repositories/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/local_database.dart';
import '../models/employee_models.dart';
import '../remote/api_service.dart';
import '../remote/supabase_sync_service.dart';
import '../repositories/app_repository.dart';

// ── CORE SINGLETONS ──────────────────────────────────────────────────

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final supabaseSyncServiceProvider =
    Provider<SupabaseSyncService>((ref) => SupabaseSyncService());

final appRepositoryProvider = Provider<AppRepository>((ref) => AppRepository(
      local: ref.watch(localDatabaseProvider),
      supabaseSync: ref.watch(supabaseSyncServiceProvider),
    ));

// ── PARTIES ──────────────────────────────────────────────────────────

final partiesStreamProvider =
    StreamProvider.family<List<dynamic>, String?>((ref, type) {
  final repo = ref.watch(appRepositoryProvider);
  return repo.watchParties(type: type == '' ? null : type);
});

final partySearchProvider = StateProvider<String>((ref) => '');

final filteredPartiesProvider =
    FutureProvider.family<List<dynamic>, String?>((ref, type) async {
  final repo = ref.watch(appRepositoryProvider);
  final search = ref.watch(partySearchProvider);
  return repo.getParties(type: type, search: search.isEmpty ? null : search);
});

// ── TRANSACTIONS ─────────────────────────────────────────────────────

final recentTransactionsProvider = StreamProvider((ref) {
  final repo = ref.watch(appRepositoryProvider);
  return repo.watchRecentTransactions();
});

// ── TODAY SUMMARY ────────────────────────────────────────────────────

final todaySummaryProvider = FutureProvider<Map<String, double>>((ref) {
  // Refresh when transactions change
  ref.watch(recentTransactionsProvider);
  return ref.watch(appRepositoryProvider).getTodaySummary();
});

// ── SYNC ─────────────────────────────────────────────────────────────

final syncCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(appRepositoryProvider);
  return repo.watchPendingSyncCount();
});

// ── BAGS ─────────────────────────────────────────────────────────────

final recentBagMovementsProvider = StreamProvider((ref) {
  final repo = ref.watch(appRepositoryProvider);
  return repo.watchRecentBagMovements();
});

// ── PARTY BALANCE (per-party) ─────────────────────────────────────────

final partyBalanceProvider =
    FutureProvider.family<double, String>((ref, partyId) {
  ref.watch(recentTransactionsProvider); // auto-refresh on new txn
  return ref.watch(appRepositoryProvider).getBalanceForParty(partyId);
});

final partyBagsProvider = FutureProvider.family<int, String>((ref, partyId) {
  ref.watch(recentBagMovementsProvider); // auto-refresh on new bag movement
  return ref.watch(appRepositoryProvider).getBagsOutstanding(partyId);
});

final totalOutstandingBagsProvider = FutureProvider<int>((ref) {
  ref.watch(recentBagMovementsProvider); // auto-refresh on new bag movement
  return ref.watch(appRepositoryProvider).getTotalOutstandingBags();
});

// ── AUTH ─────────────────────────────────────────────────────────────

final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

// ── EMPLOYEES ────────────────────────────────────────────────────────

final employeesStreamProvider =
    StreamProvider.family<List<EmployeesTableData>, String?>((ref, type) {
  final repo = ref.watch(appRepositoryProvider);
  return repo.watchEmployees(type: type == '' ? null : type);
});

final employeeSearchProvider = StateProvider<String>((ref) => '');

final filteredEmployeesProvider =
    FutureProvider.family<List<EmployeesTableData>, String?>((ref, type) async {
  final repo = ref.watch(appRepositoryProvider);
  final search = ref.watch(employeeSearchProvider);
  return repo.getEmployees(
      type: type == '' ? null : type, search: search.isEmpty ? null : search);
});

// ── ATTENDANCE ───────────────────────────────────────────────────────

final selectedAttendanceDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

final attendanceForDateStreamProvider =
    StreamProvider.family<List<AttendancesTableData>, DateTime>((ref, date) {
  final repo = ref.watch(appRepositoryProvider);
  return repo.watchAttendanceForDate(date);
});

final employeeAttendanceStreamProvider =
    StreamProvider.family<List<AttendancesTableData>, String>(
        (ref, employeeId) {
  final repo = ref.watch(appRepositoryProvider);
  return repo.watchAttendanceForEmployee(employeeId);
});

// ── EMPLOYEE PAYMENTS ────────────────────────────────────────────────

final employeePaymentsStreamProvider =
    StreamProvider.family<List<EmployeePaymentsTableData>, String>(
        (ref, employeeId) {
  final repo = ref.watch(appRepositoryProvider);
  return repo.watchPaymentsForEmployee(employeeId);
});

// ── WORKFORCE & WAGE STATS ───────────────────────────────────────────

final todayWorkforceStatsProvider =
    FutureProvider<WorkforceSummary>((ref) async {
  final today = DateTime.now();
  ref.watch(attendanceForDateStreamProvider(today));
  ref.watch(employeesStreamProvider(''));
  return ref.watch(appRepositoryProvider).getTodayWorkforceStats();
});

final employeeLedgerProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
        (ref, employeeId) async {
  ref.watch(employeeAttendanceStreamProvider(employeeId));
  ref.watch(employeePaymentsStreamProvider(employeeId));
  return ref.watch(appRepositoryProvider).getEmployeeLedger(employeeId);
});
