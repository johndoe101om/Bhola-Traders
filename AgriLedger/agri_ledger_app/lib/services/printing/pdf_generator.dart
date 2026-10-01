// lib/services/printing/pdf_generator.dart
//
// Generates two types of PDF:
//   1. Transaction Receipt  — single transaction, print/share with party
//   2. Party Ledger Report  — full khata with balance summary
//   3. Daily/Monthly Report — business P&L summary
//
// Uses 'pdf' package (pure Dart, no native dependency).
// Works offline completely.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/app_models.dart';
import '../../data/local/local_database.dart';

// ── COLORS ────────────────────────────────────────────────────────────
const _green = PdfColor.fromInt(0xFF2E7D32);
const _red   = PdfColor.fromInt(0xFFC62828);
const _blue  = PdfColor.fromInt(0xFF1565C0);
const _grey  = PdfColor.fromInt(0xFF757575);
const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
const _divider   = PdfColor.fromInt(0xFFE0E0E0);
const _white70 = PdfColor.fromInt(0xB3FFFFFF); // White with ~70% opacity

// ── NUMBER FORMATTERS ─────────────────────────────────────────────────
final _rupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _kg    = NumberFormat('#,##0.#', 'en_IN');
final _date  = DateFormat('d MMM yyyy');
final _dt    = DateFormat('d MMM yyyy, hh:mm a');

class PdfGenerator {

  // ──────────────────────────────────────────────────────────────────
  // 1. TRANSACTION RECEIPT
  // ──────────────────────────────────────────────────────────────────

  static Future<File> generateReceipt({
    required TransactionsTableData txn,
    required String partyName,
    String businessName = 'Bhola Traders',
    String? businessPhone,
  }) async {
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );
    final isIn = txn.direction == 'in';
    final color = isIn ? _green : _red;
    final entryDate = DateTime.tryParse(txn.entryDate) ?? DateTime.now();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(businessName,
                      style: pw.TextStyle(
                        color: PdfColors.white, fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      )),
if (businessPhone != null)
                      pw.Text(businessPhone,
                        style: const pw.TextStyle(color: _white70, fontSize: 12)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('रसीद / Receipt',
                      style: const pw.TextStyle(color: _white70, fontSize: 12)),
                    pw.Text('#${txn.id.substring(0, 8).toUpperCase()}',
                      style: pw.TextStyle(
                        color: PdfColors.white, fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── PARTY + DATE ─────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('पार्टी / Party',
                    style: const pw.TextStyle(color: _grey, fontSize: 11)),
                  pw.Text(partyName,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('तारीख / Date',
                    style: const pw.TextStyle(color: _grey, fontSize: 11)),
                  pw.Text(_date.format(entryDate),
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Divider(color: _divider),
          pw.SizedBox(height: 16),

          // ── TRANSACTION TYPE BADGE ────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: color.shade(0.85),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              _txnTypeLabel(txn.txnType),
              style: pw.TextStyle(color: color, fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 16),

          // ── GRAIN DETAILS (if applicable) ─────────────────────────
          if (txn.commodity != null) ...[
            _DetailRow('अनाज / Commodity', '${_commodityEmoji(txn.commodity!)} ${txn.commodity!.toUpperCase()}'),
            if (txn.quantityKg != null)
              _DetailRow('वजन / Weight', '${_kg.format(txn.quantityKg!)} KG'),
            if (txn.ratePerKg != null)
              _DetailRow('रेट / Rate', '${_rupee.format(txn.ratePerKg!)} per KG'),
            pw.SizedBox(height: 8),
            pw.Divider(color: _divider),
            pw.SizedBox(height: 8),
          ],

          // ── AMOUNT (BIG) ──────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              color: color.shade(0.9),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('कुल रकम / Total Amount',
                  style: pw.TextStyle(color: color, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  _rupee.format(txn.amount),
                  style: pw.TextStyle(color: color, fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // ── PAYMENT MODE ──────────────────────────────────────────
          _DetailRow('भुगतान / Payment', txn.paymentMode.toUpperCase()),

          if (txn.notes != null && txn.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _DetailRow('नोट / Notes', txn.notes!),
          ],

          pw.Spacer(),

          // ── FOOTER ────────────────────────────────────────────────
          pw.Divider(color: _divider),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Bhola Traders • ${_dt.format(DateTime.now())}',
              style: const pw.TextStyle(color: _grey, fontSize: 10),
            ),
          ),
        ],
      ),
    ));

    return _saveToFile(doc, 'receipt_${txn.id.substring(0, 8)}');
  }

