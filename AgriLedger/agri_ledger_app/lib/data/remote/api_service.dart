// lib/data/remote/api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/app_models.dart';

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
    return _unwrap(r, (data) =>
      (data as List).map((j) => PartyModel.fromJson(j)).toList()
    );
  }

  Future<PartyLedgerModel> getPartyLedger(String id, {
    DateTime? from, DateTime? to,
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
    String? partyId, String? type,
    DateTime? from, DateTime? to,
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
    return _unwrap(r, (data) =>
      (data['items'] as List).map((j) => TransactionModel.fromJson(j)).toList()
    );
  }

  Future<List<DailySummaryModel>> getSummary({DateTime? from, DateTime? to}) async {
    final r = await _dio.get('/transactions/summary', queryParameters: {
      if (from != null) 'from': from.toIso8601String().substring(0, 10),
      if (to != null) 'to': to.toIso8601String().substring(0, 10),
    });
    return _unwrap(r, (data) =>
      (data as List).map((j) => DailySummaryModel.fromJson(j)).toList()
    );
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final r = await _dio.post('/transactions', data: data);
    return _unwrap(r, (d) => TransactionModel.fromJson(d));
  }

  Future<TransactionModel> updateTransaction(String id, Map<String, dynamic> data) async {
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
    return _unwrap(r, (data) =>
      (data['items'] as List).map((j) => BagMovementModel.fromJson(j)).toList()
    );
  }

  Future<BagMovementModel> createBagMovement(Map<String, dynamic> data) async {
    final r = await _dio.post('/bags', data: data);
    return _unwrap(r, (d) => BagMovementModel.fromJson(d));
  }

  // ──────────────────────────────────────────────────────────────
  // SYNC
  // ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> pushSync(List<Map<String, dynamic>> changes, String deviceId) async {
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
}
