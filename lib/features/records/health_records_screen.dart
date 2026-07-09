import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';

import '../../core/theme/app_colors_ext.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/health_record.dart';
import 'health_record_provider.dart';
import 'record_detail_screen.dart';
import 'upload_record_screen.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<HealthRecordProvider>().loadRecords(userId);
      }
    });
  }

  final Map<String, String> _typeLabels = {
    'lab_report': 'Lab Report',
    'prescription': 'Prescription',
    'scan': 'Scan',
    'doctor_note': 'Doctor Note',
    'vaccination': 'Vaccination',
    'other': 'Other',
  };

  final Map<String, IconData> _typeIcons = {
    'lab_report': Icons.science_outlined,
    'prescription': Icons.medication_outlined,
    'scan': Icons.image_outlined,
    'doctor_note': Icons.note_outlined,
    'vaccination': Icons.vaccines_outlined,
    'other': Icons.folder_outlined,
  };

  Future<void> _confirmDelete(BuildContext context, HealthRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
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
        await context.read<HealthRecordProvider>().deleteRecord(
          userId,
          record.id,
        );
      }
    }
  }

  Future<void> _navigateToEdit(HealthRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadRecordScreen(existingRecord: record),
      ),
    );

    if (!mounted) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await context.read<HealthRecordProvider>().loadRecords(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthRecordProvider>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Health Records')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadRecordScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter chips
          if (provider.status == RecordStatus.loaded ||
              provider.records.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: provider.activeFilter == null,
                    onTap: () => provider.setFilter(null),
                  ),
                  ..._typeLabels.entries.map(
                    (e) => _FilterChip(
                      label: e.value,
                      selected: provider.activeFilter == e.key,
                      onTap: () => provider.setFilter(e.key),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody(context, provider)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, HealthRecordProvider provider) {
    if (provider.status == RecordStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (provider.status == RecordStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Something went wrong',
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  context.read<HealthRecordProvider>().loadRecords(userId);
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (!provider.hasRecords) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗂️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No health records yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to upload your first record',
              style: TextStyle(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    if (provider.records.isEmpty && provider.activeFilter != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No ${_typeLabels[provider.activeFilter]} records found',
              style: TextStyle(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.records.length,
      itemBuilder: (context, index) {
        final record = provider.records[index];
        return _RecordCard(
          record: record,
          icon: _typeIcons[record.recordType] ?? Icons.folder_outlined,
          typeLabel: _typeLabels[record.recordType] ?? 'Other',
          onDelete: () => _confirmDelete(context, record),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecordDetailScreen(record: record),
            ),
          ),
          onEdit: () => _navigateToEdit(record),
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.icon,
    required this.typeLabel,
    required this.onDelete,
    required this.onTap,
    required this.onEdit,
  });

  final HealthRecord record;
  final IconData icon;
  final String typeLabel;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(
              alpha: context.isDarkMode ? 0.2 : 0.1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(
          record.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              typeLabel,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  record.recordDate.calendar,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: record.recordDate.format('dd MMM yyyy'),
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(
                    Icons.info_outline,
                    size: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primary,
                size: 20,
              ),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
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
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : context.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : context.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
