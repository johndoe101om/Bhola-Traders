// lib/features/parties/screens/add_party_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/local_database.dart';
import '../../../data/repositories/providers.dart';

class AddPartyScreen extends ConsumerStatefulWidget {
  final String? initialType;
  final PartiesTableData? party;
  
  const AddPartyScreen({super.key, this.initialType, this.party});

  @override
  ConsumerState<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends ConsumerState<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _partyType = 'farmer';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.party != null) {
      _partyType = widget.party!.partyType;
      _nameCtrl.text = widget.party!.name;
      _phoneCtrl.text = widget.party!.phone ?? '';
      _villageCtrl.text = widget.party!.village ?? '';
      _notesCtrl.text = widget.party!.notes ?? '';
    } else {
      _partyType = widget.initialType ?? 'farmer';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _villageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(appRepositoryProvider);
      
      if (widget.party == null) {
        await repo.createParty(
          name: _nameCtrl.text.trim(),
          partyType: _partyType,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          village: _villageCtrl.text.trim().isEmpty ? null : _villageCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      } else {
        await repo.updateParty(
          widget.party!.id,
          name: _nameCtrl.text.trim(),
          partyType: _partyType,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          village: _villageCtrl.text.trim().isEmpty ? null : _villageCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }

      if (mounted) {
        showSuccess(context, widget.party == null ? 'पार्टी बन गई / Party added!' : 'पार्टी अपडेट हो गई / Party updated!');
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
    final isEdit = widget.party != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'पार्टी एडिट करें / Edit Party' : 'नई पार्टी / Add Party')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Party type selector
            const Text('पार्टी का प्रकार / Party Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            _PartyTypeSelector(
              selected: _partyType,
              onChanged: (t) => setState(() => _partyType = t),
            ),
            const SizedBox(height: 20),

            // Name
            _FieldLabel('नाम / Name *'),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'जैसे: राम लाल यादव',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            _FieldLabel('मोबाइल / Phone'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: '9876543210',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Village
            _FieldLabel('गाँव / Village'),
            TextFormField(
              controller: _villageCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'जैसे: सीतापुर',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            _FieldLabel('नोट / Notes'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'कोई जरूरी जानकारी...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Icon(Icons.notes_rounded),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 60),
              ),
              icon: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_rounded, color: Colors.white, size: 26),
              label: Text(
                _saving ? 'सेव हो रहा है...' : 'सेव करें / Save',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyTypeSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _PartyTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AppConstants.partyTypes.map((type) {
        final isSelected = type == selected;
        final label = AppConstants.partyTypeLabels[type]?.split('\n') ?? [type];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                  Icon(partyTypeIcon(type),
                    color: isSelected ? Colors.white : AppTheme.textSecondary, size: 28),
                  const SizedBox(height: 4),
                  Text(label.first,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary)),
    );
  }
}
