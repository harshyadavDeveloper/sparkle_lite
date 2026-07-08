import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_date_formatter/smart_date_formatter.dart';
import 'package:sparkle_lite/data/models/health_record.dart';
import '../../core/theme/app_theme.dart';
import 'health_record_provider.dart';

class UploadRecordScreen extends StatefulWidget {
  final HealthRecord? existingRecord;
  final String? userIdOverride; // for testing only
  const UploadRecordScreen({
    super.key,
    this.existingRecord,
    this.userIdOverride,
  });

  @override
  State<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();

  String? _recordType;
  String? _recordTypeError;
  DateTime _recordDate = DateTime.now();
  File? _selectedFile;
  String? _selectedFileName;

  final List<Map<String, String>> _recordTypes = [
    {'value': 'lab_report', 'label': 'Lab Report'},
    {'value': 'prescription', 'label': 'Prescription'},
    {'value': 'scan', 'label': 'Scan Report'},
    {'value': 'doctor_note', 'label': 'Doctor Visit Note'},
    {'value': 'vaccination', 'label': 'Vaccination Record'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _titleController.text = record.title;
      _doctorController.text = record.doctorName ?? '';
      _notesController.text = record.notes ?? '';
      _recordType = record.recordType;
      _recordDate = record.recordDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _recordDate = picked);
  }

  bool _isImageFile(String? fileName) {
    if (fileName == null) return false;
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _recordTypeError = _recordType == null
          ? 'Please select a record type'
          : null;
    });

    final formValid = _formKey.currentState!.validate();
    if (!formValid || _recordTypeError != null) return;

    final userId =
        widget.userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final provider = context.read<HealthRecordProvider>();
    final isEditing = widget.existingRecord != null;

    bool success;

    if (isEditing) {
      success = await provider.updateRecord(
        userId: userId,
        recordId: widget.existingRecord!.id,
        title: _titleController.text.trim(),
        recordType: _recordType!,
        recordDate: _recordDate,
        doctorName: _doctorController.text.trim().isEmpty
            ? null
            : _doctorController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        existingFileUrl: widget.existingRecord!.fileUrl,
        existingLocalPath: widget.existingRecord!.localFilePath,
        newFile: _selectedFile,
      );
    } else {
      success = await provider.addRecord(
        userId: userId,
        title: _titleController.text.trim(),
        recordType: _recordType!,
        recordDate: _recordDate,
        doctorName: _doctorController.text.trim().isEmpty
            ? null
            : _doctorController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        file: _selectedFile,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Record updated ✓' : 'Record saved ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Something went wrong'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthRecordProvider>();
    final isUploading = provider.status == RecordStatus.uploading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingRecord != null
              ? 'Edit Health Record'
              : 'Upload Health Record',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const _SectionLabel(label: 'Report Title *'),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Blood Test Report',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 20),

              // Record Type
              const _SectionLabel(label: 'Record Type *'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _recordTypes.map((type) {
                  return ChoiceChip(
                    label: Text(type['label']!),
                    selected: _recordType == type['value'],
                    onSelected: (_) => setState(() {
                      _recordType = type['value'];
                      _recordTypeError = null;
                    }),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              if (_recordTypeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _recordTypeError!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),

              // Date
              const _SectionLabel(label: 'Record Date *'),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE3EA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _recordDate.isToday
                            ? 'Today'
                            : _recordDate.isYesterday
                            ? 'Yesterday'
                            : _recordDate.format('dd MMM yyyy'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Doctor Name (optional)
              const _SectionLabel(label: 'Doctor / Clinic Name (optional)'),
              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Dr. Rao, City Clinic',
                ),
              ),
              const SizedBox(height: 20),

              // File Upload
              const _SectionLabel(label: 'Attach File (optional)'),
              if (widget.existingRecord?.fileUrl != null &&
                  _selectedFile == null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.success),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'File already attached — tap below to replace',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Show existing image preview if local path available
                if (widget.existingRecord?.localFilePath != null &&
                    _isImageFile(widget.existingRecord!.localFilePath)) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.existingRecord!.localFilePath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Replace file button
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.upload_file_outlined,
                    color: AppTheme.primary,
                  ),
                  label: const Text(
                    'Replace file',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
              ] else ...[
                // Normal file picker (new record or after picking new file)
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedFile != null
                            ? AppTheme.primary
                            : const Color(0xFFDDE3EA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedFile != null
                              ? Icons.check_circle_outline
                              : Icons.upload_file_outlined,
                          color: _selectedFile != null
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedFileName ?? 'Tap to upload PDF or image',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedFile != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedFile != null)
                          GestureDetector(
                            onTap: () => setState(() {
                              _selectedFile = null;
                              _selectedFileName = null;
                            }),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // New file image preview
                if (_selectedFile != null &&
                    _isImageFile(_selectedFileName)) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedFile!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 20),

              // Notes (optional)
              const _SectionLabel(label: 'Notes (optional)'),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any additional notes...',
                ),
              ),
              const SizedBox(height: 32),

              // Upload progress indicator
              if (isUploading) ...[
                const LinearProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Uploading your record...',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              ElevatedButton(
                onPressed: isUploading ? null : _save,
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Record'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
