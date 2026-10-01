// lib/features/voice/screens/voice_entry_screen.dart
//
// Full voice entry screen:
//   1. User taps mic → speaks in Hindi/English
//   2. Live transcript shown while speaking
//   3. Parser extracts transaction fields
//   4. User sees pre-filled form to confirm/correct
//   5. Save goes offline-first to local DB + sync queue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/voice_service.dart';
import '../../../services/voice_parser.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/local/local_database.dart';
import '../widgets/voice_waveform.dart';
import '../../transactions/screens/entry_screen.dart';

class VoiceEntryScreen extends ConsumerStatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  ConsumerState<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends ConsumerState<VoiceEntryScreen>
    with SingleTickerProviderStateMixin {
  late final VoiceService _voice;
  late final AnimationController _pulseCtrl;

  ParsedVoiceEntry? _parsed;
  bool _showConfirmation = false;
  String _liveTranscript = '';

  // Editable fields (after parsing)
  PartiesTableData? _selectedParty;
  String? _txnType;
  String? _commodity;
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _bagCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _voice = VoiceService();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _voice.addListener(_onVoiceStateChange);
    _voice.initialize();
  }

  void _onVoiceStateChange() {
    if (!mounted) return;
    setState(() => _liveTranscript = _voice.transcript);

    if (_voice.state == VoiceState.done && _voice.transcript.isNotEmpty) {
      _handleTranscript(_voice.transcript);
    }
    if (_voice.state == VoiceState.error) {
      showError(context, _voice.errorMessage ?? 'Voice error');
    }
  }

  void _handleTranscript(String text) {
    final parsed = VoiceParser.parse(text);
    setState(() {
      _parsed = parsed;
      _showConfirmation = true;
      // Pre-fill editable fields
      _txnType = parsed.txnType ?? 'purchase';
      _commodity = parsed.commodity;
      if (parsed.quantityKg != null) {
        _qtyCtrl.text = parsed.quantityKg!.toStringAsFixed(1);
      }
      if (parsed.ratePerKg != null) {
        _rateCtrl.text = parsed.ratePerKg!.toStringAsFixed(0);
      }
      if (parsed.amount != null) {
        _amountCtrl.text = parsed.amount!.toStringAsFixed(0);
      }
      if (parsed.bagCount != null) {
        _bagCtrl.text = parsed.bagCount.toString();
        // If the primary type is a bag type, also prefill qtyCtrl for backward compatibility in the form logic
        if (_txnType == 'bag_given' || _txnType == 'bag_returned') {
          _qtyCtrl.text = parsed.bagCount.toString();
        }
      }
    });
    // Try to find matching party by name
    if (parsed.partyName != null) _findParty(parsed.partyName!);
  }

  Future<void> _findParty(String name) async {
    final repo = ref.read(appRepositoryProvider);
    final parties = await repo.getParties(search: name);
    if (parties.isNotEmpty && mounted) {
      setState(() => _selectedParty = parties.first);
    } else if (mounted) {
      // Auto-create party from voice-parsed name
      try {
        final newId = await repo.createParty(
          name: name,
          partyType: 'farmer',
        );
        final created = await repo.getPartyById(newId);
        if (created != null && mounted) {
          setState(() => _selectedParty = created);
        }
      } catch (e) {
        debugPrint('[Voice] Auto-create party failed: $e');
      }
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _showConfirmation = false;
      _parsed = null;
      _liveTranscript = '';
    });
    await _voice.startListening(
      locale: 'hi_IN',
      onResult: (t) => debugPrint('[Voice] Final: $t'),
      onError: (e) => debugPrint('[Voice] Error: $e'),
    );
  }

  Future<void> _stopListening() => _voice.stop();

  // ── CONFIRM + SAVE ─────────────────────────────────────────────
  Future<void> _save() async {
    if (_saving) return;
    // Auto-create party from voice name if not yet selected
    if (_selectedParty == null && _parsed?.partyName != null) {
      try {
        final repo = ref.read(appRepositoryProvider);
        final newId = await repo.createParty(
          name: _parsed!.partyName!,
          partyType: 'farmer',
        );
        final created = await repo.getPartyById(newId);
        if (created != null && mounted) {
          setState(() => _selectedParty = created);
        }
      } catch (e) {
        if (mounted) {
          showError(
              context, 'पार्टी बनाने में दिक्कत / Could not create party');
        }
        return;
      }
    }
    if (!mounted) return;
    if (_selectedParty == null) {
      showError(context, 'पार्टी चुनें / Select a party first');
      return;
    }

    // For bag transactions, skip amount validation
    final isBagTxn = _txnType == 'bag_given' || _txnType == 'bag_returned';
    if (!isBagTxn) {
      final amount = double.tryParse(_amountCtrl.text);
      if (amount == null || amount <= 0) {
        showError(context, 'रकम सही नहीं / Invalid amount');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(appRepositoryProvider);

      // Bag movement
      if (_txnType == 'bag_given' || _txnType == 'bag_returned') {
        final qty = int.tryParse(_qtyCtrl.text) ?? _parsed?.bagCount ?? 1;
        await repo.createBagMovement(
          partyId: _selectedParty!.id,
          movement: _txnType == 'bag_given' ? 'given' : 'returned',
          quantity: qty,
          notes: 'Voice: ${_parsed?.rawText}',
        );
      } else {
        // Money transaction
        final amount = double.tryParse(_amountCtrl.text) ?? 0;
        await repo.createTransaction(
          partyId: _selectedParty!.id,
          txnType: _txnType ?? 'purchase',
          commodity: _commodity,
          quantityKg: double.tryParse(_qtyCtrl.text),
          ratePerKg: double.tryParse(_rateCtrl.text),
          amount: amount,
          voiceRaw: _parsed?.rawText,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

        // Also create a bag movement if a bag count was provided!
        final bagCount = int.tryParse(_bagCtrl.text) ?? 0;
        if (bagCount > 0) {
          final bagDirection =
              (_txnType == 'cash_out' || _txnType == 'purchase')
                  ? 'given'
                  : 'returned';
          await repo.createBagMovement(
            partyId: _selectedParty!.id,
            movement: bagDirection,
            quantity: bagCount,
            notes: 'Voice: ${_parsed?.rawText}',
          );
        }
      }

      if (mounted) {
        showSuccess(context, '✅ एंट्री सेव हो गई! / Entry saved!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── OPEN MANUAL FORM (prefilled) ───────────────────────────────
  void _openManualForm() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => EntryScreen(
                initialTxnType: _txnType,
                preselectedPartyId: _selectedParty?.id,
              )),
    );
  }

  @override
  void dispose() {
    _voice.removeListener(_onVoiceStateChange);
    _voice.dispose();
    _pulseCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _amountCtrl.dispose();
    _bagCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('आवाज़ से एंट्री / Voice Entry',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          TextButton.icon(
            onPressed: _openManualForm,
            icon:
                const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
            label:
                const Text('Manual', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: _showConfirmation && _parsed != null
          ? _ConfirmationPanel(
              parsed: _parsed!,
              selectedParty: _selectedParty,
              txnType: _txnType,
              commodity: _commodity,
              qtyCtrl: _qtyCtrl,
              rateCtrl: _rateCtrl,
              amountCtrl: _amountCtrl,
              bagCtrl: _bagCtrl,
              notesCtrl: _notesCtrl,
              saving: _saving,
              onPartyTap: _pickParty,
              onTxnTypeChanged: (t) => setState(() => _txnType = t),
              onCommodityChanged: (c) => setState(() => _commodity = c),
              onSave: _save,
              onRetry: _startListening,
            )
          : _ListeningPanel(
              voice: _voice,
              liveTranscript: _liveTranscript,
              pulseCtrl: _pulseCtrl,
              onStart: _startListening,
              onStop: _stopListening,
            ),
    );
  }

  Future<void> _pickParty() async {
    final repo = ref.read(appRepositoryProvider);
    final parties = await repo.getParties();
    if (!mounted) return;
    final picked = await showModalBottomSheet<PartiesTableData>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PartyPickerSheet(parties: parties),
    );
    if (picked != null) {
      if (picked.id == '__NEW__') {
        // Create the party in DB
        try {
          final newId = await repo.createParty(
            name: picked.name,
            partyType: 'farmer',
          );
          final created = await repo.getPartyById(newId);
          if (created != null && mounted) {
            setState(() => _selectedParty = created);
          }
        } catch (e) {
          if (mounted) {
            showError(
                context, 'पार्टी बनाने में दिक्कत / Error creating party');
          }
        }
      } else {
        setState(() => _selectedParty = picked);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// LISTENING PANEL — dark mic UI
// ─────────────────────────────────────────────────────────────────────

class _ListeningPanel extends StatelessWidget {
  final VoiceService voice;
  final String liveTranscript;
  final AnimationController pulseCtrl;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _ListeningPanel({
    required this.voice,
    required this.liveTranscript,
    required this.pulseCtrl,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = voice.isListening;

    return Column(
      children: [
        const Spacer(),

        // Example prompts
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              _ExamplePrompt('🌾 "राम लाल से 200 किलो चावल 22 रुपये खरीदा"'),
              SizedBox(height: 8),
              _ExamplePrompt('💰 "Sharma ko 5000 rupees diya"'),
              SizedBox(height: 8),
              _ExamplePrompt('📦 "Suresh ko 3 bori di"'),
            ],
          ),
        ),

        const Spacer(),

        // Live transcript
        if (liveTranscript.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              liveTranscript,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 32),

        // Waveform
        SizedBox(
          height: 60,
          child: isListening
              ? VoiceWaveform(animation: pulseCtrl)
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),

        // Mic button
        GestureDetector(
          onTap: isListening ? onStop : onStart,
          child: AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, child) {
              final scale = isListening ? 1.0 + pulseCtrl.value * 0.12 : 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? Colors.red : AppTheme.primaryLight,
                boxShadow: [
                  BoxShadow(
                    color: (isListening ? Colors.red : AppTheme.primaryLight)
                        .withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          isListening
              ? 'सुन रहे हैं... / Listening...'
              : 'माइक दबाएं / Tap to speak',
          style: TextStyle(
            color: isListening ? Colors.red[300] : Colors.white60,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        if (voice.state == VoiceState.error)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              voice.errorMessage ?? '',
              style: TextStyle(color: Colors.red[300], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),

        const Spacer(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// CONFIRMATION PANEL — show parsed data for user to verify + edit
// ─────────────────────────────────────────────────────────────────────

class _ConfirmationPanel extends StatelessWidget {
  final ParsedVoiceEntry parsed;
  final PartiesTableData? selectedParty;
  final String? txnType;
  final String? commodity;
  final TextEditingController qtyCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController bagCtrl;
  final TextEditingController notesCtrl;
  final bool saving;
  final VoidCallback onPartyTap;
  final void Function(String) onTxnTypeChanged;
  final void Function(String?) onCommodityChanged;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  const _ConfirmationPanel({
    required this.parsed,
    required this.selectedParty,
    required this.txnType,
    required this.commodity,
    required this.qtyCtrl,
    required this.rateCtrl,
    required this.amountCtrl,
    required this.bagCtrl,
    required this.notesCtrl,
    required this.saving,
    required this.onPartyTap,
    required this.onTxnTypeChanged,
    required this.onCommodityChanged,
    required this.onSave,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Voice transcript + confidence ─────────────────────────
        ParsedResultCard(parsed: parsed),

        // ── Editable confirmation form ────────────────────────────
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              children: [
                const Text('सही करें / Confirm & Edit',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 16),

                // Party
                _ConfirmRow(
                  label: 'पार्टी / Party',
                  child: GestureDetector(
                    onTap: onPartyTap,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedParty != null
                            ? AppTheme.primary.withOpacity(0.08)
                            : Colors.red[50],
                        border: Border.all(
                          color: selectedParty != null
                              ? AppTheme.primary
                              : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded,
                              color: selectedParty != null
                                  ? AppTheme.primary
                                  : Colors.red,
                              size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                            selectedParty?.name ??
                                (parsed.partyName ?? 'पार्टी चुनें ↓'),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: selectedParty != null
                                  ? AppTheme.textPrimary
                                  : Colors.red,
                            ),
                          )),
                          const Icon(Icons.edit_rounded,
                              size: 16, color: AppTheme.textHint),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Txn type — include bag types alongside money types
                _ConfirmRow(
                  label: 'प्रकार / Type',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...AppConstants.txnTypes,
                        'bag_given',
                        'bag_returned'
                      ].map((t) {
                        final isSelected = t == txnType;
                        final color = t == 'bag_given' || t == 'bag_returned'
                            ? AppTheme.bagColor
                            : txnColor(t);
                        final String label;
                        if (t == 'bag_given') {
                          label = 'बोरी दी / Bag Given';
                        } else if (t == 'bag_returned') {
                          label = 'बोरी वापस / Bag Return';
                        } else {
                          label =
                              AppConstants.txnTypeLabels[t]?.split('\n').last ??
                                  t;
                        }
                        return GestureDetector(
                          onTap: () => onTxnTypeChanged(t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? color : color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color, width: isSelected ? 2 : 1),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // For bag transactions: show bag quantity instead of amount
                if (txnType == 'bag_given' || txnType == 'bag_returned') ...[
                  _ConfirmRow(
                    label: 'बोरी की संख्या / Bag Count',
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.bagColor),
                      decoration: const InputDecoration(
                        hintText: '0',
                        suffixText: 'बोरी / Bags',
                        suffixStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  // Amount (for money transactions)
                  _ConfirmRow(
                    label: 'रकम / Amount ₹',
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ConfirmRow(
                    label: 'बोरी (वैकल्पिक) / Bags (Optional)',
                    child: TextField(
                      controller: bagCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.bagColor),
                      decoration: const InputDecoration(
                        hintText: '0',
                        suffixText: 'बोरी / Bags',
                        suffixStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Qty + Rate (grain only)
                if (txnType == 'purchase' || txnType == 'sale') ...[
                  Row(
                    children: [
                      Expanded(
                          child: _ConfirmRow(
                        label: 'वजन / KG',
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 18),
                          decoration: const InputDecoration(suffixText: 'KG'),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _ConfirmRow(
                        label: 'रेट / Rate',
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 18),
                          decoration: const InputDecoration(prefixText: '₹ '),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Notes
                _ConfirmRow(
                  label: 'नोट / Notes',
                  child: TextField(
                    controller: notesCtrl,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(hintText: 'Optional'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Action buttons ────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              // Retry voice
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('फिर बोलें\nRetry',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 1.2)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Save
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_rounded,
                          color: Colors.white, size: 24),
                  label: Text(
                    saving ? 'सेव हो रहा है...' : 'सेव करें / Save',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _ConfirmRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          child,
        ],
      );
}

class _ExamplePrompt extends StatelessWidget {
  final String text;
  const _ExamplePrompt(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.3)),
      );
}

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
        : widget.parties
            .where((p) => p.name.toLowerCase().contains(_q.toLowerCase()))
            .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              autofocus: true,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'पार्टी खोजें / Search or type new name',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          // Show "Create New" option when search text doesn't match any party
          if (_q.trim().isNotEmpty && filtered.isEmpty)
            ListTile(
              leading:
                  const Icon(Icons.person_add_rounded, color: AppTheme.primary),
              title: Text('"$_q" नई पार्टी बनाएं / Create "$_q"',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
              subtitle: const Text('New party will be added as Farmer'),
              onTap: () {
                // Return null — the caller will handle creating via the name
                Navigator.pop(
                    context,
                    PartiesTableData(
                      id: '__NEW__',
                      name: _q.trim(),
                      partyType: 'farmer',
                      isActive: true,
                      createdAt: DateTime.now().toIso8601String(),
                      updatedAt: DateTime.now().toIso8601String(),
                    ));
              },
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) => ListTile(
                leading: Icon(partyTypeIcon(filtered[i].partyType),
                    color: AppTheme.primary),
                title: Text(filtered[i].name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                subtitle: filtered[i].village != null
                    ? Text(filtered[i].village!)
                    : null,
                onTap: () => Navigator.pop(context, filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
