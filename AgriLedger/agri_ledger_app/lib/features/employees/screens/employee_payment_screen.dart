// lib/features/employees/screens/employee_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/voice_text_field.dart';
import '../../../data/repositories/providers.dart';
import '../widgets/voice_reason_field.dart';

class EmployeePaymentScreen extends ConsumerStatefulWidget {
  final String? initialEmployeeId;
  final double? initialAmount;
  final String? initialType;

  const EmployeePaymentScreen({
    super.key,
    this.initialEmployeeId,
    this.initialAmount,
    this.initialType,
  });

  @override
  ConsumerState<EmployeePaymentScreen> createState() =>
      _EmployeePaymentScreenState();
}

class _EmployeePaymentScreenState extends ConsumerState<EmployeePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  String? _selectedEmployeeId;
  DateTime _paymentDate = DateTime.now();
  String _selectedMode = 'cash';
  String _selectedType = 'wage';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.initialEmployeeId;
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountCtrl.text = widget.initialAmount!.toStringAsFixed(0);
    }
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedEmployeeId == null) {
      showError(context, 'कृपया कर्मचारी चुनें / Please select an employee');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      showError(context, 'वैध रकम दर्ज करें / Enter a valid amount');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(appRepositoryProvider);
      await repo.recordEmployeePayment(
        employeeId: _selectedEmployeeId!,
        paymentDate: _paymentDate,
        amount: amount,
        paymentMode: _selectedMode,
        paymentType: _selectedType,
        referenceNumber:
            _refCtrl.text.trim().isNotEmpty ? _refCtrl.text.trim() : null,
        notes:
            _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        voiceRaw:
            _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );

      if (mounted) {
        showSuccess(context, 'भुगतान दर्ज हो गया / Payment recorded');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, 'त्रुटि / Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider(''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('भुगतान दर्ज करें / Record Payment'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _save,
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Employee Selector ──
            const Text('कर्मचारी चुनें / Select Employee *',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            employeesAsync.when(
              data: (employees) {
                if (employees.isEmpty) {
                  return const Text(
                      'कोई सक्रिय कर्मचारी नहीं है / No active employees');
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEmployeeId,
                      isExpanded: true,
                      hint: const Text('कर्मचारी चुनें...'),
                      items: employees
                          .map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          AppTheme.primary.withOpacity(0.1),
                                      child: Text(
                                        e.name.isNotEmpty
                                            ? e.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(e.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600))),
                                    Text(
                                        '₹${e.dailyWageRate.toStringAsFixed(0)}/दिन',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedEmployeeId = val);
                      },
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // ── Date Picker ──
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300)),
              leading: const Icon(Icons.calendar_today_rounded,
                  color: AppTheme.primary),
              title: const Text('भुगतान तारीख / Payment Date'),
              subtitle: Text(
                  '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (d != null) setState(() => _paymentDate = d);
              },
            ),
            const SizedBox(height: 16),

            // ── Amount Input ──
            VoiceTextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              isNumeric: true,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              labelText: 'रकम (₹) / Amount *',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 28),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'रकम आवश्यक है / Amount is required';
                }
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'वैध संख्या दर्ज करें';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Payment Mode ──
            const Text('पेमेंट माध्यम / Payment Mode *',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _PaymentModeCard(
                  label: 'नकद\nCash',
                  icon: Icons.money_rounded,
                  selected: _selectedMode == 'cash',
                  onTap: () => setState(() => _selectedMode = 'cash'),
                ),
                const SizedBox(width: 8),
                _PaymentModeCard(
                  label: 'UPI / ऑनलाइन\nOnline',
                  icon: Icons.phone_android_rounded,
                  selected: _selectedMode == 'upi',
                  onTap: () => setState(() => _selectedMode = 'upi'),
                ),
                const SizedBox(width: 8),
                _PaymentModeCard(
                  label: 'बैंक ट्रांसफर\nBank',
                  icon: Icons.account_balance_rounded,
                  selected: _selectedMode == 'bank_transfer',
                  onTap: () => setState(() => _selectedMode = 'bank_transfer'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Payment Type ──
            const Text('पेमेंट प्रकार / Payment Type *',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.employeePaymentTypes.map((t) {
                final selected = t == _selectedType;
                return ChoiceChip(
                  label: Text(AppConstants.employeePaymentTypeLabels[t] ?? t),
                  selected: selected,
                  onSelected: (b) => setState(() => _selectedType = t),
                  selectedColor: AppTheme.primary.withOpacity(0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── UPI / Bank Reference No ──
            if (_selectedMode != 'cash') ...[
              VoiceTextFormField(
                controller: _refCtrl,
                labelText: 'यूटीआर / संदर्भ संख्या / Reference / UTR No.',
                hintText: 'e.g. 12-digit UPI ref',
                prefixIcon: const Icon(Icons.tag_rounded),
              ),
              const SizedBox(height: 16),
            ],

            // ── Notes with Voice Input ──
            VoiceReasonField(
              controller: _notesCtrl,
              labelText: 'विवरण / Memo or Notes (माइक से बोलें)',
              hintText: 'e.g. हफ्ते की मजदूरी, त्योहार एडवांस...',
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // ── Submit Button ──
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'भुगतान दर्ज करें / Record Payment',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentModeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentModeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withOpacity(0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primary : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
