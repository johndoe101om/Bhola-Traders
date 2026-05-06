// lib/features/reports/screens/reports_screen.dart  (Phase 4 — full rewrite)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/local/local_database.dart';
import '../../../services/printing/print_service.dart';
import '../../receipts/screens/printer_setup_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _exporting = false;

  PrintService get _printService => PrintService(
    thermalPrinter: ref.read(thermalPrinterProvider),
  );

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) setState(() { _from = range.start; _to = range.end; });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(appRepositoryProvider);
    final fmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 रिपोर्ट / Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            tooltip: 'Printer Setup',
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const PrinterSetupScreen())),
          ),
          _exporting
            ? const Padding(padding: EdgeInsets.all(14),
                child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                tooltip: 'Export PDF',
                onPressed: _exportPdf,
              ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── DATE RANGE ─────────────────────────────────────────
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.primary, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.date_range_rounded, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  '${fmt.format(_from)}  →  ${fmt.format(_to)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppTheme.primary),
                )),
                const Icon(Icons.edit_calendar_rounded, color: AppTheme.primary, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _QuickRange('आज', 0, _setRange),
              _QuickRange('7 दिन', 7, _setRange),
              _QuickRange('30 दिन', 30, _setRange),
              _QuickRange('90 दिन', 90, _setRange),
            ]),
          ),
          const SizedBox(height: 16),

          // ── DATA ───────────────────────────────────────────────
          FutureBuilder<List<TransactionsTableData>>(
            future: repo.getTransactions(from: _from, to: _to),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(
                child: Padding(padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator()));
              final txns = snap.data!;
              return _ReportBody(txns: txns, from: _from, to: _to,
                printService: _printService, ref: ref);
            },
          ),
        ],
      ),
    );
  }

  void _setRange(DateTime f, DateTime t) => setState(() { _from = f; _to = t; });

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final bName = prefs.getString('business_name') ?? 'Bhola Traders';
      
      final txns = await ref.read(appRepositoryProvider).getTransactions(from: _from, to: _to);
      await _printService.printBusinessReport(
        context: context, transactions: txns, from: _from, to: _to, businessName: bName);
    } catch (e) {
      if (mounted) showError(context, 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _ReportBody extends ConsumerWidget {
  final List<TransactionsTableData> txns;
  final DateTime from;
  final DateTime to;
  final PrintService printService;
  final WidgetRef ref;

  const _ReportBody({required this.txns, required this.from, required this.to,
    required this.printService, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    double purchase = 0, sale = 0, cashIn = 0, cashOut = 0;
    final cKg = <String, double>{};
    final cAmt = <String, double>{};

    for (final t in txns) {
      switch (t.txnType) {
        case 'purchase': purchase += t.amount;
        case 'sale':     sale += t.amount;
        case 'cash_in':  cashIn += t.amount;
        case 'cash_out': cashOut += t.amount;
      }
      if (t.commodity != null && t.quantityKg != null) {
        cKg[t.commodity!] = (cKg[t.commodity!] ?? 0) + t.quantityKg!;
        cAmt[t.commodity!] = (cAmt[t.commodity!] ?? 0) + t.amount;
      }
    }
    final net = (sale + cashIn) - (purchase + cashOut);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionHeader('सारांश / Summary'),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: (net >= 0 ? AppTheme.moneyIn : AppTheme.moneyOut).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('नेट / Net', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
              color: net >= 0 ? AppTheme.moneyIn : AppTheme.moneyOut)),
            Text(formatRupees(net.abs()), style: TextStyle(fontSize: 26,
              fontWeight: FontWeight.bold,
              color: net >= 0 ? AppTheme.moneyIn : AppTheme.moneyOut)),
          ]),
        ),
        const SizedBox(height: 14),
        _Row('खरीदी / Purchase', purchase, AppTheme.moneyOut),
        _Row('बिक्री / Sale', sale, AppTheme.moneyIn),
        _Row('पैसा मिला / Cash In', cashIn, AppTheme.moneyIn),
        _Row('पैसा दिया / Cash Out', cashOut, AppTheme.moneyOut),
        const Divider(),
        _Row('कुल एंट्री / Entries', txns.length.toDouble(), AppTheme.textPrimary, isCount: true),
      ]))),

      if (cKg.isNotEmpty) ...[
        const SizedBox(height: 16),
        const _SectionHeader('अनाज / Commodities'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          children: cKg.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Text(commodityEmoji(e.key), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.key.toUpperCase(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(formatKg(e.value),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ])),
              Text(formatRupees(cAmt[e.key] ?? 0),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          )).toList(),
        ))),
      ],

      const SizedBox(height: 16),
      const _SectionHeader('Export करें / Download'),
      Card(child: Column(children: [
        ListTile(
          leading: Container(width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red[700])),
          title: const Text('Business Report PDF', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${txns.length} transactions'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              final bName = prefs.getString('business_name') ?? 'Bhola Traders';
              
              await printService.printBusinessReport(
                context: context, transactions: txns, from: from, to: to, businessName: bName);
            } catch (e) {
              if (context.mounted) showError(context, '$e');
            }
          },
        ),
      ])),

      const SizedBox(height: 16),
      const _SectionHeader('सबसे ज्यादा बाकी / Outstanding'),
      _OutstandingCard(ref: ref),
      const SizedBox(height: 80),
    ]);
  }
}

class _OutstandingCard extends StatelessWidget {
  final WidgetRef ref;
  const _OutstandingCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(appRepositoryProvider);
    return FutureBuilder<List<PartiesTableData>>(
      future: repo.getParties(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _load(repo, snap.data!),
          builder: (_, b) {
            final items = b.data?.where((i) => (i['balance'] as double).abs() > 0).take(8).toList() ?? [];
            if (items.isEmpty) return const SizedBox.shrink();
            return Card(child: Column(children: items.asMap().entries.map((entry) {
              final party = entry.value['party'] as PartiesTableData;
              final balance = entry.value['balance'] as double;
              final color = balance >= 0 ? AppTheme.moneyIn : AppTheme.moneyOut;
              return Column(children: [
                ListTile(
                  leading: Icon(partyTypeIcon(party.partyType), color: AppTheme.primary),
                  title: Text(party.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: party.village != null ? Text(party.village!) : null,
                  trailing: Text(formatRupees(balance.abs()),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                ),
                if (entry.key < items.length - 1) const Divider(height: 1),
              ]);
            }).toList()));
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _load(dynamic repo, List<PartiesTableData> parties) async {
    final result = <Map<String, dynamic>>[];
    for (final p in parties) {
      final b = await repo.getBalanceForParty(p.id);
      result.add({'party': p, 'balance': b});
    }
    result.sort((a, b) => (b['balance'] as double).abs().compareTo((a['balance'] as double).abs()));
    return result;
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
      color: AppTheme.textSecondary)));
}

Widget _Row(String label, double value, Color color, {bool isCount = false}) =>
  Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
    Text(label, style: const TextStyle(fontSize: 15)),
    const Spacer(),
    Text(isCount ? value.toInt().toString() : formatRupees(value),
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
  ]));

class _QuickRange extends StatelessWidget {
  final String label;
  final int days;
  final void Function(DateTime, DateTime) onRange;
  const _QuickRange(this.label, this.days, this.onRange);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      final to = DateTime.now();
      final from = days == 0 ? to : to.subtract(Duration(days: days));
      onRange(from, to);
    },
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: AppTheme.primary)),
    ),
  );
}
