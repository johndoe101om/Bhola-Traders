// lib/core/utils/app_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

// ── FORMATTERS ───────────────────────────────────────────────────────

final _rupeeFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _kgFormat = NumberFormat('#,##0.#', 'en_IN');
final _dateFormat = DateFormat('d MMM yyyy');
final _shortDateFormat = DateFormat('d MMM');

final _dateTimeFormat = DateFormat('d MMM, hh:mm a');
final _timeFormat = DateFormat('hh:mm a');

String formatRupees(double amount) => _rupeeFormat.format(amount);
String formatKg(double kg) => '${_kgFormat.format(kg)} kg';
String formatDate(DateTime date) => _dateFormat.format(date);
String formatDateShort(DateTime date) => _shortDateFormat.format(date);
String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
String formatTime(DateTime date) => _timeFormat.format(date);

/// Returns a human-readable relative time string like "2 min ago", "3 hrs ago"
String formatTimeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'अभी / Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hrs ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return formatDateShort(date);
}

/// Parse ISO8601 string safely, returns null on failure
DateTime? tryParseDateTime(String? isoStr) {
  if (isoStr == null || isoStr.isEmpty) return null;
  return DateTime.tryParse(isoStr);
}

// ── COLORS BY TRANSACTION TYPE ───────────────────────────────────────

Color txnColor(String txnType) => switch (txnType) {
      'purchase' || 'cash_out' => AppTheme.moneyOut,
      'sale' || 'cash_in' => AppTheme.moneyIn,
      _ => Colors.grey,
    };

Color directionColor(String direction) =>
    direction == 'in' ? AppTheme.moneyIn : AppTheme.moneyOut;

IconData txnIcon(String txnType) => switch (txnType) {
      'purchase' => Icons.download_rounded,
      'sale' => Icons.upload_rounded,
      'cash_in' => Icons.add_circle_rounded,
      'cash_out' => Icons.remove_circle_rounded,
      _ => Icons.swap_horiz_rounded,
    };

IconData partyTypeIcon(String type) => switch (type) {
      'farmer' => Icons.agriculture_rounded,
      'supplier' => Icons.warehouse_rounded,
      'customer' => Icons.person_rounded,
      _ => Icons.people_rounded,
    };

String commodityEmoji(String? commodity) =>
    AppConstants.commodityEmoji[commodity] ?? '💰';

// ── SNACKBAR HELPERS ─────────────────────────────────────────────────

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: const TextStyle(fontSize: 16)),
    backgroundColor: AppTheme.moneyIn,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
  ));
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: const TextStyle(fontSize: 16)),
    backgroundColor: AppTheme.moneyOut,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
  ));
}

// ── CONFIRM DIALOG ───────────────────────────────────────────────────

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'हाँ / Yes',
  String cancelLabel = 'नहीं / No',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: Text(message, style: const TextStyle(fontSize: 16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel, style: const TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.moneyOut),
          child: Text(confirmLabel,
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ── LOADING DIALOG ───────────────────────────────────────────────────

void showLoadingDialog(BuildContext context,
    {String message = 'कृपया प्रतीक्षा करें / Please wait...'}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 15))),
        ],
      ),
    ),
  );
}
