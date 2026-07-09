import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';
import 'package:sparkle_lite/core/theme/theme_provider.dart';
import 'package:sparkle_lite/features/privacy/privacy_provider.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors_ext.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/symptom_log.dart';
import '../ai_insight/ai_insight_provider.dart';
import '../auth/auth_provider.dart';
import '../doctor_visit/doctor_summary_provider.dart';
import '../profile/profile_provider.dart';
import '../records/health_record_provider.dart';
import '../symptom_tracker/symptom_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInitialLoading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboardData());
  }

  Future<void> _loadDashboardData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isInitialLoading = false);
      return;
    }

    await Future.wait([
      context.read<ProfileProvider>().loadProfile(userId),
      context.read<SymptomProvider>().loadLogs(userId),
      context.read<HealthRecordProvider>().loadRecords(userId),
      context.read<AiInsightProvider>().loadInsights(userId),
      context.read<DoctorSummaryProvider>().loadSummaries(userId),
      context.read<PrivacyProvider>().loadSettings(userId),
    ]);

    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final symptomProvider = context.watch<SymptomProvider>();
    final recordProvider = context.watch<HealthRecordProvider>();
    final auth = context.read<AuthProvider>();
    final privacyProvider = context.watch<PrivacyProvider>();

    final recentLog = symptomProvider.logs.isNotEmpty
        ? symptomProvider.logs.first
        : null;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Sparkle'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              tooltip: 'Toggle theme',
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined),
            tooltip: 'Privacy',
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.privacySettings),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              context.read<ProfileProvider>().clear();
              await auth.signOut();
              if (context.mounted) {
                await Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${profile?.displayName ?? 'there'} 👋',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                    ),
                    if (profile != null)
                      Text(
                        profile.lifeStage,
                        style: TextStyle(color: context.textSecondary),
                      ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        _StatCard(
                          label: 'Logs',
                          count: symptomProvider.logs.length,
                          icon: Icons.favorite_border,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Records',
                          count: recordProvider.allRecords.length,
                          icon: Icons.folder_outlined,
                          color: const Color(0xFF7B68EE),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (recentLog != null) ...[
                      const _SectionTitle(title: 'Latest Log'),
                      const SizedBox(height: 10),
                      _RecentLogCard(
                        log: recentLog,
                        hideDetails: privacyProvider.hideSensitive,
                      ),
                      const SizedBox(height: 24),
                    ],

                    const _SectionTitle(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _QuickActionCard(
                          icon: Icons.add_circle_outline,
                          label: 'Log Symptom',
                          color: AppTheme.primary,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.symptomHistory,
                          ),
                        ),
                        _QuickActionCard(
                          icon: Icons.upload_file_outlined,
                          label: 'Upload Record',
                          color: const Color(0xFF7B68EE),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.healthRecords,
                          ),
                        ),
                        _QuickActionCard(
                          icon: Icons.psychology_outlined,
                          label: 'AI Insight',
                          color: const Color(0xFF26A69A),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.aiInsightInput,
                          ),
                        ),
                        _QuickActionCard(
                          icon: Icons.medical_services_outlined,
                          label: 'Doctor Summary',
                          color: const Color(0xFFEF6C00),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.doctorSummary,
                          ),
                        ),
                        _QuickActionCard(
                          icon: Icons.timeline_outlined,
                          label: 'Timeline',
                          color: const Color(0xFF5C6BC0),
                          onTap: () =>
                              Navigator.pushNamed(context, AppRouter.timeline),
                        ),
                        _QuickActionCard(
                          icon: Icons.people_outline,
                          label: 'Family',
                          color: const Color(0xFFEC407A),
                          onTap: () =>
                              Navigator.pushNamed(context, AppRouter.family),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Slightly stronger tint in dark mode so the card doesn't disappear
    // into the dark background (0.08/0.2 alpha reads as almost invisible
    // on a near-black surface).
    final fillAlpha = context.isDarkMode ? 0.16 : 0.08;
    final borderAlpha = context.isDarkMode ? 0.35 : 0.2;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: fillAlpha),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: borderAlpha)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: context.textPrimary,
      ),
    );
  }
}

class _RecentLogCard extends StatelessWidget {
  const _RecentLogCard({required this.log, this.hideDetails = false});

  final SymptomLog log;
  final bool hideDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.date.calendar,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              // Hide pain level if privacy mode on
              Text(
                hideDetails ? '••••' : 'Pain ${log.painLevel}/10',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Hide sensitive chips if privacy mode on
          hideDetails
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 12,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Details hidden for privacy',
                        style: TextStyle(fontSize: 11, color: AppTheme.primary),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 6,
                  children: [
                    _MiniChip(label: log.mood),
                    _MiniChip(label: log.periodStatus.replaceAll('_', ' ')),
                    ...log.symptoms.take(2).map((s) => _MiniChip(label: s)),
                    if (log.symptoms.length > 2)
                      _MiniChip(label: '+${log.symptoms.length - 2} more'),
                  ],
                ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(
          alpha: context.isDarkMode ? 0.18 : 0.08,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppTheme.primary),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border),
          boxShadow: context.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: context.isDarkMode ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: context.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
