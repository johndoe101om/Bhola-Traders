// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/sync/sync_providers.dart';

import '../../../data/repositories/providers.dart';
import '../../receipts/screens/printer_setup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _businessName = 'Bhola Traders';
  String _serverUrl = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _businessName = prefs.getString('business_name') ?? 'Bhola Traders';
          _serverUrl =
              prefs.getString('server_url') ?? 'http://192.168.1.11:5000';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[Settings] Failed to load prefs: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('business_name', _businessName);
      await prefs.setString('server_url', _serverUrl);
    } catch (e) {
      debugPrint('[Settings] Failed to save prefs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ सेटिंग / Settings')),
      body: ListView(
        children: [
          // ── BUSINESS ─────────────────────────────────────────────
          const _SectionHeader('व्यापार / Business'),
          _SettingTile(
            icon: Icons.store_rounded,
            label: 'व्यापार का नाम / Business Name',
            value: _businessName,
            onTap: () => _editText(
              context,
              title: 'Business Name',
              initial: _businessName,
              onSave: (v) async {
                setState(() => _businessName = v);
                await _savePrefs();
              },
            ),
          ),

          // Sync status — wrapped in safe builder
          _SyncSection(),

          // ── PRINTER ───────────────────────────────────────────────
          const _SectionHeader('प्रिंटर / Printer'),
          ListTile(
            leading: const Icon(Icons.print_rounded, color: AppTheme.primary),
            title: const Text('Bluetooth Thermal Printer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: const Text('Setup & test your receipt printer'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrinterSetupScreen()),
            ),
          ),

          // ── SECURITY ──────────────────────────────────────────────
          const _SectionHeader('सुरक्षा / Security'),
          ListTile(
            leading: const Icon(Icons.lock_rounded, color: AppTheme.primary),
            title: const Text('PIN बदलें / Change PIN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: const Text('Change your 4-digit login PIN'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _changePinDialog(context),
          ),

          // ── DATA ──────────────────────────────────────────────────
          const _SectionHeader('डेटा / Data'),
          _ClearSyncQueueTile(),

          // ── ABOUT ─────────────────────────────────────────────────
          const _SectionHeader('जानकारी / About'),
          const ListTile(
            leading: Icon(Icons.storefront_rounded, color: AppTheme.primary),
            title: Text('Bhola Traders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            subtitle: Text('Version 1.0.0 • Phase 4\nTrust • Quality • Growth'),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    String? hint,
    required String initial,
    required Future<void> Function(String) onSave,
  }) async {
    final ctrl = TextEditingController(text: initial);
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(hintText: hint ?? 'Enter $title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await onSave(ctrl.text.trim());
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePinDialog(BuildContext context) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('PIN बदलें / Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Current PIN'),
            ),
            TextField(
              controller: newCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'New PIN'),
            ),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Confirm New PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                final current = prefs.getString('user_pin') ?? '1234';
                if (oldCtrl.text != current) {
                  if (dialogCtx.mounted) {
                    showError(dialogCtx, 'Current PIN is wrong');
                  }
                  return;
                }
                if (newCtrl.text.length != 4) {
                  if (dialogCtx.mounted) {
                    showError(dialogCtx, 'PIN must be 4 digits');
                  }
                  return;
                }
                if (newCtrl.text != confirmCtrl.text) {
                  if (dialogCtx.mounted) {
                    showError(dialogCtx, 'PINs do not match');
                  }
                  return;
                }
                await prefs.setString('user_pin', newCtrl.text);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  showSuccess(context, 'PIN changed successfully!');
                }
              } catch (e) {
                debugPrint('[Settings] Change PIN error: $e');
                if (dialogCtx.mounted) {
                  showError(dialogCtx, 'An error occurred');
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

// ── SYNC SECTION (isolated to prevent crashes) ────────────────────────

class _SyncSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Isolate Riverpod providers in a Consumer so errors don't crash the page
    return Consumer(
      builder: (context, ref, child) {
        try {
          final engine = ref.watch(syncEngineProvider);
          final syncCountAsync = ref.watch(syncCountProvider);
          final syncCount = syncCountAsync.valueOrNull ?? 0;
          final isBusy = engine.state.isBusy;
          final isOnline = engine.isOnline;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.divider),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'सिंक स्थिति / Sync Status',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              engine.statusText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOnline
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: isOnline ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOnline
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: syncCount > 0
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: syncCount > 0
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          syncCount > 0
                              ? Icons.pending_actions_rounded
                              : Icons.check_circle_rounded,
                          size: 18,
                          color: syncCount > 0
                              ? Colors.orange.shade800
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncCount > 0
                                ? '$syncCount प्रविष्टियां अपलोड के लिए बाकी हैं'
                                : 'सभी डेटा सिंक है / All data synced',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: syncCount > 0
                                  ? Colors.orange.shade900
                                  : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () async {
                              try {
                                final result =
                                    await engine.syncNow(force: true);
                                if (context.mounted) {
                                  if (result.success) {
                                    if (result.pushed > 0 ||
                                        result.pulled > 0) {
                                      showSuccess(context,
                                          'Synced! ↑${result.pushed} ↓${result.pulled}');
                                    } else {
                                      showSuccess(
                                          context, 'Already up to date ✓');
                                    }
                                  } else {
                                    showError(context,
                                        result.message ?? 'Sync failed');
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showError(context, 'Sync error occurred');
                                }
                              }
                            },
                      icon: isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        isBusy
                            ? 'सिंक हो रहा है... / Syncing...'
                            : 'अभी सिंक करें / Sync Now',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          debugPrint('[Settings] SyncEngine not available: $e');
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Row(
              children: [
                Icon(Icons.sync_disabled_rounded, color: Colors.grey),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sync engine not ready. Restart app to retry.',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// ── CLEAR SYNC QUEUE (isolated) ──────────────────────────────────────

class _ClearSyncQueueTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        int syncCount = 0;
        try {
          syncCount = ref.watch(syncCountProvider).valueOrNull ?? 0;
        } catch (_) {}

        return ListTile(
          leading: Icon(Icons.delete_outline_rounded, color: Colors.red[400]),
          title: Text('सभी pending sync हटाएं',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[400])),
          subtitle: Text(syncCount > 0
              ? 'Clear $syncCount stuck sync queue items'
              : 'No pending sync items'),
          onTap: () async {
            final ok = await confirmDialog(
              context,
              title: 'Clear Sync Queue?',
              message: 'This will delete $syncCount pending sync items. '
                  'Your local data is safe.',
            );
            if (ok) {
              try {
                await ref.read(localDatabaseProvider).clearAllSyncQueue();
                if (context.mounted) showSuccess(context, 'Sync queue cleared');
              } catch (e) {
                if (context.mounted) showError(context, 'An error occurred');
              }
            }
          },
        );
      },
    );
  }
}

// ── HELPER WIDGETS ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5)),
      );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(value,
            style:
                const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        trailing:
            const Icon(Icons.edit_rounded, size: 18, color: AppTheme.textHint),
        onTap: onTap,
      );
}
