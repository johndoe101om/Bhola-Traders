// lib/features/employees/screens/add_employee_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/local/local_database.dart';
import '../../../data/models/employee_models.dart';
import '../../../data/repositories/providers.dart';
import '../widgets/voice_reason_field.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  final Employee? employee;
  final EmployeesTableData? employeeTableData;

  const AddEmployeeScreen({super.key, this.employee, this.employeeTableData});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _wageCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _teamCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedType = 'labour';
  DateTime _joiningDate = DateTime.now();
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.employeeTableData != null) {
      final e = widget.employeeTableData!;
      _nameCtrl.text = e.name;
      _phoneCtrl.text = e.phone ?? '';
      _emailCtrl.text = e.email ?? '';
      _wageCtrl.text =
          e.dailyWageRate > 0 ? e.dailyWageRate.toStringAsFixed(0) : '';
      _aadhaarCtrl.text = e.aadhaarNumber ?? '';
      _addressCtrl.text = e.address ?? '';
      _teamCtrl.text = e.teamGroup ?? '';
      _emergencyCtrl.text = e.emergencyContact ?? '';
      _notesCtrl.text = e.notes ?? '';
      _selectedType = e.employeeType;
      _joiningDate = DateTime.tryParse(e.joiningDate) ?? DateTime.now();
      _isActive = e.isActive;
    } else if (widget.employee != null) {
      final e = widget.employee!;
      _nameCtrl.text = e.name;
      _phoneCtrl.text = e.phone ?? '';
      _emailCtrl.text = e.email ?? '';
      _wageCtrl.text =
          e.dailyWageRate > 0 ? e.dailyWageRate.toStringAsFixed(0) : '';
      _aadhaarCtrl.text = e.aadhaarNumber ?? '';
      _addressCtrl.text = e.address ?? '';
      _teamCtrl.text = e.teamGroup ?? '';
      _emergencyCtrl.text = e.emergencyContact ?? '';
      _notesCtrl.text = e.notes ?? '';
      _selectedType = e.employeeType;
      _joiningDate = e.joiningDate;
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _wageCtrl.dispose();
    _aadhaarCtrl.dispose();
    _addressCtrl.dispose();
    _teamCtrl.dispose();
    _emergencyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final wage = double.tryParse(_wageCtrl.text.trim()) ?? 0.0;
      final repo = ref.read(appRepositoryProvider);
      final id = widget.employeeTableData?.id ?? widget.employee?.id;

      if (id != null) {
        await repo.updateEmployee(
          id,
          name: _nameCtrl.text.trim(),
          dailyWageRate: wage,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          aadhaarNumber: _aadhaarCtrl.text.trim().isEmpty
              ? null
              : _aadhaarCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          joiningDate: _joiningDate,
          employeeType: _selectedType,
          teamGroup:
              _teamCtrl.text.trim().isEmpty ? null : _teamCtrl.text.trim(),
          emergencyContact: _emergencyCtrl.text.trim().isEmpty
              ? null
              : _emergencyCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          isActive: _isActive,
        );
        if (mounted) {
          showSuccess(context, 'कर्मचारी अपडेट हो गया / Employee updated');
          Navigator.pop(context);
        }
      } else {
        await repo.createEmployee(
          name: _nameCtrl.text.trim(),
          dailyWageRate: wage,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          aadhaarNumber: _aadhaarCtrl.text.trim().isEmpty
              ? null
              : _aadhaarCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          joiningDate: _joiningDate,
          employeeType: _selectedType,
          teamGroup:
              _teamCtrl.text.trim().isEmpty ? null : _teamCtrl.text.trim(),
          emergencyContact: _emergencyCtrl.text.trim().isEmpty
              ? null
              : _emergencyCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
        if (mounted) {
          showSuccess(context, 'नया कर्मचारी जुड़ गया / Employee added');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) showError(context, 'त्रुटि / Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employeeTableData != null || widget.employee != null;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEdit ? 'एडिट करें / Edit Staff' : 'नया स्टाफ / Add Staff'),
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
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'नाम / Full Name *',
                hintText: 'e.g. Ramesh Kumar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'नाम आवश्यक है / Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            const Text('स्टाफ टाइप / Employee Type *',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.employeeTypes.map((t) {
                final selected = t == _selectedType;
                return ChoiceChip(
                  label: Text(AppConstants.employeeTypeLabels[t] ?? t),
                  selected: selected,
                  onSelected: (b) => setState(() => _selectedType = t),
                  selectedColor: AppTheme.primary.withOpacity(0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'मोबाइल / Phone',
                      hintText: '10-digit number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _wageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'दैनिक वेतन (₹) / Daily Rate *',
                      hintText: 'e.g. 400',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'वेतन आवश्यक है' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'ईमेल / Email (वैकल्पिक)',
                hintText: 'notification@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _teamCtrl,
                    decoration: const InputDecoration(
                      labelText: 'टीम/ग्रुप / Team or Group',
                      hintText: 'e.g. Warehouse, Field',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _aadhaarCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'आधार नं. / Aadhaar No.',
                      hintText: '12-digit',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300)),
              leading: const Icon(Icons.calendar_today_rounded,
                  color: AppTheme.primary),
              title: const Text('जॉइनिंग तारीख / Joining Date'),
              subtitle: Text(
                  '${_joiningDate.day}/${_joiningDate.month}/${_joiningDate.year}'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _joiningDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _joiningDate = picked);
              },
            ),
            const SizedBox(height: 16),
            VoiceReasonField(
              controller: _addressCtrl,
              labelText: 'पता / Address (माइक से बोलें)',
              hintText: 'गाँव / शहर का पता',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            VoiceReasonField(
              controller: _notesCtrl,
              labelText: 'टिप्पणी / Notes (माइक से बोलें)',
              hintText: 'कोई विशेष टिप्पणी या जानकारी',
              maxLines: 2,
            ),
            const SizedBox(height: 24),
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
                  : Text(
                      isEdit
                          ? 'अपडेट करें / Save Changes'
                          : 'स्टाफ जोड़ें / Register Employee',
                      style: const TextStyle(
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
