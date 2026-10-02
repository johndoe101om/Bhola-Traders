// lib/services/pdf/pdf_service.dart
//
// Generates 3 types of PDF documents entirely in Dart (no server):
//   1. Transaction Receipt  — single entry, shareable on WhatsApp
//   2. Party Khata (Ledger) — full account statement for one party
//   3. Daily/Period Report  — business summary with totals
//
// All text is bilingual: Hindi label + English value.
// Designed to be readable when photographed on cheap Android screens.

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/local/local_database.dart';

// Brand colors in PDF
const _green = PdfColor.fromInt(0xFF2E7D32);
const _red = PdfColor.fromInt(0xFFC62828);
const _blue = PdfColor.fromInt(0xFF1565C0);
const _grey = PdfColor.fromInt(0xFF757575);
const _light = PdfColor.fromInt(0xFFF5F5F5);
const _white = PdfColors.white;

final _rupee =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _dateF = DateFormat('d MMM yyyy');
final _dtF = DateFormat('d MMM yyyy, h:mm a');

String _fmt(double v) => _rupee.format(v);
String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  return d != null ? _dateF.format(d) : iso;
}

// ─────────────────────────────────────────────────────────────────────
class PdfService {
  // ── 1. TRANSACTION RECEIPT ────────────────────────────────────────
  // Used after saving a transaction — shareable on WhatsApp, print on thermal

