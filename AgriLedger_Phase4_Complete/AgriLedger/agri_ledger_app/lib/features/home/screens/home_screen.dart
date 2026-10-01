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
import '../../settings/screens/settings_screen.dart';

import '../../employees/screens/employees_screen.dart';
import '../../employees/widgets/workforce_dashboard_card.dart';

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
    EmployeesScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _navIndex, children: _pages),
      bottomNavigationBar: _ResponsiveBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
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
                  icon: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 26),
                  label: const Text('आवाज़ से / Voice',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                // Manual entry button
                FloatingActionButton.extended(
                  heroTag: 'manual_fab',
                  onPressed: () => _openEntry(context),
                  backgroundColor: AppTheme.primary,
                  icon: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 24),
                  label: const Text('लिख कर / Manual',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            )
          : null,
    );
  }

  void _openEntry(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EntryScreen()));
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
              child: SizedBox(
                width: 28,
                height: 28,
                child: Image.asset('assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.agriculture_rounded,
                        size: 24,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Bhola Traders',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          SyncEngineIconButton(),
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(todayWorkforceStatsProvider);
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
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
            ),
            const TodaySummaryCard(),

            // ── WORKFORCE SUMMARY ──────────────────────────────────────
            const WorkforceDashboardCard(),

            // ── QUICK ACTIONS ─────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('जल्दी एंट्री / Quick Entry',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
            ),
            _QuickActions(),

            // ── RECENT TRANSACTIONS ───────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('हाल की एंट्री / Recent Entries',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
            ),
            recentAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txns) {
                if (txns.isEmpty) {
                  return const _EmptyState();
                }
                return Column(
                  children:
                      txns.take(15).map((t) => RecentTxnTile(txn: t)).toList(),
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
      const _QuickAction(
        label: 'खरीदी\nPurchase',
        icon: Icons.download_rounded,
        color: AppTheme.moneyOut,
        txnType: 'purchase',
      ),
      const _QuickAction(
        label: 'बिक्री\nSale',
        icon: Icons.upload_rounded,
        color: AppTheme.moneyIn,
        txnType: 'sale',
      ),
      const _QuickAction(
        label: 'पैसा मिला\nCash In',
        icon: Icons.add_circle_rounded,
        color: AppTheme.moneyIn,
        txnType: 'cash_in',
      ),
      const _QuickAction(
        label: 'पैसा दिया\nCash Out',
        icon: Icons.remove_circle_rounded,
        color: AppTheme.moneyOut,
        txnType: 'cash_out',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 360;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: isSmall ? 1.85 : 2.2,
            children: actions,
          ),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String txnType;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.txnType,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 160;
        final iconSize = isSmall ? 24.0 : 30.0;
        final fontSize = isSmall ? 13.0 : 15.0;
        final hPadding = isSmall ? 10.0 : 14.0;
        final vPadding = isSmall ? 8.0 : 10.0;

        return Material(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EntryScreen(initialTxnType: txnType)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: hPadding, vertical: vPadding),
              child: Row(
                children: [
                  Icon(icon, color: color, size: iconSize),
                  SizedBox(width: isSmall ? 8 : 10),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                style: TextStyle(
                    fontSize: 18, color: AppTheme.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// ── RESPONSIVE BOTTOM NAVIGATION BAR ─────────────────────────────────

class _ResponsiveBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ResponsiveBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.home_rounded, label: 'होम\nHome'),
    (icon: Icons.people_rounded, label: 'पार्टी\nParties'),
    (icon: Icons.inventory_2_rounded, label: 'बोरी\nBags'),
    (icon: Icons.people_alt_rounded, label: 'स्टाफ\nStaff'),
    (icon: Icons.bar_chart_rounded, label: 'रिपोर्ट\nReport'),
    (icon: Icons.settings_rounded, label: 'सेटिंग\nSettings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Colors.grey.shade300, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isSelected = i == currentIndex;
              final color =
                  isSelected ? AppTheme.primary : AppTheme.textSecondary;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 22, color: color),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label.split('\n').first,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
