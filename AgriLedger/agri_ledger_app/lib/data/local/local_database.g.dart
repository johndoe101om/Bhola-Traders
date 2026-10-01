// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $PartiesTableTable extends PartiesTable
    with TableInfo<$PartiesTableTable, PartiesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _partyTypeMeta =
      const VerificationMeta('partyType');
  @override
  late final GeneratedColumn<String> partyType = GeneratedColumn<String>(
      'party_type', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 15),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _villageMeta =
      const VerificationMeta('village');
  @override
  late final GeneratedColumn<String> village = GeneratedColumn<String>(
      'village', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        partyType,
        phone,
        village,
        notes,
        isActive,
        createdAt,
        updatedAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parties_table';
  @override
  VerificationContext validateIntegrity(Insertable<PartiesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('party_type')) {
      context.handle(_partyTypeMeta,
          partyType.isAcceptableOrUnknown(data['party_type']!, _partyTypeMeta));
    } else if (isInserting) {
      context.missing(_partyTypeMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('village')) {
      context.handle(_villageMeta,
          village.isAcceptableOrUnknown(data['village']!, _villageMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PartiesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PartiesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      partyType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}party_type'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      village: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}village']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $PartiesTableTable createAlias(String alias) {
    return $PartiesTableTable(attachedDatabase, alias);
  }
}

class PartiesTableData extends DataClass
    implements Insertable<PartiesTableData> {
  final String id;
  final String name;
  final String partyType;
  final String? phone;
  final String? village;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? syncedAt;
  const PartiesTableData(
      {required this.id,
      required this.name,
      required this.partyType,
      this.phone,
      this.village,
      this.notes,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['party_type'] = Variable<String>(partyType);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || village != null) {
      map['village'] = Variable<String>(village);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<String>(syncedAt);
    }
    return map;
  }

  PartiesTableCompanion toCompanion(bool nullToAbsent) {
    return PartiesTableCompanion(
      id: Value(id),
      name: Value(name),
      partyType: Value(partyType),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      village: village == null && nullToAbsent
          ? const Value.absent()
          : Value(village),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory PartiesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PartiesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      partyType: serializer.fromJson<String>(json['partyType']),
      phone: serializer.fromJson<String?>(json['phone']),
      village: serializer.fromJson<String?>(json['village']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncedAt: serializer.fromJson<String?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'partyType': serializer.toJson<String>(partyType),
      'phone': serializer.toJson<String?>(phone),
      'village': serializer.toJson<String?>(village),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncedAt': serializer.toJson<String?>(syncedAt),
    };
  }

  PartiesTableData copyWith(
          {String? id,
          String? name,
          String? partyType,
          Value<String?> phone = const Value.absent(),
          Value<String?> village = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? isActive,
          String? createdAt,
          String? updatedAt,
          Value<String?> syncedAt = const Value.absent()}) =>
      PartiesTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        partyType: partyType ?? this.partyType,
        phone: phone.present ? phone.value : this.phone,
        village: village.present ? village.value : this.village,
        notes: notes.present ? notes.value : this.notes,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  PartiesTableData copyWithCompanion(PartiesTableCompanion data) {
    return PartiesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      partyType: data.partyType.present ? data.partyType.value : this.partyType,
      phone: data.phone.present ? data.phone.value : this.phone,
      village: data.village.present ? data.village.value : this.village,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PartiesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('partyType: $partyType, ')
          ..write('phone: $phone, ')
          ..write('village: $village, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, partyType, phone, village, notes,
      isActive, createdAt, updatedAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartiesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.partyType == this.partyType &&
          other.phone == this.phone &&
          other.village == this.village &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class PartiesTableCompanion extends UpdateCompanion<PartiesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> partyType;
  final Value<String?> phone;
  final Value<String?> village;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> syncedAt;
  final Value<int> rowid;
  const PartiesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.partyType = const Value.absent(),
    this.phone = const Value.absent(),
    this.village = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PartiesTableCompanion.insert({
    required String id,
    required String name,
    required String partyType,
    this.phone = const Value.absent(),
    this.village = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        partyType = Value(partyType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PartiesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? partyType,
    Expression<String>? phone,
    Expression<String>? village,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (partyType != null) 'party_type': partyType,
      if (phone != null) 'phone': phone,
      if (village != null) 'village': village,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PartiesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? partyType,
      Value<String?>? phone,
      Value<String?>? village,
      Value<String?>? notes,
      Value<bool>? isActive,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? syncedAt,
      Value<int>? rowid}) {
    return PartiesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      partyType: partyType ?? this.partyType,
      phone: phone ?? this.phone,
      village: village ?? this.village,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (partyType.present) {
      map['party_type'] = Variable<String>(partyType.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (village.present) {
      map['village'] = Variable<String>(village.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartiesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('partyType: $partyType, ')
          ..write('phone: $phone, ')
          ..write('village: $village, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTableTable extends TransactionsTable
    with TableInfo<$TransactionsTableTable, TransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _partyIdMeta =
      const VerificationMeta('partyId');
  @override
  late final GeneratedColumn<String> partyId = GeneratedColumn<String>(
      'party_id', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES parties_table (id)'));
  static const VerificationMeta _txnTypeMeta =
      const VerificationMeta('txnType');
  @override
  late final GeneratedColumn<String> txnType = GeneratedColumn<String>(
      'txn_type', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _commodityMeta =
      const VerificationMeta('commodity');
  @override
  late final GeneratedColumn<String> commodity = GeneratedColumn<String>(
      'commodity', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _quantityKgMeta =
      const VerificationMeta('quantityKg');
  @override
  late final GeneratedColumn<double> quantityKg = GeneratedColumn<double>(
      'quantity_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _ratePerKgMeta =
      const VerificationMeta('ratePerKg');
  @override
  late final GeneratedColumn<double> ratePerKg = GeneratedColumn<double>(
      'rate_per_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 5),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _paymentModeMeta =
      const VerificationMeta('paymentMode');
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
      'payment_mode', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _voiceRawMeta =
      const VerificationMeta('voiceRaw');
  @override
  late final GeneratedColumn<String> voiceRaw = GeneratedColumn<String>(
      'voice_raw', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entryDateMeta =
      const VerificationMeta('entryDate');
  @override
  late final GeneratedColumn<String> entryDate = GeneratedColumn<String>(
      'entry_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        partyId,
        txnType,
        commodity,
        quantityKg,
        ratePerKg,
        amount,
        direction,
        paymentMode,
        notes,
        voiceRaw,
        entryDate,
        createdAt,
        updatedAt,
        syncedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransactionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('party_id')) {
      context.handle(_partyIdMeta,
          partyId.isAcceptableOrUnknown(data['party_id']!, _partyIdMeta));
    } else if (isInserting) {
      context.missing(_partyIdMeta);
    }
    if (data.containsKey('txn_type')) {
      context.handle(_txnTypeMeta,
          txnType.isAcceptableOrUnknown(data['txn_type']!, _txnTypeMeta));
    } else if (isInserting) {
      context.missing(_txnTypeMeta);
    }
    if (data.containsKey('commodity')) {
      context.handle(_commodityMeta,
          commodity.isAcceptableOrUnknown(data['commodity']!, _commodityMeta));
    }
    if (data.containsKey('quantity_kg')) {
      context.handle(
          _quantityKgMeta,
          quantityKg.isAcceptableOrUnknown(
              data['quantity_kg']!, _quantityKgMeta));
    }
    if (data.containsKey('rate_per_kg')) {
      context.handle(
          _ratePerKgMeta,
          ratePerKg.isAcceptableOrUnknown(
              data['rate_per_kg']!, _ratePerKgMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
          _paymentModeMeta,
          paymentMode.isAcceptableOrUnknown(
              data['payment_mode']!, _paymentModeMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('voice_raw')) {
      context.handle(_voiceRawMeta,
          voiceRaw.isAcceptableOrUnknown(data['voice_raw']!, _voiceRawMeta));
    }
    if (data.containsKey('entry_date')) {
      context.handle(_entryDateMeta,
          entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta));
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      partyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}party_id'])!,
      txnType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}txn_type'])!,
      commodity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}commodity']),
      quantityKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity_kg']),
      ratePerKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate_per_kg']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      paymentMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_mode'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      voiceRaw: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}voice_raw']),
      entryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synced_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $TransactionsTableTable createAlias(String alias) {
    return $TransactionsTableTable(attachedDatabase, alias);
  }
}

class TransactionsTableData extends DataClass
    implements Insertable<TransactionsTableData> {
  final String id;
  final String partyId;
  final String txnType;
  final String? commodity;
  final double? quantityKg;
  final double? ratePerKg;
  final double amount;
  final String direction;
  final String paymentMode;
  final String? notes;
  final String? voiceRaw;
  final String entryDate;
  final String createdAt;
  final String updatedAt;
  final String? syncedAt;
  final bool isDeleted;
  const TransactionsTableData(
      {required this.id,
      required this.partyId,
      required this.txnType,
      this.commodity,
      this.quantityKg,
      this.ratePerKg,
      required this.amount,
      required this.direction,
      required this.paymentMode,
      this.notes,
      this.voiceRaw,
      required this.entryDate,
      required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['party_id'] = Variable<String>(partyId);
    map['txn_type'] = Variable<String>(txnType);
    if (!nullToAbsent || commodity != null) {
      map['commodity'] = Variable<String>(commodity);
    }
    if (!nullToAbsent || quantityKg != null) {
      map['quantity_kg'] = Variable<double>(quantityKg);
    }
    if (!nullToAbsent || ratePerKg != null) {
      map['rate_per_kg'] = Variable<double>(ratePerKg);
    }
    map['amount'] = Variable<double>(amount);
    map['direction'] = Variable<String>(direction);
    map['payment_mode'] = Variable<String>(paymentMode);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || voiceRaw != null) {
      map['voice_raw'] = Variable<String>(voiceRaw);
    }
    map['entry_date'] = Variable<String>(entryDate);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<String>(syncedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  TransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsTableCompanion(
      id: Value(id),
      partyId: Value(partyId),
      txnType: Value(txnType),
      commodity: commodity == null && nullToAbsent
          ? const Value.absent()
          : Value(commodity),
      quantityKg: quantityKg == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityKg),
      ratePerKg: ratePerKg == null && nullToAbsent
          ? const Value.absent()
          : Value(ratePerKg),
      amount: Value(amount),
      direction: Value(direction),
      paymentMode: Value(paymentMode),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      voiceRaw: voiceRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceRaw),
      entryDate: Value(entryDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory TransactionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsTableData(
      id: serializer.fromJson<String>(json['id']),
      partyId: serializer.fromJson<String>(json['partyId']),
      txnType: serializer.fromJson<String>(json['txnType']),
      commodity: serializer.fromJson<String?>(json['commodity']),
      quantityKg: serializer.fromJson<double?>(json['quantityKg']),
      ratePerKg: serializer.fromJson<double?>(json['ratePerKg']),
      amount: serializer.fromJson<double>(json['amount']),
      direction: serializer.fromJson<String>(json['direction']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
      notes: serializer.fromJson<String?>(json['notes']),
      voiceRaw: serializer.fromJson<String?>(json['voiceRaw']),
      entryDate: serializer.fromJson<String>(json['entryDate']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncedAt: serializer.fromJson<String?>(json['syncedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'partyId': serializer.toJson<String>(partyId),
      'txnType': serializer.toJson<String>(txnType),
      'commodity': serializer.toJson<String?>(commodity),
      'quantityKg': serializer.toJson<double?>(quantityKg),
      'ratePerKg': serializer.toJson<double?>(ratePerKg),
      'amount': serializer.toJson<double>(amount),
      'direction': serializer.toJson<String>(direction),
      'paymentMode': serializer.toJson<String>(paymentMode),
      'notes': serializer.toJson<String?>(notes),
      'voiceRaw': serializer.toJson<String?>(voiceRaw),
      'entryDate': serializer.toJson<String>(entryDate),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncedAt': serializer.toJson<String?>(syncedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  TransactionsTableData copyWith(
          {String? id,
          String? partyId,
          String? txnType,
          Value<String?> commodity = const Value.absent(),
          Value<double?> quantityKg = const Value.absent(),
          Value<double?> ratePerKg = const Value.absent(),
          double? amount,
          String? direction,
          String? paymentMode,
          Value<String?> notes = const Value.absent(),
          Value<String?> voiceRaw = const Value.absent(),
          String? entryDate,
          String? createdAt,
          String? updatedAt,
          Value<String?> syncedAt = const Value.absent(),
          bool? isDeleted}) =>
      TransactionsTableData(
        id: id ?? this.id,
        partyId: partyId ?? this.partyId,
        txnType: txnType ?? this.txnType,
        commodity: commodity.present ? commodity.value : this.commodity,
        quantityKg: quantityKg.present ? quantityKg.value : this.quantityKg,
        ratePerKg: ratePerKg.present ? ratePerKg.value : this.ratePerKg,
        amount: amount ?? this.amount,
        direction: direction ?? this.direction,
        paymentMode: paymentMode ?? this.paymentMode,
        notes: notes.present ? notes.value : this.notes,
        voiceRaw: voiceRaw.present ? voiceRaw.value : this.voiceRaw,
        entryDate: entryDate ?? this.entryDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  TransactionsTableData copyWithCompanion(TransactionsTableCompanion data) {
    return TransactionsTableData(
      id: data.id.present ? data.id.value : this.id,
      partyId: data.partyId.present ? data.partyId.value : this.partyId,
      txnType: data.txnType.present ? data.txnType.value : this.txnType,
      commodity: data.commodity.present ? data.commodity.value : this.commodity,
      quantityKg:
          data.quantityKg.present ? data.quantityKg.value : this.quantityKg,
      ratePerKg: data.ratePerKg.present ? data.ratePerKg.value : this.ratePerKg,
      amount: data.amount.present ? data.amount.value : this.amount,
      direction: data.direction.present ? data.direction.value : this.direction,
      paymentMode:
          data.paymentMode.present ? data.paymentMode.value : this.paymentMode,
      notes: data.notes.present ? data.notes.value : this.notes,
      voiceRaw: data.voiceRaw.present ? data.voiceRaw.value : this.voiceRaw,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableData(')
          ..write('id: $id, ')
          ..write('partyId: $partyId, ')
          ..write('txnType: $txnType, ')
          ..write('commodity: $commodity, ')
          ..write('quantityKg: $quantityKg, ')
          ..write('ratePerKg: $ratePerKg, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('notes: $notes, ')
          ..write('voiceRaw: $voiceRaw, ')
          ..write('entryDate: $entryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      partyId,
      txnType,
      commodity,
      quantityKg,
      ratePerKg,
      amount,
      direction,
      paymentMode,
      notes,
      voiceRaw,
      entryDate,
      createdAt,
      updatedAt,
      syncedAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsTableData &&
          other.id == this.id &&
          other.partyId == this.partyId &&
          other.txnType == this.txnType &&
          other.commodity == this.commodity &&
          other.quantityKg == this.quantityKg &&
          other.ratePerKg == this.ratePerKg &&
          other.amount == this.amount &&
          other.direction == this.direction &&
          other.paymentMode == this.paymentMode &&
          other.notes == this.notes &&
          other.voiceRaw == this.voiceRaw &&
          other.entryDate == this.entryDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.isDeleted == this.isDeleted);
}

class TransactionsTableCompanion
    extends UpdateCompanion<TransactionsTableData> {
  final Value<String> id;
  final Value<String> partyId;
  final Value<String> txnType;
  final Value<String?> commodity;
  final Value<double?> quantityKg;
  final Value<double?> ratePerKg;
  final Value<double> amount;
  final Value<String> direction;
  final Value<String> paymentMode;
  final Value<String?> notes;
  final Value<String?> voiceRaw;
  final Value<String> entryDate;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> syncedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const TransactionsTableCompanion({
    this.id = const Value.absent(),
    this.partyId = const Value.absent(),
    this.txnType = const Value.absent(),
    this.commodity = const Value.absent(),
    this.quantityKg = const Value.absent(),
    this.ratePerKg = const Value.absent(),
    this.amount = const Value.absent(),
    this.direction = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.notes = const Value.absent(),
    this.voiceRaw = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsTableCompanion.insert({
    required String id,
    required String partyId,
    required String txnType,
    this.commodity = const Value.absent(),
    this.quantityKg = const Value.absent(),
    this.ratePerKg = const Value.absent(),
    required double amount,
    required String direction,
    this.paymentMode = const Value.absent(),
    this.notes = const Value.absent(),
    this.voiceRaw = const Value.absent(),
    required String entryDate,
    required String createdAt,
    required String updatedAt,
    this.syncedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        partyId = Value(partyId),
        txnType = Value(txnType),
        amount = Value(amount),
        direction = Value(direction),
        entryDate = Value(entryDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TransactionsTableData> custom({
    Expression<String>? id,
    Expression<String>? partyId,
    Expression<String>? txnType,
    Expression<String>? commodity,
    Expression<double>? quantityKg,
    Expression<double>? ratePerKg,
    Expression<double>? amount,
    Expression<String>? direction,
    Expression<String>? paymentMode,
    Expression<String>? notes,
    Expression<String>? voiceRaw,
    Expression<String>? entryDate,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? syncedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partyId != null) 'party_id': partyId,
      if (txnType != null) 'txn_type': txnType,
      if (commodity != null) 'commodity': commodity,
      if (quantityKg != null) 'quantity_kg': quantityKg,
      if (ratePerKg != null) 'rate_per_kg': ratePerKg,
      if (amount != null) 'amount': amount,
      if (direction != null) 'direction': direction,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (notes != null) 'notes': notes,
      if (voiceRaw != null) 'voice_raw': voiceRaw,
      if (entryDate != null) 'entry_date': entryDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? partyId,
      Value<String>? txnType,
      Value<String?>? commodity,
      Value<double?>? quantityKg,
      Value<double?>? ratePerKg,
      Value<double>? amount,
      Value<String>? direction,
      Value<String>? paymentMode,
      Value<String?>? notes,
      Value<String?>? voiceRaw,
      Value<String>? entryDate,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? syncedAt,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return TransactionsTableCompanion(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      txnType: txnType ?? this.txnType,
      commodity: commodity ?? this.commodity,
      quantityKg: quantityKg ?? this.quantityKg,
      ratePerKg: ratePerKg ?? this.ratePerKg,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      voiceRaw: voiceRaw ?? this.voiceRaw,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (partyId.present) {
      map['party_id'] = Variable<String>(partyId.value);
    }
    if (txnType.present) {
      map['txn_type'] = Variable<String>(txnType.value);
    }
    if (commodity.present) {
      map['commodity'] = Variable<String>(commodity.value);
    }
    if (quantityKg.present) {
      map['quantity_kg'] = Variable<double>(quantityKg.value);
    }
    if (ratePerKg.present) {
      map['rate_per_kg'] = Variable<double>(ratePerKg.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (voiceRaw.present) {
      map['voice_raw'] = Variable<String>(voiceRaw.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<String>(entryDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('partyId: $partyId, ')
          ..write('txnType: $txnType, ')
          ..write('commodity: $commodity, ')
          ..write('quantityKg: $quantityKg, ')
          ..write('ratePerKg: $ratePerKg, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('notes: $notes, ')
          ..write('voiceRaw: $voiceRaw, ')
          ..write('entryDate: $entryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BagMovementsTableTable extends BagMovementsTable
    with TableInfo<$BagMovementsTableTable, BagMovementsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BagMovementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _partyIdMeta =
      const VerificationMeta('partyId');
  @override
  late final GeneratedColumn<String> partyId = GeneratedColumn<String>(
      'party_id', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES parties_table (id)'));
  static const VerificationMeta _movementMeta =
      const VerificationMeta('movement');
  @override
  late final GeneratedColumn<String> movement = GeneratedColumn<String>(
      'movement', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _linkedTxnIdMeta =
      const VerificationMeta('linkedTxnId');
  @override
  late final GeneratedColumn<String> linkedTxnId = GeneratedColumn<String>(
      'linked_txn_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entryDateMeta =
      const VerificationMeta('entryDate');
  @override
  late final GeneratedColumn<String> entryDate = GeneratedColumn<String>(
      'entry_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        partyId,
        movement,
        quantity,
        linkedTxnId,
        notes,
        entryDate,
        createdAt,
        updatedAt,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bag_movements_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<BagMovementsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('party_id')) {
      context.handle(_partyIdMeta,
          partyId.isAcceptableOrUnknown(data['party_id']!, _partyIdMeta));
    } else if (isInserting) {
      context.missing(_partyIdMeta);
    }
    if (data.containsKey('movement')) {
      context.handle(_movementMeta,
          movement.isAcceptableOrUnknown(data['movement']!, _movementMeta));
    } else if (isInserting) {
      context.missing(_movementMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('linked_txn_id')) {
      context.handle(
          _linkedTxnIdMeta,
          linkedTxnId.isAcceptableOrUnknown(
              data['linked_txn_id']!, _linkedTxnIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('entry_date')) {
      context.handle(_entryDateMeta,
          entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta));
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BagMovementsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BagMovementsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      partyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}party_id'])!,
      movement: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}movement'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      linkedTxnId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}linked_txn_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      entryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $BagMovementsTableTable createAlias(String alias) {
    return $BagMovementsTableTable(attachedDatabase, alias);
  }
}

class BagMovementsTableData extends DataClass
    implements Insertable<BagMovementsTableData> {
  final String id;
  final String partyId;
  final String movement;
  final int quantity;
  final String? linkedTxnId;
  final String? notes;
  final String entryDate;
  final String createdAt;
  final String updatedAt;
  final String? syncedAt;
  const BagMovementsTableData(
      {required this.id,
      required this.partyId,
      required this.movement,
      required this.quantity,
      this.linkedTxnId,
      this.notes,
      required this.entryDate,
      required this.createdAt,
      required this.updatedAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['party_id'] = Variable<String>(partyId);
    map['movement'] = Variable<String>(movement);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || linkedTxnId != null) {
      map['linked_txn_id'] = Variable<String>(linkedTxnId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['entry_date'] = Variable<String>(entryDate);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<String>(syncedAt);
    }
    return map;
  }

  BagMovementsTableCompanion toCompanion(bool nullToAbsent) {
    return BagMovementsTableCompanion(
      id: Value(id),
      partyId: Value(partyId),
      movement: Value(movement),
      quantity: Value(quantity),
      linkedTxnId: linkedTxnId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTxnId),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      entryDate: Value(entryDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory BagMovementsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BagMovementsTableData(
      id: serializer.fromJson<String>(json['id']),
      partyId: serializer.fromJson<String>(json['partyId']),
      movement: serializer.fromJson<String>(json['movement']),
      quantity: serializer.fromJson<int>(json['quantity']),
      linkedTxnId: serializer.fromJson<String?>(json['linkedTxnId']),
      notes: serializer.fromJson<String?>(json['notes']),
      entryDate: serializer.fromJson<String>(json['entryDate']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncedAt: serializer.fromJson<String?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'partyId': serializer.toJson<String>(partyId),
      'movement': serializer.toJson<String>(movement),
      'quantity': serializer.toJson<int>(quantity),
      'linkedTxnId': serializer.toJson<String?>(linkedTxnId),
      'notes': serializer.toJson<String?>(notes),
      'entryDate': serializer.toJson<String>(entryDate),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncedAt': serializer.toJson<String?>(syncedAt),
    };
  }

  BagMovementsTableData copyWith(
          {String? id,
          String? partyId,
          String? movement,
          int? quantity,
          Value<String?> linkedTxnId = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? entryDate,
          String? createdAt,
          String? updatedAt,
          Value<String?> syncedAt = const Value.absent()}) =>
      BagMovementsTableData(
        id: id ?? this.id,
        partyId: partyId ?? this.partyId,
        movement: movement ?? this.movement,
        quantity: quantity ?? this.quantity,
        linkedTxnId: linkedTxnId.present ? linkedTxnId.value : this.linkedTxnId,
        notes: notes.present ? notes.value : this.notes,
        entryDate: entryDate ?? this.entryDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  BagMovementsTableData copyWithCompanion(BagMovementsTableCompanion data) {
    return BagMovementsTableData(
      id: data.id.present ? data.id.value : this.id,
      partyId: data.partyId.present ? data.partyId.value : this.partyId,
      movement: data.movement.present ? data.movement.value : this.movement,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      linkedTxnId:
          data.linkedTxnId.present ? data.linkedTxnId.value : this.linkedTxnId,
      notes: data.notes.present ? data.notes.value : this.notes,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BagMovementsTableData(')
          ..write('id: $id, ')
          ..write('partyId: $partyId, ')
          ..write('movement: $movement, ')
          ..write('quantity: $quantity, ')
          ..write('linkedTxnId: $linkedTxnId, ')
          ..write('notes: $notes, ')
          ..write('entryDate: $entryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, partyId, movement, quantity, linkedTxnId,
      notes, entryDate, createdAt, updatedAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BagMovementsTableData &&
          other.id == this.id &&
          other.partyId == this.partyId &&
          other.movement == this.movement &&
          other.quantity == this.quantity &&
          other.linkedTxnId == this.linkedTxnId &&
          other.notes == this.notes &&
          other.entryDate == this.entryDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class BagMovementsTableCompanion
    extends UpdateCompanion<BagMovementsTableData> {
  final Value<String> id;
  final Value<String> partyId;
  final Value<String> movement;
  final Value<int> quantity;
  final Value<String?> linkedTxnId;
  final Value<String?> notes;
  final Value<String> entryDate;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> syncedAt;
  final Value<int> rowid;
  const BagMovementsTableCompanion({
    this.id = const Value.absent(),
    this.partyId = const Value.absent(),
    this.movement = const Value.absent(),
    this.quantity = const Value.absent(),
    this.linkedTxnId = const Value.absent(),
    this.notes = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BagMovementsTableCompanion.insert({
    required String id,
    required String partyId,
    required String movement,
    required int quantity,
    this.linkedTxnId = const Value.absent(),
    this.notes = const Value.absent(),
    required String entryDate,
    required String createdAt,
    required String updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        partyId = Value(partyId),
        movement = Value(movement),
        quantity = Value(quantity),
        entryDate = Value(entryDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<BagMovementsTableData> custom({
    Expression<String>? id,
    Expression<String>? partyId,
    Expression<String>? movement,
    Expression<int>? quantity,
    Expression<String>? linkedTxnId,
    Expression<String>? notes,
    Expression<String>? entryDate,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partyId != null) 'party_id': partyId,
      if (movement != null) 'movement': movement,
      if (quantity != null) 'quantity': quantity,
      if (linkedTxnId != null) 'linked_txn_id': linkedTxnId,
      if (notes != null) 'notes': notes,
      if (entryDate != null) 'entry_date': entryDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BagMovementsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? partyId,
      Value<String>? movement,
      Value<int>? quantity,
      Value<String?>? linkedTxnId,
      Value<String?>? notes,
      Value<String>? entryDate,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? syncedAt,
      Value<int>? rowid}) {
    return BagMovementsTableCompanion(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      movement: movement ?? this.movement,
      quantity: quantity ?? this.quantity,
      linkedTxnId: linkedTxnId ?? this.linkedTxnId,
      notes: notes ?? this.notes,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (partyId.present) {
      map['party_id'] = Variable<String>(partyId.value);
    }
    if (movement.present) {
      map['movement'] = Variable<String>(movement.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (linkedTxnId.present) {
      map['linked_txn_id'] = Variable<String>(linkedTxnId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<String>(entryDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BagMovementsTableCompanion(')
          ..write('id: $id, ')
          ..write('partyId: $partyId, ')
          ..write('movement: $movement, ')
          ..write('quantity: $quantity, ')
          ..write('linkedTxnId: $linkedTxnId, ')
          ..write('notes: $notes, ')
          ..write('entryDate: $entryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entityType, entityId, operation, payload, retryCount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload;
  final int retryCount;
  final String createdAt;
  const SyncQueueTableData(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payload,
      required this.retryCount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  SyncQueueTableData copyWith(
          {int? id,
          String? entityType,
          String? entityId,
          String? operation,
          String? payload,
          int? retryCount,
          String? createdAt}) =>
      SyncQueueTableData(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payload: payload ?? this.payload,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, entityType, entityId, operation, payload, retryCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int> retryCount;
  final Value<String> createdAt;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    this.retryCount = const Value.absent(),
    required String createdAt,
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? retryCount,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payload,
      Value<int>? retryCount,
      Value<String>? createdAt}) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $PartiesTableTable partiesTable = $PartiesTableTable(this);
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $BagMovementsTableTable bagMovementsTable =
      $BagMovementsTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [partiesTable, transactionsTable, bagMovementsTable, syncQueueTable];
}

typedef $$PartiesTableTableCreateCompanionBuilder = PartiesTableCompanion
    Function({
  required String id,
  required String name,
  required String partyType,
  Value<String?> phone,
  Value<String?> village,
  Value<String?> notes,
  Value<bool> isActive,
  required String createdAt,
  required String updatedAt,
  Value<String?> syncedAt,
  Value<int> rowid,
});
typedef $$PartiesTableTableUpdateCompanionBuilder = PartiesTableCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> partyType,
  Value<String?> phone,
  Value<String?> village,
  Value<String?> notes,
  Value<bool> isActive,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> syncedAt,
  Value<int> rowid,
});

class $$PartiesTableTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $PartiesTableTable,
    PartiesTableData,
    $$PartiesTableTableFilterComposer,
    $$PartiesTableTableOrderingComposer,
    $$PartiesTableTableCreateCompanionBuilder,
    $$PartiesTableTableUpdateCompanionBuilder> {
  $$PartiesTableTableTableManager(_$LocalDatabase db, $PartiesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PartiesTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PartiesTableTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> partyType = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> village = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PartiesTableCompanion(
            id: id,
            name: name,
            partyType: partyType,
            phone: phone,
            village: village,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String partyType,
            Value<String?> phone = const Value.absent(),
            Value<String?> village = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<String?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PartiesTableCompanion.insert(
            id: id,
            name: name,
            partyType: partyType,
            phone: phone,
            village: village,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
        ));
}

class $$PartiesTableTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $PartiesTableTable> {
  $$PartiesTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get partyType => $state.composableBuilder(
      column: $state.table.partyType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get village => $state.composableBuilder(
      column: $state.table.village,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter transactionsTableRefs(
      ComposableFilter Function($$TransactionsTableTableFilterComposer f) f) {
    final $$TransactionsTableTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.transactionsTable,
            getReferencedColumn: (t) => t.partyId,
            builder: (joinBuilder, parentComposers) =>
                $$TransactionsTableTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.transactionsTable,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter bagMovementsTableRefs(
      ComposableFilter Function($$BagMovementsTableTableFilterComposer f) f) {
    final $$BagMovementsTableTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.bagMovementsTable,
            getReferencedColumn: (t) => t.partyId,
            builder: (joinBuilder, parentComposers) =>
                $$BagMovementsTableTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.bagMovementsTable,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }
}

class $$PartiesTableTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $PartiesTableTable> {
  $$PartiesTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get partyType => $state.composableBuilder(
      column: $state.table.partyType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get village => $state.composableBuilder(
      column: $state.table.village,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TransactionsTableTableCreateCompanionBuilder
    = TransactionsTableCompanion Function({
  required String id,
  required String partyId,
  required String txnType,
  Value<String?> commodity,
  Value<double?> quantityKg,
  Value<double?> ratePerKg,
  required double amount,
  required String direction,
  Value<String> paymentMode,
  Value<String?> notes,
  Value<String?> voiceRaw,
  required String entryDate,
  required String createdAt,
  required String updatedAt,
  Value<String?> syncedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$TransactionsTableTableUpdateCompanionBuilder
    = TransactionsTableCompanion Function({
  Value<String> id,
  Value<String> partyId,
  Value<String> txnType,
  Value<String?> commodity,
  Value<double?> quantityKg,
  Value<double?> ratePerKg,
  Value<double> amount,
  Value<String> direction,
  Value<String> paymentMode,
  Value<String?> notes,
  Value<String?> voiceRaw,
  Value<String> entryDate,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> syncedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});

class $$TransactionsTableTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $TransactionsTableTable,
    TransactionsTableData,
    $$TransactionsTableTableFilterComposer,
    $$TransactionsTableTableOrderingComposer,
    $$TransactionsTableTableCreateCompanionBuilder,
    $$TransactionsTableTableUpdateCompanionBuilder> {
  $$TransactionsTableTableTableManager(
      _$LocalDatabase db, $TransactionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TransactionsTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$TransactionsTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> partyId = const Value.absent(),
            Value<String> txnType = const Value.absent(),
            Value<String?> commodity = const Value.absent(),
            Value<double?> quantityKg = const Value.absent(),
            Value<double?> ratePerKg = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String> paymentMode = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> voiceRaw = const Value.absent(),
            Value<String> entryDate = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> syncedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsTableCompanion(
            id: id,
            partyId: partyId,
            txnType: txnType,
            commodity: commodity,
            quantityKg: quantityKg,
            ratePerKg: ratePerKg,
            amount: amount,
            direction: direction,
            paymentMode: paymentMode,
            notes: notes,
            voiceRaw: voiceRaw,
            entryDate: entryDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String partyId,
            required String txnType,
            Value<String?> commodity = const Value.absent(),
            Value<double?> quantityKg = const Value.absent(),
            Value<double?> ratePerKg = const Value.absent(),
            required double amount,
            required String direction,
            Value<String> paymentMode = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> voiceRaw = const Value.absent(),
            required String entryDate,
            required String createdAt,
            required String updatedAt,
            Value<String?> syncedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsTableCompanion.insert(
            id: id,
            partyId: partyId,
            txnType: txnType,
            commodity: commodity,
            quantityKg: quantityKg,
            ratePerKg: ratePerKg,
            amount: amount,
            direction: direction,
            paymentMode: paymentMode,
            notes: notes,
            voiceRaw: voiceRaw,
            entryDate: entryDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
        ));
}

class $$TransactionsTableTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get txnType => $state.composableBuilder(
      column: $state.table.txnType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get commodity => $state.composableBuilder(
      column: $state.table.commodity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get quantityKg => $state.composableBuilder(
      column: $state.table.quantityKg,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get ratePerKg => $state.composableBuilder(
      column: $state.table.ratePerKg,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get direction => $state.composableBuilder(
      column: $state.table.direction,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get paymentMode => $state.composableBuilder(
      column: $state.table.paymentMode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get voiceRaw => $state.composableBuilder(
      column: $state.table.voiceRaw,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entryDate => $state.composableBuilder(
      column: $state.table.entryDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$PartiesTableTableFilterComposer get partyId {
    final $$PartiesTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partyId,
        referencedTable: $state.db.partiesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$PartiesTableTableFilterComposer(ComposerState($state.db,
                $state.db.partiesTable, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$TransactionsTableTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get txnType => $state.composableBuilder(
      column: $state.table.txnType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get commodity => $state.composableBuilder(
      column: $state.table.commodity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get quantityKg => $state.composableBuilder(
      column: $state.table.quantityKg,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get ratePerKg => $state.composableBuilder(
      column: $state.table.ratePerKg,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get direction => $state.composableBuilder(
      column: $state.table.direction,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get paymentMode => $state.composableBuilder(
      column: $state.table.paymentMode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get voiceRaw => $state.composableBuilder(
      column: $state.table.voiceRaw,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entryDate => $state.composableBuilder(
      column: $state.table.entryDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$PartiesTableTableOrderingComposer get partyId {
    final $$PartiesTableTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partyId,
        referencedTable: $state.db.partiesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$PartiesTableTableOrderingComposer(ComposerState($state.db,
                $state.db.partiesTable, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$BagMovementsTableTableCreateCompanionBuilder
    = BagMovementsTableCompanion Function({
  required String id,
  required String partyId,
  required String movement,
  required int quantity,
  Value<String?> linkedTxnId,
  Value<String?> notes,
  required String entryDate,
  required String createdAt,
  required String updatedAt,
  Value<String?> syncedAt,
  Value<int> rowid,
});
typedef $$BagMovementsTableTableUpdateCompanionBuilder
    = BagMovementsTableCompanion Function({
  Value<String> id,
  Value<String> partyId,
  Value<String> movement,
  Value<int> quantity,
  Value<String?> linkedTxnId,
  Value<String?> notes,
  Value<String> entryDate,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> syncedAt,
  Value<int> rowid,
});

class $$BagMovementsTableTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $BagMovementsTableTable,
    BagMovementsTableData,
    $$BagMovementsTableTableFilterComposer,
    $$BagMovementsTableTableOrderingComposer,
    $$BagMovementsTableTableCreateCompanionBuilder,
    $$BagMovementsTableTableUpdateCompanionBuilder> {
  $$BagMovementsTableTableTableManager(
      _$LocalDatabase db, $BagMovementsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BagMovementsTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$BagMovementsTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> partyId = const Value.absent(),
            Value<String> movement = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<String?> linkedTxnId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> entryDate = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BagMovementsTableCompanion(
            id: id,
            partyId: partyId,
            movement: movement,
            quantity: quantity,
            linkedTxnId: linkedTxnId,
            notes: notes,
            entryDate: entryDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String partyId,
            required String movement,
            required int quantity,
            Value<String?> linkedTxnId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required String entryDate,
            required String createdAt,
            required String updatedAt,
            Value<String?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BagMovementsTableCompanion.insert(
            id: id,
            partyId: partyId,
            movement: movement,
            quantity: quantity,
            linkedTxnId: linkedTxnId,
            notes: notes,
            entryDate: entryDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
        ));
}

class $$BagMovementsTableTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $BagMovementsTableTable> {
  $$BagMovementsTableTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get movement => $state.composableBuilder(
      column: $state.table.movement,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get linkedTxnId => $state.composableBuilder(
      column: $state.table.linkedTxnId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entryDate => $state.composableBuilder(
      column: $state.table.entryDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$PartiesTableTableFilterComposer get partyId {
    final $$PartiesTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partyId,
        referencedTable: $state.db.partiesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$PartiesTableTableFilterComposer(ComposerState($state.db,
                $state.db.partiesTable, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$BagMovementsTableTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $BagMovementsTableTable> {
  $$BagMovementsTableTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get movement => $state.composableBuilder(
      column: $state.table.movement,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get linkedTxnId => $state.composableBuilder(
      column: $state.table.linkedTxnId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entryDate => $state.composableBuilder(
      column: $state.table.entryDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$PartiesTableTableOrderingComposer get partyId {
    final $$PartiesTableTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partyId,
        referencedTable: $state.db.partiesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$PartiesTableTableOrderingComposer(ComposerState($state.db,
                $state.db.partiesTable, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  required String entityType,
  required String entityId,
  required String operation,
  required String payload,
  Value<int> retryCount,
  required String createdAt,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payload,
  Value<int> retryCount,
  Value<String> createdAt,
});

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder> {
  $$SyncQueueTableTableTableManager(
      _$LocalDatabase db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncQueueTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncQueueTableTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payload,
            retryCount: retryCount,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required String entityId,
            required String operation,
            required String payload,
            Value<int> retryCount = const Value.absent(),
            required String createdAt,
          }) =>
              SyncQueueTableCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payload,
            retryCount: retryCount,
            createdAt: createdAt,
          ),
        ));
}

class $$SyncQueueTableTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entityType => $state.composableBuilder(
      column: $state.table.entityType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entityId => $state.composableBuilder(
      column: $state.table.entityId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncQueueTableTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entityType => $state.composableBuilder(
      column: $state.table.entityType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entityId => $state.composableBuilder(
      column: $state.table.entityId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$PartiesTableTableTableManager get partiesTable =>
      $$PartiesTableTableTableManager(_db, _db.partiesTable);
  $$TransactionsTableTableTableManager get transactionsTable =>
      $$TransactionsTableTableTableManager(_db, _db.transactionsTable);
  $$BagMovementsTableTableTableManager get bagMovementsTable =>
      $$BagMovementsTableTableTableManager(_db, _db.bagMovementsTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
}
