import 'package:flutter/material.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/health_record.dart';

class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.record});
  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(record.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Type',
              value: record.recordType.replaceAll('_', ' ').toUpperCase(),
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Record Date',
              value: record.recordDate.format('dd MMM yyyy'),
            ),
            if (record.doctorName != null)
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Doctor / Clinic',
                value: record.doctorName!,
              ),
            _DetailRow(
              icon: Icons.access_time_outlined,
              label: 'Uploaded',
              value: record.createdAt.timeAgo,
            ),
            if (record.notes != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE3EA)),
                ),
                child: Text(
                  record.notes!,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
            if (record.fileUrl != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // URL launcher can be added as bonus
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('View File'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
