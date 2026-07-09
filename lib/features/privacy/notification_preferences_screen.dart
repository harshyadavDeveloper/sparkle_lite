import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sparkle_lite/data/services/shared_pref_service.dart';
import 'package:sparkle_lite/features/ai_insight/ai_insight_result_screen.dart';

import '../../core/constants/preference_keys.dart';
import '../../core/theme/app_colors_ext.dart';
import '../../core/theme/app_theme.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final _storage = SharedPreferencesService.instance;

  bool _symptomLogReminders = true;
  bool _doctorVisitReminders = true;
  bool _weeklyHealthSummary = false;
  bool _medicationReminders = false;
  bool _cycleReminders = true;
  bool _useGenericText = true;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final hasLocalCache = _storage.getString('notifications.cached') == 'true';

    if (hasLocalCache) {
      setState(() {
        _symptomLogReminders = _storage.getBool(
          PreferenceKeys.symptomLogReminders,
          defaultValue: true,
        );
        _doctorVisitReminders = _storage.getBool(
          PreferenceKeys.doctorVisitReminders,
          defaultValue: true,
        );
        _weeklyHealthSummary = _storage.getBool(
          PreferenceKeys.weeklyHealthSummary,
        );
        _medicationReminders = _storage.getBool(
          PreferenceKeys.medicationReminders,
        );
        _cycleReminders = _storage.getBool(
          PreferenceKeys.cycleReminders,
          defaultValue: true,
        );
        _useGenericText = _storage.getBool(
          PreferenceKeys.notificationsUseGenericText,
          defaultValue: true,
        );
        _isLoading = false;
      });
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('notificationPreferences')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _symptomLogReminders = data['symptomLogReminders'] ?? true;
        _doctorVisitReminders = data['doctorVisitReminders'] ?? true;
        _weeklyHealthSummary = data['weeklyHealthSummary'] ?? false;
        _medicationReminders = data['medicationReminders'] ?? false;
        _cycleReminders = data['cycleReminders'] ?? true;
        _useGenericText = data['useGenericText'] ?? true;
      }

      setState(() {});
    } catch (e) {
      debugPrint('Failed to load notification preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cacheAllLocally() async {
    await _storage.setBool(
      PreferenceKeys.symptomLogReminders,
      _symptomLogReminders,
    );
    await _storage.setBool(
      PreferenceKeys.doctorVisitReminders,
      _doctorVisitReminders,
    );
    await _storage.setBool(
      PreferenceKeys.weeklyHealthSummary,
      _weeklyHealthSummary,
    );
    await _storage.setBool(
      PreferenceKeys.medicationReminders,
      _medicationReminders,
    );
    await _storage.setBool(PreferenceKeys.cycleReminders, _cycleReminders);
    await _storage.setBool(
      PreferenceKeys.notificationsUseGenericText,
      _useGenericText,
    );
    await _storage.setString('notifications.cached', 'true');
  }

  void _updateToggle(void Function() applyChange) {
    setState(applyChange);
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      await FirebaseFirestore.instance
          .collection('notificationPreferences')
          .doc(userId)
          .set({
            'symptomLogReminders': _symptomLogReminders,
            'doctorVisitReminders': _doctorVisitReminders,
            'weeklyHealthSummary': _weeklyHealthSummary,
            'medicationReminders': _medicationReminders,
            'cycleReminders': _cycleReminders,
            'useGenericText': _useGenericText,
            'updatedAt': DateTime.now().toIso8601String(),
          });

      await _cacheAllLocally();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save preferences'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WarningBox(
              icon: Icons.info_outline,
              message:
                  'Generic notification text is ON by default. '
                  'This means notifications say "You have a health '
                  'reminder" instead of revealing health details '
                  'on your lock screen.',
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'Privacy'),
            _NotificationTile(
              title: 'Use generic notification text',
              subtitle: _useGenericText
                  ? '"You have a health reminder" — private'
                  : '"Your cycle reminder is due" — specific',
              value: _useGenericText,
              onChanged: (val) => _updateToggle(() => _useGenericText = val),
              highlightColor: AppTheme.primary,
            ),
            Divider(color: context.border),
            const SizedBox(height: 8),

            const _SectionHeader(title: 'Reminders'),
            _NotificationTile(
              title: 'Symptom log reminders',
              subtitle: 'Reminds you to log daily symptoms',
              value: _symptomLogReminders,
              onChanged: (val) =>
                  _updateToggle(() => _symptomLogReminders = val),
            ),
            _NotificationTile(
              title: 'Cycle reminders',
              subtitle: 'Period start and cycle tracking alerts',
              value: _cycleReminders,
              onChanged: (val) => _updateToggle(() => _cycleReminders = val),
            ),
            _NotificationTile(
              title: 'Doctor visit reminders',
              subtitle: 'Upcoming appointment alerts',
              value: _doctorVisitReminders,
              onChanged: (val) =>
                  _updateToggle(() => _doctorVisitReminders = val),
            ),
            _NotificationTile(
              title: 'Medication reminders',
              subtitle: 'Reminders for current medications',
              value: _medicationReminders,
              onChanged: (val) =>
                  _updateToggle(() => _medicationReminders = val),
            ),
            Divider(color: context.border),
            const SizedBox(height: 8),

            const _SectionHeader(title: 'Reports'),
            _NotificationTile(
              title: 'Weekly health summary',
              subtitle: 'A weekly overview of your logged activity',
              value: _weeklyHealthSummary,
              onChanged: (val) =>
                  _updateToggle(() => _weeklyHealthSummary = val),
            ),
            const SizedBox(height: 32),

            const _SectionHeader(title: 'Notification Preview'),
            // This mock deliberately mimics a real OS notification, which
            // stays light-surfaced/dark-text on most platforms regardless
            // of the app's own theme — so it intentionally does NOT follow
            // context.card/context.textPrimary here.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🌸', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Sparkle',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'now',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _useGenericText
                        ? 'You have a health reminder.'
                        : 'Your symptom log reminder is due.',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _useGenericText
                  ? '✓ Private — health details not visible on lock screen'
                  : '⚠️ Specific text visible on lock screen',
              style: TextStyle(
                fontSize: 12,
                color: _useGenericText
                    ? AppTheme.success
                    : (context.isDarkMode
                          ? const Color(0xFFE0B84D)
                          : const Color(0xFF92610A)),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Preferences'),
            ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.highlightColor,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: value && highlightColor != null
              ? highlightColor
              : context.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.textSecondary, fontSize: 12),
      ),
      value: value,
      activeThumbColor: highlightColor ?? AppTheme.primary,
      onChanged: onChanged,
    );
  }
}
