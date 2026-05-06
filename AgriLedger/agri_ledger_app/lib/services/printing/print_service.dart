// lib/services/printing/print_service.dart
//
// Unified print service — caller doesn't care whether it's PDF or thermal.
// Chooses the right output based on user preference + availability.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../data/local/local_database.dart';
import 'pdf_generator.dart';
import 'thermal_printer.dart';

class PrintService {
  final ThermalPrinterService thermalPrinter;

  PrintService({required this.thermalPrinter});

  // ── RECEIPT: PDF share / system print dialog ───────────────────
  Future<void> printReceiptPdf({
    required BuildContext context,
    required TransactionsTableData txn,
    required String partyName,
    String businessName = 'Bhola Traders',
    String? businessPhone,
  }) async {
    final file = await PdfGenerator.generateReceipt(
      txn: txn,
      partyName: partyName,
      businessName: businessName,
      businessPhone: businessPhone,
    );
    if (context.mounted) {
      await _showPdfOptions(context, file, title: 'Receipt — $partyName');
    }
  }

  // ── RECEIPT: thermal printer ───────────────────────────────────
  Future<bool> printReceiptThermal({
    required TransactionsTableData txn,
    required String partyName,
    String businessName = 'Bhola Traders',
  }) async {
    if (!thermalPrinter.isConnected) return false;

    return thermalPrinter.printTransactionReceipt(
      partyName: partyName,
      txnType: txn.txnType,
      amount: txn.amount,
      direction: txn.direction,
      commodity: txn.commodity,
      quantityKg: txn.quantityKg,
      ratePerKg: txn.ratePerKg,
      date: txn.entryDate,
      paymentMode: txn.paymentMode,
      notes: txn.notes,
      businessName: businessName,
    );
  }

  // ── PARTY LEDGER PDF ───────────────────────────────────────────
  Future<void> printPartyLedger({
    required BuildContext context,
    required PartiesTableData party,
    required List<TransactionsTableData> transactions,
    required List<BagMovementsTableData> bagMovements,
    required double balance,
    required int bagsOutstanding,
    String businessName = 'Bhola Traders',
    DateTime? from,
    DateTime? to,
  }) async {
    final file = await PdfGenerator.generatePartyLedger(
      party: party,
      transactions: transactions,
      bagMovements: bagMovements,
      balance: balance,
      bagsOutstanding: bagsOutstanding,
      businessName: businessName,
      from: from,
      to: to,
    );
    if (context.mounted) {
      await _showPdfOptions(context, file, title: '${party.name} — Ledger');
    }
  }

  // ── BUSINESS REPORT PDF ────────────────────────────────────────
  Future<void> printBusinessReport({
    required BuildContext context,
    required List<TransactionsTableData> transactions,
    required DateTime from,
    required DateTime to,
    String businessName = 'Bhola Traders',
  }) async {
    final file = await PdfGenerator.generateBusinessReport(
      transactions: transactions,
      from: from,
      to: to,
      businessName: businessName,
    );
    if (context.mounted) {
      await _showPdfOptions(context, file, title: 'Business Report');
    }
  }

  // ── BALANCE SLIP: thermal ──────────────────────────────────────
  Future<bool> printBalanceSlip({
    required String partyName,
    required double balance,
    required int bagsOutstanding,
  }) async {
    if (!thermalPrinter.isConnected) return false;
    return thermalPrinter.printBalanceSlip(
      partyName: partyName,
      balance: balance,
      bagsOutstanding: bagsOutstanding,
    );
  }

  // ── PDF OPTIONS BOTTOM SHEET ───────────────────────────────────
  Future<void> _showPdfOptions(
    BuildContext context, File file, {required String title}
  ) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PdfOptionsSheet(file: file, title: title),
    );
  }
}

// ── PDF OPTIONS SHEET ─────────────────────────────────────────────────

class _PdfOptionsSheet extends StatelessWidget {
  final File file;
  final String title;

  const _PdfOptionsSheet({required this.file, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('PDF ready — choose an action',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 20),

          // ── WhatsApp / Share ──────────────────────────────────
          _OptionTile(
            icon: Icons.share_rounded,
            color: Colors.green[600]!,
            label: 'WhatsApp / Share करें',
            subtitle: 'Send PDF via WhatsApp, email, etc.',
            onTap: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(file.path)],
                subject: title,
                text: 'Please find attached: $title',
              );
            },
          ),

          // ── System Print ──────────────────────────────────────
          _OptionTile(
            icon: Icons.print_rounded,
            color: Colors.blue[700]!,
            label: 'प्रिंट करें / Print',
            subtitle: 'Use system print dialog (Wi-Fi printer)',
            onTap: () async {
              Navigator.pop(context);
              final bytes = await file.readAsBytes();
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
          ),

          // ── Open / View ───────────────────────────────────────
          _OptionTile(
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.red[700]!,
            label: 'PDF देखें / View PDF',
            subtitle: 'Open in PDF viewer on your phone',
            onTap: () async {
              Navigator.pop(context);
              await OpenFilex.open(file.path);
            },
          ),

          // ── Save ──────────────────────────────────────────────
          _OptionTile(
            icon: Icons.save_alt_rounded,
            color: Colors.grey[700]!,
            label: 'Save to Downloads',
            subtitle: file.path.split('/').last,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon, required this.color,
    required this.label, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 24),
    ),
    title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
    onTap: onTap,
  );
}
