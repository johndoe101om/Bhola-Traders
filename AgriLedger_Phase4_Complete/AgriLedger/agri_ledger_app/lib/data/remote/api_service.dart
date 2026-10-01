// lib/data/remote/api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/app_models.dart';
import '../models/employee_models.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.baseUrl}${AppConstants.apiVersion}',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));

    // ── Interceptors ────────────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final pin = prefs.getString('user_pin') ?? AppConstants.defaultPin;
        options.headers['X-PIN'] = pin;

        // Dynamically override baseUrl with user's settings if present
        final serverUrl = prefs.getString('server_url');
        if (serverUrl != null && serverUrl.isNotEmpty) {
          options.baseUrl = '$serverUrl${AppConstants.apiVersion}';
        }

        handler.next(options);
      },
      onError: (DioException e, handler) {
        // Wrap in friendly error
        handler.next(e);
      },
    ));
  }

  // ── Helper ────────────────────────────────────────────────────
  T _unwrap<T>(Response r, T Function(dynamic data) parse) {
    final body = r.data as Map<String, dynamic>;
    if (body['success'] == false) throw Exception(body['message']);
    return parse(body['data']);
  }

  // ──────────────────────────────────────────────────────────────
  // AUTH
  // ──────────────────────────────────────────────────────────────

  Future<bool> verifyPin(String pin) async {
    try {
      final r = await _dio.post('/auth/verify', data: {'pin': pin});
      return r.data['success'] == true;
    } on DioException {
      return false;
    }
  }

  Future<bool> isServerReachable() async {
    try {
      await _dio.get(
        '${AppConstants.baseUrl}/health',
        options: Options(sendTimeout: const Duration(seconds: 3)),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // PARTIES
  // ──────────────────────────────────────────────────────────────

  Future<List<PartyModel>> getParties({String? type, String? q}) async {
    final r = await _dio.get('/parties', queryParameters: {
      if (type != null) 'type': type,
      if (q != null) 'q': q,
    });
    return _unwrap(r,
        (data) => (data as List).map((j) => PartyModel.fromJson(j)).toList());
  }

  Future<PartyLedgerModel> getPartyLedger(
    String id, {
    DateTime? from,
    DateTime? to,
  }) async {
    final r = await _dio.get('/parties/$id/ledger', queryParameters: {
      if (from != null) 'from': from.toIso8601String().substring(0, 10),
      if (to != null) 'to': to.toIso8601String().substring(0, 10),
    });
    return _unwrap(r, (data) => PartyLedgerModel.fromJson(data));
  }

  Future<PartyModel> createParty(Map<String, dynamic> data) async {
    final r = await _dio.post('/parties', data: data);
    return _unwrap(r, (d) => PartyModel.fromJson(d));
  }

  Future<PartyModel> updateParty(String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/parties/$id', data: data);
    return _unwrap(r, (d) => PartyModel.fromJson(d));
  }

  // ──────────────────────────────────────────────────────────────
  // TRANSACTIONS
  // ──────────────────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions({
    String? partyId,
    String? type,
    DateTime? from,
    DateTime? to,
    int page = 1,
  }) async {
    final r = await _dio.get('/transactions', queryParameters: {
      if (partyId != null) 'partyId': partyId,
      if (type != null) 'type': type,
      if (from != null) 'from': from.toIso8601String().substring(0, 10),
      if (to != null) 'to': to.toIso8601String().substring(0, 10),
      'page': page,
      'pageSize': 50,
    });
    return _unwrap(
        r,
        (data) => (data['items'] as List)
            .map((j) => TransactionModel.fromJson(j))
            .toList());
  }

  Future<List<DailySummaryModel>> getSummary(
      {DateTime? from, DateTime? to}) async {
    final r = await _dio.get('/transactions/summary', queryParameters: {
      if (from != null) 'from': from.toIso8601String().substring(0, 10),
      if (to != null) 'to': to.toIso8601String().substring(0, 10),
    });
    return _unwrap(
        r,
        (data) =>
            (data as List).map((j) => DailySummaryModel.fromJson(j)).toList());
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final r = await _dio.post('/transactions', data: data);
    return _unwrap(r, (d) => TransactionModel.fromJson(d));
  }

  Future<TransactionModel> updateTransaction(
      String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/transactions/$id', data: data);
    return _unwrap(r, (d) => TransactionModel.fromJson(d));
  }

  Future<void> deleteTransaction(String id) async {
    await _dio.delete('/transactions/$id');
  }

  // ──────────────────────────────────────────────────────────────
  // BAGS
  // ──────────────────────────────────────────────────────────────

  Future<List<BagMovementModel>> getBagMovements({String? partyId}) async {
    final r = await _dio.get('/bags', queryParameters: {
      if (partyId != null) 'partyId': partyId,
    });
    return _unwrap(
        r,
        (data) => (data['items'] as List)
            .map((j) => BagMovementModel.fromJson(j))
            .toList());
  }

  Future<BagMovementModel> createBagMovement(Map<String, dynamic> data) async {
    final r = await _dio.post('/bags', data: data);
    return _unwrap(r, (d) => BagMovementModel.fromJson(d));
  }

  // ──────────────────────────────────────────────────────────────
  // SYNC
  // ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> pushSync(
      List<Map<String, dynamic>> changes, String deviceId) async {
    final r = await _dio.post('/sync/push', data: {
      'deviceId': deviceId,
      'changes': changes,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> pullSync(DateTime? since) async {
    final r = await _dio.get('/sync/pull', queryParameters: {
      if (since != null) 'since': since.toIso8601String(),
    });
    return r.data as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────────────────
  // EMPLOYEES
  // ──────────────────────────────────────────────────────────────

  Future<List<Employee>> getEmployees(
      {String? type, String? q, String? team}) async {
    final r = await _dio.get('/employees', queryParameters: {
      if (type != null) 'type': type,
      if (q != null) 'q': q,
      if (team != null) 'team': team,
    });
    return _unwrap(
        r, (data) => (data as List).map((j) => Employee.fromJson(j)).toList());
  }

  Future<Employee> getEmployee(String id) async {
    final r = await _dio.get('/employees/$id');
    return _unwrap(r, (d) => Employee.fromJson(d));
  }

  Future<Employee> createEmployee(Map<String, dynamic> data) async {
    final r = await _dio.post('/employees', data: data);
    return _unwrap(r, (d) => Employee.fromJson(d));
  }

  Future<Employee> updateEmployee(String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/employees/$id', data: data);
    return _unwrap(r, (d) => Employee.fromJson(d));
  }

  Future<void> deleteEmployee(String id) async {
    await _dio.delete('/employees/$id');
  }

  Future<Map<String, dynamic>> getEmployeeLedger(String id,
      {DateTime? from, DateTime? to}) async {
    final r = await _dio.get('/employees/$id/ledger', queryParameters: {
      if (from != null) 'from': from.toIso8601String().substring(0, 10),
      if (to != null) 'to': to.toIso8601String().substring(0, 10),
    });
    return _unwrap(r, (d) => d as Map<String, dynamic>);
  }

  // ──────────────────────────────────────────────────────────────
  // ATTENDANCE
  // ──────────────────────────────────────────────────────────────

  Future<List<Attendance>> getAttendance({
    String? employeeId,
    String? date,
    String? from,
    String? to,
    String? status,
  }) async {
    final r = await _dio.get('/attendance', queryParameters: {
      if (employeeId != null) 'employeeId': employeeId,
      if (date != null) 'date': date,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (status != null) 'status': status,
    });
    return _unwrap(
        r,
        (data) => (data['items'] as List)
            .map((j) => Attendance.fromJson(j))
            .toList());
  }

  Future<Map<String, dynamic>> getTodayAttendanceDashboard() async {
    final r = await _dio.get('/attendance/today');
    return _unwrap(r, (d) => d as Map<String, dynamic>);
  }

  Future<Attendance> markAttendance(Map<String, dynamic> data) async {
    final r = await _dio.post('/attendance', data: data);
    return _unwrap(r, (d) => Attendance.fromJson(d));
  }

  Future<void> bulkMarkAttendance(Map<String, dynamic> data) async {
    await _dio.post('/attendance/bulk', data: data);
  }

  // ──────────────────────────────────────────────────────────────
  // EMPLOYEE PAYMENTS
  // ──────────────────────────────────────────────────────────────

  Future<List<EmployeePayment>> getEmployeePayments({
    String? employeeId,
    String? from,
    String? to,
    String? mode,
    String? type,
  }) async {
    final r = await _dio.get('/employee-payments', queryParameters: {
      if (employeeId != null) 'employeeId': employeeId,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (mode != null) 'mode': mode,
      if (type != null) 'type': type,
    });
    return _unwrap(
        r,
        (data) => (data['items'] as List)
            .map((j) => EmployeePayment.fromJson(j))
            .toList());
  }

  Future<EmployeePayment> recordEmployeePayment(
      Map<String, dynamic> data) async {
    final r = await _dio.post('/employee-payments', data: data);
    return _unwrap(r, (d) => EmployeePayment.fromJson(d));
  }
}
