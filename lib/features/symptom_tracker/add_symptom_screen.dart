import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';
import 'package:sparkle_lite/data/models/symptom_log.dart';
import '../../core/theme/app_theme.dart';
import 'symptom_provider.dart';

class AddSymptomScreen extends StatefulWidget {
  final String? userIdOverride; // for testing only
  final SymptomLog? existingLog;

  const AddSymptomScreen({super.key, this.userIdOverride, this.existingLog});

  @override
  State<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends State<AddSymptomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _periodStatus;
  String? _flowLevel;
  int _painLevel = 0;
  String? _mood;
  final List<String> _selectedSymptoms = [];

  String? _periodStatusError;
  String? _flowLevelError;
  String? _moodError;

  final List<String> _periodStatuses = [
    'no_period',
    'started',
    'ongoing',
    'ended',
  ];

  final List<String> _flowLevels = ['none', 'light', 'medium', 'heavy'];

  final List<String> _moods = [
    'calm',
    'anxious',
    'tired',
    'irritable',
    'happy',
    'sad',
  ];

  final List<String> _symptoms = [
    'cramps',
    'headache',
    'bloating',
    'fatigue',
    'nausea',
    'spotting',
    'irregular bleeding',
    'other',
  ];

  final Map<String, String> _periodStatusLabels = {
    'no_period': 'No Period',
    'started': 'Period Started',
    'ongoing': 'Period Ongoing',
    'ended': 'Period Ended',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _selectedDate = log.date;
      _periodStatus = log.periodStatus;
      _flowLevel = log.flowLevel;
      _painLevel = log.painLevel;
      _mood = log.mood;
      _selectedSymptoms.addAll(log.symptoms);
      _notesController.text = log.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveLog() async {
    setState(() {
      _periodStatusError = _periodStatus == null
          ? 'Please select a period status'
          : null;
      _flowLevelError = _flowLevel == null
          ? 'Please select a flow level'
          : null;
      _moodError = _mood == null ? 'Please select a mood' : null;
    });

    final formValid = _formKey.currentState!.validate();
    final chipsValid =
        _periodStatusError == null &&
        _flowLevelError == null &&
        _moodError == null;

    if (!formValid || !chipsValid) return;

    final userId =
        widget.userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final provider = context.read<SymptomProvider>();
    final isEditing = widget.existingLog != null;

    bool success;

    if (isEditing) {
      // Update existing log
      final updatedLog = SymptomLog(
        id: widget.existingLog!.id,
        userId: userId,
        date: _selectedDate,
        periodStatus: _periodStatus!,
        flowLevel: _flowLevel!,
        painLevel: _painLevel,
        mood: _mood!,
        symptoms: _selectedSymptoms,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.existingLog!.createdAt,
        updatedAt: DateTime.now(),
      );
      success = await provider.updateLog(updatedLog);
    } else {
      // Add new log
      success = await provider.addLog(
        userId: userId,
        date: _selectedDate,
        periodStatus: _periodStatus!,
        flowLevel: _flowLevel!,
        painLevel: _painLevel,
        mood: _mood!,
        symptoms: _selectedSymptoms,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Symptom log updated ✓' : 'Symptom log saved ✓',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Something went wrong'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<SymptomProvider>().status == SymptomStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingLog != null ? 'Edit Symptom Log' : 'Log Symptoms',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Picker
              const _SectionLabel(label: 'Date'),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE3EA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate.isToday
                            ? 'Today'
                            : _selectedDate.isYesterday
                            ? 'Yesterday'
                            : _selectedDate.format('dd MMM yyyy'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Period Status
              const _SectionLabel(label: 'Period Status *'),
              Wrap(
                spacing: 8,
                children: _periodStatuses.map((status) {
                  return ChoiceChip(
                    label: Text(_periodStatusLabels[status] ?? status),
                    selected: _periodStatus == status,
                    onSelected: (_) => setState(() {
                      _periodStatus = status;
                      _periodStatusError = null; // clear error on select
                    }),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              if (_periodStatusError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _periodStatusError!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Flow Level
              const _SectionLabel(label: 'Flow Level *'),
              Wrap(
                spacing: 8,
                children: _flowLevels.map((level) {
                  return ChoiceChip(
                    label: Text(level[0].toUpperCase() + level.substring(1)),
                    selected: _flowLevel == level,
                    onSelected: (_) => setState(() {
                      _flowLevel = level;
                      _flowLevelError = null;
                    }),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              if (_flowLevelError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _flowLevelError!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Pain Level
              _SectionLabel(label: 'Pain Level: $_painLevel / 10'),
              Slider(
                value: _painLevel.toDouble(),
                max: 10,
                divisions: 10,
                activeColor: AppTheme.primary,
                label: _painLevel.toString(),
                onChanged: (val) => setState(() => _painLevel = val.toInt()),
              ),
              const SizedBox(height: 24),

              // Mood
              const _SectionLabel(label: 'Mood *'),
              Wrap(
                spacing: 8,
                children: _moods.map((mood) {
                  return ChoiceChip(
                    label: Text(mood[0].toUpperCase() + mood.substring(1)),
                    selected: _mood == mood,
                    onSelected: (_) => setState(() {
                      _mood = mood;
                      _moodError = null;
                    }),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              if (_moodError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _moodError!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Symptoms
              const _SectionLabel(label: 'Symptoms'),
              Wrap(
                spacing: 8,
                children: _symptoms.map((symptom) {
                  final selected = _selectedSymptoms.contains(symptom);
                  return FilterChip(
                    label: Text(
                      symptom[0].toUpperCase() + symptom.substring(1),
                    ),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        val
                            ? _selectedSymptoms.add(symptom)
                            : _selectedSymptoms.remove(symptom);
                      });
                    },
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Notes
              const _SectionLabel(label: 'Notes (optional)'),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any additional notes...',
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: isLoading ? null : _saveLog,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.existingLog != null ? 'Update Log' : 'Save Log',
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
