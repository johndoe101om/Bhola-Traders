// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../data/repositories/providers.dart';
import '../../parties/screens/parties_screen.dart';
import '../../transactions/screens/entry_screen.dart';
import '../../bags/screens/bags_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../voice/screens/voice_entry_screen.dart';
import '../widgets/today_summary_card.dart';
import '../widgets/recent_txn_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  final _pages = const [
    _DashboardPage(),
    PartiesScreen(),
    BagsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _navIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'होम / Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'पार्टी / Parties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'बोरी / Bags',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'रिपोर्ट / Report',
          ),
        ],
      ),
      // FAB: quick new entry
      floatingActionButton: _navIndex == 0
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Voice entry button
              FloatingActionButton.extended(
                heroTag: 'voice_fab',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoiceEntryScreen()),
                ),
                backgroundColor: const Color(0xFF1A1A2E),
                icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
                label: const Text('आवाज़ से / Voice',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              // Manual entry button
              FloatingActionButton.extended(
                heroTag: 'manual_fab',
                onPressed: () => _openEntry(context),
                backgroundColor: AppTheme.primary,
                icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                label: const Text('लिख कर / Manual',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          )
        : null,
    );
  }

  void _openEntry(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryScreen()));
  }
}

// ── DASHBOARD PAGE ───────────────────────────────────────────────────

class _DashboardPage extends ConsumerWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/images/logo.png', width: 32, height: 32),
            ),
            const SizedBox(width: 10),
            const Text('Bhola Traders'),
          ],
        ),
        actions: [
          const SyncEngineIconButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(recentTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // ── SYNC BANNER (shows if offline items pending) ──────────
            const SyncBanner(),

            // ── TODAY'S SUMMARY ───────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text('आज का हिसाब / Today\'s Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            ),
            const TodaySummaryCard(),

            // ── QUICK ACTIONS ─────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('जल्दी एंट्री / Quick Entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            ),
            _QuickActions(),

            // ── RECENT TRANSACTIONS ───────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('हाल की एंट्री / Recent Entries',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            ),
            recentAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txns) {
                if (txns.isEmpty) {
                  return const _EmptyState();
                }
                return Column(
                  children: txns.take(15).map((t) => RecentTxnTile(txn: t)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── QUICK ACTIONS GRID ───────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'खरीदी\nPurchase',
        icon: Icons.download_rounded,
        color: AppTheme.moneyOut,
        txnType: 'purchase',
      ),
      _QuickAction(
        label: 'बिक्री\nSale',
        icon: Icons.upload_rounded,
        color: AppTheme.moneyIn,
        txnType: 'sale',
      ),
      _QuickAction(
        label: 'पैसा मिला\nCash In',
        icon: Icons.add_circle_rounded,
        color: AppTheme.moneyIn,
        txnType: 'cash_in',
      ),
      _QuickAction(
        label: 'पैसा दिया\nCash Out',
        icon: Icons.remove_circle_rounded,
        color: AppTheme.moneyOut,
        txnType: 'cash_out',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
        children: actions,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String txnType;

  const _QuickAction({
    required this.label, required this.icon,
    required this.color, required this.txnType,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EntryScreen(initialTxnType: txnType)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: color,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── EMPTY STATE ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          children: [
            Text('📋', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('कोई एंट्री नहीं\nNo entries yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
