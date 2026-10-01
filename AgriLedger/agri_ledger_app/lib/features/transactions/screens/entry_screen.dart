// lib/features/transactions/screens/entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/local/local_database.dart';

class EntryScreen extends ConsumerStatefulWidget {
  final String? initialTxnType;
  final String? preselectedPartyId;
  /// If provided, the screen operates in edit mode for this transaction.
  final TransactionsTableData? transaction;

  const EntryScreen({
    super.key,
    this.initialTxnType,
    this.preselectedPartyId,
    this.transaction,
  });

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _txnType = 'purchase';
  String? _commodity;
  String _paymentMode = 'cash';
  PartiesTableData? _selectedParty;
  DateTime _entryDate = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.transaction != null;
  bool get _isGrainTxn => _txnType == 'purchase' || _txnType == 'sale';

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      // Pre-populate fields from existing transaction
      final txn = widget.transaction!;
      _txnType = txn.txnType;
      _commodity = txn.commodity;
      _paymentMode = txn.paymentMode;
      _amountCtrl.text = txn.amount.toStringAsFixed(0);
      _notesCtrl.text = txn.notes ?? '';
      if (txn.quantityKg != null) _quantityCtrl.text = txn.quantityKg.toString();
      if (txn.ratePerKg != null) _rateCtrl.text = txn.ratePerKg!.toStringAsFixed(0);
      _entryDate = DateTime.tryParse(txn.entryDate) ?? DateTime.now();
      _loadPartyForEdit(txn.partyId);
    } else {
      _txnType = widget.initialTxnType ?? 'purchase';
      if (_isGrainTxn) _commodity = 'rice';
      _loadPreselectedParty();
    }
  }

  Future<void> _loadPartyForEdit(String partyId) async {
    final repo = ref.read(appRepositoryProvider);
    final p = await repo.getPartyById(partyId);
    if (mounted) setState(() => _selectedParty = p);
  }

  Future<void> _loadPreselectedParty() async {
    if (widget.preselectedPartyId == null) return;
    final repo = ref.read(appRepositoryProvider);
    final p = await repo.getPartyById(widget.preselectedPartyId!);
    if (mounted) setState(() => _selectedParty = p);
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _rateCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onTxnTypeChanged(String type) {
    setState(() {
      _txnType = type;
      _commodity = _isGrainTxn ? (_commodity ?? 'rice') : null;
    });
  }

  void _recalcAmount() {
    final qty = double.tryParse(_quantityCtrl.text);
    final rate = double.tryParse(_rateCtrl.text);
    if (qty != null && rate != null) {
      _amountCtrl.text = (qty * rate).toStringAsFixed(0);
    }
  }

  Future<void> _pickParty() async {
    final repo = ref.read(appRepositoryProvider);
    final parties = await repo.getParties();
    if (!mounted) return;

    final selected = await showModalBottomSheet<PartiesTableData>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PartyPickerSheet(parties: parties),
    );
    if (selected != null) setState(() => _selectedParty = selected);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _entryDate = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_selectedParty == null) {
      showError(context, 'पार्टी चुनें / Select a party');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      showError(context, 'रकम डालें / Enter amount');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(appRepositoryProvider);

      if (_isEdit) {
        // Update existing transaction
        await repo.updateTransaction(
          id: widget.transaction!.id,
          partyId: _selectedParty!.id,
          txnType: _txnType,
          commodity: _isGrainTxn ? _commodity : null,
          quantityKg: double.tryParse(_quantityCtrl.text),
          ratePerKg: double.tryParse(_rateCtrl.text),
          amount: amount,
          paymentMode: _paymentMode,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          entryDate: _entryDate,
        );
        if (mounted) {
          showSuccess(context, 'एंट्री अपडेट हो गई / Entry updated!');
          Navigator.pop(context, true);
        }
      } else {
        // Create new transaction
        await repo.createTransaction(
          partyId: _selectedParty!.id,
          txnType: _txnType,
          commodity: _isGrainTxn ? _commodity : null,
          quantityKg: double.tryParse(_quantityCtrl.text),
          ratePerKg: double.tryParse(_rateCtrl.text),
          amount: amount,
          paymentMode: _paymentMode,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          entryDate: _entryDate,
        );
        if (mounted) {
          showSuccess(context, 'एंट्री सेव हो गई / Entry saved!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) showError(context, 'An error occurred processing your request');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTransaction() async {
    if (!_isEdit) return;
    final ok = await confirmDialog(
      context,
      title: 'एंट्री हटाएं? / Delete Entry?',
      message: 'क्या आप इस एंट्री को हटाना चाहते हैं?\nAre you sure you want to delete this entry?',
    );
    if (!ok) return;

    setState(() => _saving = true);
    try {
      await ref.read(appRepositoryProvider).deleteTransaction(widget.transaction!.id);
      if (mounted) {
        showSuccess(context, 'एंट्री हटा दी गई / Entry deleted!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showError(context, 'An error occurred processing your request');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'एंट्री बदलें / Edit Entry' : 'नई एंट्री / New Entry'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Delete Entry',
              onPressed: _saving ? null : _deleteTransaction,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [

            // ── TXN TYPE ───────────────────────────────────────────
            _SectionLabel('एंट्री का प्रकार / Entry Type'),
            _TxnTypeSelector(selected: _txnType, onChanged: _onTxnTypeChanged),
            const SizedBox(height: 20),

            // ── PARTY SELECTOR ─────────────────────────────────────
            _SectionLabel('पार्टी / Party *'),
            GestureDetector(
              onTap: _pickParty,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _selectedParty == null ? Colors.red : AppTheme.divider),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedParty != null
                        ? partyTypeIcon(_selectedParty!.partyType)
                        : Icons.person_search_rounded,
                      color: AppTheme.primary, size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedParty?.name ?? 'पार्टी चुनें / Select Party',
                        style: TextStyle(
                          fontSize: 18,
                          color: _selectedParty != null ? AppTheme.textPrimary : AppTheme.textHint,
                          fontWeight: _selectedParty != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── COMMODITY (grain only) ─────────────────────────────
            if (_isGrainTxn) ...[
              _SectionLabel('अनाज / Commodity'),
              _CommoditySelector(
                selected: _commodity,
                onChanged: (c) => setState(() => _commodity = c),
              ),
              const SizedBox(height: 16),
            ],

            // ── QUANTITY + RATE (grain only) ───────────────────────
            if (_isGrainTxn) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('वजन (KG)'),
                        TextFormField(
                          controller: _quantityCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 20),
                          decoration: const InputDecoration(
                            hintText: '0.0',
                            suffixText: 'KG',
                          ),
                          onChanged: (_) => _recalcAmount(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('रेट / Rate'),
                        TextFormField(
                          controller: _rateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 20),
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixText: '₹ ',
                            suffixText: '/KG',
                          ),
                          onChanged: (_) => _recalcAmount(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── AMOUNT ─────────────────────────────────────────────
            _SectionLabel('रकम (₹) / Amount *'),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                filled: true,
                fillColor: AppTheme.primary.withOpacity(0.05),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Amount required' : null,
            ),
            const SizedBox(height: 16),

            // ── PAYMENT MODE ───────────────────────────────────────
            _SectionLabel('भुगतान / Payment Mode'),
            _PaymentModeSelector(
              selected: _paymentMode,
              onChanged: (m) => setState(() => _paymentMode = m),
            ),
            const SizedBox(height: 16),

            // ── DATE ───────────────────────────────────────────────
            _SectionLabel('तारीख / Date'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Text(formatDate(_entryDate), style: const TextStyle(fontSize: 18)),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_rounded, color: AppTheme.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── NOTES ──────────────────────────────────────────────
            _SectionLabel('नोट / Notes'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(hintText: 'कोई जरूरी जानकारी / Any extra info'),
            ),

            // ── TIMESTAMP (edit mode only) ─────────────────────────
            if (_isEdit) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'बनाया गया / Created: ${_formatTxnTimestamp(widget.transaction!.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.update_rounded, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'अपडेट / Updated: ${_formatTxnTimestamp(widget.transaction!.updatedAt)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── SAVE BUTTON ────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: txnColor(_txnType),
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _saving
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(txnIcon(_txnType), color: Colors.white, size: 28),
              label: Text(
                _saving
                  ? 'सेव हो रहा है...'
                  : (_isEdit ? 'अपडेट करें / Update' : 'सेव करें / Save'),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTxnTimestamp(String isoStr) {
    final dt = DateTime.tryParse(isoStr);
    if (dt == null) return isoStr;
    return formatDateTime(dt);
  }
}

// ── TRANSACTION TYPE SELECTOR ────────────────────────────────────────

class _TxnTypeSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _TxnTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = AppConstants.txnTypes;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.8,
      children: types.map((type) {
        final isSelected = type == selected;
        final color = txnColor(type);
        final lines = AppConstants.txnTypeLabels[type]?.split('\n') ?? [type];
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.08),
              border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(txnIcon(type), color: isSelected ? Colors.white : color, size: 22),
                const SizedBox(width: 8),
                Text(lines.join('\n'),
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, height: 1.3,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── COMMODITY SELECTOR ───────────────────────────────────────────────

class _CommoditySelector extends StatelessWidget {
  final String? selected;
  final void Function(String) onChanged;
  const _CommoditySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AppConstants.commodities.map((c) {
        final isSelected = c == selected;
        final emoji = AppConstants.commodityEmoji[c] ?? '';
        final label = AppConstants.commodityLabels[c]?.split('\n') ?? [c];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.divider,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(label.last,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── PAYMENT MODE SELECTOR ────────────────────────────────────────────

class _PaymentModeSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _PaymentModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AppConstants.paymentModes.map((mode) {
        final isSelected = mode == selected;
        final label = AppConstants.paymentModeLabels[mode] ?? mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withOpacity(0.15) : Colors.white,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.divider,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── PARTY PICKER SHEET ───────────────────────────────────────────────

class _PartyPickerSheet extends StatefulWidget {
  final List<PartiesTableData> parties;
  const _PartyPickerSheet({required this.parties});

  @override
  State<_PartyPickerSheet> createState() => _PartyPickerSheetState();
}

class _PartyPickerSheetState extends State<_PartyPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _q.isEmpty
      ? widget.parties
      : widget.parties.where((p) =>
          p.name.toLowerCase().contains(_q.toLowerCase()) ||
          (p.village?.toLowerCase().contains(_q.toLowerCase()) ?? false)
        ).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                autofocus: true,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'पार्टी खोजें / Search party',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  return ListTile(
                    leading: Icon(partyTypeIcon(p.partyType), color: AppTheme.primary),
                    title: Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    subtitle: p.village != null ? Text(p.village!) : null,
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary)),
  );
}
