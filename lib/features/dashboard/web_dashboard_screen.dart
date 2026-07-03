import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';
import 'package:sparkle_lite/core/utils/logger.dart';
import 'package:sparkle_lite/data/models/symptom_log.dart';
import '../../core/routing/app_router.dart';
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

  final List<_NavItem> _navItems = [
    const _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    const _NavItem(icon: Icons.folder_outlined, label: 'Records'),
    const _NavItem(icon: Icons.timeline_outlined, label: 'Timeline'),
    const _NavItem(
      icon: Icons.medical_services_outlined,
      label: 'Doctor Visit',
    ),
    const _NavItem(icon: Icons.privacy_tip_outlined, label: 'Privacy'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      context.read<ProfileProvider>().loadProfile(userId);
      context.read<SymptomProvider>().loadLogs(userId);
      context.read<HealthRecordProvider>().loadRecords(userId);
      context.read<AiInsightProvider>().loadInsights(userId);
      context.read<DoctorSummaryProvider>().loadSummaries(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    Logger.info('web dashboard build');
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _Sidebar(
            navItems: _navItems,
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
          ),
          // Vertical divider
          Container(width: 1, color: const Color(0xFFEEF0F3)),
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
        return const _WebDoctorSummaryPage();
      case 4:
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
      color: Colors.white,
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
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

          const Divider(height: 1),
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
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
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
          const Divider(height: 1),

          // Logout
          GestureDetector(
            onTap: () async {
              await auth.signOut();
              if (context.mounted) {
                await Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: AppTheme.textSecondary),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (profile != null)
            Text(
              profile.lifeStage,
              style: const TextStyle(color: AppTheme.textSecondary),
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
              const Text(
                'Health Records',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
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
                      color: AppTheme.background,
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
          const Text(
            'Health Timeline',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
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
              const Text(
                'Doctor Visit Summaries',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
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
              (summary) => _WebCard(
                title: summary.generatedAt.format('dd MMM yyyy, hh:mm a'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.profileSnapshot,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Questions for Doctor',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
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
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
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
        ],
      ),
    );
  }
}

// Web Privacy Page
class _WebPrivacyPage extends StatelessWidget {
  const _WebPrivacyPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy & Sharing Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Control how your health data is stored and shared.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          _WebCard(
            title: 'Privacy Settings',
            child: Navigator.of(context).canPop()
                ? const SizedBox.shrink()
                : const Text(
                    'Manage your privacy settings from the mobile app '
                    'or use the dedicated privacy screen.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.privacySettings),
            child: const Text('Open Privacy Settings'),
          ),
        ],
      ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF0F3)),
          boxShadow: [
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
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.textPrimary,
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
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
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

class _WebEmptyState extends StatelessWidget {
  const _WebEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
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
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppTheme.textSecondary,
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
          color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}
