import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sparkle_lite/data/services/dio_client.dart';
import '../../core/utils/logger.dart';
import '../models/health_record.dart';
import '../models/symptom_log.dart';
import '../models/user_profile.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  //   static const String _baseUrl =
  // 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  static const String _systemPrompt = '''
You are a compassionate women's health companion assistant.
Your role is to help users understand patterns in their health data 
and prepare for doctor visits.

STRICT RULES — you must NEVER violate these:
- Never diagnose any medical condition
- Never say "You have PCOS", "You are pregnant", "You have cancer"
- Never say "You do not need a doctor" or "This is definitely normal"
- Never replace professional medical advice
- Always frame insights as educational and supportive
- Always include a disclaimer that this is not a diagnosis
- Use warm, calm, non-alarming language
- Keep responses focused and practical
''';

  // ─── AI Insight ───────────────────────────────────────────────

  static Future<Map<String, dynamic>?> generateInsight({
    required List<SymptomLog> selectedLogs,
  }) async {
    Logger.info('GeminiService → generateInsight called');
    Logger.info('Selected logs count: ${selectedLogs.length}');

    final logsContext = selectedLogs
        .map(
          (log) => {
            'date': log.date.toIso8601String().split('T').first,
            'periodStatus': log.periodStatus,
            'flowLevel': log.flowLevel,
            'painLevel': log.painLevel,
            'mood': log.mood,
            'symptoms': log.symptoms,
            'notes': log.notes ?? 'none',
          },
        )
        .toList();

    final prompt = _buildInsightPrompt(logsContext);

    Logger.info('GeminiService → sending insight prompt to Gemini');

    return await _callGemini(prompt, context: 'AI Insight');
  }

  static String _buildInsightPrompt(List<Map<String, dynamic>> logsContext) {
    return '''
$_systemPrompt

Analyse the following symptom logs and provide a health insight.

SYMPTOM LOGS:
${jsonEncodeLogs(logsContext)}

Respond ONLY with a valid JSON object in this exact format:
{
  "summary": "A warm 2-3 sentence plain-language summary of what the logs show",
  "possiblePattern": "One sentence describing any pattern noticed",
  "careGuidance": "One sentence of supportive care guidance",
  "doctorQuestions": [
    "Question 1 to ask a doctor",
    "Question 2 to ask a doctor",
    "Question 3 to ask a doctor"
  ],
  "disclaimer": "This is not a diagnosis and does not replace medical advice. Please consult a qualified healthcare professional."
}

Do not include any text outside the JSON object.
Do not use markdown code blocks.
''';
  }

  // ─── Doctor Summary ───────────────────────────────────────────

  static Future<Map<String, dynamic>?> generateDoctorSummary({
    required UserProfile profile,
    required List<SymptomLog> recentLogs,
    required List<HealthRecord> records,
    String? userNotes,
  }) async {
    Logger.info('GeminiService → generateDoctorSummary called');

    final profileContext = {
      'name': profile.displayName,
      'ageRange': profile.ageRange,
      'lifeStage': profile.lifeStage,
      'menstrualCycleStatus': profile.menstrualCycleStatus,
      'knownConditions': profile.knownConditions,
      'currentMedications': profile.currentMedications,
    };

    final logsContext = recentLogs
        .take(10)
        .map(
          (log) => {
            'date': log.date.toIso8601String().split('T').first,
            'periodStatus': log.periodStatus,
            'flowLevel': log.flowLevel,
            'painLevel': log.painLevel,
            'mood': log.mood,
            'symptoms': log.symptoms,
            'notes': log.notes ?? 'none',
          },
        )
        .toList();

    final recordsContext = records
        .take(5)
        .map(
          (r) => {
            'title': r.title,
            'type': r.recordType,
            'date': r.recordDate.toIso8601String().split('T').first,
            'doctor': r.doctorName ?? 'not specified',
          },
        )
        .toList();

    final prompt =
        '''
$_systemPrompt

Generate a doctor visit preparation summary for the following patient.

PATIENT PROFILE:
${jsonEncodeLogs(profileContext)}

RECENT SYMPTOM LOGS (last 10):
${jsonEncodeLogs(logsContext)}

HEALTH RECORDS:
${jsonEncodeLogs(recordsContext)}

PATIENT'S OWN NOTES AND CONCERNS:
${userNotes ?? 'No additional notes provided'}

Generate a clear, structured doctor visit summary.
Respond ONLY with a valid JSON object in this exact format:
{
  "profileSnapshot": "One sentence summarising the patient profile",
  "symptomSummary": "2-3 sentences summarising recent symptom patterns",
  "periodSummary": "1-2 sentences summarising period history from logs",
  "recordsSummary": "One sentence listing uploaded health records",
  "questionsForDoctor": [
    "Specific question 1 based on their data and concerns",
    "Specific question 2 based on their data and concerns",
    "Specific question 3 based on their data and concerns",
    "Specific question 4 based on their data and concerns"
  ],
  "patientConcerns": "Summary of what the patient typed in their notes, or null if none",
  "disclaimer": "This summary is for personal use only and is not a medical document. Always consult a qualified healthcare professional."
}

Make the questions specific to THIS patient's actual data and concerns.
Do not use generic questions.
Do not include any text outside the JSON object.
Do not use markdown code blocks.
''';

    Logger.info('GeminiService → sending doctor summary prompt to Gemini');

    return await _callGemini(prompt, context: 'Doctor Summary');
  }

  // ─── Core API Call (now using Dio) ─────────────────────────────

  static Future<Map<String, dynamic>?> _callGemini(
    String prompt, {
    required String context,
  }) async {
    try {
      final response = await DioClient.instance.post(
        _baseUrl,
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 2048,
            'topP': 0.8,
            'topK': 40,
            'thinkingConfig': {'thinkingBudget': 0},
          },
        },
      );

      // Dio already decodes JSON — response.data is a Map, not a String.
      final decoded = response.data as Map<String, dynamic>;

      final finishReason =
          decoded['candidates']?[0]?['finishReason'] as String?;
      if (finishReason == 'MAX_TOKENS') {
        Logger.error(
          'GeminiService [$context] → response truncated (MAX_TOKENS)',
        );
      }

      final text =
          decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
              as String?;

      if (text == null) {
        Logger.error('GeminiService [$context] → no text in response');
        return null;
      }

      Logger.success('GeminiService [$context] → received response');

      final cleaned = text
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final parsed = jsonDecodeSafe(cleaned);

      if (parsed == null) {
        Logger.error('GeminiService [$context] → failed to parse JSON');
        return null;
      }

      Logger.success('GeminiService [$context] → JSON parsed successfully');
      return parsed;
    } on DioException catch (e) {
      // Retry already happened inside the interceptor for 503/timeouts.
      // If we're here, retries were exhausted or it's a non-retryable error.
      Logger.error(
        'GeminiService [$context] → DioException: ${e.response?.statusCode} ${e.message}',
      );
      return null;
    } catch (e) {
      Logger.error('GeminiService [$context] → unexpected exception: $e');
      return null;
    }
  }
}

String jsonEncodeLogs(dynamic data) => jsonEncode(data);

Map<String, dynamic>? jsonDecodeSafe(String text) {
  try {
    return jsonDecode(text) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
