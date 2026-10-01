// lib/data/models/employee_models.dart

class Employee {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final double dailyWageRate;
  final String? aadhaarNumber;
  final String? address;
  final DateTime joiningDate;
  final String employeeType;
  final String? teamGroup;
  final bool isActive;
  final String? emergencyContact;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  // Computed summary fields
  final int daysPresent;
  final double totalPaid;
  final double balance;

  Employee({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.dailyWageRate,
    this.aadhaarNumber,
    this.address,
    required this.joiningDate,
    required this.employeeType,
    this.teamGroup,
    this.isActive = true,
    this.emergencyContact,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.daysPresent = 0,
    this.totalPaid = 0.0,
    this.balance = 0.0,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      dailyWageRate:
          (json['dailyWageRate'] ?? json['daily_wage_rate'] ?? 0 as num)
              .toDouble(),
      aadhaarNumber: json['aadhaarNumber'] ?? json['aadhaar_number'],
      address: json['address'],
      joiningDate: DateTime.tryParse(
              json['joiningDate'] ?? json['joining_date'] ?? '') ??
          DateTime.now(),
      employeeType: json['employeeType'] ?? json['employee_type'] ?? 'labour',
      teamGroup: json['teamGroup'] ?? json['team_group'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      emergencyContact: json['emergencyContact'] ?? json['emergency_contact'],
      notes: json['notes'],
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ??
              DateTime.now(),
      syncedAt: (json['syncedAt'] ?? json['synced_at']) != null
          ? DateTime.tryParse(json['syncedAt'] ?? json['synced_at'])
          : null,
      daysPresent: json['daysPresent'] ?? json['days_present'] ?? 0,
      totalPaid:
          (json['totalPaid'] ?? json['total_paid'] ?? 0 as num).toDouble(),
      balance: (json['balance'] ?? 0 as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'dailyWageRate': dailyWageRate,
      'aadhaarNumber': aadhaarNumber,
      'address': address,
      'joiningDate': joiningDate.toIso8601String().substring(0, 10),
      'employeeType': employeeType,
      'teamGroup': teamGroup,
      'isActive': isActive,
      'emergencyContact': emergencyContact,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
      'daysPresent': daysPresent,
      'totalPaid': totalPaid,
      'balance': balance,
    };
  }

  Employee copyWith({
    String? name,
    String? phone,
    String? email,
    double? dailyWageRate,
    String? aadhaarNumber,
    String? address,
    DateTime? joiningDate,
    String? employeeType,
    String? teamGroup,
    bool? isActive,
    String? emergencyContact,
    String? notes,
    int? daysPresent,
    double? totalPaid,
    double? balance,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dailyWageRate: dailyWageRate ?? this.dailyWageRate,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      address: address ?? this.address,
      joiningDate: joiningDate ?? this.joiningDate,
      employeeType: employeeType ?? this.employeeType,
      teamGroup: teamGroup ?? this.teamGroup,
      isActive: isActive ?? this.isActive,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncedAt: syncedAt,
      daysPresent: daysPresent ?? this.daysPresent,
      totalPaid: totalPaid ?? this.totalPaid,
      balance: balance ?? this.balance,
    );
  }
}

class Attendance {
  final String id;
  final String employeeId;
  final String? employeeName;
  final DateTime attendanceDate;
  final String status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? absenceReason;
  final String? voiceRaw;
  final double? overtimeHours;
  final bool notificationSent;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  Attendance({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.attendanceDate,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.absenceReason,
    this.voiceRaw,
    this.overtimeHours,
    this.notificationSent = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeName: json['employeeName'] ?? json['employee_name'],
      attendanceDate: DateTime.tryParse(
              json['attendanceDate'] ?? json['attendance_date'] ?? '') ??
          DateTime.now(),
      status: json['status'] ?? 'present',
      checkInTime: (json['checkInTime'] ?? json['check_in_time']) != null
          ? DateTime.tryParse(json['checkInTime'] ?? json['check_in_time'])
          : null,
      checkOutTime: (json['checkOutTime'] ?? json['check_out_time']) != null
          ? DateTime.tryParse(json['checkOutTime'] ?? json['check_out_time'])
          : null,
      absenceReason: json['absenceReason'] ?? json['absence_reason'],
      voiceRaw: json['voiceRaw'] ?? json['voice_raw'],
      overtimeHours: (json['overtimeHours'] ?? json['overtime_hours']) != null
          ? (json['overtimeHours'] ?? json['overtime_hours'] as num).toDouble()
          : null,
      notificationSent:
          json['notificationSent'] ?? json['notification_sent'] ?? false,
      notes: json['notes'],
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ??
              DateTime.now(),
      syncedAt: (json['syncedAt'] ?? json['synced_at']) != null
          ? DateTime.tryParse(json['syncedAt'] ?? json['synced_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      if (employeeName != null) 'employeeName': employeeName,
      'attendanceDate': attendanceDate.toIso8601String().substring(0, 10),
      'status': status,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'absenceReason': absenceReason,
      'voiceRaw': voiceRaw,
      'overtimeHours': overtimeHours,
      'notificationSent': notificationSent,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
    };
  }
}

class EmployeePayment {
  final String id;
  final String employeeId;
  final String? employeeName;
  final DateTime paymentDate;
  final double amount;
  final String paymentMode;
  final String paymentType;
  final String? referenceNumber;
  final String? notes;
  final String? voiceRaw;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  EmployeePayment({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.paymentDate,
    required this.amount,
    required this.paymentMode,
    required this.paymentType,
    this.referenceNumber,
    this.notes,
    this.voiceRaw,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  factory EmployeePayment.fromJson(Map<String, dynamic> json) {
    return EmployeePayment(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeName: json['employeeName'] ?? json['employee_name'],
      paymentDate: DateTime.tryParse(
              json['paymentDate'] ?? json['payment_date'] ?? '') ??
          DateTime.now(),
      amount: (json['amount'] ?? 0 as num).toDouble(),
      paymentMode: json['paymentMode'] ?? json['payment_mode'] ?? 'cash',
      paymentType: json['paymentType'] ?? json['payment_type'] ?? 'wage',
      referenceNumber: json['referenceNumber'] ?? json['reference_number'],
      notes: json['notes'],
      voiceRaw: json['voiceRaw'] ?? json['voice_raw'],
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ??
              DateTime.now(),
      syncedAt: (json['syncedAt'] ?? json['synced_at']) != null
          ? DateTime.tryParse(json['syncedAt'] ?? json['synced_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      if (employeeName != null) 'employeeName': employeeName,
      'paymentDate': paymentDate.toIso8601String().substring(0, 10),
      'amount': amount,
      'paymentMode': paymentMode,
      'paymentType': paymentType,
      'referenceNumber': referenceNumber,
      'notes': notes,
      'voiceRaw': voiceRaw,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
    };
  }
}

class WorkforceSummary {
  final int totalEmployees;
  final int presentCount;
  final int absentCount;
  final int halfDayCount;
  final int overtimeCount;
  final int notMarkedCount;
  final double totalWagesToday;

  const WorkforceSummary({
    this.totalEmployees = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.halfDayCount = 0,
    this.overtimeCount = 0,
    this.notMarkedCount = 0,
    this.totalWagesToday = 0.0,
  });
}
