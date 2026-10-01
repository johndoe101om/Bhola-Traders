// lib/data/remote/supabase_sync_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/local_database.dart';

class SupabaseSyncService {
  final SupabaseClient? _injectedClient;

  SupabaseSyncService([SupabaseClient? client]) : _injectedClient = client;

  SupabaseClient? get _client => _injectedClient ?? _safeGetClient();

  static SupabaseClient? _safeGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isSupabaseConfigured => _client != null;

  // ── PUSH LOGIC ───────────────────────────────────────────────────

  Future<bool> pushParty(Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseSync] pushParty skipped: client not configured');
      return false;
    }
    try {
      await client.from('parties').upsert(_mapToSnakeCase(data));
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] pushParty error: $e');
      return false;
    }
  }

  Future<bool> pushTransaction(Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseSync] pushTransaction skipped: client not configured');
      return false;
    }
    try {
      await client.from('transactions').upsert(_mapToSnakeCase(data));
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] pushTransaction error: $e');
      return false;
    }
  }

  Future<bool> pushBagMovement(Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseSync] pushBagMovement skipped: client not configured');
      return false;
    }
    try {
      await client.from('bag_movements').upsert(_mapToSnakeCase(data));
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] pushBagMovement error: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from('transactions').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] deleteTransaction error: $e');
      return false;
    }
  }

  /// Soft-delete bag movement on server so other devices detect the deletion
  /// during pull sync (mirrors the transaction soft-delete pattern).
  Future<bool> deleteBagMovement(String id) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from('bag_movements').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] deleteBagMovement error: $e');
      return false;
    }
  }

  Future<bool> pushEmployee(Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseSync] pushEmployee skipped: client not configured');
      return false;
    }
    try {
      await client.from('employees').upsert(_mapToSnakeCase(data));
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] pushEmployee error: $e');
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from('employees').update({
        'is_active': false,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] deleteEmployee error: $e');
      return false;
    }
  }

  Future<bool> pushAttendance(Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseSync] pushAttendance skipped: client not configured');
      return false;
    }
    try {
      await client.from('attendances').upsert(
            _mapToSnakeCase(data),
            onConflict: 'employee_id,attendance_date',
          );
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] pushAttendance error: $e');
      return false;
    }
  }

  Future<bool> pushEmployeePayment(Map<String, dynamic> data) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseSync] pushEmployeePayment skipped: client not configured');
      return false;
    }
    try {
      await client.from('employee_payments').upsert(_mapToSnakeCase(data));
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] pushEmployeePayment error: $e');
      return false;
    }
  }

  Future<bool> deleteEmployeePayment(String id) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from('employee_payments').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] deleteEmployeePayment error: $e');
      return false;
    }
  }

  // ── PROCESS QUEUE ────────────────────────────────────────────────

  Future<List<String>> processSyncQueue(List<SyncQueueTableData> items) async {
    final List<String> acceptedIds = [];

    for (final item in items) {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      bool success = false;

      switch (item.entityType) {
        case 'party':
          success = await pushParty(payload);
          break;
        case 'transaction':
          if (item.operation == 'delete') {
            success = await deleteTransaction(item.entityId);
          } else {
            success = await pushTransaction(payload);
          }
          break;
        case 'bag_movement':
          if (item.operation == 'delete') {
            success = await deleteBagMovement(item.entityId);
          } else {
            success = await pushBagMovement(payload);
          }
          break;
        case 'employee':
          if (item.operation == 'delete') {
            success = await deleteEmployee(item.entityId);
          } else {
            success = await pushEmployee(payload);
          }
          break;
        case 'attendance':
          success = await pushAttendance(payload);
          break;
        case 'employee_payment':
          if (item.operation == 'delete') {
            success = await deleteEmployeePayment(item.entityId);
          } else {
            success = await pushEmployeePayment(payload);
          }
          break;
      }

      if (success) {
        acceptedIds.add(item.entityId);
      }
    }

    return acceptedIds;
  }

  // ── PULL LOGIC ───────────────────────────────────────────────────

  Future<Map<String, List<Map<String, dynamic>>>> pullChanges(
      String? lastSyncTimestamp) async {
    final Map<String, List<Map<String, dynamic>>> results = {
      'parties': [],
      'transactions': [],
      'bag_movements': [],
      'employees': [],
      'attendances': [],
      'employee_payments': [],
    };

    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseSync] pullChanges skipped: client not configured');
      return results;
    }

    try {
      var queryParties = client.from('parties').select();
      var queryTxns = client.from('transactions').select();
      var queryBags = client.from('bag_movements').select();
      var queryEmployees = client.from('employees').select();
      var queryAttendances = client.from('attendances').select();
      var queryPayments = client.from('employee_payments').select();

      if (lastSyncTimestamp != null && lastSyncTimestamp.isNotEmpty) {
        queryParties = queryParties.gt('updated_at', lastSyncTimestamp);
        queryTxns = queryTxns.gt('updated_at', lastSyncTimestamp);
        queryBags = queryBags.gt('updated_at', lastSyncTimestamp);
        queryEmployees = queryEmployees.gt('updated_at', lastSyncTimestamp);
        queryAttendances = queryAttendances.gt('updated_at', lastSyncTimestamp);
        queryPayments = queryPayments.gt('updated_at', lastSyncTimestamp);
      }

      final responses = await Future.wait([
        queryParties,
        queryTxns,
        queryBags,
        queryEmployees,
        queryAttendances,
        queryPayments,
      ]);

      results['parties'] = List<Map<String, dynamic>>.from(responses[0]);
      results['transactions'] = List<Map<String, dynamic>>.from(responses[1]);
      results['bag_movements'] = List<Map<String, dynamic>>.from(responses[2]);
      results['employees'] = List<Map<String, dynamic>>.from(responses[3]);
      results['attendances'] = List<Map<String, dynamic>>.from(responses[4]);
      results['employee_payments'] =
          List<Map<String, dynamic>>.from(responses[5]);

      // Map back to camelCase for local insertion
      results['parties'] = results['parties']!.map(_mapToCamelCase).toList();
      results['transactions'] =
          results['transactions']!.map(_mapToCamelCase).toList();
      results['bag_movements'] =
          results['bag_movements']!.map(_mapToCamelCase).toList();
      results['employees'] =
          results['employees']!.map(_mapToCamelCase).toList();
      results['attendances'] =
          results['attendances']!.map(_mapToCamelCase).toList();
      results['employee_payments'] =
          results['employee_payments']!.map(_mapToCamelCase).toList();

      debugPrint('[SupabaseSync] Pull complete: '
          '${results['parties']!.length} parties, '
          '${results['transactions']!.length} txns, '
          '${results['bag_movements']!.length} bags, '
          '${results['employees']!.length} employees, '
          '${results['attendances']!.length} attendances, '
          '${results['employee_payments']!.length} payments');
    } catch (e) {
      debugPrint('[SupabaseSync] pullChanges error: $e');
    }

    return results;
  }

  // ── HELPERS ─────────────────────────────────────────────────────

  Map<String, dynamic> _mapToSnakeCase(Map<String, dynamic> data) {
    final Map<String, dynamic> mapped = {};
    data.forEach((key, value) {
      final snakeKey = key.replaceAllMapped(
          RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}');
      mapped[snakeKey] = value;
    });
    return mapped;
  }

  Map<String, dynamic> _mapToCamelCase(Map<String, dynamic> data) {
    final Map<String, dynamic> mapped = {};
    data.forEach((key, value) {
      final camelKey = key.replaceAllMapped(
          RegExp(r'_([a-z])'), (match) => match.group(1)!.toUpperCase());
      mapped[camelKey] = value;
    });
    return mapped;
  }
}
