import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'ai_insight_provider.dart';

class AiInsightResultScreen extends StatelessWidget {
  const AiInsightResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiInsightProvider>();
    final insight = provider.currentInsight;

    if (insight == null) {
      return const Scaffold(body: Center(child: Text('No insight available')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Health Insight'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: Color(0xFF92610A),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight.disclaimer,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92610A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _InsightSection(
              icon: '📋',
              title: 'Summary',
              content: insight.summary,
            ),
            const SizedBox(height: 20),

            _InsightSection(
              icon: '🔍',
              title: 'Pattern Noticed',
              content: insight.possiblePattern,
            ),
            const SizedBox(height: 20),

            _InsightSection(
              icon: '💙',
              title: 'Care Guidance',
              content: insight.careGuidance,
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEF0F3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🩺', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        'Questions to Ask Your Doctor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...insight.doctorQuestions.map(
                    (q) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '•  ',
                            style: TextStyle(color: AppTheme.primary),
                          ),
                          Expanded(
                            child: Text(
                              q,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: provider.status == AiInsightStatus.saved
                  ? null
                  : () async {
                      final success = await provider.saveInsightToTimeline();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Insight saved to timeline ✓'
                                  : 'Failed to save insight',
                            ),
                            backgroundColor: success
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        );
                      }
                    },
              icon: Icon(
                provider.status == AiInsightStatus.saved
                    ? Icons.check
                    : Icons.save_outlined,
              ),
              label: Text(
                provider.status == AiInsightStatus.saved
                    ? 'Saved to Timeline'
                    : 'Save to Timeline',
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () {
                provider.reset();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  final String icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
