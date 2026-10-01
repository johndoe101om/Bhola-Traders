// lib/features/parties/screens/party_ledger_screen.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/local/local_database.dart';
import '../../transactions/screens/entry_screen.dart';
import '../../bags/screens/bag_entry_screen.dart';
import '../../receipts/screens/printer_setup_screen.dart';
import '../../receipts/widgets/print_action_sheet.dart';
import '../../../services/printing/print_service.dart';

class PartyLedgerScreen extends ConsumerStatefulWidget {
  final String partyId;
  const PartyLedgerScreen({super.key, required this.partyId});

  @override
  ConsumerState<PartyLedgerScreen> createState() => _PartyLedgerScreenState();
}

class _PartyLedgerScreenState extends ConsumerState<PartyLedgerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  PartiesTableData? _party;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {}); // Rebuild for FAB changes
    });
    _loadParty();
  }

  Future<void> _loadParty() async {
    final repo = ref.read(appRepositoryProvider);
    final p = await repo.getPartyById(widget.partyId);
    if (mounted) {
      setState(() {
        _party = p;
        _loading = false;
      });
    }
  }

  Future<void> _exportLedgerPdf(BuildContext context) async {
    if (_party == null) return;
    final repo = ref.read(appRepositoryProvider);
    final txns = await repo.getTransactions(partyId: widget.partyId);
    final bags = await repo.getBagMovements(widget.partyId);
    final balance = await repo.getBalanceForParty(widget.partyId);
    final bagsOut = await repo.getBagsOutstanding(widget.partyId);
    final svc = PrintService(thermalPrinter: ref.read(thermalPrinterProvider));

    final prefs = await SharedPreferences.getInstance();
    final bName = prefs.getString('business_name') ?? 'Bhola Traders';

    if (context.mounted) {
      await svc.printPartyLedger(
        context: context,
        party: _party!,
        transactions: txns,
        bagMovements: bags,
        balance: balance,
        bagsOutstanding: bagsOut,
        businessName: bName,
      );
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_party == null) {
      return const Scaffold(body: Center(child: Text('Party not found')));
    }

    final balanceAsync = ref.watch(partyBalanceProvider(widget.partyId));
    final bagsAsync = ref.watch(partyBagsProvider(widget.partyId));

    final balance = balanceAsync.valueOrNull ?? 0;
    final bags = bagsAsync.valueOrNull ?? 0;
    final balanceColor = balance >= 0 ? AppTheme.moneyIn : AppTheme.moneyOut;
    final balanceLabel =
        balance >= 0 ? 'हमारा बाकी\nThey owe us' : 'उनका बाकी\nWe owe them';

    return Scaffold(
      appBar: AppBar(
        title: Text(_party!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: 'Export Ledger PDF',
            onPressed: () => _exportLedgerPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      EntryScreen(preselectedPartyId: widget.partyId)),
            ).then((_) {
              ref.invalidate(partyBalanceProvider(widget.partyId));
              ref.invalidate(partyBagsProvider(widget.partyId));
            }),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '💰 हिसाब / Ledger'),
            Tab(text: '🛍️ बोरी / Bags'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primary.withOpacity(0.05),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_party!.village != null)
                        Row(children: [
                          const Icon(Icons.location_on_rounded,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(_party!.village!,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textSecondary),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      if (_party!.phone != null)
                        Row(children: [
                          const Icon(Icons.phone_rounded,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(_party!.phone!,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textSecondary),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppConstants.partyTypeLabels[_party!.partyType]
                                  ?.split('\n')
                                  .last ??
                              '',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(formatRupees(balance.abs()),
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: balanceColor)),
                    ),
                    Text(balanceLabel,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12, color: balanceColor, height: 1.3)),
                    if (bags > 0) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.inventory_2_rounded,
                            size: 14, color: AppTheme.bagColor),
                        const SizedBox(width: 4),
                        Text('$bags बोरी बाकी',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.bagColor,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _TransactionsList(partyId: widget.partyId),
                _BagsList(partyId: widget.partyId),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BagEntryScreen(partyId: widget.partyId)),
              ).then((_) => ref.invalidate(partyBagsProvider(widget.partyId))),
              backgroundColor: AppTheme.bagColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('बोरी एंट्री / Bag Entry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ── TRANSACTIONS LIST ────────────────────────────────────────────────

class _TransactionsList extends ConsumerWidget {
  final String partyId;
  const _TransactionsList({required this.partyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appRepositoryProvider);

    return FutureBuilder<List<TransactionsTableData>>(
      future: repo.getTransactions(partyId: partyId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final txns = snap.data ?? [];
        if (txns.isEmpty) {
          return const Center(
            child: Text('कोई लेन-देन नहीं\nNo transactions yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18, color: AppTheme.textSecondary, height: 1.5)),
          );
        }

        double runningBalance = 0;
        final withBalance = txns.reversed
            .map((t) {
              runningBalance += t.direction == 'in' ? t.amount : -t.amount;
              return (txn: t, balance: runningBalance);
            })
            .toList()
            .reversed
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: withBalance.length,
          itemBuilder: (_, i) {
            final item = withBalance[i];
            return _LedgerRow(
              txn: item.txn,
              runningBalance: item.balance,
              partyId: partyId,
            );
          },
        );
      },
    );
  }
}

class _LedgerRow extends ConsumerWidget {
  final TransactionsTableData txn;
  final double runningBalance;
  final String partyId;
  const _LedgerRow(
      {required this.txn, required this.runningBalance, required this.partyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIn = txn.direction == 'in';
    final color = isIn ? AppTheme.moneyIn : AppTheme.moneyOut;
    final typeLabel =
        AppConstants.txnTypeLabels[txn.txnType]?.split('\n').last ??
            txn.txnType;
    final date = DateTime.tryParse(txn.entryDate) ?? DateTime.now();
    final createdAt = tryParseDateTime(txn.createdAt);

    return GestureDetector(
      onTap: () => _editTransaction(context, ref),
      onLongPress: () => _showActions(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 42,
              child: Column(
                children: [
                  Text('${date.day}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_monthShort(date.month),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(typeLabel,
                            style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (txn.commodity != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${commodityEmoji(txn.commodity)} ${txn.commodity}',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined,
                          size: 14, color: AppTheme.textHint),
                    ],
                  ),
                  if (txn.quantityKg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          '${formatKg(txn.quantityKg!)} × ₹${txn.ratePerKg?.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                    ),
                  if (txn.notes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(txn.notes!,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  // Timestamp
                  if (createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        formatDateTime(createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIn ? '+' : '-'}${formatRupees(txn.amount)}',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupees(runningBalance.abs()),
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Open EntryScreen in edit mode for this transaction
  void _editTransaction(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntryScreen(transaction: txn),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(partyBalanceProvider(partyId));
        ref.invalidate(partyBagsProvider(partyId));
        ref.invalidate(recentTransactionsProvider);
      }
    });
  }

  /// Show popup menu with Edit / Delete / Print actions
  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.edit_rounded, color: AppTheme.primary),
                title: const Text('एडिट करें / Edit',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _editTransaction(context, ref);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('हटाएं / Delete',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await confirmDialog(
                    context,
                    title: 'एंट्री हटाएं? / Delete Entry?',
                    message:
                        'क्या आप इस एंट्री को हटाना चाहते हैं?\nAre you sure?',
                  );
                  if (ok) {
                    await ref
                        .read(appRepositoryProvider)
                        .deleteTransaction(txn.id);
                    if (context.mounted) {
                      showSuccess(context, 'एंट्री हटा दी गई / Entry deleted!');
                      ref.invalidate(partyBalanceProvider(partyId));
                      ref.invalidate(recentTransactionsProvider);
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded,
                    color: AppTheme.textSecondary),
                title: const Text('रसीद / Print Receipt',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  showPrintSheet(context, txn: txn, partyName: txn.partyId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthShort(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];
}

// ── BAGS LIST ────────────────────────────────────────────────────────

class _BagsList extends ConsumerWidget {
  final String partyId;
  const _BagsList({required this.partyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appRepositoryProvider);

    return FutureBuilder<List<BagMovementsTableData>>(
      future: repo.getBagMovements(partyId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final bags = snap.data ?? [];
        if (bags.isEmpty) {
          return const Center(
            child: Text('कोई बोरी एंट्री नहीं\nNo bag entries yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18, color: AppTheme.textSecondary, height: 1.5)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: bags.length,
          itemBuilder: (_, i) => _BagTile(bag: bags[i]),
        );
      },
    );
  }
}

class _BagTile extends StatelessWidget {
  final BagMovementsTableData bag;
  const _BagTile({required this.bag});

  @override
  Widget build(BuildContext context) {
    final isGiven = bag.movement == 'given';
    final color = isGiven ? AppTheme.moneyOut : AppTheme.moneyIn;
    final date = DateTime.tryParse(bag.entryDate) ?? DateTime.now();
    final createdAt = tryParseDateTime(bag.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Center(
            child: Text(isGiven ? '📦' : '✅',
                style: const TextStyle(fontSize: 22))),
      ),
      title: Text(
        isGiven ? 'बोरी दी / Bags Given' : 'बोरी वापस / Bags Returned',
        style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bag.notes != null ? bag.notes! : formatDate(date),
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (createdAt != null)
            Text(
              formatDateTime(createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${isGiven ? '-' : '+'}${bag.quantity}',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const Text('बोरी',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BagEntryScreen(partyId: bag.partyId, bag: bag)),
      ),
    );
  }
}
