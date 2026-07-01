import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/symptom_log.dart';
import 'add_symptom_screen.dart';
import 'symptom_provider.dart';

class SymptomHistoryScreen extends StatefulWidget {
  const SymptomHistoryScreen({super.key});

  @override
  State<SymptomHistoryScreen> createState() => _SymptomHistoryScreenState();
}

class _SymptomHistoryScreenState extends State<SymptomHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<SymptomProvider>().loadLogs(userId);
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, SymptomLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text(
          'Are you sure you want to delete this symptom log?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await context.read<SymptomProvider>().deleteLog(userId, log.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SymptomProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Symptom History')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSymptomScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, SymptomProvider provider) {
    // Loading state
    if (provider.status == SymptomStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    // Error state
    if (provider.status == SymptomStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  context.read<SymptomProvider>().loadLogs(userId);
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (!provider.hasLogs) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌸', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'No symptom logs yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to log your first symptom entry',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Loaded state
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.logs.length,
      itemBuilder: (context, index) {
        final log = provider.logs[index];
        return _SymptomLogCard(
          log: log,
          onDelete: () => _confirmDelete(context, log),
        );
      },
    );
  }
}

class _SymptomLogCard extends StatelessWidget {
  const _SymptomLogCard({required this.log, required this.onDelete});

  final SymptomLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      log.date.calendar,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: log.date.format('dd MMM yyyy'),
                      triggerMode: TooltipTriggerMode.tap,
                      decoration: BoxDecoration(
                        color: AppTheme.textPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.error,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _InfoChip(label: 'Pain: ${log.painLevel}/10'),
                _InfoChip(label: log.mood),
                _InfoChip(label: log.flowLevel),
                ...log.symptoms.map((s) => _InfoChip(label: s)),
              ],
            ),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                log.notes!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
