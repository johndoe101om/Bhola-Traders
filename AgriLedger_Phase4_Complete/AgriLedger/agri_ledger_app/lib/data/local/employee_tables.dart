// lib/data/local/employee_tables.dart
import 'package:drift/drift.dart';

// EmployeesTable
class EmployeesTable extends Table {
  TextColumn get id => text().withLength(max: 36)();
  TextColumn get name => text().withLength(max: 200)();
  TextColumn get phone => text().withLength(max: 15).nullable()();
  TextColumn get email => text().withLength(max: 200).nullable()();
  RealColumn get dailyWageRate => real().withDefault(const Constant(0.0))();
  TextColumn get aadhaarNumber => text().withLength(max: 12).nullable()();
  TextColumn get address => text().withLength(max: 500).nullable()();
  TextColumn get joiningDate => text()(); // YYYY-MM-DD
  TextColumn get employeeType =>
      text().withLength(max: 30).withDefault(const Constant('labour'))();
  TextColumn get teamGroup => text().withLength(max: 100).nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get emergencyContact => text().withLength(max: 15).nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// AttendancesTable
class AttendancesTable extends Table {
  TextColumn get id => text().withLength(max: 36)();
  TextColumn get employeeId =>
      text().withLength(max: 36).references(EmployeesTable, #id)();
  TextColumn get attendanceDate => text().withLength(max: 10)(); // YYYY-MM-DD
  TextColumn get status => text()
      .withLength(max: 20)(); // present, absent, half_day, overtime, holiday
  TextColumn get checkInTime => text().nullable()();
  TextColumn get checkOutTime => text().nullable()();
  TextColumn get absenceReason => text().nullable()();
  TextColumn get voiceRaw => text().nullable()();
  RealColumn get overtimeHours => real().nullable()();
  BoolColumn get notificationSent =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// EmployeePaymentsTable
class EmployeePaymentsTable extends Table {
  TextColumn get id => text().withLength(max: 36)();
  TextColumn get employeeId =>
      text().withLength(max: 36).references(EmployeesTable, #id)();
  TextColumn get paymentDate => text().withLength(max: 10)(); // YYYY-MM-DD
  RealColumn get amount => real()();
  TextColumn get paymentMode =>
      text().withLength(max: 20)(); // cash, upi, bank_transfer
  TextColumn get paymentType => text()
      .withLength(max: 20)(); // wage, advance, bonus, deduction, settlement
  TextColumn get referenceNumber => text().withLength(max: 100).nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get voiceRaw => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