  // ──────────────────────────────────────────────────────────────────
  // 2. PARTY LEDGER REPORT (full khata)
  // ──────────────────────────────────────────────────────────────────

  static Future<File> generatePartyLedger({
    required PartiesTableData party,
    required List<TransactionsTableData> transactions,
    required List<BagMovementsTableData> bagMovements,
    required double balance,
    required int bagsOutstanding,
    String businessName = 'Bhola Traders',
    DateTime? from,
    DateTime? to,
  }) async {
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );
    final balanceColor = balance >= 0 ? _green : _red;
    final balanceLabel = balance >= 0 ? 'हमारा बाकी / They owe us' : 'उनका बाकी / We owe them';

    // Split into pages if many transactions
    const int rowsPerPage = 20;
    final pages = <List<TransactionsTableData>>[];
    for (int i = 0; i < transactions.length; i += rowsPerPage) {
      pages.add(transactions.sublist(
        i, (i + rowsPerPage).clamp(0, transactions.length)));
    }
    if (pages.isEmpty) pages.add([]);

    for (int pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── PAGE HEADER ────────────────────────────────────────
            if (pageIdx == 0) ...[
              // Business + party header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(businessName,
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _green)),
                    pw.Text('खाता बही / Party Ledger',
                      style: const pw.TextStyle(color: _grey, fontSize: 12)),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text(_date.format(DateTime.now()),
                      style: const pw.TextStyle(color: _grey, fontSize: 12)),
                    if (from != null || to != null)
                      pw.Text(
                        '${from != null ? _date.format(from) : '...'} → ${to != null ? _date.format(to) : 'Today'}',
                        style: const pw.TextStyle(color: _grey, fontSize: 11),
                      ),
                  ]),
                ],
              ),

              pw.SizedBox(height: 16),

              // Party info + balance card
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: _lightGrey,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _divider),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(party.name,
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      if (party.village != null)
                        pw.Text(party.village!,
                          style: const pw.TextStyle(color: _grey, fontSize: 12)),
                      pw.Text(party.partyType.toUpperCase(),
                        style: pw.TextStyle(color: _green, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text(_rupee.format(balance.abs()),
                        style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold, color: balanceColor)),
                      pw.Text(balanceLabel,
                        style: pw.TextStyle(color: balanceColor, fontSize: 11)),
                      if (bagsOutstanding > 0)
                        pw.Text('$bagsOutstanding बोरी बाकी / bags pending',
                          style: const pw.TextStyle(color: _blue, fontSize: 11)),
                    ]),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
            ] else ...[
              // Continuation header
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('${party.name} — Ledger (cont.)',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Page ${pageIdx + 1} of ${pages.length}',
                  style: const pw.TextStyle(color: _grey, fontSize: 11)),
              ]),
              pw.SizedBox(height: 12),
            ],

            // ── TRANSACTION TABLE ──────────────────────────────────
            pw.Text('लेन-देन / Transactions',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _grey)),
            pw.SizedBox(height: 8),

            if (transactions.isEmpty)
              pw.Text('कोई लेन-देन नहीं / No transactions',
                style: const pw.TextStyle(color: _grey, fontSize: 12))
            else
              pw.Table(
                border: pw.TableBorder.all(color: _divider, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),  // Date
                  1: const pw.FlexColumnWidth(2),     // Type + notes
                  2: const pw.FixedColumnWidth(80),   // Qty
                  3: const pw.FixedColumnWidth(80),   // Amount
                  4: const pw.FixedColumnWidth(80),   // Balance
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _lightGrey),
                    children: [
                      _TableHeader('तारीख\nDate'),
                      _TableHeader('विवरण\nDetails'),
                      _TableHeader('वजन\nKG'),
                      _TableHeader('रकम\nAmount'),
                      _TableHeader('बैलेंस\nBalance'),
                    ],
                  ),
                  // Data rows with running balance
                  ..._buildTransactionRows(pages[pageIdx]),
                ],
              ),

            // ── BAGS TABLE (first page only) ──────────────────────
            if (pageIdx == 0 && bagMovements.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('बोरी / Bag Movements',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _grey)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: _divider, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(70),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FixedColumnWidth(70),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _lightGrey),
                    children: [
                      _TableHeader('तारीख\nDate'),
                      _TableHeader('प्रकार\nType'),
                      _TableHeader('संख्या\nCount'),
                    ],
                  ),
                  ...bagMovements.take(10).map((b) {
                    final isGiven = b.movement == 'given';
                    final date = DateTime.tryParse(b.entryDate) ?? DateTime.now();
                    return pw.TableRow(children: [
                      _TableCell(_date.format(date)),
                      _TableCell(isGiven ? '📦 बोरी दी / Given' : '✅ बोरी वापस / Returned'),
                      _TableCell('${isGiven ? '-' : '+'}${b.quantity}',
                        color: isGiven ? _red : _green, bold: true),
                    ]);
                  }),
                ],
              ),
            ],

            pw.Spacer(),

            // ── FOOTER ────────────────────────────────────────────
            pw.Divider(color: _divider),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Bhola Traders • Generated ${_dt.format(DateTime.now())}',
                  style: const pw.TextStyle(color: _grey, fontSize: 9)),
                pw.Text('Page ${pageIdx + 1} of ${pages.length}',
                  style: const pw.TextStyle(color: _grey, fontSize: 9)),
              ],
            ),
          ],
        ),
      ));
    }

    return _saveToFile(doc, 'ledger_${party.name.replaceAll(' ', '_')}');
  }

  // ──────────────────────────────────────────────────────────────────
  // 3. BUSINESS SUMMARY REPORT
  // ──────────────────────────────────────────────────────────────────

  static Future<File> generateBusinessReport({
    required List<TransactionsTableData> transactions,
    required DateTime from,
    required DateTime to,
    String businessName = 'Bhola Traders',
  }) async {
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    // Aggregate by date
    final byDate = <String, Map<String, double>>{};
    double totalPurchase = 0, totalSale = 0, totalCashIn = 0, totalCashOut = 0;
    final commodityTotals = <String, double>{};

    for (final t in transactions) {
      final dateKey = t.entryDate.substring(0, 10);
      byDate.putIfAbsent(dateKey, () => {
        'purchase': 0, 'sale': 0, 'cash_in': 0, 'cash_out': 0,
      });
      byDate[dateKey]![t.txnType] = (byDate[dateKey]![t.txnType] ?? 0) + t.amount;

      switch (t.txnType) {
        case 'purchase': totalPurchase += t.amount;
        case 'sale':     totalSale += t.amount;
        case 'cash_in':  totalCashIn += t.amount;
        case 'cash_out': totalCashOut += t.amount;
      }
      if (t.commodity != null && t.quantityKg != null) {
        commodityTotals[t.commodity!] =
          (commodityTotals[t.commodity!] ?? 0) + t.quantityKg!;
      }
    }

    final netProfit = (totalSale + totalCashIn) - (totalPurchase + totalCashOut);
    final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(businessName,
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 20,
                      fontWeight: pw.FontWeight.bold)),
                  pw.Text('व्यापार रिपोर्ट / Business Report',
style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 12)),
                ]),
                pw.Text(
                  '${_date.format(from)}\nto ${_date.format(to)}',
                  textAlign: pw.TextAlign.right,
style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 12),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── SUMMARY CARDS (2×2 grid) ──────────────────────────
          pw.Row(children: [
            _SummaryCard('खरीदी\nPurchase', totalPurchase, _red),
            pw.SizedBox(width: 8),
            _SummaryCard('बिक्री\nSale', totalSale, _green),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _SummaryCard('पैसा मिला\nCash In', totalCashIn, _green),
            pw.SizedBox(width: 8),
            _SummaryCard('पैसा दिया\nCash Out', totalCashOut, _red),
          ]),

          pw.SizedBox(height: 12),

          // ── NET ───────────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              color: netProfit >= 0 ? _green.shade(0.85) : _red.shade(0.85),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(14),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('नेट / Net Total',
                  style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold,
                    color: netProfit >= 0 ? _green : _red)),
                pw.Text(_rupee.format(netProfit.abs()),
                  style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold,
                    color: netProfit >= 0 ? _green : _red)),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── COMMODITY TOTALS ──────────────────────────────────
          if (commodityTotals.isNotEmpty) ...[
            pw.Text('अनाज सारांश / Commodity Summary',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _grey)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: commodityTotals.entries.map((e) =>
                pw.Expanded(child: pw.Container(
                  margin: const pw.EdgeInsets.only(right: 6),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _lightGrey,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: _divider),
                  ),
                  child: pw.Column(children: [
                    pw.Text(_commodityEmoji(e.key),
                      style: const pw.TextStyle(fontSize: 18)),
                    pw.Text(e.key.toUpperCase(),
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${_kg.format(e.value)} KG',
                      style: const pw.TextStyle(fontSize: 12, color: _grey)),
                  ]),
                ))
              ).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── DAILY BREAKDOWN TABLE ─────────────────────────────
          pw.Text('दिन-वार / Daily Breakdown',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _grey)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: _divider, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(80),
              1: const pw.FlexColumnWidth(),
              2: const pw.FlexColumnWidth(),
              3: const pw.FlexColumnWidth(),
              4: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _lightGrey),
                children: [
                  _TableHeader('तारीख\nDate'),
                  _TableHeader('खरीदी\nPurchase'),
                  _TableHeader('बिक्री\nSale'),
                  _TableHeader('Cash In'),
                  _TableHeader('Cash Out'),
                ],
              ),
              ...sortedDates.take(30).map((dateKey) {
                final d = byDate[dateKey]!;
                final dt = DateTime.tryParse(dateKey) ?? DateTime.now();
                return pw.TableRow(children: [
                  _TableCell(_date.format(dt)),
                  _TableCell(d['purchase']! > 0 ? _rupee.format(d['purchase']) : '-',
                    color: d['purchase']! > 0 ? _red : _grey),
                  _TableCell(d['sale']! > 0 ? _rupee.format(d['sale']) : '-',
                    color: d['sale']! > 0 ? _green : _grey),
                  _TableCell(d['cash_in']! > 0 ? _rupee.format(d['cash_in']) : '-',
                    color: d['cash_in']! > 0 ? _green : _grey),
                  _TableCell(d['cash_out']! > 0 ? _rupee.format(d['cash_out']) : '-',
                    color: d['cash_out']! > 0 ? _red : _grey),
                ]);
              }),
            ],
          ),

          pw.Spacer(),
          pw.Divider(color: _divider),
          pw.SizedBox(height: 4),
          pw.Text('Bhola Traders • Generated ${_dt.format(DateTime.now())}',
            style: const pw.TextStyle(color: _grey, fontSize: 9)),
        ],
      ),
    ));

    return _saveToFile(doc, 'report_${_date.format(from)}_to_${_date.format(to)}');
  }

  // ──────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────

  static List<pw.TableRow> _buildTransactionRows(
    List<TransactionsTableData> txns,
  ) {
    double running = 0;
    return txns.map((t) {
      running += t.direction == 'in' ? t.amount : -t.amount;
      final date = DateTime.tryParse(t.entryDate) ?? DateTime.now();
      final isIn = t.direction == 'in';
      final color = isIn ? _green : _red;

      return pw.TableRow(children: [
        _TableCell(_date.format(date)),
        _TableCell([
          _txnTypeLabel(t.txnType),
          if (t.commodity != null) ' • ${t.commodity}',
          if (t.notes != null) '\n${t.notes}',
        ].join('')),
        _TableCell(t.quantityKg != null ? '${_kg.format(t.quantityKg!)}' : '-'),
        _TableCell(
          '${isIn ? '+' : '-'}${_rupee.format(t.amount)}',
          color: color, bold: true,
        ),
        _TableCell(
          _rupee.format(running.abs()),
          color: running >= 0 ? _green : _red,
        ),
      ]);
    }).toList();
  }

  static Future<File> _saveToFile(pw.Document doc, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static String _txnTypeLabel(String type) => switch (type) {
    'purchase' => 'खरीदी / Purchase',
    'sale'     => 'बिक्री / Sale',
    'cash_in'  => 'पैसा मिला / Cash In',
    'cash_out' => 'पैसा दिया / Cash Out',
    _ => type,
  };

  static String _commodityEmoji(String c) => switch (c) {
    'rice'  => '🌾', 'wheat' => '🌿', 'maize' => '🌽', _ => '📦',
  };
}

// ── PDF WIDGET HELPERS ────────────────────────────────────────────────

pw.Widget _DetailRow(String label, String value) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 5),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: const pw.TextStyle(color: _grey, fontSize: 11)),
      pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
    ],
  ),
);

pw.Widget _TableHeader(String text) => pw.Padding(
  padding: const pw.EdgeInsets.all(6),
  child: pw.Text(text,
    textAlign: pw.TextAlign.center,
    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _grey)),
);

pw.Widget _TableCell(String text, {PdfColor? color, bool bold = false}) =>
  pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(text,
      style: pw.TextStyle(
        fontSize: 10, color: color,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      )),
  );

pw.Widget _SummaryCard(String label, double amount, PdfColor color) =>
  pw.Expanded(child: pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: color.shade(0.9),
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: color.shade(0.7)),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label,
        style: pw.TextStyle(color: color, fontSize: 11, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount),
        style: pw.TextStyle(color: color, fontSize: 18, fontWeight: pw.FontWeight.bold)),
    ]),
  ));
