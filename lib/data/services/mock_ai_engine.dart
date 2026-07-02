import 'package:uuid/uuid.dart';

import '../models/ai_insight.dart';
import '../models/symptom_log.dart';

class MockAiEngine {
  static const _disclaimer =
      'This is not a diagnosis and does not replace medical advice. '
      'Please consult a qualified healthcare professional for any '
      'health concerns.';

  static AiInsight generateInsight({
    required String userId,
    required List<SymptomLog> selectedLogs,
  }) {
    final id = const Uuid().v4();
    final now = DateTime.now();

    // Analyse patterns from selected logs
    final avgPain = selectedLogs.isEmpty
        ? 0
        : selectedLogs.map((l) => l.painLevel).reduce((a, b) => a + b) /
              selectedLogs.length;

    final hasHighPain = selectedLogs.any((l) => l.painLevel >= 8);
    final hasHeavyFlow = selectedLogs.any((l) => l.flowLevel == 'heavy');
    final hasDizziness = selectedLogs.any(
      (l) => l.notes?.toLowerCase().contains('dizz') ?? false,
    );
    final hasIrregularBleeding = selectedLogs.any(
      (l) => l.symptoms.contains('irregular bleeding'),
    );
    final hasSpotting = selectedLogs.any(
      (l) => l.symptoms.contains('spotting'),
    );
    final noSymptoms = selectedLogs.every((l) => l.symptoms.isEmpty);
    final multipleLogs = selectedLogs.length >= 3;
    final moods = selectedLogs.map((l) => l.mood).toSet();
    final hasAnxiety = moods.contains('anxious');

    // Apply mock insight rules — per PDF spec
    if (hasHighPain) {
      return AiInsight(
        id: id,
        userId: userId,
        summary:
            'Your recent logs show a pattern of high pain levels '
            '(${avgPain.toStringAsFixed(1)}/10 average). '
            'This level of discomfort is worth discussing with a doctor.',
        possiblePattern:
            'Recurring high pain levels noted across your recent logs.',
        careGuidance:
            'Consider discussing severe or recurring pain with a '
            'gynaecologist or your primary care provider.',
        doctorQuestions: [
          'Could these pain levels be related to my cycle?',
          'Should I track any additional symptoms?',
          'Are there any tests you would recommend?',
          'What pain management options are available?',
        ],
        disclaimer: _disclaimer,
        createdAt: now,
      );
    }

    if (hasHeavyFlow && hasDizziness) {
      return AiInsight(
        id: id,
        userId: userId,
        summary:
            'Your logs show heavy flow alongside notes of dizziness. '
            'This combination may be worth monitoring closely.',
        possiblePattern:
            'Heavy flow with dizziness can sometimes be associated '
            'with iron levels or other factors worth exploring.',
        careGuidance:
            'It may be helpful to discuss this pattern with your '
            'doctor, particularly around iron and energy levels.',
        doctorQuestions: [
          'Could heavy flow be affecting my iron or energy levels?',
          'Should I check my haemoglobin levels?',
          'Is this flow level typical for my cycle stage?',
          'What should I watch out for?',
        ],
        disclaimer: _disclaimer,
        createdAt: now,
      );
    }

    if (hasIrregularBleeding || hasSpotting) {
      return AiInsight(
        id: id,
        userId: userId,
        summary:
            'Your recent logs include irregular bleeding or spotting. '
            'Tracking these patterns over time can be helpful for '
            'your healthcare provider.',
        possiblePattern:
            'Irregular bleeding patterns noted across your selected logs.',
        careGuidance:
            'Keeping a detailed record of dates and patterns is useful '
            'when discussing this with a gynaecologist.',
        doctorQuestions: [
          'What could be causing irregular bleeding at this stage?',
          'Should I track the frequency and duration more closely?',
          'Are there any tests that might help identify a pattern?',
          'Could this be related to my current medications?',
        ],
        disclaimer: _disclaimer,
        createdAt: now,
      );
    }

    if (hasAnxiety && multipleLogs) {
      return AiInsight(
        id: id,
        userId: userId,
        summary:
            'Your logs show a recurring pattern of anxious mood. '
            'Emotional wellbeing is an important part of overall health.',
        possiblePattern:
            'Anxious mood appears across multiple recent log entries.',
        careGuidance:
            'Consider discussing emotional wellbeing with your doctor '
            'or a mental health professional if this persists.',
        doctorQuestions: [
          'Could my cycle be affecting my mood and anxiety levels?',
          'Are there lifestyle or dietary changes that might help?',
          'Should I consider speaking with a counsellor?',
        ],
        disclaimer: _disclaimer,
        createdAt: now,
      );
    }

    if (multipleLogs && !noSymptoms) {
      return AiInsight(
        id: id,
        userId: userId,
        summary:
            'Your recent logs show a pattern of recurring symptoms '
            'over the past entries. Consistent tracking like this '
            'gives your doctor a clearer picture.',
        possiblePattern:
            'Symptoms appear consistently across ${selectedLogs.length} '
            'recent log entries.',
        careGuidance:
            'Continue tracking and consider sharing this timeline '
            'with your healthcare provider at your next visit.',
        doctorQuestions: [
          'Could these symptoms be related to my cycle?',
          'Should I track any additional details?',
          'Do I need any routine checks based on this pattern?',
        ],
        disclaimer: _disclaimer,
        createdAt: now,
      );
    }

    // Default — no symptoms / gentle wellness
    return AiInsight(
      id: id,
      userId: userId,
      summary:
          'Your recent logs look relatively calm with no major symptoms '
          'reported. Keep listening to your body and logging regularly.',
      possiblePattern: 'No significant symptom patterns detected.',
      careGuidance:
          'Continue your current routine and log any changes you notice. '
          'Regular check-ups are always a good idea.',
      doctorQuestions: [
        'Are there any routine screenings I should schedule?',
        'Any lifestyle habits you would recommend for my life stage?',
      ],
      disclaimer: _disclaimer,
      createdAt: now,
    );
  }
}
