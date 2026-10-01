// lib/data/repositories/app_repository.dart
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../local/local_database.dart';
import '../models/employee_models.dart';
import '../remote/supabase_sync_service.dart';
import 'package:drift/drift.dart' show Value;

class AppRepository {
  final LocalDatabase _local;
  final SupabaseSyncService _supabaseSync;
  final _uuid = const Uuid();

  AppRepository(
      {required LocalDatabase local, required SupabaseSyncService supabaseSync})
      : _local = local,
        _supabaseSync = supabaseSync;

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

  Future<PartiesTableData?> getPartyById(String id) => _local.getPartyById(id);

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
      'id': id,
      'name': name,
      'partyType': partyType,
      'phone': phone,
      'village': village,
      'notes': notes,
      'isActive': true,
      'createdAt': now,
      'updatedAt': now,
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

  Future<void> updateParty(
    String id, {
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
      'id': id,
      'name': name,
      'partyType': partyType,
      'phone': phone,
      'village': village,
      'notes': notes,
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
    String? partyId,
    String? txnType,
    DateTime? from,
    DateTime? to,
  }) =>
      _local.getTransactions(
        partyId: partyId,
        txnType: txnType,
        from: from,
        to: to,
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
    final dateStr =
        (entryDate ?? DateTime.now()).toIso8601String().substring(0, 10);
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
      'id': id,
      'partyId': partyId,
      'txnType': txnType,
      'commodity': commodity,
      'quantityKg': quantityKg,
      'ratePerKg': ratePerKg,
      'amount': amount,
      'direction': direction,
      'paymentMode': paymentMode,
      'notes': notes,
      'voiceRaw': voiceRaw,
      'entryDate': dateStr,
      'createdAt': now,
      'updatedAt': now,
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
    final dateStr =
        (entryDate ?? DateTime.now()).toIso8601String().substring(0, 10);
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
      'id': id,
      'partyId': partyId,
      'txnType': txnType,
      'commodity': commodity,
      'quantityKg': quantityKg,
      'ratePerKg': ratePerKg,
      'amount': amount,
      'direction': direction,
      'paymentMode': paymentMode,
      'notes': notes,
      'entryDate': dateStr,
      'updatedAt': now,
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

  Future<int> getTotalOutstandingBags() => _local.getTotalOutstandingBags();

  Future<Map<String, double>> getTodaySummary() => _local.getTodaySummary();

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
    final dateStr =
        (entryDate ?? DateTime.now()).toIso8601String().substring(0, 10);

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
      'id': id,
      'partyId': partyId,
      'movement': movement,
      'quantity': quantity,
      'linkedTxnId': linkedTxnId,
      'notes': notes,
      'entryDate': dateStr,
      'createdAt': now,
      'updatedAt': now,
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
      'id': bag.id,
      'partyId': bag.partyId,
      'movement': bag.movement,
      'quantity': bag.quantity,
      'linkedTxnId': bag.linkedTxnId,
      'notes': bag.notes,
      'entryDate': bag.entryDate,
      'updatedAt': now,
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
    // Soft-delete locally to preserve tombstone for sync
    await _local.softDeleteBagMovement(id);
    if (await _isOnline) {
      try {
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
            await _local.upsertParty(PartiesTableCompanion(
                id: Value(item.entityId), syncedAt: Value(now)));
          } else if (item.entityType == 'transaction' &&
              item.operation != 'delete') {
            await _local.upsertTransaction(TransactionsTableCompanion(
                id: Value(item.entityId), syncedAt: Value(now)));
          } else if (item.entityType == 'bag_movement') {
            await _local.upsertBagMovement(BagMovementsTableCompanion(
                id: Value(item.entityId), syncedAt: Value(now)));
          } else if (item.entityType == 'employee' &&
              item.operation != 'delete') {
            await _local.upsertEmployee(EmployeesTableCompanion(
                id: Value(item.entityId), syncedAt: Value(now)));
          } else if (item.entityType == 'attendance') {
            await _local.upsertAttendance(AttendancesTableCompanion(
                id: Value(item.entityId), syncedAt: Value(now)));
          } else if (item.entityType == 'employee_payment') {
            await _local.upsertEmployeePayment(EmployeePaymentsTableCompanion(
                id: Value(item.entityId), syncedAt: Value(now)));
          }
        }
      }
      pushed = acceptedIds.length;
    }

    // 2. PULL CHANGES — with conflict resolution
    final lastSync = prefs.getString('last_sync_timestamp');
    final pulledData = await _supabaseSync.pullChanges(lastSync);

    // Get current pending sync items to check for local-wins scenarios
    final currentPending = await _local.getPendingSyncItems();
    final pendingEntityIds = <String>{};
    final pendingEntityTimestamps = <String, String>{};
    for (final item in currentPending) {
      pendingEntityIds.add(item.entityId);
      // Extract updatedAt from payload for timestamp comparison
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        final localUpdatedAt =
            (payload['updatedAt'] ?? payload['updated_at']) as String?;
        if (localUpdatedAt != null) {
          pendingEntityTimestamps[item.entityId] = localUpdatedAt;
        }
      } catch (_) {
        // Malformed payload — treat as no timestamp
      }
    }

    int pulled = 0;

    // ── MERGE PARTIES ──
    for (final p in pulledData['parties']!) {
      try {
        final entityId = p['id'] as String;
        final serverIsActive = p['isActive'] == true || p['isActive'] == 1;

        // If server says party is deactivated, apply locally AND
        // remove any stale sync queue entries that would re-push it
        if (!serverIsActive) {
          await _local.upsertParty(_mapToPartyCompanion(p));
          await _local.removeSyncQueueItemsForEntity('party', entityId);
          pulled++;
          continue;
        }

        // Timestamp conflict check: if local has a pending change with
        // a NEWER timestamp, skip the server version (local wins)
        if (pendingEntityIds.contains(entityId)) {
          final serverUpdatedAt = p['updatedAt'] as String?;
          final localUpdatedAt = pendingEntityTimestamps[entityId];
          if (serverUpdatedAt != null && localUpdatedAt != null) {
            if (localUpdatedAt.compareTo(serverUpdatedAt) > 0) {
              continue; // Local is newer — skip server version
            }
          }
        }

        await _local.upsertParty(_mapToPartyCompanion(p));
        pulled++;
      } catch (e) {
        // Skip malformed party
      }
    }

    // ── MERGE TRANSACTIONS ──
    for (final t in pulledData['transactions']!) {
      try {
        final entityId = t['id'] as String;
        final serverIsDeleted =
            t['isDeleted'] == true || t['isDeleted'] == 1;

        // If server says transaction is deleted, soft-delete locally AND
        // remove any stale sync queue entries to prevent resurrection
        if (serverIsDeleted) {
          await _local.softDeleteTransaction(entityId);
          await _local.removeSyncQueueItemsForEntity(
              'transaction', entityId);
          pulled++;
          continue;
        }

        // Timestamp conflict check
        if (pendingEntityIds.contains(entityId)) {
          final serverUpdatedAt = t['updatedAt'] as String?;
          final localUpdatedAt = pendingEntityTimestamps[entityId];
          if (serverUpdatedAt != null && localUpdatedAt != null) {
            if (localUpdatedAt.compareTo(serverUpdatedAt) > 0) {
              continue; // Local is newer — skip server version
            }
          }
        }

        await _local.upsertTransaction(_mapToTxnCompanion(t));
        pulled++;
      } catch (e) {
        // Skip malformed transaction
      }
    }

    // ── MERGE BAG MOVEMENTS ──
    for (final b in pulledData['bag_movements']!) {
      try {
        final entityId = b['id'] as String;
        final serverIsDeleted =
            b['isDeleted'] == true || b['isDeleted'] == 1;

        // If server says bag movement is deleted, soft-delete locally AND
        // remove any stale sync queue entries to prevent resurrection
        if (serverIsDeleted) {
          await _local.softDeleteBagMovement(entityId);
          await _local.removeSyncQueueItemsForEntity(
              'bag_movement', entityId);
          pulled++;
          continue;
        }

        // Timestamp conflict check
        if (pendingEntityIds.contains(entityId)) {
          final serverUpdatedAt = b['updatedAt'] as String?;
          final localUpdatedAt = pendingEntityTimestamps[entityId];
          if (serverUpdatedAt != null && localUpdatedAt != null) {
            if (localUpdatedAt.compareTo(serverUpdatedAt) > 0) {
              continue; // Local is newer — skip server version
            }
          }
        }

        await _local.upsertBagMovement(_mapToBagCompanion(b));
        pulled++;
      } catch (e) {
        // Skip malformed bag movement
      }
    }

    await prefs.setString(
        'last_sync_timestamp', DateTime.now().toIso8601String());

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
      quantityKg: Value(data['quantityKg'] != null
          ? (data['quantityKg'] as num).toDouble()
          : null),
      ratePerKg: Value(data['ratePerKg'] != null
          ? (data['ratePerKg'] as num).toDouble()
          : null),
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
      isDeleted: Value(data['isDeleted'] == true || data['isDeleted'] == 1),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // EMPLOYEES
  // ──────────────────────────────────────────────────────────────

  Future<List<EmployeesTableData>> getEmployees(
          {String? type, String? search}) =>
      _local.getAllEmployees(type: type, search: search);

  Stream<List<EmployeesTableData>> watchEmployees({String? type}) =>
      _local.watchAllEmployees(type: type);

  Future<EmployeesTableData?> getEmployeeById(String id) =>
      _local.getEmployeeById(id);

  Future<String> createEmployee({
    required String name,
    required double dailyWageRate,
    String? phone,
    String? email,
    String? aadhaarNumber,
    String? address,
    DateTime? joiningDate,
    String employeeType = 'labour',
    String? teamGroup,
    String? emergencyContact,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final joinStr =
        (joiningDate ?? DateTime.now()).toIso8601String().substring(0, 10);

    final companion = EmployeesTableCompanion.insert(
      id: id,
      name: name,
      dailyWageRate: Value(dailyWageRate),
      phone: Value(phone),
      email: Value(email),
      aadhaarNumber: Value(aadhaarNumber),
      address: Value(address),
      joiningDate: joinStr,
      employeeType: Value(employeeType),
      teamGroup: Value(teamGroup),
      isActive: const Value(true),
      emergencyContact: Value(emergencyContact),
      notes: Value(notes),
      createdAt: now,
      updatedAt: now,
    );

    await _local.upsertEmployee(companion);

    final payload = {
      'id': id,
      'name': name,
      'daily_wage_rate': dailyWageRate,
      'phone': phone,
      'email': email,
      'aadhaar_number': aadhaarNumber,
      'address': address,
      'joining_date': joinStr,
      'employee_type': employeeType,
      'team_group': teamGroup,
      'is_active': true,
      'emergency_contact': emergencyContact,
      'notes': notes,
      'created_at': now,
      'updated_at': now,
    };

    await _queueForSync('employee', id, 'insert', payload);
    return id;
  }

  Future<void> updateEmployee(
    String id, {
    required String name,
    required double dailyWageRate,
    String? phone,
    String? email,
    String? aadhaarNumber,
    String? address,
    DateTime? joiningDate,
    String employeeType = 'labour',
    String? teamGroup,
    bool isActive = true,
    String? emergencyContact,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final joinStr =
        (joiningDate ?? DateTime.now()).toIso8601String().substring(0, 10);

    await _local.upsertEmployee(EmployeesTableCompanion(
      id: Value(id),
      name: Value(name),
      dailyWageRate: Value(dailyWageRate),
      phone: Value(phone),
      email: Value(email),
      aadhaarNumber: Value(aadhaarNumber),
      address: Value(address),
      joiningDate: Value(joinStr),
      employeeType: Value(employeeType),
      teamGroup: Value(teamGroup),
      isActive: Value(isActive),
      emergencyContact: Value(emergencyContact),
      notes: Value(notes),
      updatedAt: Value(now),
      syncedAt: const Value(null),
    ));

    final payload = {
      'id': id,
      'name': name,
      'daily_wage_rate': dailyWageRate,
      'phone': phone,
      'email': email,
      'aadhaar_number': aadhaarNumber,
      'address': address,
      'joining_date': joinStr,
      'employee_type': employeeType,
      'team_group': teamGroup,
      'is_active': isActive,
      'emergency_contact': emergencyContact,
      'notes': notes,
      'updated_at': now,
    };

    await _queueForSync('employee', id, 'update', payload);
  }

  Future<void> deleteEmployee(String id) async {
    await _local.softDeleteEmployee(id);
    await _queueForSync('employee', id, 'delete', {'id': id});
  }

  // ──────────────────────────────────────────────────────────────
  // ATTENDANCE
  // ──────────────────────────────────────────────────────────────

  Future<List<AttendancesTableData>> getAttendanceForDate(DateTime date) {
    final dateStr = date.toIso8601String().substring(0, 10);
    return _local.getAttendanceForDate(dateStr);
  }

  Stream<List<AttendancesTableData>> watchAttendanceForDate(DateTime date) {
    final dateStr = date.toIso8601String().substring(0, 10);
    return _local.watchAttendanceForDate(dateStr);
  }

  Future<String> markAttendance({
    required String employeeId,
    required DateTime date,
    required String status,
    String? absenceReason,
    String? voiceRaw,
    double? overtimeHours,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final dateStr = date.toIso8601String().substring(0, 10);

    final existingList = await _local.getAttendanceForDate(dateStr);
    final existing =
        existingList.where((a) => a.employeeId == employeeId).firstOrNull;

    final targetId = existing != null ? existing.id : id;

    final companion = AttendancesTableCompanion(
      id: Value(targetId),
      employeeId: Value(employeeId),
      attendanceDate: Value(dateStr),
      status: Value(status),
      absenceReason: Value(absenceReason),
      voiceRaw: Value(voiceRaw),
      overtimeHours: Value(overtimeHours),
      notes: Value(notes),
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
      syncedAt: const Value(null),
    );

    await _local.upsertAttendance(companion);

    final payload = {
      'id': targetId,
      'employee_id': employeeId,
      'attendance_date': dateStr,
      'status': status,
      'absence_reason': absenceReason,
      'voice_raw': voiceRaw,
      'overtime_hours': overtimeHours,
      'notes': notes,
      'created_at': existing?.createdAt ?? now,
      'updated_at': now,
    };

    await _queueForSync('attendance', targetId,
        existing != null ? 'update' : 'insert', payload);
    return targetId;
  }

  Future<void> bulkMarkAttendance({
    required DateTime date,
    required List<Map<String, dynamic>> items,
  }) async {
    for (final item in items) {
      await markAttendance(
        employeeId: item['employeeId'],
        date: date,
        status: item['status'] ?? 'present',
        absenceReason: item['absenceReason'],
        voiceRaw: item['voiceRaw'],
        overtimeHours: item['overtimeHours'],
        notes: item['notes'],
      );
    }
  }

  Future<List<AttendancesTableData>> getAttendanceForEmployee(
    String employeeId, {
    DateTime? from,
    DateTime? to,
  }) {
    final fromStr = from?.toIso8601String().substring(0, 10);
    final toStr = to?.toIso8601String().substring(0, 10);
    return _local.getAttendanceForEmployee(employeeId,
        from: fromStr, to: toStr);
  }

  Future<List<AttendancesTableData>> getAttendanceInRange({
    String? employeeId,
    required DateTime from,
    required DateTime to,
  }) {
    final fromStr = from.toIso8601String().substring(0, 10);
    final toStr = to.toIso8601String().substring(0, 10);
    return _local.getAttendanceInRange(
        employeeId: employeeId, from: fromStr, to: toStr);
  }

  Stream<List<AttendancesTableData>> watchAttendanceForEmployee(
          String employeeId) =>
      _local.watchAttendanceForEmployee(employeeId);

  // ──────────────────────────────────────────────────────────────
  // EMPLOYEE PAYMENTS
  // ──────────────────────────────────────────────────────────────

  Future<String> recordEmployeePayment({
    required String employeeId,
    required DateTime paymentDate,
    required double amount,
    String paymentMode = 'cash',
    String paymentType = 'wage',
    String? referenceNumber,
    String? notes,
    String? voiceRaw,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final dateStr = paymentDate.toIso8601String().substring(0, 10);

    final companion = EmployeePaymentsTableCompanion.insert(
      id: id,
      employeeId: employeeId,
      paymentDate: dateStr,
      amount: amount,
      paymentMode: paymentMode,
      paymentType: paymentType,
      referenceNumber: Value(referenceNumber),
      notes: Value(notes),
      voiceRaw: Value(voiceRaw),
      createdAt: now,
      updatedAt: now,
    );

    await _local.upsertEmployeePayment(companion);

    final payload = {
      'id': id,
      'employee_id': employeeId,
      'payment_date': dateStr,
      'amount': amount,
      'payment_mode': paymentMode,
      'payment_type': paymentType,
      'reference_number': referenceNumber,
      'notes': notes,
      'voice_raw': voiceRaw,
      'created_at': now,
      'updated_at': now,
    };

    await _queueForSync('employee_payment', id, 'insert', payload);
    return id;
  }

  Future<List<EmployeePaymentsTableData>> getPaymentsForEmployee(
    String employeeId, {
    DateTime? from,
    DateTime? to,
  }) {
    final fromStr = from?.toIso8601String().substring(0, 10);
    final toStr = to?.toIso8601String().substring(0, 10);
    return _local.getPaymentsForEmployee(employeeId, from: fromStr, to: toStr);
  }

  Future<List<EmployeePaymentsTableData>> getAllPaymentsInRange({
    DateTime? from,
    DateTime? to,
  }) {
    final fromStr = from?.toIso8601String().substring(0, 10);
    final toStr = to?.toIso8601String().substring(0, 10);
    return _local.getAllPaymentsInRange(from: fromStr, to: toStr);
  }

  Stream<List<EmployeePaymentsTableData>> watchPaymentsForEmployee(
          String employeeId) =>
      _local.watchPaymentsForEmployee(employeeId);

  Future<void> deleteEmployeePayment(String id) async {
    await _local.deleteEmployeePayment(id);
    await _queueForSync('employee_payment', id, 'delete', {'id': id});
  }

  // ──────────────────────────────────────────────────────────────
  // WORKFORCE & LEDGER SUMMARIES
  // ──────────────────────────────────────────────────────────────

  Future<WorkforceSummary> getTodayWorkforceStats() async {
    final data = await _local.getTodayWorkforceStats();
    return WorkforceSummary(
      totalEmployees: data['total'] ?? 0,
      presentCount: data['present'] ?? 0,
      absentCount: data['absent'] ?? 0,
      halfDayCount: data['half_day'] ?? 0,
      overtimeCount: data['overtime'] ?? 0,
      notMarkedCount: data['not_marked'] ?? 0,
      totalWagesToday: (data['wages'] ?? 0 as num).toDouble(),
    );
  }

  Future<Map<String, dynamic>> getEmployeeLedger(String employeeId) =>
      _local.getEmployeeLedgerSummary(employeeId);

  // ──────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────

  Future<void> _queueForSync(
    String entityType,
    String entityId,
    String operation,
    Map<String, dynamic> payload,
  ) =>
      _local.addToSyncQueue(
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
  SyncResult(
      {required this.success, this.pushed = 0, this.pulled = 0, this.message});
}
