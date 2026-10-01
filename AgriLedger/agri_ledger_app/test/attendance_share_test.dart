import 'package:flutter_test/flutter_test.dart';
import 'package:agri_ledger_app/services/attendance_share_service.dart';
import 'package:agri_ledger_app/data/local/local_database.dart';

void main() {
  group('AttendanceShareService phone helpers', () {
    test('cleans 10-digit standard Indian phone numbers', () {
      expect(AttendanceShareService.cleanPhone('9876543210'), equals('9876543210'));
      expect(AttendanceShareService.cleanPhone(' 98765-43210 '), equals('9876543210'));
    });

    test('cleans phone numbers with +91 or 91 country code', () {
      expect(AttendanceShareService.cleanPhone('+919876543210'), equals('9876543210'));
      expect(AttendanceShareService.cleanPhone('919876543210'), equals('9876543210'));
    });

    test('cleans phone numbers with leading 0', () {
      expect(AttendanceShareService.cleanPhone('09876543210'), equals('9876543210'));
    });

    test('handles null and invalid phone inputs gracefully', () {
      expect(AttendanceShareService.cleanPhone(null), isNull);
      expect(AttendanceShareService.cleanPhone(''), isNull);
      expect(AttendanceShareService.cleanPhone('   '), isNull);
    });

    test('formats phone for WhatsApp with 91 country code', () {
      expect(AttendanceShareService.formatWhatsAppNumber('9876543210'), equals('919876543210'));
      expect(AttendanceShareService.formatWhatsAppNumber('+919876543210'), equals('919876543210'));
    });
  });

  group('AttendanceShareService message generators', () {
    final testEmp = EmployeesTableData(
      id: 'emp-1',
      name: 'रमेश कुमार (Ramesh Kumar)',
      dailyWageRate: 400.0,
      phone: '9876543210',
      joiningDate: '2026-01-01',
      employeeType: 'labour',
      isActive: true,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );

    final testDate = DateTime(2026, 10, 1);

    test('generates individual attendance slip for present status', () {
      final slip = AttendanceShareService.generateIndividualSlip(
        employee: testEmp,
        status: 'present',
        date: testDate,
      );

      expect(slip, contains('भोला ट्रेडर्स / BHOLA TRADERS'));
      expect(slip, contains('रमेश कुमार'));
      expect(slip, contains('01/10/2026'));
      expect(slip, contains('उपस्थित / Present'));
      expect(slip, contains('₹400'));
    });

    test('generates individual attendance slip for absent status with reason', () {
      final slip = AttendanceShareService.generateIndividualSlip(
        employee: testEmp,
        status: 'absent',
        date: testDate,
        absenceReason: 'बीमार था (Fever)',
      );

      expect(slip, contains('अनुपस्थित / Absent'));
      expect(slip, contains('बीमार था (Fever)'));
      expect(slip, contains('Today Wage:* ₹0'));
    });

    test('generates individual attendance slip for overtime status with calculated wage', () {
      final slip = AttendanceShareService.generateIndividualSlip(
        employee: testEmp,
        status: 'overtime',
        date: testDate,
        overtimeHours: 2.0,
      );

      expect(slip, contains('ओवरटाइम / Overtime'));
      expect(slip, contains('2.0 घंटे'));
      // Daily wage = 400. Hourly = 50. OT rate = 1.5 * 50 = 75/hr. 2 hrs OT = 150. Total = 550.
      expect(slip, contains('₹550'));
    });

    test('generates team daily attendance summary report with accurate tallies', () {
      final emp2 = EmployeesTableData(
        id: 'emp-2',
        name: 'सुरेश (Suresh)',
        dailyWageRate: 500.0,
        phone: '9876543211',
        joiningDate: '2026-01-01',
        employeeType: 'driver',
        isActive: true,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
      );

      final summary = AttendanceShareService.generateTeamSummary(
        employees: [testEmp, emp2],
        statusMap: {'emp-1': 'present', 'emp-2': 'half_day'},
        reasonMap: {},
        otMap: {},
        date: testDate,
      );

      expect(summary, contains('दैनिक स्टाफ हाजिरी रिपोर्ट'));
      expect(summary, contains('कुल कर्मचारी / Total Staff:* 2'));
      expect(summary, contains('उपस्थित / Present:* 1'));
      expect(summary, contains('आधा दिन / Half Day:* 1'));
      // Total wage = 400 (present) + 250 (half day of 500) = 650
      expect(summary, contains('₹650'));
      expect(summary, contains('रमेश कुमार'));
      expect(summary, contains('सुरेश'));
    });
  });
}
