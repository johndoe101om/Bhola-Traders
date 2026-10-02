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
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/local/local_database.dart';

// ── COLORS ────────────────────────────────────────────────────────────
const _green = PdfColor.fromInt(0xFF2E7D32);
const _red = PdfColor.fromInt(0xFFC62828);
const _blue = PdfColor.fromInt(0xFF1565C0);
const _grey = PdfColor.fromInt(0xFF757575);
const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
const _divider = PdfColor.fromInt(0xFFE0E0E0);
const _white70 = PdfColor.fromInt(0xB3FFFFFF); // White with ~70% opacity

// ── NUMBER FORMATTERS ─────────────────────────────────────────────────
final _rupee =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _kg = NumberFormat('#,##0.#', 'en_IN');
final _date = DateFormat('d MMM yyyy');
final _dt = DateFormat('d MMM yyyy, hh:mm a');

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
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    if (businessPhone != null)
                      pw.Text(businessPhone,
                          style: const pw.TextStyle(
                              color: _white70, fontSize: 12)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('रसीद / Receipt',
                        style:
                            const pw.TextStyle(color: _white70, fontSize: 12)),
                    pw.Text('#${txn.id.substring(0, 8).toUpperCase()}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
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
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('तारीख / Date',
                      style: const pw.TextStyle(color: _grey, fontSize: 11)),
                  pw.Text(_date.format(entryDate),
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Divider(color: _divider),
          pw.SizedBox(height: 16),

          // ── TRANSACTION TYPE BADGE ────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: pw.BoxDecoration(
              color: isIn
                  ? const PdfColor.fromInt(0xFFF0FDF4)
                  : const PdfColor.fromInt(0xFFFFF1F2),
              border: pw.Border.all(
                color: isIn
                    ? const PdfColor.fromInt(0xFF86EFAC)
                    : const PdfColor.fromInt(0xFFFECDD3),
              ),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              _txnTypeLabel(txn.txnType),
              style: pw.TextStyle(
                  color: isIn
                      ? const PdfColor.fromInt(0xFF166534)
                      : const PdfColor.fromInt(0xFF9F1239),
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 16),

          // ── GRAIN DETAILS (if applicable) ─────────────────────────
          if (txn.commodity != null) ...[
            _DetailRow('अनाज / Commodity',
                '${_commodityEmoji(txn.commodity!)} ${txn.commodity!.toUpperCase()}'),
            if (txn.quantityKg != null)
              _DetailRow('वजन / Weight', '${_kg.format(txn.quantityKg!)} KG'),
            if (txn.ratePerKg != null)
              _DetailRow(
                  'रेट / Rate', '${_rupee.format(txn.ratePerKg!)} per KG'),
            pw.SizedBox(height: 8),
            pw.Divider(color: _divider),
            pw.SizedBox(height: 8),
          ],

          // ── AMOUNT (BIG) ──────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              color: isIn
                  ? const PdfColor.fromInt(0xFFF0FDF4)
                  : const PdfColor.fromInt(0xFFFFF1F2),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: isIn
                    ? const PdfColor.fromInt(0xFF86EFAC)
                    : const PdfColor.fromInt(0xFFFECDD3),
                width: 1.5,
              ),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('कुल रकम / Total Amount',
                    style: pw.TextStyle(
                        color: isIn
                            ? const PdfColor.fromInt(0xFF166534)
                            : const PdfColor.fromInt(0xFF9F1239),
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  _rupee.format(txn.amount),
                  style: pw.TextStyle(
                      color: isIn
                          ? const PdfColor.fromInt(0xFF166534)
                          : const PdfColor.fromInt(0xFF9F1239),
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold),
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
    final balanceLabel =
        balance >= 0 ? 'हमारा बाकी / They owe us' : 'उनका बाकी / We owe them';

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
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(businessName,
                            style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: _green)),
                        pw.Text('खाता बही / Party Ledger',
                            style:
                                const pw.TextStyle(color: _grey, fontSize: 12)),
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(_date.format(DateTime.now()),
                            style:
                                const pw.TextStyle(color: _grey, fontSize: 12)),
                        if (from != null || to != null)
                          pw.Text(
                            '${from != null ? _date.format(from) : '...'} → ${to != null ? _date.format(to) : 'Today'}',
                            style:
                                const pw.TextStyle(color: _grey, fontSize: 11),
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
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(party.name,
                              style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold)),
                          if (party.village != null)
                            pw.Text(party.village!,
                                style: const pw.TextStyle(
                                    color: _grey, fontSize: 12)),
                          pw.Text(party.partyType.toUpperCase(),
                              style: pw.TextStyle(
                                  color: _green,
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold)),
                        ]),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(_rupee.format(balance.abs()),
                              style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: balanceColor)),
                          pw.Text(balanceLabel,
                              style: pw.TextStyle(
                                  color: balanceColor, fontSize: 11)),
                          if (bagsOutstanding > 0)
                            pw.Text('$bagsOutstanding बोरी बाकी / bags pending',
                                style: const pw.TextStyle(
                                    color: _blue, fontSize: 11)),
                        ]),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
            ] else ...[
              // Continuation header
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${party.name} — Ledger (cont.)',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Page ${pageIdx + 1} of ${pages.length}',
                        style: const pw.TextStyle(color: _grey, fontSize: 11)),
                  ]),
              pw.SizedBox(height: 12),
            ],

            // ── TRANSACTION TABLE ──────────────────────────────────
            pw.Text('लेन-देन / Transactions',
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey)),
            pw.SizedBox(height: 8),

            if (transactions.isEmpty)
              pw.Text('कोई लेन-देन नहीं / No transactions',
                  style: const pw.TextStyle(color: _grey, fontSize: 12))
            else
              pw.Table(
                border: pw.TableBorder.all(color: _divider, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(60), // Date
                  1: const pw.FlexColumnWidth(2), // Type + notes
                  2: const pw.FixedColumnWidth(80), // Qty
                  3: const pw.FixedColumnWidth(80), // Amount
                  4: const pw.FixedColumnWidth(80), // Balance
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
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _grey)),
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
                    final date =
                        DateTime.tryParse(b.entryDate) ?? DateTime.now();
                    return pw.TableRow(children: [
                      _TableCell(_date.format(date)),
                      _TableCell(isGiven
                          ? '📦 बोरी दी / Given'
                          : '✅ बोरी वापस / Returned'),
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
                pw.Text(
                    'Bhola Traders • Generated ${_dt.format(DateTime.now())}',
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
      byDate.putIfAbsent(
          dateKey,
          () => {
                'purchase': 0,
                'sale': 0,
                'cash_in': 0,
                'cash_out': 0,
              });
      byDate[dateKey]![t.txnType] =
          (byDate[dateKey]![t.txnType] ?? 0) + t.amount;

      switch (t.txnType) {
        case 'purchase':
          totalPurchase += t.amount;
        case 'sale':
          totalSale += t.amount;
        case 'cash_in':
          totalCashIn += t.amount;
        case 'cash_out':
          totalCashOut += t.amount;
      }
      if (t.commodity != null && t.quantityKg != null) {
        commodityTotals[t.commodity!] =
            (commodityTotals[t.commodity!] ?? 0) + t.quantityKg!;
      }
    }

    final netProfit =
        (totalSale + totalCashIn) - (totalPurchase + totalCashOut);
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
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(businessName,
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('व्यापार रिपोर्ट / Business Report',
                          style: const pw.TextStyle(
                              color: PdfColors.grey300, fontSize: 12)),
                    ]),
                pw.Text(
                  '${_date.format(from)}\nto ${_date.format(to)}',
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                      color: PdfColors.grey300, fontSize: 12),
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
              color: netProfit >= 0
                  ? const PdfColor.fromInt(0xFF15803D)
                  : const PdfColor.fromInt(0xFFB91C1C),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('नेट / Net Total',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.Text(_rupee.format(netProfit.abs()),
                    style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── COMMODITY TOTALS ──────────────────────────────────
          if (commodityTotals.isNotEmpty) ...[
            pw.Text('अनाज सारांश / Commodity Summary',
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: commodityTotals.entries
                  .map((e) => pw.Expanded(
                          child: pw.Container(
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
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('${_kg.format(e.value)} KG',
                              style: const pw.TextStyle(
                                  fontSize: 12, color: _grey)),
                        ]),
                      )))
                  .toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── DAILY BREAKDOWN TABLE ─────────────────────────────
          pw.Text('दिन-वार / Daily Breakdown',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: _grey)),
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
                  _TableCell(
                      d['purchase']! > 0 ? _rupee.format(d['purchase']) : '-',
                      color: d['purchase']! > 0 ? _red : _grey),
                  _TableCell(d['sale']! > 0 ? _rupee.format(d['sale']) : '-',
                      color: d['sale']! > 0 ? _green : _grey),
                  _TableCell(
                      d['cash_in']! > 0 ? _rupee.format(d['cash_in']) : '-',
                      color: d['cash_in']! > 0 ? _green : _grey),
                  _TableCell(
                      d['cash_out']! > 0 ? _rupee.format(d['cash_out']) : '-',
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

    return _saveToFile(
        doc, 'report_${_date.format(from)}_to_${_date.format(to)}');
  }

  // ──────────────────────────────────────────────────────────────────
  // 4. EMPLOYEE PAYSLIP & WAGE STATEMENT (वेतन पर्ची)
  // ──────────────────────────────────────────────────────────────────

  static Future<File> generatePayslip({
    required EmployeesTableData employee,
    required List<AttendancesTableData> attendances,
    required List<EmployeePaymentsTableData> payments,
    required DateTime from,
    required DateTime to,
    String businessName = 'Bhola Traders',
    String? businessPhone,
  }) async {
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    int daysPresent = 0;
    int halfDays = 0;
    int overtimeDays = 0;
    double overtimeHoursTotal = 0;

    for (final a in attendances) {
      if (a.status == 'present') {
        daysPresent++;
      } else if (a.status == 'half_day') {
        halfDays++;
      } else if (a.status == 'overtime') {
        overtimeDays++;
        overtimeHoursTotal += (a.overtimeHours ?? 2.0);
      }
    }

    final regularWage = (daysPresent * employee.dailyWageRate) +
        (halfDays * employee.dailyWageRate * 0.5);
    final hourlyRate =
        employee.dailyWageRate > 0 ? (employee.dailyWageRate / 8.0) * 1.5 : 0.0;
    final overtimeWage = (overtimeDays * employee.dailyWageRate) +
        (overtimeHoursTotal * hourlyRate);
    final grossEarned = regularWage + overtimeWage;

    double totalPaid = 0.0;
    double totalDeduction = 0.0;

    for (final p in payments) {
      if (p.paymentType == 'deduction') {
        totalDeduction += p.amount;
      } else {
        totalPaid += p.amount;
      }
    }

    final netBalance = grossEarned - (totalPaid - totalDeduction);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── HEADER ────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(businessName,
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('वेतन पर्ची / PAYSLIP & WAGE STATEMENT',
                          style: const pw.TextStyle(
                              color: _white70, fontSize: 12)),
                      if (businessPhone != null)
                        pw.Text('📞 $businessPhone',
                            style: const pw.TextStyle(
                                color: _white70, fontSize: 10)),
                    ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('अवधि / Period',
                          style: const pw.TextStyle(
                              color: _white70, fontSize: 10)),
                      pw.Text('${_date.format(from)} - ${_date.format(to)}',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('दिनांक: ${_date.format(DateTime.now())}',
                          style: const pw.TextStyle(
                              color: _white70, fontSize: 10)),
                    ]),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── EMPLOYEE INFO BOX ─────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _lightGrey,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _divider),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('कर्मचारी का नाम / Employee Name:',
                          style:
                              const pw.TextStyle(color: _grey, fontSize: 10)),
                      pw.Text(employee.name,
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black)),
                      if (employee.phone != null && employee.phone!.isNotEmpty)
                        pw.Text('मोबाइल: ${employee.phone}',
                            style:
                                const pw.TextStyle(fontSize: 11, color: _grey)),
                    ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('पद / Role:',
                          style:
                              const pw.TextStyle(color: _grey, fontSize: 10)),
                      pw.Text(employee.employeeType.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: _blue)),
                      if (employee.teamGroup != null)
                        pw.Text('टीम: ${employee.teamGroup}',
                            style:
                                const pw.TextStyle(fontSize: 11, color: _grey)),
                    ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('दैनिक दर / Daily Wage:',
                          style:
                              const pw.TextStyle(color: _grey, fontSize: 10)),
                      pw.Text('${_rupee.format(employee.dailyWageRate)} / दिन',
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: _green)),
                      if (employee.aadhaarNumber != null &&
                          employee.aadhaarNumber!.length >= 4)
                        pw.Text(
                            'आधार: XXXX-${employee.aadhaarNumber!.substring(employee.aadhaarNumber!.length - 4)}',
                            style:
                                const pw.TextStyle(fontSize: 10, color: _grey)),
                    ]),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── ATTENDANCE & EARNINGS SUMMARY TABLE ───────────────────
          pw.Text('हाजिरी एवं मजदूरी विवरण / Attendance & Wages Breakdown',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: _green)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: _divider, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _lightGrey),
                children: [
                  _TableHeader('विवरण / Description'),
                  _TableHeader('दिन/घंटे / Units'),
                  _TableHeader('दर / Rate'),
                  _TableHeader('रकम / Amount'),
                ],
              ),
              pw.TableRow(children: [
                _TableCell('पूरे दिन की हाजिरी / Full Days'),
                _TableCell('$daysPresent दिन'),
                _TableCell(_rupee.format(employee.dailyWageRate)),
                _TableCell(_rupee.format(daysPresent * employee.dailyWageRate),
                    bold: true),
              ]),
              if (halfDays > 0)
                pw.TableRow(children: [
                  _TableCell('आधा दिन / Half Days'),
                  _TableCell('$halfDays दिन'),
                  _TableCell(_rupee.format(employee.dailyWageRate * 0.5)),
                  _TableCell(
                      _rupee.format(halfDays * employee.dailyWageRate * 0.5),
                      bold: true),
                ]),
              if (overtimeDays > 0)
                pw.TableRow(children: [
                  _TableCell('ओवरटाइम कार्य / Overtime'),
                  _TableCell('${overtimeHoursTotal.toStringAsFixed(1)} hrs'),
                  _TableCell('${_rupee.format(hourlyRate)}/hr'),
                  _TableCell(_rupee.format(overtimeWage), bold: true),
                ]),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _lightGrey),
                children: [
                  _TableCell('कुल देय मजदूरी / Gross Wages Earned', bold: true),
                  _TableCell('${daysPresent + (halfDays * 0.5)} दिन',
                      bold: true),
                  _TableCell(''),
                  _TableCell(_rupee.format(grossEarned),
                      bold: true, color: _green),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // ── PAYMENTS & ADVANCES TABLE ─────────────────────────────
          pw.Text('प्राप्त भुगतान एवं एडवांस / Payments & Advances Given',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: _blue)),
          pw.SizedBox(height: 8),

          if (payments.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _divider),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Center(
                  child: pw.Text(
                      'इस अवधि में कोई भुगतान दर्ज नहीं है / No payments recorded in this period',
                      style: const pw.TextStyle(color: _grey, fontSize: 10))),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: _divider, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _lightGrey),
                  children: [
                    _TableHeader('तारीख / Date'),
                    _TableHeader('माध्यम / Mode'),
                    _TableHeader('प्रकार / Type'),
                    _TableHeader('संदर्भ/नोट / Ref/Note'),
                    _TableHeader('रकम / Amount'),
                  ],
                ),
                ...payments.map((p) => pw.TableRow(children: [
                      _TableCell(p.paymentDate),
                      _TableCell(p.paymentMode.toUpperCase()),
                      _TableCell(p.paymentType),
                      _TableCell(p.referenceNumber ?? p.notes ?? '-'),
                      _TableCell(
                        p.paymentType == 'deduction'
                            ? '- ${_rupee.format(p.amount)}'
                            : _rupee.format(p.amount),
                        bold: true,
                        color: p.paymentType == 'deduction'
                            ? _red
                            : PdfColors.black,
                      ),
                    ])),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _lightGrey),
                  children: [
                    _TableCell('कुल प्राप्त भुगतान / Total Paid', bold: true),
                    _TableCell(''),
                    _TableCell(''),
                    _TableCell(''),
                    _TableCell(_rupee.format(totalPaid - totalDeduction),
                        bold: true, color: _blue),
                  ],
                ),
              ],
            ),
          pw.SizedBox(height: 16),

          // ── NET SETTLEMENT SUMMARY ────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: netBalance > 0 ? _lightGrey : PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                  color: netBalance > 0 ? _green : PdfColors.green300,
                  width: 1.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('शुद्ध शेष देय राशि / NET BALANCE DUE',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: _grey)),
                      pw.Text(
                        netBalance > 0
                            ? 'कर्मचारी को देय / Payable to Employee'
                            : (netBalance < 0
                                ? 'कर्मचारी से लेना / Advance Due from Employee'
                                : 'पूर्ण हिसाब / Fully Settled'),
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: netBalance > 0 ? _green : _blue),
                      ),
                    ]),
                pw.Text(
                  _rupee.format(netBalance.abs()),
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: netBalance > 0
                          ? _green
                          : (netBalance < 0 ? _red : _green)),
                ),
              ],
            ),
          ),
          pw.Spacer(),

          // ── SIGNATURES & STAMP SECTION ────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(children: [
                pw.Container(width: 150, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 6),
                pw.Text('कर्मचारी के हस्ताक्षर / अँगूठा',
                    style: const pw.TextStyle(fontSize: 10, color: _grey)),
                pw.Text('(Employee Signature / Thumb)',
                    style: const pw.TextStyle(fontSize: 8, color: _grey)),
              ]),
              pw.Column(children: [
                pw.Container(width: 150, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 6),
                pw.Text('मुंशी / व्यवस्थापक के हस्ताक्षर',
                    style: const pw.TextStyle(fontSize: 10, color: _grey)),
                pw.Text('Bhola Traders, Official Stamp',
                    style: const pw.TextStyle(fontSize: 8, color: _grey)),
              ]),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
                'AgriLedger • Bhola Traders • Computer Generated Payslip',
                style: const pw.TextStyle(color: _grey, fontSize: 8)),
          ),
        ],
      ),
    ));

    return _saveToFile(doc,
        'payslip_${employee.name.replaceAll(' ', '_')}_${_date.format(from)}');
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
        _TableCell(t.quantityKg != null ? _kg.format(t.quantityKg!) : '-'),
        _TableCell(
          '${isIn ? '+' : '-'}${_rupee.format(t.amount)}',
          color: color,
          bold: true,
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
        'sale' => 'बिक्री / Sale',
        'cash_in' => 'पैसा मिला / Cash In',
        'cash_out' => 'पैसा दिया / Cash Out',
        _ => type,
      };

  static String _commodityEmoji(String c) => switch (c) {
        'rice' => '🌾',
        'wheat' => '🌿',
        'maize' => '🌽',
        _ => '📦',
      };

  // ──────────────────────────────────────────────────────────────────
  // 5. MONTHLY WORKFORCE REPORT (मासिक कर्मचारी रिपोर्ट)
  // ──────────────────────────────────────────────────────────────────

  static Future<File> generateMonthlyWorkforceReport({
    required int month,
    required int year,
    required List<EmployeesTableData> employees,
    required List<AttendancesTableData> attendances,
    required List<EmployeePaymentsTableData> payments,
    String businessName = 'Bhola Traders',
    String? businessPhone,
  }) async {
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    int totalEmployees = employees.length;
    int totalPresentDays = 0;
    int totalAbsentDays = 0;
    int totalHalfDays = 0;

    for (final a in attendances) {
      if (a.status == 'present' || a.status == 'overtime') {
        totalPresentDays++;
      } else if (a.status == 'absent') {
        totalAbsentDays++;
      } else if (a.status == 'half_day') {
        totalHalfDays++;
      }
    }

    double totalWagesEarned = 0.0;
    double totalPaidCash = 0.0;
    double totalPaidOnline = 0.0;
    double totalPaidDisbursed = 0.0;

    final Map<String, _EmpReportItem> empStats = {};
    for (final emp in employees) {
      empStats[emp.id] = _EmpReportItem(employee: emp);
    }

    for (final a in attendances) {
      final item = empStats[a.employeeId];
      if (item != null) {
        if (a.status == 'present') {
          item.presentDays++;
        } else if (a.status == 'absent') {
          item.absentDays++;
        } else if (a.status == 'half_day') {
          item.halfDays++;
        } else if (a.status == 'overtime') {
          item.presentDays++;
          item.overtimeHours += (a.overtimeHours ?? 2.0);
        }
      }
    }

    for (final p in payments) {
      if (p.paymentType != 'deduction') {
        totalPaidDisbursed += p.amount;
        if (p.paymentMode == 'cash') {
          totalPaidCash += p.amount;
        } else {
          totalPaidOnline += p.amount;
        }
      }

      final item = empStats[p.employeeId];
      if (item != null) {
        if (p.paymentType != 'deduction') {
          item.totalPaid += p.amount;
          if (p.paymentMode == 'cash') {
            item.cashPaid += p.amount;
          } else {
            item.onlinePaid += p.amount;
          }
        }
      }
    }

    for (final item in empStats.values) {
      final regWage = (item.presentDays * item.employee.dailyWageRate) +
          (item.halfDays * item.employee.dailyWageRate * 0.5);
      final hourlyRate = item.employee.dailyWageRate > 0
          ? (item.employee.dailyWageRate / 8.0) * 1.5
          : 0.0;
      final otWage = item.overtimeHours * hourlyRate;
      item.grossEarned = regWage + otWage;
      item.balanceDue = item.grossEarned - item.totalPaid;
      totalWagesEarned += item.grossEarned;
    }

    final totalBalanceRemaining = totalWagesEarned - totalPaidDisbursed;
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.all(14),
        margin: const pw.EdgeInsets.only(bottom: 16),
        decoration: pw.BoxDecoration(
          color: _green,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(businessName,
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'मासिक कर्मचारी व मजदूरी रिपोर्ट / Monthly Workforce & Wage Report',
                      style: const pw.TextStyle(color: _white70, fontSize: 10)),
                ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(monthName,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('तैयार: ${_date.format(DateTime.now())}',
                  style: const pw.TextStyle(color: _white70, fontSize: 9)),
            ]),
          ],
        ),
      ),
      build: (ctx) => [
        pw.Row(children: [
          _SummaryCard('कर्मचारी / Staff', totalEmployees.toDouble(), _blue),
          pw.SizedBox(width: 6),
          _SummaryCard('हाजिरी / Days',
              (totalPresentDays + (totalHalfDays * 0.5)), _green),
          pw.SizedBox(width: 6),
          _SummaryCard('गैरहाजिर / Absent', totalAbsentDays.toDouble(), _red),
          pw.SizedBox(width: 6),
          _SummaryCard('मजदूरी / Wages', totalWagesEarned, _blue),
          pw.SizedBox(width: 6),
          _SummaryCard('भुगतान / Disbursed', totalPaidDisbursed, _red),
        ]),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _lightGrey,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _divider),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Text('नकद भुगतान / Cash: ${_rupee.format(totalPaidCash)}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.black)),
              pw.Text(
                  'ऑनलाइन भुगतान / Online: ${_rupee.format(totalPaidOnline)}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: _blue)),
              pw.Text(
                  'शेष बाकी / Net Outstanding: ${_rupee.format(totalBalanceRemaining)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: totalBalanceRemaining > 0 ? _red : _green,
                  )),
            ],
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Text('कर्मचारीवार विवरण / Individual Employee Ledger Breakdown',
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: _green)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _divider, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.0),
            4: const pw.FlexColumnWidth(1.8),
            5: const pw.FlexColumnWidth(1.8),
            6: const pw.FlexColumnWidth(1.8),
            7: const pw.FlexColumnWidth(2.0),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _lightGrey),
              children: [
                _TableHeader('नाम / Name'),
                _TableHeader('पद / Role'),
                _TableHeader('उपस्थित / Pres'),
                _TableHeader('अनुपस्थित / Abs'),
                _TableHeader('कमाई / Earned'),
                _TableHeader('नकद / Cash'),
                _TableHeader('ऑनलाइन / Online'),
                _TableHeader('बाकी / Due'),
              ],
            ),
            ...empStats.values.map((e) => pw.TableRow(
                  children: [
                    _TableCell(e.employee.name, bold: true),
                    _TableCell(e.employee.employeeType.toUpperCase()),
                    _TableCell(
                        '${e.presentDays}${e.halfDays > 0 ? " + ${e.halfDays}h" : ""}'),
                    _TableCell('${e.absentDays}'),
                    _TableCell(_rupee.format(e.grossEarned)),
                    _TableCell(_rupee.format(e.cashPaid)),
                    _TableCell(_rupee.format(e.onlinePaid)),
                    _TableCell(
                      _rupee.format(e.balanceDue),
                      bold: true,
                      color: e.balanceDue > 0 ? _red : _green,
                    ),
                  ],
                )),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(children: [
              pw.Container(width: 140, height: 1, color: _divider),
              pw.SizedBox(height: 4),
              pw.Text('मुंशी / व्यवस्थापक हस्ताक्षर',
                  style: const pw.TextStyle(fontSize: 10, color: _grey)),
            ]),
            pw.Column(children: [
              pw.Container(width: 140, height: 1, color: _divider),
              pw.SizedBox(height: 4),
              pw.Text('मालिक / प्रोपराइटर हस्ताक्षर',
                  style: const pw.TextStyle(fontSize: 10, color: _grey)),
            ]),
          ],
        ),
      ],
    ));

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/workforce_report_${month}_$year.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }
}

