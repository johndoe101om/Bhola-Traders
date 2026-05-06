// lib/data/remote/supabase_sync_service.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/local_database.dart';

class SupabaseSyncService {
  final SupabaseClient _client;

  SupabaseSyncService() : _client = Supabase.instance.client;

  bool get isSupabaseConfigured {
    // Check if initialized with real values
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── PUSH LOGIC ───────────────────────────────────────────────────

  Future<bool> pushParty(Map<String, dynamic> data) async {
    try {
      await _client.from('parties').upsert(_mapToSnakeCase(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pushTransaction(Map<String, dynamic> data) async {
    try {
      await _client.from('transactions').upsert(_mapToSnakeCase(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pushBagMovement(Map<String, dynamic> data) async {
    try {
      await _client.from('bag_movements').upsert(_mapToSnakeCase(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _client.from('transactions').update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBagMovement(String id) async {
    try {
      await _client.from('bag_movements').delete().eq('id', id);
      return true;
    } catch (e) {
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
      }

      if (success) {
        acceptedIds.add(item.entityId);
      }
    }

    return acceptedIds;
  }

  // ── PULL LOGIC ───────────────────────────────────────────────────

  Future<Map<String, List<Map<String, dynamic>>>> pullChanges(String? lastSyncTimestamp) async {
    final Map<String, List<Map<String, dynamic>>> results = {
      'parties': [],
      'transactions': [],
      'bag_movements': [],
    };

    try {
      var queryParties = _client.from('parties').select();
      var queryTxns = _client.from('transactions').select();
      var queryBags = _client.from('bag_movements').select();

      if (lastSyncTimestamp != null) {
        queryParties = queryParties.gt('updated_at', lastSyncTimestamp);
        queryTxns = queryTxns.gt('updated_at', lastSyncTimestamp);
        queryBags = queryBags.gt('updated_at', lastSyncTimestamp);
      }

      final responses = await Future.wait([
        queryParties,
        queryTxns,
        queryBags,
      ]);

      results['parties'] = List<Map<String, dynamic>>.from(responses[0]);
      results['transactions'] = List<Map<String, dynamic>>.from(responses[1]);
      results['bag_movements'] = List<Map<String, dynamic>>.from(responses[2]);

      // Map back to camelCase for local insertion
      results['parties'] = results['parties']!.map(_mapToCamelCase).toList();
      results['transactions'] = results['transactions']!.map(_mapToCamelCase).toList();
      results['bag_movements'] = results['bag_movements']!.map(_mapToCamelCase).toList();

    } catch (e) {
      // Silently fail or use a logger
    }

    return results;
  }

  // ── HELPERS ─────────────────────────────────────────────────────

  Map<String, dynamic> _mapToSnakeCase(Map<String, dynamic> data) {
    final Map<String, dynamic> mapped = {};
    data.forEach((key, value) {
      final snakeKey = key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}');
      mapped[snakeKey] = value;
    });
    return mapped;
  }

  Map<String, dynamic> _mapToCamelCase(Map<String, dynamic> data) {
    final Map<String, dynamic> mapped = {};
    data.forEach((key, value) {
      final camelKey = key.replaceAllMapped(RegExp(r'_([a-z])'), (match) => match.group(1)!.toUpperCase());
      mapped[camelKey] = value;
    });
    return mapped;
  }
}
