// lib/features/bags/screens/bag_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/local/local_database.dart';

class BagEntryScreen extends ConsumerStatefulWidget {
  final String? partyId;
  final BagMovementsTableData? bag;

  const BagEntryScreen({super.key, this.partyId, this.bag});

  @override
  ConsumerState<BagEntryScreen> createState() => _BagEntryScreenState();
}

class _BagEntryScreenState extends ConsumerState<BagEntryScreen> {
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _movement = 'given';
  PartiesTableData? _party;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.partyId != null) _loadParty();
    if (widget.bag != null) {
      _movement = widget.bag!.movement;
      _qtyCtrl.text = widget.bag!.quantity.toString();
      _notesCtrl.text = widget.bag!.notes ?? '';
    }
  }

  Future<void> _loadParty() async {
    final p = await ref.read(appRepositoryProvider).getPartyById(widget.partyId!);
    if (mounted) setState(() => _party = p);
  }

  Future<void> _pickParty() async {
    final parties = await ref.read(appRepositoryProvider).getParties();
    if (!mounted) return;
    final picked = await showModalBottomSheet<PartiesTableData>(
      context: context,
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: parties.length,
        itemBuilder: (_, i) => ListTile(
          leading: Icon(partyTypeIcon(parties[i].partyType), color: AppTheme.primary),
          title: Text(parties[i].name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          subtitle: parties[i].village != null ? Text(parties[i].village!) : null,
          onTap: () => Navigator.pop(context, parties[i]),
        ),
      ),
    );
    if (picked != null) setState(() => _party = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_party == null && widget.bag == null) { showError(context, 'पार्टी चुनें / Select party'); return; }
    final qty = int.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) { showError(context, 'संख्या डालें / Enter quantity'); return; }

    setState(() => _saving = true);
    try {
      if (widget.bag != null) {
        // Edit existing
        final updated = widget.bag!.copyWith(
          movement: _movement,
          quantity: qty,
          notes: _notesCtrl.text.trim().isEmpty ? const drift.Value(null) : drift.Value(_notesCtrl.text.trim()),
          syncedAt: const drift.Value(null),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await ref.read(appRepositoryProvider).updateBagMovement(updated);
        if (mounted) {
          showSuccess(context, 'बोरी एंट्री अपडेट हो गई!');
          Navigator.pop(context, true);
        }
      } else {
        // Create new
        await ref.read(appRepositoryProvider).createBagMovement(
          partyId: _party!.id,
          movement: _movement,
          quantity: qty,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
        if (mounted) {
          showSuccess(context, 'बोरी एंट्री सेव हो गई!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.bag == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('हटाएं? / Delete?'),
        content: const Text('क्या आप इस बोरी एंट्री को हटाना चाहते हैं?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await ref.read(appRepositoryProvider).deleteBagMovement(widget.bag!.id);
      if (mounted) {
        showSuccess(context, 'एंट्री हटा दी गई!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.bag != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'एंट्री बदलें / Edit Entry' : 'बोरी एंट्री / Bag Entry'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movement type
            const Text('बोरी का प्रकार / Type',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: AppConstants.bagMovements.map((m) {
                final isSelected = m == _movement;
                final label = AppConstants.bagMovementLabels[m]?.split('\n') ?? [m];
                final color = m == 'given' ? AppTheme.moneyOut : AppTheme.moneyIn;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _movement = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withOpacity(0.08),
                        border: Border.all(color: color, width: isSelected ? 2 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(m == 'given' ? '📦' : '✅', style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(label.join('\n'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : color, height: 1.3)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Party
            if (!isEdit) ...[
              const Text('पार्टी / Party', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickParty,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(_party != null ? partyTypeIcon(_party!.partyType) : Icons.person_search_rounded,
                        color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Text(_party?.name ?? 'पार्टी चुनें / Select Party',
                        style: TextStyle(fontSize: 17,
                          color: _party != null ? AppTheme.textPrimary : AppTheme.textHint,
                          fontWeight: _party != null ? FontWeight.w600 : FontWeight.normal)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Quantity
            const Text('संख्या / Quantity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'बोरी / Bags',
                suffixStyle: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            const Text('नोट / Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(hintText: 'वैकल्पिक / Optional'),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.bagColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _saving ? 'सेव हो रहा है...' : (isEdit ? 'अपडेट करें / Update' : 'सेव करें / Save'),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
