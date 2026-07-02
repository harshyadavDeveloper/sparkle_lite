import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../records/health_record_provider.dart';
import '../symptom_tracker/symptom_provider.dart';
import 'doctor_summary_provider.dart';
import 'doctor_summary_result_screen.dart';

class DoctorSummaryScreen extends StatefulWidget {
  const DoctorSummaryScreen({super.key});

  @override
  State<DoctorSummaryScreen> createState() => _DoctorSummaryScreenState();
}

class _DoctorSummaryScreenState extends State<DoctorSummaryScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    // We'll need profile — for now use a minimal fallback
    // Profile loading will be wired in dashboard
    final symptomProvider = context.read<SymptomProvider>();
    final recordProvider = context.read<HealthRecordProvider>();
    final summaryProvider = context.read<DoctorSummaryProvider>();

    if (symptomProvider.logs.isEmpty && recordProvider.allRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some symptom logs or health records first'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Profile will be loaded from Firestore in dashboard integration
    // For now generating with available data
    await summaryProvider.generateSummary(
      profile: _getFallbackProfile(),
      recentLogs: symptomProvider.logs,
      records: recordProvider.allRecords,
      userNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (mounted && summaryProvider.status == DoctorSummaryStatus.generated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorSummaryResultScreen()),
      );
    }
  }

  // Fallback until profile provider is wired
  _getFallbackProfile() {
    // This will be replaced when we wire the profile provider
    // in the dashboard on Day 6
    return _MinimalProfile();
  }

  @override
  Widget build(BuildContext context) {
    final summaryProvider = context.watch<DoctorSummaryProvider>();
    final symptomProvider = context.watch<SymptomProvider>();
    final recordProvider = context.watch<HealthRecordProvider>();

    final hasData =
        symptomProvider.logs.isNotEmpty || recordProvider.allRecords.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Visit Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🩺', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        'Prepare for your visit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We\'ll compile your recent symptoms, health '
                    'records, and suggested questions into a '
                    'summary you can share with your doctor.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data preview
            const Text(
              'What will be included',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _DataPreviewRow(
              icon: Icons.favorite_border,
              label: 'Symptom logs',
              count: symptomProvider.logs.length,
            ),
            _DataPreviewRow(
              icon: Icons.folder_outlined,
              label: 'Health records',
              count: recordProvider.allRecords.length,
            ),

            if (!hasData) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ Add symptom logs or health records to generate '
                  'a meaningful summary.',
                  style: TextStyle(color: Colors.amber, fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Notes
            const Text(
              'Additional notes for your doctor (optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Any specific concerns or questions you want '
                    'to make sure you discuss...',
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: summaryProvider.status == DoctorSummaryStatus.loading
                  ? null
                  : _generate,
              child: summaryProvider.status == DoctorSummaryStatus.loading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Generating summary...'),
                      ],
                    )
                  : const Text('Generate Summary'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataPreviewRow extends StatelessWidget {
  const _DataPreviewRow({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: count > 0 ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Temporary minimal profile — replaced when dashboard wires profile
class _MinimalProfile {
  final String displayName = 'User';
  final String ageRange = 'Not specified';
  final String lifeStage = 'General wellness';
  final String menstrualCycleStatus = 'Not specified';
  final List<String> knownConditions = [];
  final List<String> currentMedications = [];
}
