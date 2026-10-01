// lib/features/parties/screens/parties_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/local/local_database.dart';
import 'party_ledger_screen.dart';
import 'add_party_screen.dart';

class PartiesScreen extends ConsumerStatefulWidget {
  const PartiesScreen({super.key});
  @override
  ConsumerState<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends ConsumerState<PartiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  final _tabs = [
    (label: 'सभी\nAll', type: ''),
    (label: 'किसान\nFarmer', type: 'farmer'),
    (label: 'सप्लायर\nSupplier', type: 'supplier'),
    (label: 'ग्राहक\nCustomer', type: 'customer'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'नाम / गाँव खोजें...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  ref.read(partySearchProvider.notifier).state = v;
                },
              )
            : const Text('पार्टी / Parties'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search_rounded,
                color: Colors.white),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchCtrl.clear();
                  ref.read(partySearchProvider.notifier).state = '';
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: _tabs
              .map((t) => Tab(
                    child: Text(t.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, height: 1.3)),
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((t) => _PartyList(type: t.type)).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPartyScreen()),
        ).then((_) => ref.invalidate(filteredPartiesProvider(''))),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('नई पार्टी / Add Party',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── PARTY LIST ───────────────────────────────────────────────────────

class _PartyList extends ConsumerWidget {
  final String type;
  const _PartyList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(partySearchProvider);
    final repo = ref.watch(appRepositoryProvider);

    return FutureBuilder<List<PartiesTableData>>(
      future: repo.getParties(
        type: type.isEmpty ? null : type,
        search: search.isEmpty ? null : search,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final parties = snap.data ?? [];
        if (parties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('😐', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  search.isNotEmpty
                      ? '"$search" नहीं मिला\nNot found'
                      : 'कोई पार्टी नहीं\nNo parties yet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, top: 4),
          itemCount: parties.length,
          itemBuilder: (_, i) => _PartyTile(party: parties[i]),
        );
      },
    );
  }
}

// ── PARTY TILE ───────────────────────────────────────────────────────

class _PartyTile extends ConsumerWidget {
  final PartiesTableData party;
  const _PartyTile({required this.party});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(partyBalanceProvider(party.id));
    final bagsAsync = ref.watch(partyBagsProvider(party.id));

    final balance = balanceAsync.valueOrNull ?? 0;
    final bags = bagsAsync.valueOrNull ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PartyLedgerScreen(partyId: party.id)),
        ).then((_) {
          ref.invalidate(partyBalanceProvider(party.id));
          ref.invalidate(partyBagsProvider(party.id));
        }),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(partyTypeIcon(party.partyType),
                      color: AppTheme.primary, size: 28),
                ),
              ),
              const SizedBox(width: 14),

              // Name + village + timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(party.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    if (party.village != null)
                      Text(party.village!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.textSecondary)),
                    // Timestamp
                    Builder(builder: (_) {
                      final updatedAt = tryParseDateTime(party.updatedAt);
                      if (updatedAt == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text(
                              formatTimeAgo(updatedAt),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Balance + bags
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatRupees(balance.abs()),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color:
                            balance >= 0 ? AppTheme.moneyIn : AppTheme.moneyOut,
                      ),
                    ),
                  ),
                  if (bags > 0)
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_rounded,
                            size: 14, color: AppTheme.bagColor),
                        const SizedBox(width: 4),
                        Text('$bags बोरी',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.bagColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              ),

              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.textHint),
                onSelected: (val) async {
                  if (val == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddPartyScreen(party: party)),
                    ).then((_) {
                      ref.invalidate(filteredPartiesProvider(''));
                    });
                  } else if (val == 'delete') {
                    final ok = await confirmDialog(context,
                        title: 'पार्टी हटाएं? / Delete Party?',
                        message:
                            'Are you sure you want to delete ${party.name}?');
                    if (ok) {
                      await ref
                          .read(appRepositoryProvider)
                          .deleteParty(party.id);
                      if (context.mounted) {
                        showSuccess(
                            context, 'पार्टी हटा दी गई / Party deleted');
                      }
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('एडिट करें / Edit')),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('हटाएं / Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