  static Future<Uint8List> buildReceipt({
    required TransactionsTableData txn,
    required String partyName,
    required String? village,
    required String businessName,
  }) async {
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    final doc = pw.Document();

    final isIn = txn.direction == 'in';
    final amountColor = isIn ? _green : _red;
    final txnLabel = _txnLabel(txn.txnType);
    final entryDate = _fmtDate(txn.entryDate);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── HEADER ───────────────────────────────────────────────
          _Header(businessName: businessName, font: font, fontBold: fontBold),
          pw.SizedBox(height: 16),
          _Divider(),
          pw.SizedBox(height: 12),

          // ── RECEIPT TITLE ────────────────────────────────────────
          pw.Center(
            child: pw.Text('रसीद / RECEIPT',
                style:
                    pw.TextStyle(font: fontBold, fontSize: 18, color: _green)),
          ),
          pw.SizedBox(height: 12),

          // ── RECEIPT META ─────────────────────────────────────────
          _TwoCol('तारीख / Date', entryDate, font, fontBold),
          _TwoCol('पार्टी / Party', partyName, font, fontBold),
          if (village != null)
            _TwoCol('गाँव / Village', village, font, fontBold),
          _TwoCol('प्रकार / Type', txnLabel, font, fontBold),
          pw.SizedBox(height: 8),
          _Divider(),
          pw.SizedBox(height: 8),

          // ── GRAIN DETAILS (if applicable) ────────────────────────
          if (txn.commodity != null) ...[
            _TwoCol(
                'अनाज / Commodity',
                '${_commodityEmoji(txn.commodity!)} ${txn.commodity!.toUpperCase()}',
                font,
                fontBold),
            if (txn.quantityKg != null)
              _TwoCol('वजन / Weight',
                  '${txn.quantityKg!.toStringAsFixed(1)} KG', font, fontBold),
            if (txn.ratePerKg != null)
              _TwoCol('रेट / Rate per KG',
                  '₹ ${txn.ratePerKg!.toStringAsFixed(0)}', font, fontBold),
            pw.SizedBox(height: 8),
            _Divider(),
            pw.SizedBox(height: 8),
          ],

          // ── AMOUNT (BIG) ──────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
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
            child: pw.Column(
              children: [
                pw.Text('कुल रकम / Total Amount',
                    style:
                        pw.TextStyle(font: font, fontSize: 13, color: _grey)),
                pw.SizedBox(height: 6),
                pw.Text(_fmt(txn.amount),
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 32, color: amountColor)),
                pw.SizedBox(height: 4),
                pw.Text(isIn ? '(प्राप्त / Received)' : '(भुगतान / Paid)',
                    style: pw.TextStyle(
                        font: font, fontSize: 12, color: amountColor)),
              ],
            ),
          ),

          pw.SizedBox(height: 12),
          _TwoCol('भुगतान / Payment Mode', txn.paymentMode.toUpperCase(), font,
              fontBold),

          if (txn.notes != null) ...[
            pw.SizedBox(height: 8),
            _TwoCol('नोट / Notes', txn.notes!, font, fontBold),
          ],

          pw.Spacer(),

          // ── FOOTER ───────────────────────────────────────────────
          _Divider(),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Generated by Bhola Traders • ${_dtF.format(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
            ),
          ),
        ],
      ),
    ));

    return doc.save();
  }

  // ── 2. PARTY KHATA (LEDGER STATEMENT) ─────────────────────────────

  static Future<Uint8List> buildKhata({
    required PartiesTableData party,
    required List<TransactionsTableData> transactions,
    required List<BagMovementsTableData> bagMovements,
    required double balance,
    required int bagsOutstanding,
    required String businessName,
    DateTime? from,
    DateTime? to,
  }) async {
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    final doc = pw.Document();
    final balanceColor = balance >= 0 ? _green : _red;
    final balanceLabel =
        balance >= 0 ? 'हमारा बाकी / They owe us' : 'उनका बाकी / We owe them';

    // ── PAGE 1: SUMMARY ───────────────────────────────────────────
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _Header(businessName: businessName, font: font, fontBold: fontBold),
          pw.SizedBox(height: 16),
          _Divider(),
          pw.SizedBox(height: 16),

          // Account statement title
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('खाता विवरण / ACCOUNT STATEMENT',
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 16, color: _green)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        '${party.name}  •  ${party.partyType.toUpperCase()}',
                        style: pw.TextStyle(font: fontBold, fontSize: 13)),
                    if (party.village != null)
                      pw.Text(party.village!,
                          style: pw.TextStyle(
                              font: font, fontSize: 11, color: _grey)),
                    if (party.phone != null)
                      pw.Text('📞 ${party.phone}',
                          style: pw.TextStyle(
                              font: font, fontSize: 11, color: _grey)),
                  ]),
              // Balance box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: balance >= 0
                      ? const PdfColor.fromInt(0xFFF0FDF4)
                      : const PdfColor.fromInt(0xFFFFF1F2),
                  border: pw.Border.all(
                    color: balance >= 0
                        ? const PdfColor.fromInt(0xFF86EFAC)
                        : const PdfColor.fromInt(0xFFFECDD3),
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(balanceLabel,
                        style: pw.TextStyle(
                            font: font, fontSize: 10, color: balanceColor)),
                    pw.Text(_fmt(balance.abs()),
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 22, color: balanceColor)),
                    if (bagsOutstanding > 0)
                      pw.Text('📦 $bagsOutstanding बोरी बाकी',
                          style: pw.TextStyle(
                              font: font, fontSize: 10, color: _blue)),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 8),
          if (from != null || to != null)
            pw.Text(
              'अवधि / Period: ${from != null ? _dateF.format(from) : 'शुरू'}'
              ' — ${to != null ? _dateF.format(to) : 'आज'}',
              style: pw.TextStyle(font: font, fontSize: 11, color: _grey),
            ),

          pw.SizedBox(height: 20),

          // ── TRANSACTIONS TABLE ────────────────────────────────────
          pw.Text('लेन-देन / Transactions',
              style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 8),

          if (transactions.isEmpty)
            pw.Text('कोई लेन-देन नहीं / No transactions',
                style: pw.TextStyle(font: font, color: _grey))
          else
            _TxnTable(
              transactions: transactions,
              font: font,
              fontBold: fontBold,
            ),

          pw.SizedBox(height: 20),

          // ── BAG MOVEMENTS TABLE ───────────────────────────────────
          if (bagMovements.isNotEmpty) ...[
            pw.Text('बोरी विवरण / Bag Movements',
                style: pw.TextStyle(font: fontBold, fontSize: 14)),
            pw.SizedBox(height: 8),
            _BagTable(bags: bagMovements, font: font, fontBold: fontBold),
            pw.SizedBox(height: 16),
          ],

          pw.Spacer(),
          _Divider(),
          pw.SizedBox(height: 8),
          pw.Center(
              child: pw.Text(
            'Bhola Traders  •  Generated ${_dtF.format(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
          )),
        ],
      ),
    ));

    return doc.save();
  }

  // ── 3. DAILY / PERIOD REPORT ───────────────────────────────────────

  static Future<Uint8List> buildDailyReport({
    required List<TransactionsTableData> transactions,
    required String businessName,
    required DateTime from,
    required DateTime to,
  }) async {
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    // Compute totals
    double purchase = 0, sale = 0, cashIn = 0, cashOut = 0;
    final byDate = <String, List<TransactionsTableData>>{};

    for (final t in transactions) {
      switch (t.txnType) {
        case 'purchase':
          purchase += t.amount;
        case 'sale':
          sale += t.amount;
        case 'cash_in':
          cashIn += t.amount;
        case 'cash_out':
          cashOut += t.amount;
      }
      byDate.putIfAbsent(t.entryDate, () => []).add(t);
    }
    final net = (sale + cashIn) - (purchase + cashOut);

    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) =>
          _Header(businessName: businessName, font: font, fontBold: fontBold),
      footer: (ctx) => pw.Center(
          child: pw.Text(
        'Bhola Traders  •  Page ${ctx.pageNumber}/${ctx.pagesCount}',
        style: pw.TextStyle(font: font, fontSize: 9, color: _grey),
      )),
      build: (ctx) => [
        pw.SizedBox(height: 16),
        pw.Text('व्यापार रिपोर्ट / BUSINESS REPORT',
            style: pw.TextStyle(font: fontBold, fontSize: 18, color: _green)),
        pw.Text(
          '${_dateF.format(from)} — ${_dateF.format(to)}',
          style: pw.TextStyle(font: font, fontSize: 12, color: _grey),
        ),
        pw.SizedBox(height: 20),

        // ── SUMMARY BOX ──────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _light,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(children: [
            pw.Row(children: [
              _SummaryCell(
                  'खरीदी\nPurchase', _fmt(purchase), _red, font, fontBold),
              _SummaryCell('बिक्री\nSale', _fmt(sale), _green, font, fontBold),
              _SummaryCell('Cash In', _fmt(cashIn), _green, font, fontBold),
              _SummaryCell('Cash Out', _fmt(cashOut), _red, font, fontBold),
            ]),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('नेट / NET : ',
                    style: pw.TextStyle(font: fontBold, fontSize: 16)),
                pw.Text(_fmt(net.abs()),
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 22,
                        color: net >= 0 ? _green : _red)),
                pw.SizedBox(width: 8),
                pw.Text(net >= 0 ? '(लाभ / Profit)' : '(हानि / Loss)',
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        color: net >= 0 ? _green : _red)),
              ],
            ),
          ]),
        ),

        pw.SizedBox(height: 24),

        // ── DAILY BREAKDOWN ───────────────────────────────────────
        pw.Text('दिन-वार विवरण / Daily Breakdown',
            style: pw.TextStyle(font: fontBold, fontSize: 14)),
        pw.SizedBox(height: 8),

        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            _TableHeader([
              'तारीख / Date',
              'खरीदी',
              'बिक्री',
              'Cash In',
              'Cash Out',
              'Net'
            ], font: fontBold),
            ..._buildDailyBreakdownRows(byDate, font, fontBold),
          ],
        ),

        pw.SizedBox(height: 24),

        // ── ALL TRANSACTIONS DETAIL ───────────────────────────────
        pw.Text('सभी एंट्री / All Transactions',
            style: pw.TextStyle(font: fontBold, fontSize: 14)),
        pw.SizedBox(height: 8),
        _TxnTable(
            transactions: transactions,
            font: font,
            fontBold: fontBold,
            showParty: true),
      ],
    ));

    return doc.save();
  }

  // ── 4. ESC/POS THERMAL RECEIPT (58mm / 80mm printers) ─────────────
  // Returns raw bytes ready to send via Bluetooth to thermal printer

  static String buildThermalText({
    required TransactionsTableData txn,
    required String partyName,
    required String businessName,
    required String? village,
  }) {
    final sb = StringBuffer();
    const line = '================================';
    const shortLine = '----------------';

    sb.writeln(businessName.toUpperCase());
    sb.writeln('Bhola Traders कृषि बही-खाता');
    sb.writeln(line);
    sb.writeln('रसीद / RECEIPT');
    sb.writeln(shortLine);
    sb.writeln('तारीख: ${_fmtDate(txn.entryDate)}');
    sb.writeln('पार्टी: $partyName');
    if (village != null) sb.writeln('गाँव:  $village');
    sb.writeln('प्रकार: ${_txnLabel(txn.txnType)}');
    sb.writeln(shortLine);

    if (txn.commodity != null) {
      sb.writeln('अनाज:  ${txn.commodity!.toUpperCase()}');
    }
    if (txn.quantityKg != null) {
      sb.writeln('वजन:   ${txn.quantityKg!.toStringAsFixed(1)} KG');
    }
    if (txn.ratePerKg != null) {
      sb.writeln('रेट:   Rs.${txn.ratePerKg!.toStringAsFixed(0)}/KG');
    }

    sb.writeln(shortLine);
    sb.writeln('कुल:   Rs.${txn.amount.toStringAsFixed(0)}');
    sb.writeln('भुगतान: ${txn.paymentMode.toUpperCase()}');
    if (txn.notes != null) sb.writeln('नोट:   ${txn.notes}');
    sb.writeln(line);
    sb.writeln('Bhola Traders  ${DateTime.now().year}');
    sb.writeln();
    sb.writeln();
    sb.writeln(); // Feed lines

    return sb.toString();
  }

  // ── FILE SAVE HELPER ──────────────────────────────────────────────

  static Future<File> savePdfToTemp(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── PRINT VIA SYSTEM DIALOG ───────────────────────────────────────
  // Works for: WiFi printers, PDF viewers, Google Cloud Print

  static Future<void> printPdf(Uint8List bytes,
      {String name = 'Bhola Traders'}) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: name,
    );
  }

  // ── PREVIEW IN APP ────────────────────────────────────────────────

  static Future<void> previewPdf(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: 'bhola_traders.pdf');
  }

  // ── HELPERS ───────────────────────────────────────────────────────

  static String _txnLabel(String type) => switch (type) {
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

  /// Builds daily breakdown rows for the report table
  static List<pw.TableRow> _buildDailyBreakdownRows(
    Map<String, List<TransactionsTableData>> byDate,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final rows = byDate.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return rows.take(31).map((e) {
      final txns = e.value;
      double p = 0, s = 0, ci = 0, co = 0;
      for (final t in txns) {
        switch (t.txnType) {
          case 'purchase':
            p += t.amount;
          case 'sale':
            s += t.amount;
          case 'cash_in':
            ci += t.amount;
          case 'cash_out':
            co += t.amount;
        }
      }
      final dayNet = (s + ci) - (p + co);
      return _TableRow(
        [
          _fmtDate(e.key),
          p > 0 ? _fmt(p) : '-',
          s > 0 ? _fmt(s) : '-',
          ci > 0 ? _fmt(ci) : '-',
          co > 0 ? _fmt(co) : '-',
          _fmt(dayNet),
        ],
        font: font,
        netColor: dayNet >= 0 ? _green : _red,
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────
// PDF WIDGET HELPERS
// ─────────────────────────────────────────────────────────────────────

pw.Widget _Header({
  required String businessName,
  required pw.Font font,
  required pw.Font fontBold,
}) =>
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(businessName,
              style: pw.TextStyle(font: fontBold, fontSize: 18, color: _green)),
          pw.Text('कृषि बही-खाता / Agricultural Ledger',
              style: pw.TextStyle(font: font, fontSize: 11, color: _grey)),
        ]),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _green.shade(0.08),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text('🌾 Bhola Traders',
              style: pw.TextStyle(font: fontBold, fontSize: 12, color: _green)),
        ),
      ],
    );

