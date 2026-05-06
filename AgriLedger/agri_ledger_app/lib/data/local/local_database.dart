// lib/data/local/local_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_database.g.dart';

// ── TABLE DEFINITIONS ────────────────────────────────────────────────

class PartiesTable extends Table {
  TextColumn get id => text().withLength(max: 36)();
  TextColumn get name => text().withLength(max: 200)();
  TextColumn get partyType => text().withLength(max: 20)();
  TextColumn get phone => text().withLength(max: 15).nullable()();
  TextColumn get village => text().withLength(max: 100).nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionsTable extends Table {
  TextColumn get id => text().withLength(max: 36)();
  TextColumn get partyId => text().withLength(max: 36).references(PartiesTable, #id)();
  TextColumn get txnType => text().withLength(max: 20)();
  TextColumn get commodity => text().withLength(max: 20).nullable()();
  RealColumn get quantityKg => real().nullable()();
  RealColumn get ratePerKg => real().nullable()();
  RealColumn get amount => real()();
  TextColumn get direction => text().withLength(max: 5)();
  TextColumn get paymentMode => text().withLength(max: 10).withDefault(const Constant('cash'))();
  TextColumn get notes => text().nullable()();
  TextColumn get voiceRaw => text().nullable()();
  TextColumn get entryDate => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class BagMovementsTable extends Table {
  TextColumn get id => text().withLength(max: 36)();
  TextColumn get partyId => text().withLength(max: 36).references(PartiesTable, #id)();
  TextColumn get movement => text().withLength(max: 10)();
  IntColumn get quantity => integer()();
  TextColumn get linkedTxnId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get entryDate => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text().withLength(max: 30)();
  TextColumn get entityId => text().withLength(max: 36)();
  TextColumn get operation => text().withLength(max: 10)();
  TextColumn get payload => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
}

// ── DATABASE CLASS ───────────────────────────────────────────────────

@DriftDatabase(tables: [PartiesTable, TransactionsTable, BagMovementsTable, SyncQueueTable])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ──────────────────────────────────────────────────────────────────
  // PARTY OPERATIONS
  // ──────────────────────────────────────────────────────────────────

  Future<List<PartiesTableData>> getAllParties({
    String? type,
    String? search,
  }) {
    var query = select(partiesTable)
      ..where((p) => p.isActive.equals(true));

    if (type != null) {
      query.where((p) => p.partyType.equals(type));
    }
    if (search != null && search.isNotEmpty) {
      final s = '%$search%';
      query.where((p) =>
        p.name.like(s) | p.village.like(s) | p.phone.like(s)
      );
    }
    return (query..orderBy([(p) => OrderingTerm.asc(p.name)])).get();
  }

  Stream<List<PartiesTableData>> watchAllParties({String? type}) {
    var query = select(partiesTable)
      ..where((p) => p.isActive.equals(true))
      ..orderBy([(p) => OrderingTerm.asc(p.name)]);
    if (type != null) query.where((p) => p.partyType.equals(type));
    return query.watch();
  }

  Future<PartiesTableData?> getPartyById(String id) =>
      (select(partiesTable)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<void> upsertParty(PartiesTableCompanion party) =>
      into(partiesTable).insertOnConflictUpdate(party);

  Future<void> softDeleteParty(String id) =>
      (update(partiesTable)..where((p) => p.id.equals(id)))
          .write(PartiesTableCompanion(
            isActive: const Value(false),
            updatedAt: Value(DateTime.now().toIso8601String()),
          ));

  // ──────────────────────────────────────────────────────────────────
  // TRANSACTION OPERATIONS
  // ──────────────────────────────────────────────────────────────────

  Future<List<TransactionsTableData>> getTransactionsForParty(String partyId) =>
      (select(transactionsTable)
        ..where((t) => t.partyId.equals(partyId) & t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.entryDate)])
      ).get();

  Stream<List<TransactionsTableData>> watchRecentTransactions({int limit = 30}) =>
      (select(transactionsTable)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(limit)
      ).watch();

  Future<List<TransactionsTableData>> getTransactions({
    String? partyId,
    String? txnType,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) {
    var query = select(transactionsTable)
      ..where((t) => t.isDeleted.equals(false));
    if (partyId != null) query.where((t) => t.partyId.equals(partyId));
    if (txnType != null) query.where((t) => t.txnType.equals(txnType));
    if (from != null) query.where((t) => t.entryDate.isBiggerOrEqualValue(from.toIso8601String().substring(0,10)));
    if (to != null) query.where((t) => t.entryDate.isSmallerOrEqualValue(to.toIso8601String().substring(0,10)));
    query.orderBy([(t) => OrderingTerm.desc(t.entryDate)]);
    query.limit(limit, offset: offset);
    return query.get();
  }

  Future<void> upsertTransaction(TransactionsTableCompanion txn) =>
      into(transactionsTable).insertOnConflictUpdate(txn);

  Future<void> softDeleteTransaction(String id) =>
      (update(transactionsTable)..where((t) => t.id.equals(id)))
          .write(TransactionsTableCompanion(
            isDeleted: const Value(true),
            updatedAt: Value(DateTime.now().toIso8601String()),
          ));

  // ──────────────────────────────────────────────────────────────────
  // BALANCE (computed locally — no stored balance column)
  // ──────────────────────────────────────────────────────────────────

Future<double> getBalanceForParty(String partyId) async {
    final txns = await (select(transactionsTable)
      ..where((t) => t.partyId.equals(partyId) & t.isDeleted.equals(false))
    ).get();
    double balance = 0.0;
    for (final t in txns) {
      balance += t.direction == 'in' ? t.amount : -t.amount;
    }
    return balance;
  }

  // ──────────────────────────────────────────────────────────────────
  // BAG OPERATIONS
  // ──────────────────────────────────────────────────────────────────

  Future<List<BagMovementsTableData>> getBagMovementsForParty(String partyId) =>
      (select(bagMovementsTable)
        ..where((b) => b.partyId.equals(partyId))
        ..orderBy([(b) => OrderingTerm.desc(b.entryDate)])
      ).get();

Future<int> getBagsOutstandingForParty(String partyId) async {
    final rows = await (select(bagMovementsTable)
      ..where((b) => b.partyId.equals(partyId))
    ).get();
    int bags = 0;
    for (final b in rows) {
      bags += b.movement == 'given' ? b.quantity : -b.quantity;
    }
    return bags;
  }

  Future<int> getTotalOutstandingBags() async {
    final rows = await select(bagMovementsTable).get();
    int bags = 0;
    for (final b in rows) {
      bags += b.movement == 'given' ? b.quantity : -b.quantity;
    }
    return bags;
  }

  Stream<List<BagMovementsTableData>> watchRecentBagMovements({int limit = 30}) =>
      (select(bagMovementsTable)
        ..orderBy([(b) => OrderingTerm.desc(b.createdAt)])
        ..limit(limit)
      ).watch();

  Future<void> upsertBagMovement(BagMovementsTableCompanion bag) =>
      into(bagMovementsTable).insertOnConflictUpdate(bag);

  Future<void> deleteBagMovement(String id) =>
      (delete(bagMovementsTable)..where((b) => b.id.equals(id))).go();

  // ──────────────────────────────────────────────────────────────────
  // TODAY'S SUMMARY
  // ──────────────────────────────────────────────────────────────────

  Future<Map<String, double>> getTodaySummary() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final txns = await (select(transactionsTable)
      ..where((t) => t.entryDate.equals(today) & t.isDeleted.equals(false))
    ).get();

    double purchaseTotal = 0, saleTotal = 0, cashIn = 0, cashOut = 0;
    for (final t in txns) {
      switch (t.txnType) {
        case 'purchase': purchaseTotal += t.amount;
        case 'sale':     saleTotal += t.amount;
        case 'cash_in':  cashIn += t.amount;
        case 'cash_out': cashOut += t.amount;
      }
    }
    return {
      'purchase': purchaseTotal,
      'sale': saleTotal,
      'cash_in': cashIn,
      'cash_out': cashOut,
      'net': (saleTotal + cashIn) - (purchaseTotal + cashOut),
    };
  }

  // ──────────────────────────────────────────────────────────────────
  // SYNC QUEUE
  // ──────────────────────────────────────────────────────────────────

  Future<void> addToSyncQueue({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
  }) => into(syncQueueTable).insert(SyncQueueTableCompanion.insert(
    entityType: entityType,
    entityId: entityId,
    operation: operation,
    payload: payload,
    createdAt: DateTime.now().toIso8601String(),
  ));

  Future<List<SyncQueueTableData>> getPendingSyncItems() =>
      (select(syncQueueTable)
        ..orderBy([(s) => OrderingTerm.asc(s.id)])
        ..limit(50)
      ).get();

  Future<int> getPendingSyncCount() =>
      (select(syncQueueTable)).get().then((r) => r.length);

  Future<void> removeSyncItem(int id) =>
      (delete(syncQueueTable)..where((s) => s.id.equals(id))).go();

  Future<void> clearAllSyncQueue() => delete(syncQueueTable).go();

  Stream<int> watchPendingSyncCount() =>
      (select(syncQueueTable)).watch().map((r) => r.length);
}

// ── CONNECTION FACTORY ───────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'agriledger.sqlite'));
    return SqfliteQueryExecutor.inDatabaseFolder(path: file.path);
  });
}
