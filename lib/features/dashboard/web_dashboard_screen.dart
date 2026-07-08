import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';
import 'package:sparkle_lite/core/theme/theme_provider.dart';
import 'package:sparkle_lite/core/utils/logger.dart';
import 'package:sparkle_lite/data/models/symptom_log.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors_ext.dart';
import '../../core/theme/app_theme.dart';
import '../ai_insight/ai_insight_provider.dart';
import '../auth/auth_provider.dart';
import '../doctor_visit/doctor_summary_provider.dart';
import '../profile/profile_provider.dart';
import '../records/health_record_provider.dart';
import '../symptom_tracker/symptom_provider.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  int _selectedIndex = 0;
  bool _isInitialLoading = true;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _NavItem(icon: Icons.folder_outlined, label: 'Records'),
    _NavItem(icon: Icons.timeline_outlined, label: 'Timeline'),
    _NavItem(icon: Icons.psychology_outlined, label: 'AI Insights'),
    _NavItem(icon: Icons.medical_services_outlined, label: 'Doctor Visit'),
    _NavItem(icon: Icons.privacy_tip_outlined, label: 'Privacy'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchDashboardData();
      if (mounted) setState(() => _isInitialLoading = false);
    });
  }

  Future<void> _fetchDashboardData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await Future.wait([
      context.read<ProfileProvider>().loadProfile(userId),
      context.read<SymptomProvider>().loadLogs(userId),
      context.read<HealthRecordProvider>().loadRecords(userId),
      context.read<AiInsightProvider>().loadInsights(userId),
      context.read<DoctorSummaryProvider>().loadSummaries(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    Logger.info('web dashboard build');
    return Scaffold(
      backgroundColor: context.bg,
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Row(
              children: [
                // Sidebar
                _Sidebar(
                  navItems: _navItems,
                  selectedIndex: _selectedIndex,
                  onItemSelected: (i) => setState(() => _selectedIndex = i),
                ),
                // Vertical divider
                Container(width: 1, color: context.border),
                // Main content
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const _WebDashboardOverview();
      case 1:
        return const _WebRecordsManager();
      case 2:
        return const _WebTimelinePage();
      case 3:
        return const _WebAiInsightsPage();
      case 4:
        return const _WebDoctorSummaryPage();
      case 5:
        return const _WebPrivacyPage();
      default:
        return const _WebDashboardOverview();
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.navItems,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<_NavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final auth = context.read<AuthProvider>();

    return Container(
      width: 220,
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 8),
            child: Text(
              '🌸 Sparkle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),

          // User info
          if (profile != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                profile.displayName,
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
            ),

          Divider(height: 1, color: context.border),
          const SizedBox(height: 12),

          // Nav items
          ...navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = selectedIndex == index;

            return GestureDetector(
              onTap: () => onItemSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 18,
                      color: isSelected
                          ? AppTheme.primary
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primary
                            : context.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),
          Divider(height: 1, color: context.border),

          // Theme toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => GestureDetector(
              onTap: themeProvider.toggleTheme,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 18,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Logout
          GestureDetector(
            onTap: () async {
              await auth.signOut();
              if (context.mounted) {
                await Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: context.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 14,
                    ),
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

// Web Dashboard Overview
class _WebDashboardOverview extends StatelessWidget {
  const _WebDashboardOverview();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final symptomProvider = context.watch<SymptomProvider>();
    final recordProvider = context.watch<HealthRecordProvider>();
    final insightProvider = context.watch<AiInsightProvider>();
    final summaryProvider = context.watch<DoctorSummaryProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Welcome back, ${profile?.displayName ?? 'there'} 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          if (profile != null)
            Text(
              profile.lifeStage,
              style: TextStyle(color: context.textSecondary),
            ),
          const SizedBox(height: 32),

          // Summary cards row
          Row(
            children: [
              _WebStatCard(
                label: 'Symptom Logs',
                count: symptomProvider.logs.length,
                icon: Icons.favorite_border,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 16),
              _WebStatCard(
                label: 'Health Records',
                count: recordProvider.allRecords.length,
                icon: Icons.folder_outlined,
                color: const Color(0xFF7B68EE),
              ),
              const SizedBox(width: 16),
              _WebStatCard(
                label: 'AI Insights',
                count: insightProvider.savedInsights.length,
                icon: Icons.psychology_outlined,
                color: const Color(0xFF26A69A),
              ),
              const SizedBox(width: 16),
              _WebStatCard(
                label: 'Doctor Summaries',
                count: summaryProvider.savedSummaries.length,
                icon: Icons.medical_services_outlined,
                color: const Color(0xFFEF6C00),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent activity + timeline preview
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent symptom logs
              Expanded(
                flex: 3,
                child: _WebCard(
                  title: 'Recent Symptom Logs',
                  child: symptomProvider.logs.isEmpty
                      ? const _WebEmptyState(message: 'No symptom logs yet')
                      : Column(
                          children: symptomProvider.logs
                              .take(5)
                              .map((log) => _WebLogRow(log: log))
                              .toList(),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Timeline preview
              Expanded(
                flex: 2,
                child: _WebCard(
                  title: 'Recent Activity',
                  child:
                      recordProvider.allRecords.isEmpty &&
                          symptomProvider.logs.isEmpty
                      ? const _WebEmptyState(message: 'No activity yet')
                      : Column(
                          children: [
                            ...symptomProvider.logs
                                .take(3)
                                .map(
                                  (log) => _WebActivityRow(
                                    icon: Icons.favorite_border,
                                    title: 'Symptom Log',
                                    subtitle: log.date.calendar,
                                    color: AppTheme.primary,
                                  ),
                                ),
                            ...recordProvider.allRecords
                                .take(2)
                                .map(
                                  (r) => _WebActivityRow(
                                    icon: Icons.folder_outlined,
                                    title: r.title,
                                    subtitle: r.recordDate.calendar,
                                    color: const Color(0xFF7B68EE),
                                  ),
                                ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebAiInsightsPage extends StatelessWidget {
  const _WebAiInsightsPage();

  @override
  Widget build(BuildContext context) {
    final insights = context.watch<AiInsightProvider>().savedInsights;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Health Insights',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.aiInsightInput),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Insight'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'AI-generated health pattern summaries based on your symptom logs.',
            style: TextStyle(color: context.textSecondary),
          ),

          const SizedBox(height: 16),
          const _WarningBox(
            icon: Icons.warning_amber_outlined,
            message:
                'These insights identify patterns for discussion '
                'with your doctor. They are not a diagnosis and '
                'do not replace medical advice.',
          ),
          const SizedBox(height: 24),

          if (insights.isEmpty)
            const _WebEmptyState(
              message:
                  'No AI insights yet — generate one from your symptom logs',
            )
          else
            ...insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WebCard(
                  title: '',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF26A69A,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.psychology_outlined,
                                  color: Color(0xFF26A69A),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'AI Health Insight',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            insight.createdAt.format('dd MMM yyyy, hh:mm a'),
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: context.border),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _WebInsightSection(
                                  icon: '📋',
                                  title: 'Summary',
                                  content: insight.summary,
                                ),
                                const SizedBox(height: 12),
                                _WebInsightSection(
                                  icon: '🔍',
                                  title: 'Pattern',
                                  content: insight.possiblePattern,
                                ),
                                const SizedBox(height: 12),
                                _WebInsightSection(
                                  icon: '💙',
                                  title: 'Care Guidance',
                                  content: insight.careGuidance,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '🩺',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Questions for Your Doctor',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...insight.doctorQuestions.map(
                                  (q) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '•  ',
                                          style: TextStyle(
                                            color: Color(0xFF26A69A),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            q,
                                            style: TextStyle(
                                              color: context.textSecondary,
                                              fontSize: 13,
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
                        ],
                      ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.border),
                        ),
                        child: Text(
                          insight.disclaimer,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WebInsightSection extends StatelessWidget {
  const _WebInsightSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  final String icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// Web Records Manager
class _WebRecordsManager extends StatelessWidget {
  const _WebRecordsManager();

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<HealthRecordProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Records',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.uploadRecord),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Upload Record'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (recordProvider.allRecords.isEmpty)
            const _WebEmptyState(message: 'No health records yet')
          else
            _WebCard(
              title: '',
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(
                      color: context.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    children: const [
                      _TableHeader(label: 'Title'),
                      _TableHeader(label: 'Type'),
                      _TableHeader(label: 'Date'),
                      _TableHeader(label: 'Doctor'),
                    ],
                  ),
                  // Rows
                  ...recordProvider.allRecords.map(
                    (record) => TableRow(
                      children: [
                        _TableCell(label: record.title, bold: true),
                        _TableCell(
                          label: record.recordType.replaceAll('_', ' '),
                        ),
                        _TableCell(
                          label: record.recordDate.format('dd MMM yyyy'),
                        ),
                        _TableCell(label: record.doctorName ?? '—'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Web Timeline Page
class _WebTimelinePage extends StatelessWidget {
  const _WebTimelinePage();

  @override
  Widget build(BuildContext context) {
    final symptomProvider = context.watch<SymptomProvider>();
    final recordProvider = context.watch<HealthRecordProvider>();
    final insightProvider = context.watch<AiInsightProvider>();
    final summaryProvider = context.watch<DoctorSummaryProvider>();

    final allEntries = [
      ...symptomProvider.logs.map(
        (l) => (
          date: l.date,
          title: 'Symptom Log',
          subtitle: 'Pain ${l.painLevel}/10 · ${l.mood}',
          icon: Icons.favorite_border,
          color: AppTheme.primary,
        ),
      ),
      ...recordProvider.allRecords.map(
        (r) => (
          date: r.recordDate,
          title: r.title,
          subtitle: r.recordType.replaceAll('_', ' '),
          icon: Icons.folder_outlined,
          color: const Color(0xFF7B68EE),
        ),
      ),
      ...insightProvider.savedInsights.map(
        (i) => (
          date: i.createdAt,
          title: 'AI Insight',
          subtitle: i.possiblePattern,
          icon: Icons.psychology_outlined,
          color: const Color(0xFF26A69A),
        ),
      ),
      ...summaryProvider.savedSummaries.map(
        (s) => (
          date: s.generatedAt,
          title: 'Doctor Summary',
          subtitle: '${s.questionsForDoctor.length} questions',
          icon: Icons.medical_services_outlined,
          color: const Color(0xFFEF6C00),
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Timeline',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          if (allEntries.isEmpty)
            const _WebEmptyState(message: 'No timeline entries yet')
          else
            _WebCard(
              title: '',
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(3),
                  3: FlexColumnWidth(2),
                },
                children: [
                  const TableRow(
                    children: [
                      _TableHeader(label: 'Type'),
                      _TableHeader(label: 'Title'),
                      _TableHeader(label: 'Details'),
                      _TableHeader(label: 'Date'),
                    ],
                  ),
                  ...allEntries.map(
                    (entry) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(entry.icon, color: entry.color, size: 18),
                        ),
                        _TableCell(label: entry.title, bold: true),
                        _TableCell(label: entry.subtitle),
                        _TableCell(label: entry.date.format('dd MMM yyyy')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Web Doctor Summary Page
class _WebDoctorSummaryPage extends StatelessWidget {
  const _WebDoctorSummaryPage();

  @override
  Widget build(BuildContext context) {
    final summaries = context.watch<DoctorSummaryProvider>().savedSummaries;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Doctor Visit Summaries',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.doctorSummary),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Summary'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (summaries.isEmpty)
            const _WebEmptyState(message: 'No doctor summaries yet')
          else
            ...summaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WebCard(
                  title: summary.generatedAt.format('dd MMM yyyy, hh:mm a'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.profileSnapshot,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Questions for Doctor',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...summary.questionsForDoctor.map(
                        (q) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(color: AppTheme.primary),
                              ),
                              Expanded(
                                child: Text(
                                  q,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.textSecondary,
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
              ),
            ),
        ],
      ),
    );
  }
}

// Web Privacy Page
class _WebPrivacyPage extends StatefulWidget {
  const _WebPrivacyPage();

  @override
  State<_WebPrivacyPage> createState() => _WebPrivacyPageState();
}

class _WebPrivacyPageState extends State<_WebPrivacyPage> {
  bool _hideSensitive = false;
  bool _genericNotifications = true;
  bool _confirmBeforeSharing = true;
  bool _familyAccess = false;
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
        final data = doc.data()!;
        setState(() {
          _hideSensitive = data['hideSensitiveDashboardDetails'] ?? false;
          _genericNotifications = data['useGenericNotificationText'] ?? true;
          _confirmBeforeSharing =
              data['requireConfirmationBeforeSharing'] ?? true;
          _familyAccess = data['familyProfileAccessEnabled'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load privacy settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      await FirebaseFirestore.instance
          .collection('privacySettings')
          .doc(userId)
          .set({
            'userId': userId,
            'hideSensitiveDashboardDetails': _hideSensitive,
            'useGenericNotificationText': _genericNotifications,
            'requireConfirmationBeforeSharing': _confirmBeforeSharing,
            'familyProfileAccessEnabled': _familyAccess,
            'updatedAt': DateTime.now().toIso8601String(),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings'),
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
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Privacy & Sharing Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Control how your health data is stored and shared.',
            style: TextStyle(color: context.textSecondary),
          ),
          const SizedBox(height: 32),

          // Two column layout — web appropriate
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: [
                    _WebCard(
                      title: 'Dashboard',
                      child: _WebPrivacyToggle(
                        title: 'Hide sensitive details',
                        subtitle:
                            'Hides period and symptom details '
                            'on the main dashboard',
                        value: _hideSensitive,
                        onChanged: (val) =>
                            setState(() => _hideSensitive = val),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _WebCard(
                      title: 'Notifications',
                      child: _WebPrivacyToggle(
                        title: 'Use generic notification text',
                        subtitle:
                            'Shows "You have a health reminder" '
                            'instead of specific health details',
                        value: _genericNotifications,
                        onChanged: (val) =>
                            setState(() => _genericNotifications = val),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Right column
              Expanded(
                child: Column(
                  children: [
                    _WebCard(
                      title: 'Sharing',
                      child: Column(
                        children: [
                          _WebPrivacyToggle(
                            title: 'Confirm before sharing',
                            subtitle:
                                'Always ask for confirmation '
                                'before sharing health records',
                            value: _confirmBeforeSharing,
                            onChanged: (val) =>
                                setState(() => _confirmBeforeSharing = val),
                          ),
                          Divider(color: context.border),
                          _WebPrivacyToggle(
                            title: 'Enable family profile access',
                            subtitle:
                                'Allow family section to access '
                                'shared health information',
                            value: _familyAccess,
                            onChanged: (val) =>
                                setState(() => _familyAccess = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Privacy notice
                    const _WarningBox(
                      icon: Icons.info_outline,
                      message:
                          'Generic notification text is ON by '
                          'default. Your health details are '
                          'never shown on your lock screen '
                          'unless you explicitly disable this.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).cardColor,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebPrivacyToggle extends StatelessWidget {
  const _WebPrivacyToggle({
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

// Shared Web Widgets
class _WebStatCard extends StatelessWidget {
  const _WebStatCard({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
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
      ),
    );
  }
}

class _WebCard extends StatelessWidget {
  const _WebCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class _WebLogRow extends StatelessWidget {
  const _WebLogRow({required this.log});
  final SymptomLog log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            log.date.calendar,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Pain ${log.painLevel}/10 · ${log.mood}',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _WebActivityRow extends StatelessWidget {
  const _WebActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebEmptyState extends StatelessWidget {
  const _WebEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(message, style: TextStyle(color: context.textSecondary)),
      ),
    );
  }
}

/// Amber warning/info callout box. Uses a muted amber tint in dark mode
/// instead of the bright light-mode yellow, so it doesn't glare.
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: fgColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: context.textSecondary,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.label, this.bold = false});
  final String label;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: bold ? context.textPrimary : context.textSecondary,
          fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}