pw.Widget _Divider() => pw.Divider(color: PdfColors.grey300, thickness: 0.5);

pw.Widget _TwoCol(String label, String value, pw.Font font, pw.Font fontBold) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(children: [
        pw.SizedBox(
            width: 140,
            child: pw.Text(label,
                style: pw.TextStyle(font: font, fontSize: 11, color: _grey))),
        pw.Text(':  ',
            style: pw.TextStyle(font: font, fontSize: 11, color: _grey)),
        pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(font: fontBold, fontSize: 12))),
      ]),
    );

pw.Widget _TxnTable({
  required List<TransactionsTableData> transactions,
  required pw.Font font,
  required pw.Font fontBold,
  bool showParty = false,
}) {
  final headers = showParty
      ? ['तारीख', 'पार्टी', 'प्रकार', 'अनाज', 'KG', 'रेट', 'रकम / Amount']
      : ['तारीख', 'प्रकार', 'अनाज', 'KG', 'रेट', 'रकम / Amount'];

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: showParty
        ? {
            0: const pw.FixedColumnWidth(62),
            1: const pw.FixedColumnWidth(70),
            2: const pw.FixedColumnWidth(55),
            3: const pw.FixedColumnWidth(40),
            4: const pw.FixedColumnWidth(36),
            5: const pw.FixedColumnWidth(34),
            6: const pw.FixedColumnWidth(60),
          }
        : {
            0: const pw.FixedColumnWidth(70),
            1: const pw.FixedColumnWidth(70),
            2: const pw.FixedColumnWidth(50),
            3: const pw.FixedColumnWidth(50),
            4: const pw.FixedColumnWidth(40),
            5: const pw.FixedColumnWidth(72),
          },
    children: [
      // Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _green),
        children: headers
            .map((h) => pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(h,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 9, color: _white)),
                ))
            .toList(),
      ),
      // Rows
      ...transactions.reversed.map((t) {
        final isIn = t.direction == 'in';
        final rowBg = isIn ? _green.shade(0.04) : _red.shade(0.04);
        final amtColor = isIn ? _green : _red;

        final cells = showParty
            ? [
                _fmtDate(t.entryDate),
                t.partyId,
                _txnLabelShort(t.txnType),
                t.commodity ?? '-',
                t.quantityKg?.toStringAsFixed(0) ?? '-',
                t.ratePerKg?.toStringAsFixed(0) ?? '-',
                '${isIn ? '+' : '-'}${_rupee.format(t.amount)}',
              ]
            : [
                _fmtDate(t.entryDate),
                _txnLabelShort(t.txnType),
                t.commodity ?? '-',
                t.quantityKg?.toStringAsFixed(0) ?? '-',
                t.ratePerKg?.toStringAsFixed(0) ?? '-',
                '${isIn ? '+' : '-'}${_rupee.format(t.amount)}',
              ];

        return pw.TableRow(
          decoration: pw.BoxDecoration(color: rowBg),
          children: [
            for (var i = 0; i < cells.length; i++)
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Text(cells[i],
                    style: pw.TextStyle(
                      font: i == cells.length - 1 ? fontBold : font,
                      fontSize: 9,
                      color: i == cells.length - 1 ? amtColor : PdfColors.black,
                    )),
              ),
          ],
        );
      }),
    ],
  );
}

