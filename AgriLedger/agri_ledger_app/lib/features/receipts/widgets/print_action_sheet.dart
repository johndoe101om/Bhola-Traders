// lib/features/receipts/widgets/print_action_sheet.dart
//
// Bottom sheet that shows print options for a transaction:
//   - PDF receipt (share/WhatsApp/print)
//   - Thermal printer receipt (if connected)
//   - Balance slip (thermal)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/local/local_database.dart';
import '../../../services/printing/print_service.dart';
import '../screens/printer_setup_screen.dart';

class PrintActionSheet extends ConsumerWidget {
  final TransactionsTableData txn;
  final String partyName;
  final String businessName;

  const PrintActionSheet({
    super.key,
    required this.txn,
    required this.partyName,
    this.businessName = 'Bhola Traders',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printer = ref.watch(thermalPrinterProvider);
    final printService = PrintService(thermalPrinter: printer);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
              child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),

          // Title
          Row(children: [
            const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('रसीद / Receipt',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Text(formatRupees(txn.amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: txn.direction == 'in'
                      ? AppTheme.moneyIn
                      : AppTheme.moneyOut,
                )),
          ]),
          Text('$partyName • ${txn.entryDate}',
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),

          // ── PDF share ──────────────────────────────────────────
          _PrintOption(
            icon: Icons.share_rounded,
            color: Colors.green[700]!,
            label: 'WhatsApp / Share करें',
            subtitle: 'Send PDF receipt via WhatsApp, email, Drive',
            onTap: () async {
              Navigator.pop(context);
              await printService.printReceiptPdf(
                context: context,
                txn: txn,
                partyName: partyName,
                businessName: businessName,
              );
            },
          ),

          // ── System print ──────────────────────────────────────
          _PrintOption(
            icon: Icons.print_rounded,
            color: Colors.blue[700]!,
            label: 'System Print करें',
            subtitle: 'Wi-Fi printer / Google Cloud Print',
            onTap: () async {
              Navigator.pop(context);
              await printService.printReceiptPdf(
                context: context,
                txn: txn,
                partyName: partyName,
              );
            },
          ),

          // ── Thermal printer ───────────────────────────────────
          _PrintOption(
            icon: Icons.receipt_rounded,
            color:
                printer.isConnected ? Colors.orange[700]! : Colors.grey[400]!,
            label: printer.isConnected
                ? 'थर्मल प्रिंट / Thermal Print'
                : 'थर्मल प्रिंटर नहीं जुड़ा',
            subtitle: printer.isConnected
                ? 'Print on ${printer.connectedDeviceName ?? 'connected printer'}'
                : 'Tap "Setup Printer" to connect Bluetooth printer',
            onTap: printer.isConnected
                ? () async {
                    Navigator.pop(context);
                    final ok = await printService.printReceiptThermal(
                      txn: txn,
                      partyName: partyName,
                      businessName: businessName,
                    );
                    if (context.mounted) {
                      if (ok) {
                        showSuccess(context, '🖨️ Printed successfully!');
                      } else {
                        showError(context, 'Thermal print failed');
                      }
                    }
                  }
                : () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrinterSetupScreen()));
                  },
          ),
        ],
      ),
    );
  }
}

class _PrintOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PrintOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        onTap: onTap,
      );
}

// ── HELPER: show the sheet ────────────────────────────────────────────

Future<void> showPrintSheet(
  BuildContext context, {
  required TransactionsTableData txn,
  required String partyName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final bName = prefs.getString('business_name') ?? 'Bhola Traders';

  if (context.mounted) {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ProviderScope(
        child: PrintActionSheet(
            txn: txn, partyName: partyName, businessName: bName),
      ),
    );
  }
}
