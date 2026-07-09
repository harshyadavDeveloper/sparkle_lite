import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparkle_lite/core/routing/app_router.dart';
import 'package:sparkle_lite/core/theme/theme_provider.dart';
import 'package:sparkle_lite/data/services/shared_pref_service.dart';
import 'package:sparkle_lite/features/privacy/privacy_provider.dart';

import '../../core/constants/preference_keys.dart';
import '../../core/theme/app_colors_ext.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/privacy_settings.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _storage = SharedPreferencesService.instance;

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

    final hasLocalCache = _storage.getString('privacy.cached') == 'true';

    if (hasLocalCache) {
      setState(() {
        _settings = PrivacySettings(
          userId: userId,
          hideSensitiveDashboardDetails: _storage.getBool(
            PreferenceKeys.hideSensitiveDashboardDetails,
          ),
          useGenericNotificationText: _storage.getBool(
            PreferenceKeys.useGenericNotificationText,
          ),
          requireConfirmationBeforeSharing: _storage.getBool(
            PreferenceKeys.requireConfirmationBeforeSharing,
          ),
          familyProfileAccessEnabled: _storage.getBool(
            PreferenceKeys.familyProfileAccessEnabled,
          ),
          updatedAt: DateTime.now(),
        );
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('privacySettings')
          .doc(userId)
          .get();

      final settings = (doc.exists && doc.data() != null)
          ? PrivacySettings.fromMap(doc.data()!)
          : PrivacySettings(userId: userId, updatedAt: DateTime.now());

      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cacheLocally(PrivacySettings settings) async {
    await _storage.setBool(
      PreferenceKeys.hideSensitiveDashboardDetails,
      settings.hideSensitiveDashboardDetails,
    );
    await _storage.setBool(
      PreferenceKeys.useGenericNotificationText,
      settings.useGenericNotificationText,
    );
    await _storage.setBool(
      PreferenceKeys.requireConfirmationBeforeSharing,
      settings.requireConfirmationBeforeSharing,
    );
    await _storage.setBool(
      PreferenceKeys.familyProfileAccessEnabled,
      settings.familyProfileAccessEnabled,
    );
    await _storage.setString('privacy.cached', 'true');
  }

  void _updateSetting(PrivacySettings updated) {
    setState(() => _settings = updated);
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

      await _cacheLocally(updated);
      if (mounted) {
        context.read<PrivacyProvider>().updateSettings(updated);
      }

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
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Appearance'),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Dark mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode
                      ? 'Dark theme active'
                      : 'Light theme active',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                secondary: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: AppTheme.primary,
                ),
                value: themeProvider.isDarkMode,
                activeThumbColor: AppTheme.primary,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
            Divider(color: context.border),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(
                  alpha: context.isDarkMode ? 0.1 : 0.05,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(
                    alpha: context.isDarkMode ? 0.35 : 0.2,
                  ),
                ),
              ),
              child: Text(
                '🔒 Your privacy matters. Sensitive notifications '
                'are generic by default so your health data stays '
                'private on your device.',
                style: TextStyle(
                  color: context.textSecondary,
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
              onChanged: (val) => _updateSetting(
                PrivacySettings(
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
            Divider(color: context.border),

            const _SectionHeader(title: 'Notifications'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.primary,
              ),
              title: Text(
                'Notification preferences',
                style: TextStyle(color: context.textPrimary),
              ),
              subtitle: Text(
                'Manage reminders and notification privacy',
                style: TextStyle(color: context.textSecondary),
              ),
              trailing: Icon(Icons.chevron_right, color: context.textSecondary),
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.notificationSettings),
            ),
            Divider(color: context.border),

            const _SectionHeader(title: 'Sharing'),
            _PrivacyToggle(
              title: 'Confirm before sharing records',
              subtitle:
                  'Always ask for confirmation before sharing any '
                  'health records',
              value: _settings.requireConfirmationBeforeSharing,
              onChanged: (val) => _updateSetting(
                PrivacySettings(
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
              onChanged: (val) => _updateSetting(
                PrivacySettings(
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
            Divider(color: context.border),

            const _SectionHeader(title: 'Account'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.download_outlined,
                color: AppTheme.primary,
              ),
              title: Text(
                'Export my data',
                style: TextStyle(color: context.textPrimary),
              ),
              subtitle: Text(
                'Download a copy of your health data',
                style: TextStyle(color: context.textSecondary),
              ),
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
              subtitle: Text(
                'Permanently delete your account and data',
                style: TextStyle(color: context.textSecondary),
              ),
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
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: context.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.textSecondary, fontSize: 12),
      ),
      value: value,
      activeThumbColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }
}
