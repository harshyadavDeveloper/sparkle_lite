import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';
import 'package:sparkle_lite/data/models/ai_insight.dart';
import 'package:sparkle_lite/data/models/doctor_summary.dart';
import 'package:sparkle_lite/features/ai_insight/ai_insight_provider.dart';
import 'package:sparkle_lite/features/doctor_visit/doctor_summary_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/health_record.dart';
import '../../data/models/symptom_log.dart';
import '../records/health_record_provider.dart';
import '../symptom_tracker/symptom_provider.dart';

// Unified timeline entry
class TimelineEntry {
  final DateTime date;
  final String type; // 'symptom' | 'record'
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const TimelineEntry({
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String? _activeFilter; // null = all, 'symptom', 'record'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<SymptomProvider>().loadLogs(userId);
        context.read<HealthRecordProvider>().loadRecords(userId);
        context.read<AiInsightProvider>().loadInsights(userId);
        context.read<DoctorSummaryProvider>().loadSummaries(userId);
      }
    });
  }

  List<TimelineEntry> _buildEntries(
    List<SymptomLog> logs,
    List<HealthRecord> records,
    List<AiInsight> insights,
    List<DoctorSummary> summaries,
  ) {
    final entries = <TimelineEntry>[];

    for (final log in logs) {
      entries.add(
        TimelineEntry(
          date: log.date,
          type: 'symptom',
          title: 'Symptom Log',
          subtitle:
              'Pain ${log.painLevel}/10 · ${log.mood} · ${log.periodStatus.replaceAll('_', ' ')}',
          icon: Icons.favorite_border,
          color: AppTheme.primary,
        ),
      );
    }

    for (final record in records) {
      entries.add(
        TimelineEntry(
          date: record.recordDate,
          type: 'record',
          title: record.title,
          subtitle: record.recordType.replaceAll('_', ' '),
          icon: Icons.folder_outlined,
          color: const Color(0xFF7B68EE),
        ),
      );
    }

    for (final insight in insights) {
      entries.add(
        TimelineEntry(
          date: insight.createdAt,
          type: 'insight',
          title: 'AI Health Insight',
          subtitle: insight.possiblePattern,
          icon: Icons.psychology_outlined,
          color: const Color(0xFF26A69A),
        ),
      );
    }

    for (final summary in summaries) {
      entries.add(
        TimelineEntry(
          date: summary.generatedAt,
          type: 'doctor_summary',
          title: 'Doctor Visit Summary',
          subtitle: '${summary.questionsForDoctor.length} questions prepared',
          icon: Icons.medical_services_outlined,
          color: const Color(0xFFEF6C00),
        ),
      );
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final symptomProvider = context.watch<SymptomProvider>();
    final recordProvider = context.watch<HealthRecordProvider>();
    final insightProvider = context.watch<AiInsightProvider>();
    final doctorSummaryProvider = context.watch<DoctorSummaryProvider>();

    final isLoading =
        symptomProvider.status == SymptomStatus.loading ||
        recordProvider.status == RecordStatus.loading;

    final hasError =
        symptomProvider.status == SymptomStatus.error ||
        recordProvider.status == RecordStatus.error;

    final allEntries = _buildEntries(
      symptomProvider.logs,
      recordProvider.allRecords,
      insightProvider.savedInsights,
      doctorSummaryProvider.savedSummaries,
    );

    final filtered = _activeFilter == null
        ? allEntries
        : allEntries.where((e) => e.type == _activeFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Health Timeline')),
      body: Column(
        children: [
          // Filter row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterPill(
                  label: 'All',
                  selected: _activeFilter == null,
                  onTap: () => setState(() => _activeFilter = null),
                ),
                _FilterPill(
                  label: 'Symptoms',
                  selected: _activeFilter == 'symptom',
                  onTap: () => setState(() => _activeFilter = 'symptom'),
                ),
                _FilterPill(
                  label: 'Records',
                  selected: _activeFilter == 'record',
                  onTap: () => setState(() => _activeFilter = 'record'),
                ),
                _FilterPill(
                  label: 'Insights',
                  selected: _activeFilter == 'insight',
                  onTap: () => setState(() => _activeFilter = 'insight'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(
              context,
              isLoading: isLoading,
              hasError: hasError,
              entries: filtered,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isLoading,
    required bool hasError,
    required List<TimelineEntry> entries,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            const Text(
              'Failed to load timeline',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  context.read<SymptomProvider>().loadLogs(userId);
                  context.read<HealthRecordProvider>().loadRecords(userId);
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📋', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'Your timeline is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Logs and records will appear here',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        return _TimelineCard(entry: entry, isLast: isLast);
      },
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.entry, required this.isLast});

  final TimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    color: entry.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: entry.color.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEF0F3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(entry.icon, color: entry.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          entry.subtitle,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        entry.date.calendar,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Tooltip(
                        message: entry.date.format('dd MMM yyyy'),
                        triggerMode: TooltipTriggerMode.tap,
                        child: const Icon(
                          Icons.info_outline,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFDDE3EA),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
