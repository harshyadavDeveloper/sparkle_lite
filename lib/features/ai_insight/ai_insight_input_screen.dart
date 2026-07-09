import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';

import '../../core/theme/app_colors_ext.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/symptom_log.dart';
import '../symptom_tracker/symptom_provider.dart';
import 'ai_insight_provider.dart';
import 'ai_insight_result_screen.dart';

class AiInsightInputScreen extends StatefulWidget {
  const AiInsightInputScreen({super.key});

  @override
  State<AiInsightInputScreen> createState() => _AiInsightInputScreenState();
}

class _AiInsightInputScreenState extends State<AiInsightInputScreen> {
  final List<String> _selectedLogIds = [];

  List<SymptomLog> get _selectedLogs => context
      .read<SymptomProvider>()
      .logs
      .where((l) => _selectedLogIds.contains(l.id))
      .toList();

  Future<void> _generateInsight() async {
    if (_selectedLogIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom log'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final provider = context.read<AiInsightProvider>();
    await provider.generateInsight(_selectedLogs);

    if (mounted && provider.status == AiInsightStatus.generated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiInsightResultScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final symptomProvider = context.watch<SymptomProvider>();
    final aiProvider = context.watch<AiInsightProvider>();
    final logs = symptomProvider.logs;
    final isGenerating = aiProvider.status == AiInsightStatus.loading;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('AI Health Insight')),
      body: isGenerating
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: AppTheme.primary.withValues(
                    alpha: context.isDarkMode ? 0.1 : 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 Select logs to analyse',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose recent symptom logs and we\'ll look '
                        'for patterns to discuss with your doctor.',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _WarningBox(
                        icon: Icons.info_outline,
                        message:
                            'This feature does not diagnose conditions. '
                            'It identifies patterns to discuss with your doctor.',
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: logs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('📋', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                'No symptom logs yet',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add symptom logs first to use this feature',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final isSelected = _selectedLogIds.contains(log.id);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  isSelected
                                      ? _selectedLogIds.remove(log.id)
                                      : _selectedLogIds.add(log.id);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(
                                          alpha: context.isDarkMode
                                              ? 0.16
                                              : 0.08,
                                        )
                                      : context.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : context.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : context.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                log.date.calendar,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Tooltip(
                                                message: log.date.format(
                                                  'dd MMM yyyy',
                                                ),
                                                triggerMode:
                                                    TooltipTriggerMode.tap,
                                                child: Icon(
                                                  Icons.info_outline,
                                                  size: 12,
                                                  color: context.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pain ${log.painLevel}/10 · '
                                            '${log.mood} · '
                                            '${log.periodStatus.replaceAll('_', ' ')}',
                                            style: TextStyle(
                                              color: context.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (log.symptoms.isNotEmpty)
                                            Text(
                                              log.symptoms.join(', '),
                                              style: const TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_selectedLogIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${_selectedLogIds.length} log${_selectedLogIds.length > 1 ? 's' : ''} selected',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: aiProvider.status == AiInsightStatus.loading
                            ? null
                            : _generateInsight,
                        child: aiProvider.status == AiInsightStatus.loading
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
                                  Text('Analysing your logs...'),
                                ],
                              )
                            : const Text('Generate Insight'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Amber info/warning callout. Muted in dark mode so it doesn't glare.
class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final bgColor = context.isDarkMode
        ? const Color(0xFF3A2E12)
        : const Color(0xFFFFF8E1);
    final borderColor = context.isDarkMode
        ? const Color(0xFF5C4A1E)
        : const Color(0xFFFFE082);
    final fgColor = context.isDarkMode
        ? const Color(0xFFE0B84D)
        : const Color(0xFF92610A);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 11, color: fgColor),
            ),
          ),
        ],
      ),
    );
  }
}