// ── PDF WIDGET HELPERS ────────────────────────────────────────────────

pw.Widget _DetailRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: _grey, fontSize: 11)),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

pw.Widget _TableHeader(String text) => pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold, color: _grey)),
    );

pw.Widget _TableCell(String text, {PdfColor? color, bool bold = false}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          )),
    );

pw.Widget _SummaryCard(String label, double amount, PdfColor color) {
  final isRed = color == _red;
  final bg = isRed
      ? const PdfColor.fromInt(0xFFFFF1F2)
      : const PdfColor.fromInt(0xFFF0FDF4);
  final border = isRed
      ? const PdfColor.fromInt(0xFFFECDD3)
      : const PdfColor.fromInt(0xFFBBF7D0);
  final textCol = isRed
      ? const PdfColor.fromInt(0xFF9F1239)
      : const PdfColor.fromInt(0xFF166534);

  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: border, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: textCol,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            NumberFormat.currency(
                    locale: 'en_IN', symbol: '₹', decimalDigits: 0)
                .format(amount),
            style: pw.TextStyle(
              color: textCol,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmpReportItem {
  final EmployeesTableData employee;
  int presentDays = 0;
  int halfDays = 0;
  int absentDays = 0;
  double overtimeHours = 0;
  double grossEarned = 0;
  double cashPaid = 0;
  double onlinePaid = 0;
  double totalPaid = 0;
  double balanceDue = 0;

  _EmpReportItem({required this.employee});
}
