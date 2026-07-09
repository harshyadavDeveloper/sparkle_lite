import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/family_member.dart';

class FamilyMemberDetailScreen extends StatefulWidget {
  const FamilyMemberDetailScreen({super.key, required this.member});
  final FamilyMember member;

  @override
  State<FamilyMemberDetailScreen> createState() =>
      _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState extends State<FamilyMemberDetailScreen> {
  late TextEditingController _doctorNameController;
  late TextEditingController _doctorContactController;
  late TextEditingController _notesController;
  late TextEditingController _medicationController;

  late List<String> _conditions;
  late List<String> _medications;
  String? _selectedBloodGroup;
  bool _isSaving = false;

  final List<String> _availableConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'Thyroid',
    'PCOS',
    'Arthritis',
    'Other',
  ];

  final List<String> _bloodGroups = [
    'A+',
    'A−',
    'B+',
    'B−',
    'AB+',
    'AB−',
    'O+',
    'O−',
  ];

  @override
  void initState() {
    super.initState();
    _doctorNameController = TextEditingController(
      text: widget.member.doctorName ?? '',
    );
    _doctorContactController = TextEditingController(
      text: widget.member.doctorContact ?? '',
    );
    _notesController = TextEditingController(text: widget.member.notes ?? '');
    _medicationController = TextEditingController();
    _conditions = List.from(widget.member.conditions);
    _medications = List.from(widget.member.medications);
    _selectedBloodGroup = widget.member.bloodGroup;
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _doctorContactController.dispose();
    _notesController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final updated = FamilyMember(
      id: widget.member.id,
      userId: userId,
      name: widget.member.name,
      relationship: widget.member.relationship,
      ageRange: widget.member.ageRange,
      conditions: _conditions,
      medications: _medications,
      doctorName: _doctorNameController.text.trim().isEmpty
          ? null
          : _doctorNameController.text.trim(),
      doctorContact: _doctorContactController.text.trim().isEmpty
          ? null
          : _doctorContactController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.member.createdAt,
    );

    try {
      await FirebaseFirestore.instance
          .collection('familyMembers')
          .doc(userId)
          .collection('members')
          .doc(widget.member.id)
          .update(updated.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health notes saved ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addMedication() {
    final med = _medicationController.text.trim();
    if (med.isEmpty) return;
    setState(() {
      _medications.add(med);
      _medicationController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.name),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEC407A).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEC407A).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(
                      0xFFEC407A,
                    ).withValues(alpha: 0.1),
                    child: Text(
                      widget.member.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFEC407A),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.member.relationship} · '
                        '${widget.member.ageRange}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 13, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These notes are stored separately from your '
                      'personal health data and are never mixed.',
                      style: TextStyle(fontSize: 11, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'Basic Health Info'),
            DropdownButtonFormField<String>(
              initialValue: _selectedBloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group'),
              items: [
                const DropdownMenuItem(child: Text('Not specified')),
                ..._bloodGroups.map(
                  (g) => DropdownMenuItem(value: g, child: Text(g)),
                ),
              ],
              onChanged: (v) => setState(() => _selectedBloodGroup = v),
            ),
            const SizedBox(height: 20),

            const _SectionHeader(title: 'Known Conditions'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableConditions.map((condition) {
                final selected = _conditions.contains(condition);
                return FilterChip(
                  label: Text(condition),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      val
                          ? _conditions.add(condition)
                          : _conditions.remove(condition);
                    });
                  },
                  selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const _SectionHeader(title: 'Current Medications'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _medicationController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Metformin 500mg',
                    ),
                    onSubmitted: (_) => _addMedication(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addMedication,
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
            if (_medications.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _medications.map((med) {
                  return Chip(
                    label: Text(med, style: const TextStyle(fontSize: 12)),
                    onDeleted: () => setState(() => _medications.remove(med)),
                    deleteIconColor: AppTheme.error,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),

            const _SectionHeader(title: 'Doctor / Clinic'),
            TextFormField(
              controller: _doctorNameController,
              decoration: const InputDecoration(
                labelText: 'Doctor or clinic name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doctorContactController,
              decoration: const InputDecoration(
                labelText: 'Contact number (optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }
                if (value.length != 10) {
                  return 'Enter a valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            const _SectionHeader(title: 'Additional Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Allergies, dietary restrictions, '
                    'recent visits, anything relevant...',
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Health Notes'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
