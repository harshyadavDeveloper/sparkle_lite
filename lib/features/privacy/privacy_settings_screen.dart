import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/privacy_settings.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  PrivacySettings _settings = PrivacySettings(
    userId: '',
    updatedAt: DateTime.now(),
  );
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('privacySettings')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _settings = PrivacySettings.fromMap(doc.data()!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _settings = PrivacySettings(
            userId: userId,
            updatedAt: DateTime.now(),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      final updated = PrivacySettings(
        userId: userId,
        hideSensitiveDashboardDetails: _settings.hideSensitiveDashboardDetails,
        useGenericNotificationText: _settings.useGenericNotificationText,
        requireConfirmationBeforeSharing:
            _settings.requireConfirmationBeforeSharing,
        familyProfileAccessEnabled: _settings.familyProfileAccessEnabled,
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('privacySettings')
          .doc(userId)
          .set(updated.toMap());

      setState(() {
        _settings = updated;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings saved ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Text(
                '🔒 Your privacy matters. Sensitive notifications '
                'are generic by default so your health data stays '
                'private on your device.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'Dashboard'),
            _PrivacyToggle(
              title: 'Hide sensitive details',
              subtitle:
                  'Hides period status and symptom details on the '
                  'main dashboard',
              value: _settings.hideSensitiveDashboardDetails,
              onChanged: (val) => setState(
                () => _settings = PrivacySettings(
                  userId: _settings.userId,
                  hideSensitiveDashboardDetails: val,
                  useGenericNotificationText:
                      _settings.useGenericNotificationText,
                  requireConfirmationBeforeSharing:
                      _settings.requireConfirmationBeforeSharing,
                  familyProfileAccessEnabled:
                      _settings.familyProfileAccessEnabled,
                  updatedAt: DateTime.now(),
                ),
              ),
            ),
            const Divider(),

            const _SectionHeader(title: 'Notifications'),
            _PrivacyToggle(
              title: 'Use generic notification text',
              subtitle:
                  'Shows "You have a health reminder" instead of '
                  'specific health details',
              value: _settings.useGenericNotificationText,
              onChanged: (val) => setState(
                () => _settings = PrivacySettings(
                  userId: _settings.userId,
                  hideSensitiveDashboardDetails:
                      _settings.hideSensitiveDashboardDetails,
                  useGenericNotificationText: val,
                  requireConfirmationBeforeSharing:
                      _settings.requireConfirmationBeforeSharing,
                  familyProfileAccessEnabled:
                      _settings.familyProfileAccessEnabled,
                  updatedAt: DateTime.now(),
                ),
              ),
            ),
            const Divider(),

            const _SectionHeader(title: 'Sharing'),
            _PrivacyToggle(
              title: 'Confirm before sharing records',
              subtitle:
                  'Always ask for confirmation before sharing any '
                  'health records',
              value: _settings.requireConfirmationBeforeSharing,
              onChanged: (val) => setState(
                () => _settings = PrivacySettings(
                  userId: _settings.userId,
                  hideSensitiveDashboardDetails:
                      _settings.hideSensitiveDashboardDetails,
                  useGenericNotificationText:
                      _settings.useGenericNotificationText,
                  requireConfirmationBeforeSharing: val,
                  familyProfileAccessEnabled:
                      _settings.familyProfileAccessEnabled,
                  updatedAt: DateTime.now(),
                ),
              ),
            ),
            _PrivacyToggle(
              title: 'Enable family profile access',
              subtitle:
                  'Allow family members section to access shared '
                  'health information',
              value: _settings.familyProfileAccessEnabled,
              onChanged: (val) => setState(
                () => _settings = PrivacySettings(
                  userId: _settings.userId,
                  hideSensitiveDashboardDetails:
                      _settings.hideSensitiveDashboardDetails,
                  useGenericNotificationText:
                      _settings.useGenericNotificationText,
                  requireConfirmationBeforeSharing:
                      _settings.requireConfirmationBeforeSharing,
                  familyProfileAccessEnabled: val,
                  updatedAt: DateTime.now(),
                ),
              ),
            ),
            const Divider(),

            const _SectionHeader(title: 'Account'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.download_outlined,
                color: AppTheme.primary,
              ),
              title: const Text('Export my data'),
              subtitle: const Text('Download a copy of your health data'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: AppTheme.error),
              title: const Text(
                'Delete account',
                style: TextStyle(color: AppTheme.error),
              ),
              subtitle: const Text('Permanently delete your account and data'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text(
                      'This will permanently delete your account '
                      'and all data. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Settings'),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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

class _PrivacyToggle extends StatelessWidget {
  const _PrivacyToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      value: value,
      activeThumbColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }
}
