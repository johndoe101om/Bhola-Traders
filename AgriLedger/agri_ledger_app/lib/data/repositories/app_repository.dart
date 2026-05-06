// lib/data/repositories/app_repository.dart
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../local/local_database.dart';
import '../remote/supabase_sync_service.dart';
import 'package:drift/drift.dart' show Value;

class AppRepository {
  final LocalDatabase _local;
  final SupabaseSyncService _supabaseSync;
  final _uuid = const Uuid();

  AppRepository({required LocalDatabase local, required SupabaseSyncService supabaseSync})
      : _local = local, _supabaseSync = supabaseSync;

  // ── Connectivity check ────────────────────────────────────────
  Future<bool> get _isOnline async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false; // Assume offline if check fails
    }
  }

  // ──────────────────────────────────────────────────────────────
  // PARTIES
  // ──────────────────────────────────────────────────────────────

  Future<List<PartiesTableData>> getParties({String? type, String? search}) =>
      _local.getAllParties(type: type, search: search);

  Stream<List<PartiesTableData>> watchParties({String? type}) =>
      _local.watchAllParties(type: type);

  Future<PartiesTableData?> getPartyById(String id) =>
      _local.getPartyById(id);

  Future<String> createParty({
    required String name,
    required String partyType,
    String? phone,
    String? village,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final companion = PartiesTableCompanion.insert(
      id: id,
      name: name,
      partyType: partyType,
      phone: Value(phone),
      village: Value(village),
      notes: Value(notes),
      isActive: const Value(true),
      createdAt: now,
      updatedAt: now,
    );

    await _local.upsertParty(companion);

    final payload = {
      'id': id, 'name': name, 'partyType': partyType,
      'phone': phone, 'village': village, 'notes': notes,
      'isActive': true, 'createdAt': now, 'updatedAt': now,
    };

    // Try to push immediately, else queue
    if (await _isOnline) {
      try {
        await _supabaseSync.pushParty(payload);
        await _local.upsertParty(companion.copyWith(syncedAt: Value(now)));
      } catch (_) {
        await _queueForSync('party', id, 'insert', payload);
      }
    } else {
      await _queueForSync('party', id, 'insert', payload);
    }

    return id;
  }

  Future<void> updateParty(String id, {
    required String name,
    required String partyType,
    String? phone,
    String? village,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _local.upsertParty(PartiesTableCompanion(
      id: Value(id),
      name: Value(name),
      partyType: Value(partyType),
      phone: Value(phone),
      village: Value(village),
      notes: Value(notes),
      updatedAt: Value(now),
    ));

    final payload = {
      'id': id, 'name': name, 'partyType': partyType,
      'phone': phone, 'village': village, 'notes': notes,
      'updatedAt': now,
    };

    if (await _isOnline) {
      try {
        await _supabaseSync.pushParty(payload);
      } catch (_) {
        await _queueForSync('party', id, 'update', payload);
      }
    } else {
      await _queueForSync('party', id, 'update', payload);
    }
  }

  Future<void> deleteParty(String id) async {
    await _local.softDeleteParty(id);
    final payload = {
      'id': id,
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String()
    };
    if (await _isOnline) {
      try {
        await _supabaseSync.pushParty(payload);
      } catch (_) {
        await _queueForSync('party', id, 'update', payload);
      }
    } else {
      await _queueForSync('party', id, 'update', payload);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // TRANSACTIONS
  // ──────────────────────────────────────────────────────────────

  Future<List<TransactionsTableData>> getTransactions({
    String? partyId, String? txnType,
    DateTime? from, DateTime? to,
  }) => _local.getTransactions(
    partyId: partyId, txnType: txnType, from: from, to: to,
  );

  Stream<List<TransactionsTableData>> watchRecentTransactions() =>
      _local.watchRecentTransactions();

  Future<String> createTransaction({
    required String partyId,
    required String txnType,
    String? commodity,
    double? quantityKg,
    double? ratePerKg,
    required double amount,
    String paymentMode = 'cash',
    String? notes,
    String? voiceRaw,
    DateTime? entryDate,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final dateStr = (entryDate ?? DateTime.now()).toIso8601String().substring(0, 10);
    final direction = _directionForType(txnType);

    await _local.upsertTransaction(TransactionsTableCompanion.insert(
      id: id,
      partyId: partyId,
      txnType: txnType,
      commodity: Value(commodity),
      quantityKg: Value(quantityKg),
      ratePerKg: Value(ratePerKg),
      amount: amount,
      direction: direction,
      paymentMode: Value(paymentMode),
      notes: Value(notes),
      voiceRaw: Value(voiceRaw),
      entryDate: dateStr,
      createdAt: now,
      updatedAt: now,
    ));

    final payload = {
      'id': id, 'partyId': partyId, 'txnType': txnType,
      'commodity': commodity, 'quantityKg': quantityKg,
      'ratePerKg': ratePerKg, 'amount': amount, 'direction': direction,
      'paymentMode': paymentMode, 'notes': notes, 'voiceRaw': voiceRaw,
      'entryDate': dateStr, 'createdAt': now, 'updatedAt': now,
    };

    if (await _isOnline) {
      try {
        await _supabaseSync.pushTransaction(payload);
        await _local.upsertTransaction(TransactionsTableCompanion(
          id: Value(id),
          syncedAt: Value(now),
        ));
      } catch (_) {
        await _queueForSync('transaction', id, 'insert', payload);
      }
    } else {
      await _queueForSync('transaction', id, 'insert', payload);
    }

    return id;
  }

  Future<void> updateTransaction({
    required String id,
    required String partyId,
    required String txnType,
    String? commodity,
    double? quantityKg,
    double? ratePerKg,
    required double amount,
    String paymentMode = 'cash',
    String? notes,
    DateTime? entryDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    final dateStr = (entryDate ?? DateTime.now()).toIso8601String().substring(0, 10);
    final direction = _directionForType(txnType);

    await _local.upsertTransaction(TransactionsTableCompanion(
      id: Value(id),
      partyId: Value(partyId),
      txnType: Value(txnType),
      commodity: Value(commodity),
      quantityKg: Value(quantityKg),
      ratePerKg: Value(ratePerKg),
      amount: Value(amount),
      direction: Value(direction),
      paymentMode: Value(paymentMode),
      notes: Value(notes),
      entryDate: Value(dateStr),
      updatedAt: Value(now),
      syncedAt: const Value(null),
    ));

    final payload = {
      'id': id, 'partyId': partyId, 'txnType': txnType,
      'commodity': commodity, 'quantityKg': quantityKg,
      'ratePerKg': ratePerKg, 'amount': amount, 'direction': direction,
      'paymentMode': paymentMode, 'notes': notes,
      'entryDate': dateStr, 'updatedAt': now,
    };

    if (await _isOnline) {
      try {
        await _supabaseSync.pushTransaction(payload);
      } catch (_) {
        await _queueForSync('transaction', id, 'update', payload);
      }
    } else {
      await _queueForSync('transaction', id, 'update', payload);
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _local.softDeleteTransaction(id);
    if (await _isOnline) {
      try {
        await _supabaseSync.deleteTransaction(id);
      } catch (_) {
        await _queueForSync('transaction', id, 'delete', {'id': id});
      }
    } else {
      await _queueForSync('transaction', id, 'delete', {'id': id});
    }
  }

  // ──────────────────────────────────────────────────────────────
  // BALANCE & SUMMARY
  // ──────────────────────────────────────────────────────────────

  Future<double> getBalanceForParty(String partyId) =>
      _local.getBalanceForParty(partyId);

  Future<int> getBagsOutstanding(String partyId) =>
      _local.getBagsOutstandingForParty(partyId);

  Future<int> getTotalOutstandingBags() =>
      _local.getTotalOutstandingBags();

  Future<Map<String, double>> getTodaySummary() =>
      _local.getTodaySummary();

  // ──────────────────────────────────────────────────────────────
  // BAGS
  // ──────────────────────────────────────────────────────────────

  Future<List<BagMovementsTableData>> getBagMovements(String partyId) =>
      _local.getBagMovementsForParty(partyId);

  Stream<List<BagMovementsTableData>> watchRecentBagMovements() =>
      _local.watchRecentBagMovements();

  Future<String> createBagMovement({
    required String partyId,
    required String movement,
    required int quantity,
    String? linkedTxnId,
    String? notes,
    DateTime? entryDate,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final dateStr = (entryDate ?? DateTime.now()).toIso8601String().substring(0, 10);

    await _local.upsertBagMovement(BagMovementsTableCompanion.insert(
      id: id,
      partyId: partyId,
      movement: movement,
      quantity: quantity,
      linkedTxnId: Value(linkedTxnId),
      notes: Value(notes),
      entryDate: dateStr,
      createdAt: now,
      updatedAt: now,
    ));

    final payload = {
      'id': id, 'partyId': partyId, 'movement': movement,
      'quantity': quantity, 'linkedTxnId': linkedTxnId, 'notes': notes,
      'entryDate': dateStr, 'createdAt': now, 'updatedAt': now,
    };

    if (await _isOnline) {
      try {
        await _supabaseSync.pushBagMovement(payload);
      } catch (_) {
        await _queueForSync('bag_movement', id, 'insert', payload);
      }
    } else {
      await _queueForSync('bag_movement', id, 'insert', payload);
    }

    return id;
  }

  Future<void> updateBagMovement(BagMovementsTableData bag) async {
    final now = DateTime.now().toIso8601String();
    final companion = BagMovementsTableCompanion(
      id: Value(bag.id),
      partyId: Value(bag.partyId),
      movement: Value(bag.movement),
      quantity: Value(bag.quantity),
      notes: Value(bag.notes),
      entryDate: Value(bag.entryDate),
      updatedAt: Value(now),
    );
    await _local.upsertBagMovement(companion);

    final payload = {
      'id': bag.id, 'partyId': bag.partyId, 'movement': bag.movement,
      'quantity': bag.quantity, 'linkedTxnId': bag.linkedTxnId, 'notes': bag.notes,
      'entryDate': bag.entryDate, 'updatedAt': now,
    };

    if (await _isOnline) {
      try {
        await _supabaseSync.pushBagMovement(payload);
      } catch (_) {
        await _queueForSync('bag_movement', bag.id, 'update', payload);
      }
    } else {
      await _queueForSync('bag_movement', bag.id, 'update', payload);
    }
  }

  Future<void> deleteBagMovement(String id) async {
    await _local.deleteBagMovement(id);
    if (await _isOnline) {
      try {
        // We'll use a generic push for bag movements in SupabaseSyncService
        // but for delete we might need a specific one if we want to delete from cloud too.
        // For now, SupabaseSyncService.pushBagMovement handles upsert.
        // We should add a deleteBagMovement to SupabaseSyncService too.
        await _supabaseSync.deleteBagMovement(id);
      } catch (_) {
        await _queueForSync('bag_movement', id, 'delete', {'id': id});
      }
    } else {
      await _queueForSync('bag_movement', id, 'delete', {'id': id});
    }
  }

  // ──────────────────────────────────────────────────────────────
  // SYNC
  // ──────────────────────────────────────────────────────────────

  Stream<int> watchPendingSyncCount() => _local.watchPendingSyncCount();

  Future<SyncResult> syncNow() async {
    if (!await _isOnline) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    final prefs = await SharedPreferences.getInstance();
    
    // 1. PUSH PENDING CHANGES
    final pending = await _local.getPendingSyncItems();
    int pushed = 0;
    if (pending.isNotEmpty) {
      final acceptedIds = await _supabaseSync.processSyncQueue(pending);
      for (final item in pending) {
        if (acceptedIds.contains(item.entityId)) {
          await _local.removeSyncItem(item.id);
          // Mark synced locally if not already
          final now = DateTime.now().toIso8601String();
          if (item.entityType == 'party') {
            await _local.upsertParty(PartiesTableCompanion(id: Value(item.entityId), syncedAt: Value(now)));
          } else if (item.entityType == 'transaction' && item.operation != 'delete') {
            await _local.upsertTransaction(TransactionsTableCompanion(id: Value(item.entityId), syncedAt: Value(now)));
          } else if (item.entityType == 'bag_movement') {
            await _local.upsertBagMovement(BagMovementsTableCompanion(id: Value(item.entityId), syncedAt: Value(now)));
          }
        }
      }
      pushed = acceptedIds.length;
    }

    // 2. PULL CHANGES
    final lastSync = prefs.getString('last_sync_timestamp');
    final pulledData = await _supabaseSync.pullChanges(lastSync);
    
    int pulled = 0;
    // Insert pulled data into local database
    for (final p in pulledData['parties']!) {
      try {
        await _local.upsertParty(_mapToPartyCompanion(p));
        pulled++;
      } catch (e) {
        // Skip malformed party
      }
    }
    for (final t in pulledData['transactions']!) {
      try {
        await _local.upsertTransaction(_mapToTxnCompanion(t));
        pulled++;
      } catch (e) {
        // Skip malformed transaction
      }
    }
    for (final b in pulledData['bag_movements']!) {
      try {
        await _local.upsertBagMovement(_mapToBagCompanion(b));
        pulled++;
      } catch (e) {
        // Skip malformed bag movement
      }
    }

    await prefs.setString('last_sync_timestamp', DateTime.now().toIso8601String());

    return SyncResult(success: true, pushed: pushed, pulled: pulled);
  }

  // Helper mappers for pull sync
  PartiesTableCompanion _mapToPartyCompanion(Map<String, dynamic> data) {
    return PartiesTableCompanion(
      id: Value(data['id']),
      name: Value(data['name']),
      partyType: Value(data['partyType']),
      phone: Value(data['phone']),
      village: Value(data['village']),
      notes: Value(data['notes']),
      isActive: Value(data['isActive'] == true || data['isActive'] == 1),
      createdAt: Value(data['createdAt']),
      updatedAt: Value(data['updatedAt']),
      syncedAt: Value(DateTime.now().toIso8601String()),
    );
  }

  TransactionsTableCompanion _mapToTxnCompanion(Map<String, dynamic> data) {
    return TransactionsTableCompanion(
      id: Value(data['id']),
      partyId: Value(data['partyId']),
      txnType: Value(data['txnType']),
      commodity: Value(data['commodity']),
      quantityKg: Value(data['quantityKg'] != null ? (data['quantityKg'] as num).toDouble() : null),
      ratePerKg: Value(data['ratePerKg'] != null ? (data['ratePerKg'] as num).toDouble() : null),
      amount: Value((data['amount'] as num).toDouble()),
      direction: Value(data['direction']),
      paymentMode: Value(data['paymentMode'] ?? 'cash'),
      notes: Value(data['notes']),
      voiceRaw: Value(data['voiceRaw']),
      entryDate: Value(data['entryDate']),
      createdAt: Value(data['createdAt']),
      updatedAt: Value(data['updatedAt']),
      syncedAt: Value(DateTime.now().toIso8601String()),
      isDeleted: Value(data['isDeleted'] == true || data['isDeleted'] == 1),
    );
  }

  BagMovementsTableCompanion _mapToBagCompanion(Map<String, dynamic> data) {
    return BagMovementsTableCompanion(
      id: Value(data['id']),
      partyId: Value(data['partyId']),
      movement: Value(data['movement']),
      quantity: Value((data['quantity'] as num).toInt()),
      linkedTxnId: Value(data['linkedTxnId']),
      notes: Value(data['notes']),
      entryDate: Value(data['entryDate']),
      createdAt: Value(data['createdAt']),
      updatedAt: Value(data['updatedAt']),
      syncedAt: Value(DateTime.now().toIso8601String()),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────

  Future<void> _queueForSync(
    String entityType, String entityId, String operation,
    Map<String, dynamic> payload,
  ) => _local.addToSyncQueue(
    entityType: entityType,
    entityId: entityId,
    operation: operation,
    payload: jsonEncode(payload),
  );

  String _directionForType(String txnType) => switch (txnType) {
    'purchase' || 'cash_out' => 'out',
    _ => 'in',
  };
}

class SyncResult {
  final bool success;
  final int pushed;
  final int pulled;
  final String? message;
  SyncResult({required this.success, this.pushed = 0, this.pulled = 0, this.message});
}
