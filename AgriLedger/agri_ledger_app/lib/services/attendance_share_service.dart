// lib/services/attendance_share_service.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_utils.dart';
import '../data/local/local_database.dart';

class AttendanceShareService {
  AttendanceShareService._();

  /// Clean phone number for WhatsApp and SMS
  static String? cleanPhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return null;
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.length == 10) {
      return digits; // Standard 10 digit Indian number
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      return digits.substring(1);
    }
    return digits;
  }

  /// Format phone with country code (91) for WhatsApp
  static String formatWhatsAppNumber(String phone) {
    final cleaned = cleanPhone(phone) ?? phone;
    if (cleaned.length == 10) {
      return '91$cleaned';
    }
    return cleaned;
  }

  /// Generate individual attendance slip text
  static String generateIndividualSlip({
    required EmployeesTableData employee,
    required String status,
    required DateTime date,
    String? absenceReason,
    double? overtimeHours,
  }) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final statusHindi = AppConstants.attendanceStatusLabels[status] ?? status;

    String statusDisplay;
    double wageToday = 0.0;
    switch (status) {
      case 'present':
        statusDisplay = 'उपस्थित / Present ✅';
        wageToday = employee.dailyWageRate;
        break;
      case 'absent':
        statusDisplay = 'अनुपस्थित / Absent ❌';
        wageToday = 0.0;
        break;
      case 'half_day':
        statusDisplay = 'आधा दिन / Half Day ⏳';
        wageToday = employee.dailyWageRate * 0.5;
        break;
      case 'overtime':
        final ot = overtimeHours ?? 2.0;
        final otRate = employee.dailyWageRate > 0
            ? (employee.dailyWageRate / 8.0) * 1.5
            : 0.0;
        final otWage = ot * otRate;
        statusDisplay = 'ओवरटाइम / Overtime ⏱️ (${ot.toStringAsFixed(1)} घंटे)';
        wageToday = employee.dailyWageRate + otWage;
        break;
      case 'holiday':
        statusDisplay = 'छुट्टी / Holiday 🏖️';
        wageToday = 0.0;
        break;
      default:
        statusDisplay = statusHindi;
    }

    final buffer = StringBuffer();
    buffer.writeln('🌾 *भोला ट्रेडर्स / BHOLA TRADERS* 🌾');
    buffer.writeln('📋 *दैनिक हाजिरी पर्ची / Attendance Slip*');
    buffer.writeln('--------------------------------');
    buffer.writeln('👤 *कर्मचारी / Staff:* ${employee.name}');
    buffer.writeln('📅 *तारीख / Date:* $dateStr');
    buffer.writeln('📌 *स्थिति / Status:* $statusDisplay');
    buffer.writeln('💵 *दैनिक दर / Daily Rate:* ₹${employee.dailyWageRate.toStringAsFixed(0)}');

    if (status == 'overtime' && overtimeHours != null) {
      buffer.writeln('⏱️ *ओवरटाइम / OT:* ${overtimeHours.toStringAsFixed(1)} घंटे');
    }

    if (status == 'absent' && absenceReason != null && absenceReason.isNotEmpty) {
      buffer.writeln('📝 *कारण / Reason:* $absenceReason');
    }

    buffer.writeln('💰 *आज का कुल वेतन / Today Wage:* ₹${wageToday.toStringAsFixed(0)}');
    buffer.writeln('--------------------------------');
    buffer.writeln('भोला ट्रेडर्स (मंडी रोड)');
    buffer.writeln('📞 किसी भी प्रश्न के लिए संपर्क करें।');

    return buffer.toString();
  }

  /// Generate team daily attendance summary report
  static String generateTeamSummary({
    required List<EmployeesTableData> employees,
    required Map<String, String> statusMap, // employeeId -> status
    required Map<String, String> reasonMap, // employeeId -> absenceReason
    required Map<String, double> otMap, // employeeId -> overtimeHours
    required DateTime date,
  }) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    int present = 0;
    int absent = 0;
    int halfDay = 0;
    int overtime = 0;
    int holiday = 0;
    double totalWages = 0.0;

    final buffer = StringBuffer();
    buffer.writeln('🌾 *भोला ट्रेडर्स / BHOLA TRADERS* 🌾');
    buffer.writeln('📊 *दैनिक स्टाफ हाजिरी रिपोर्ट / Daily Staff Report*');
    buffer.writeln('📅 *तारीख / Date:* $dateStr');
    buffer.writeln('================================');

    final details = <String>[];
    int index = 1;

    for (final emp in employees) {
      final st = statusMap[emp.id] ?? 'present';
      final reason = reasonMap[emp.id];
      final ot = otMap[emp.id] ?? 2.0;

      double w = 0.0;
      String stLabel = '';

      switch (st) {
        case 'present':
          present++;
          w = emp.dailyWageRate;
          stLabel = 'उपस्थित (P)';
          break;
        case 'absent':
          absent++;
          stLabel = 'अनुपस्थित (A)${reason?.isNotEmpty == true ? ' - $reason' : ''}';
          break;
        case 'half_day':
          halfDay++;
          w = emp.dailyWageRate * 0.5;
          stLabel = 'आधा दिन (H)';
          break;
        case 'overtime':
          overtime++;
          final otRate = emp.dailyWageRate > 0
              ? (emp.dailyWageRate / 8.0) * 1.5
              : 0.0;
          w = emp.dailyWageRate + (ot * otRate);
          stLabel = 'ओवरटाइम (OT - ${ot.toStringAsFixed(1)}h)';
          break;
        case 'holiday':
          holiday++;
          stLabel = 'छुट्टी (Hol)';
          break;
      }
      totalWages += w;

      details.add(
          '$index. ${emp.name}: $stLabel ${w > 0 ? '(₹${w.toStringAsFixed(0)})' : ''}');
      index++;
    }

    buffer.writeln('👥 *कुल कर्मचारी / Total Staff:* ${employees.length}');
    buffer.writeln('✅ *उपस्थित / Present:* $present');
    buffer.writeln('❌ *अनुपस्थित / Absent:* $absent');
    if (halfDay > 0) buffer.writeln('⏳ *आधा दिन / Half Day:* $halfDay');
    if (overtime > 0) buffer.writeln('⏱️ *ओवरटाइम / Overtime:* $overtime');
    if (holiday > 0) buffer.writeln('🏖️ *छुट्टी / Holiday:* $holiday');
    buffer.writeln('💰 *आज का कुल वेतन / Total Wages:* ₹${totalWages.toStringAsFixed(0)}');
    buffer.writeln('--------------------------------');
    buffer.writeln('📝 *कर्मचारी विवरण / Staff Details:*');
    for (final d in details) {
      buffer.writeln(d);
    }
    buffer.writeln('================================');
    buffer.writeln('भोला ट्रेडर्स — दैनिक रिकॉर्ड');

    return buffer.toString();
  }

  /// Launch WhatsApp with message
  static Future<bool> sendViaWhatsApp({
    String? phone,
    required String message,
  }) async {
    final encoded = Uri.encodeComponent(message);

    if (phone != null && phone.trim().isNotEmpty) {
      final waNumber = formatWhatsAppNumber(phone);

      // Try direct whatsapp:// uri first
      final directUri = Uri.parse('whatsapp://send?phone=$waNumber&text=$encoded');
      try {
        if (await canLaunchUrl(directUri)) {
          final launched = await launchUrl(directUri,
              mode: LaunchMode.externalNonBrowserApplication);
          if (launched) return true;
        }
      } catch (_) {}

      // Fallback to https://wa.me/
      final webUri = Uri.parse('https://wa.me/$waNumber?text=$encoded');
      try {
        final launched = await launchUrl(webUri,
            mode: LaunchMode.externalApplication);
        if (launched) return true;
      } catch (_) {}
    }

    // Generic WhatsApp share (user picks contact)
    final genericUri = Uri.parse('whatsapp://send?text=$encoded');
    try {
      if (await canLaunchUrl(genericUri)) {
        final launched = await launchUrl(genericUri,
            mode: LaunchMode.externalNonBrowserApplication);
        if (launched) return true;
      }
    } catch (_) {}

    // Fallback to system share
    await Share.share(message);
    return true;
  }

  /// Launch SMS with message
  static Future<bool> sendViaSms({
    String? phone,
    required String message,
  }) async {
    final cleaned = phone != null ? cleanPhone(phone) : null;
    final encoded = Uri.encodeComponent(message);

    if (cleaned != null && cleaned.isNotEmpty) {
      final smsUri = Uri.parse('sms:$cleaned?body=$encoded');
      try {
        if (await canLaunchUrl(smsUri)) {
          final launched = await launchUrl(smsUri,
              mode: LaunchMode.externalApplication);
          if (launched) return true;
        }
      } catch (_) {}
    }

    // Fallback to generic sms
    final genericSms = Uri.parse('sms:?body=$encoded');
    try {
      if (await canLaunchUrl(genericSms)) {
        final launched = await launchUrl(genericSms,
            mode: LaunchMode.externalApplication);
        if (launched) return true;
      }
    } catch (_) {}

    // Ultimate fallback
    await Share.share(message);
    return true;
  }

  /// Open bottom sheet dialog to share individual attendance
  static void showShareIndividualDialog({
    required BuildContext context,
    required EmployeesTableData employee,
    required String status,
    required DateTime date,
    String? absenceReason,
    double? overtimeHours,
  }) {
    final message = generateIndividualSlip(
      employee: employee,
      status: status,
      date: date,
      absenceReason: absenceReason,
      overtimeHours: overtimeHours,
    );

    final phone = employee.phone;
    final hasPhone = phone != null && phone.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'हाजिरी पर्ची शेयर करें / Share Slip',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                '${employee.name} ${hasPhone ? '($phone)' : '(फ़ोन नंबर नहीं है)'}',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              // Preview container
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(
                        fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sharing buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('WhatsApp',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        sendViaWhatsApp(phone: phone, message: message);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.sms_outlined, size: 18),
                      label: const Text('SMS / संदेश',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        sendViaSms(phone: phone, message: message);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('अन्य ऐप में भेजें / Other Apps',
                      style: TextStyle(fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.share(message);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open bottom sheet dialog to share team daily attendance summary
  static void showShareTeamSummaryDialog({
    required BuildContext context,
    required List<EmployeesTableData> employees,
    required Map<String, String> statusMap,
    required Map<String, String> reasonMap,
    required Map<String, double> otMap,
    required DateTime date,
  }) {
    final message = generateTeamSummary(
      employees: employees,
      statusMap: statusMap,
      reasonMap: reasonMap,
      otMap: otMap,
      date: date,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'दैनिक हाजिरी रिपोर्ट शेयर करें / Daily Report',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'कुल कर्मचारी: ${employees.length}  •  तारीख: ${date.day}/${date.month}/${date.year}',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              // Preview container
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(
                        fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('WhatsApp पर शेयर',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        sendViaWhatsApp(message: message);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.sms_outlined, size: 18),
                      label: const Text('SMS / संदेश',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        sendViaSms(message: message);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('अन्य ऐप में शेयर करें / Share Sheet',
                      style: TextStyle(fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.share(message);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
