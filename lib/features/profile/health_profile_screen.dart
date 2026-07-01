import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_profile.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedAgeRange = '18–25';
  String _selectedLifeStage = 'General wellness';
  String _selectedCycleStatus = 'Regular';
  final List<String> _selectedConditions = [];
  bool _isLoading = false;

  final List<String> _ageRanges = ['18–25', '26–35', '36–45', '46–55', '55+'];
  final List<String> _lifeStages = [
    'General wellness',
    'Period tracking',
    'Fertility planning',
    'Pregnancy',
    'Postpartum',
    'Menopause / perimenopause',
  ];
  final List<String> _cycleStatuses = [
    'Regular',
    'Irregular',
    'No period',
    'Unsure',
  ];
  final List<String> _conditions = [
    'PCOS',
    'Thyroid',
    'Diabetes',
    'Endometriosis',
    'Other',
  ];

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();
      final profile = UserProfile(
        userId: user.uid,
        displayName: _nameController.text.trim(),
        ageRange: _selectedAgeRange,
        lifeStage: _selectedLifeStage,
        menstrualCycleStatus: _selectedCycleStatus,
        knownConditions: _selectedConditions,
        createdAt: now,
        updatedAt: now,
      );

      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .set(profile.toMap());

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    } catch (e, st) {
      if (mounted) {
        debugPrint('PROFILE SAVE ERROR: $e');
        debugPrintStack(stackTrace: st);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Health Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us a little about yourself',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sensitive fields are optional. You can update this anytime.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name or nickname',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 20),

              // Age Range
              DropdownButtonFormField<String>(
                value: _selectedAgeRange,
                decoration: const InputDecoration(labelText: 'Age range'),
                items: _ageRanges
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAgeRange = v!),
              ),
              const SizedBox(height: 20),

              // Life Stage
              DropdownButtonFormField<String>(
                value: _selectedLifeStage,
                decoration: const InputDecoration(labelText: 'Life stage'),
                items: _lifeStages
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedLifeStage = v!),
              ),
              const SizedBox(height: 20),

              // Cycle Status
              DropdownButtonFormField<String>(
                value: _selectedCycleStatus,
                decoration: const InputDecoration(
                  labelText: 'Menstrual cycle status',
                ),
                items: _cycleStatuses
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCycleStatus = v!),
              ),
              const SizedBox(height: 20),

              // Known Conditions (optional)
              Text(
                'Known conditions (optional)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _conditions.map((condition) {
                  final selected = _selectedConditions.contains(condition);
                  return FilterChip(
                    label: Text(condition),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        val
                            ? _selectedConditions.add(condition)
                            : _selectedConditions.remove(condition);
                      });
                    },
                    selectedColor: AppTheme.primary.withOpacity(0.2),
                    checkmarkColor: AppTheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
