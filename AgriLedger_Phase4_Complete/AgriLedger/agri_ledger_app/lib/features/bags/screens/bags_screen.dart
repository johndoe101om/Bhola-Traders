// lib/features/bags/screens/bags_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/local/local_database.dart';
import '../../parties/screens/party_ledger_screen.dart';
import 'bag_entry_screen.dart';

class BagsScreen extends ConsumerWidget {
  const BagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(recentBagMovementsProvider); // Auto-refresh when new bag added
    final repo = ref.watch(appRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🛍️ बोरी / Jute Bags')),
      body: FutureBuilder<List<PartiesTableData>>(
        future: repo.getParties(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final parties = snap.data ?? [];
          return _OutstandingList(parties: parties, repo: repo);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BagEntryScreen()),
        ).then((_) => ref.invalidate(appRepositoryProvider)),
        backgroundColor: AppTheme.bagColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('बोरी एंट्री / Bag Entry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OutstandingList extends StatelessWidget {
  final List<PartiesTableData> parties;
  final dynamic repo;

  const _OutstandingList({required this.parties, required this.repo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadOutstanding(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        final withBags = items.where((i) => (i['bags'] as int) > 0).toList();

        if (withBags.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✅', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 16),
                  Text('सभी बोरी वापस आ गई!\nAll bags returned!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          color: AppTheme.textSecondary,
                          height: 1.4)),
                ],
              ),
            ),
          );
        }

        final totalOutstanding =
            withBags.fold<int>(0, (s, i) => s + (i['bags'] as int));

        return Column(
          children: [
            // Summary header
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bagColor.withOpacity(0.1),
                border: Border.all(color: AppTheme.bagColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      color: AppTheme.bagColor, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('कुल बोरी बाकी\nTotal Outstanding',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$totalOutstanding',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.bagColor)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: withBags.length,
                itemBuilder: (_, i) {
                  final item = withBags[i];
                  final party = item['party'] as PartiesTableData;
                  final bags = item['bags'] as int;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.bagColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Text('📦', style: TextStyle(fontSize: 22))),
                      ),
                      title: Text(party.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      subtitle: party.village != null
                          ? Text(party.village!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13))
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('$bags',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.bagColor)),
                          ),
                          const Text('बोरी बाकी',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                PartyLedgerScreen(partyId: party.id)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadOutstanding() async {
    final result = <Map<String, dynamic>>[];
    for (final party in parties) {
      final bags = await repo.getBagsOutstanding(party.id);
      result.add({'party': party, 'bags': bags});
    }
    result.sort((a, b) => (b['bags'] as int).compareTo(a['bags'] as int));
    return result;
  }
}