pw.Widget _BagTable({
  required List<BagMovementsTableData> bags,
  required pw.Font font,
  required pw.Font fontBold,
}) =>
    pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _blue),
          children:
              ['तारीख / Date', 'प्रकार / Type', 'संख्या / Qty', 'नोट / Notes']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(h,
                            style: pw.TextStyle(
                                font: fontBold, fontSize: 9, color: _white)),
                      ))
                  .toList(),
        ),
        ...bags.map((b) => pw.TableRow(
              children: [
                _fmtDate(b.entryDate),
                b.movement,
                '${b.quantity}',
                b.notes ?? '-'
              ]
                  .map((c) => pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(c,
                            style: pw.TextStyle(font: font, fontSize: 9)),
                      ))
                  .toList(),
            )),
      ],
    );

pw.Widget _SummaryCell(
  String label,
  String value,
  PdfColor color,
  pw.Font font,
  pw.Font fontBold,
) {
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
      margin: const pw.EdgeInsets.symmetric(horizontal: 4),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: border, width: 0.8),
      ),
      child: pw.Column(children: [
        pw.Text(label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: font, fontSize: 9, color: textCol)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style:
                pw.TextStyle(font: fontBold, fontSize: 13, color: textCol)),
      ]),
    ),
  );
}

pw.TableRow _TableHeader(List<String> cols, {required pw.Font font}) =>
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: _light),
      children: cols
          .map((c) => pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: pw.Text(c, style: pw.TextStyle(font: font, fontSize: 9)),
              ))
          .toList(),
    );

pw.TableRow _TableRow(
  List<String> cells, {
  required pw.Font font,
  PdfColor? netColor,
}) =>
    pw.TableRow(
      children: cells
          .asMap()
          .map((i, c) => MapEntry(
                i,
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: pw.Text(c,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 9,
                        color: (i == cells.length - 1 && netColor != null)
                            ? netColor
                            : PdfColors.black,
                      )),
                ),
              ))
          .values
          .toList(),
    );

String _txnLabelShort(String type) => switch (type) {
      'purchase' => 'खरीदी',
      'sale' => 'बिक्री',
      'cash_in' => 'Cash In',
      'cash_out' => 'Cash Out',
      _ => type,
    };
