// lib/data/models/app_models.dart

/// Party (farmer / supplier / customer)
class PartyModel {
  final String id;
  final String name;
  final String partyType;
  final String? phone;
  final String? village;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  // Computed (from server or local query)
  final double balance;
  final int bagsOutstanding;
  final int totalTransactions;

  const PartyModel({
    required this.id,
    required this.name,
    required this.partyType,
    this.phone,
    this.village,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.balance = 0,
    this.bagsOutstanding = 0,
    this.totalTransactions = 0,
  });

  factory PartyModel.fromJson(Map<String, dynamic> j) => PartyModel(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    partyType: j['partyType'] ?? j['party_type'] ?? '',
    phone: j['phone'],
    village: j['village'],
    notes: j['notes'],
    isActive: j['isActive'] ?? j['is_active'] ?? true,
    createdAt: DateTime.tryParse(j['createdAt'] ?? j['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(j['updatedAt'] ?? j['updated_at'] ?? '') ?? DateTime.now(),
    syncedAt: j['syncedAt'] != null ? DateTime.tryParse(j['syncedAt']) : null,
    balance: (j['balance'] ?? 0).toDouble(),
    bagsOutstanding: j['bagsOutstanding'] ?? j['bags_outstanding'] ?? 0,
    totalTransactions: j['totalTransactions'] ?? j['total_transactions'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'partyType': partyType,
    'phone': phone,
    'village': village,
    'notes': notes,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
  };

  PartyModel copyWith({
    double? balance,
    int? bagsOutstanding,
    int? totalTransactions,
  }) => PartyModel(
    id: id, name: name, partyType: partyType, phone: phone,
    village: village, notes: notes, isActive: isActive,
    createdAt: createdAt, updatedAt: updatedAt, syncedAt: syncedAt,
    balance: balance ?? this.balance,
    bagsOutstanding: bagsOutstanding ?? this.bagsOutstanding,
    totalTransactions: totalTransactions ?? this.totalTransactions,
  );
}

/// Transaction (grain purchase/sale or cash movement)
class TransactionModel {
  final String id;
  final String partyId;
  final String partyName;
  final String txnType;       // purchase | sale | cash_in | cash_out
  final String? commodity;    // rice | wheat | maize
  final double? quantityKg;
  final double? ratePerKg;
  final double amount;
  final String direction;     // in | out
  final String paymentMode;
  final String? notes;
  final String? voiceRaw;
  final DateTime entryDate;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final bool isDeleted;

  const TransactionModel({
    required this.id,
    required this.partyId,
    this.partyName = '',
    required this.txnType,
    this.commodity,
    this.quantityKg,
    this.ratePerKg,
    required this.amount,
    required this.direction,
    this.paymentMode = 'cash',
    this.notes,
    this.voiceRaw,
    required this.entryDate,
    required this.createdAt,
    this.syncedAt,
    this.isDeleted = false,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
    id: j['id'] ?? '',
    partyId: j['partyId'] ?? j['party_id'] ?? '',
    partyName: j['partyName'] ?? j['party_name'] ?? '',
    txnType: j['txnType'] ?? j['txn_type'] ?? '',
    commodity: j['commodity'],
    quantityKg: j['quantityKg'] != null ? (j['quantityKg']).toDouble() : null,
    ratePerKg: j['ratePerKg'] != null ? (j['ratePerKg']).toDouble() : null,
    amount: (j['amount'] ?? 0).toDouble(),
    direction: j['direction'] ?? 'in',
    paymentMode: j['paymentMode'] ?? j['payment_mode'] ?? 'cash',
    notes: j['notes'],
    voiceRaw: j['voiceRaw'] ?? j['voice_raw'],
    entryDate: DateTime.tryParse(j['entryDate'] ?? j['entry_date'] ?? '') ?? DateTime.now(),
    createdAt: DateTime.tryParse(j['createdAt'] ?? j['created_at'] ?? '') ?? DateTime.now(),
    syncedAt: j['syncedAt'] != null ? DateTime.tryParse(j['syncedAt']) : null,
    isDeleted: j['isDeleted'] ?? j['is_deleted'] ?? false,
  );

  Map<String, dynamic> toJson() => {
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
    'entryDate': entryDate.toIso8601String().substring(0, 10),
    'createdAt': createdAt.toIso8601String(),
    if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
    'isDeleted': isDeleted,
  };
}

/// Jute bag movement
class BagMovementModel {
  final String id;
  final String partyId;
  final String partyName;
  final String movement;   // given | returned
  final int quantity;
  final String? linkedTxnId;
  final String? notes;
  final DateTime entryDate;
  final DateTime createdAt;
  final DateTime? syncedAt;

  const BagMovementModel({
    required this.id,
    required this.partyId,
    this.partyName = '',
    required this.movement,
    required this.quantity,
    this.linkedTxnId,
    this.notes,
    required this.entryDate,
    required this.createdAt,
    this.syncedAt,
  });

  factory BagMovementModel.fromJson(Map<String, dynamic> j) => BagMovementModel(
    id: j['id'] ?? '',
    partyId: j['partyId'] ?? j['party_id'] ?? '',
    partyName: j['partyName'] ?? j['party_name'] ?? '',
    movement: j['movement'] ?? '',
    quantity: j['quantity'] ?? 0,
    linkedTxnId: j['linkedTxnId'] ?? j['linked_txn_id'],
    notes: j['notes'],
    entryDate: DateTime.tryParse(j['entryDate'] ?? j['entry_date'] ?? '') ?? DateTime.now(),
    createdAt: DateTime.tryParse(j['createdAt'] ?? j['created_at'] ?? '') ?? DateTime.now(),
    syncedAt: j['syncedAt'] != null ? DateTime.tryParse(j['syncedAt']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'partyId': partyId,
    'movement': movement,
    'quantity': quantity,
    'linkedTxnId': linkedTxnId,
    'notes': notes,
    'entryDate': entryDate.toIso8601String().substring(0, 10),
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Full party ledger (from server or computed locally)
class PartyLedgerModel {
  final PartyModel party;
  final double balanceAmount;
  final String balanceDirection; // they_owe_us | we_owe_them | settled
  final int bagsOutstanding;
  final List<TransactionModel> transactions;
  final List<BagMovementModel> bagMovements;

  const PartyLedgerModel({
    required this.party,
    required this.balanceAmount,
    required this.balanceDirection,
    required this.bagsOutstanding,
    required this.transactions,
    required this.bagMovements,
  });

  factory PartyLedgerModel.fromJson(Map<String, dynamic> j) {
    final balanceMap = j['balance'] as Map<String, dynamic>? ?? {};
    return PartyLedgerModel(
      party: PartyModel.fromJson(j['party'] ?? {}),
      balanceAmount: (balanceMap['amount'] ?? 0).toDouble(),
      balanceDirection: balanceMap['direction'] ?? 'settled',
      bagsOutstanding: j['bagsOutstanding'] ?? j['bags_outstanding'] ?? 0,
      transactions: (j['transactions'] as List? ?? [])
          .map((t) => TransactionModel.fromJson(t))
          .toList(),
      bagMovements: (j['bagMovements'] ?? j['bag_movements'] as List? ?? [])
          .map((b) => BagMovementModel.fromJson(b))
          .toList(),
    );
  }
}

/// Daily summary from /transactions/summary
class DailySummaryModel {
  final DateTime date;
  final double totalPurchaseAmount;
  final double totalSaleAmount;
  final double totalCashIn;
  final double totalCashOut;
  final double netCash;
  final int totalTransactions;

  const DailySummaryModel({
    required this.date,
    required this.totalPurchaseAmount,
    required this.totalSaleAmount,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.netCash,
    required this.totalTransactions,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> j) => DailySummaryModel(
    date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
    totalPurchaseAmount: (j['totalPurchaseAmount'] ?? 0).toDouble(),
    totalSaleAmount: (j['totalSaleAmount'] ?? 0).toDouble(),
    totalCashIn: (j['totalCashIn'] ?? 0).toDouble(),
    totalCashOut: (j['totalCashOut'] ?? 0).toDouble(),
    netCash: (j['netCash'] ?? 0).toDouble(),
    totalTransactions: j['totalTransactions'] ?? 0,
  );
}
