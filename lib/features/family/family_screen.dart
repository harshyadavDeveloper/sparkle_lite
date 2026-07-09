import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/family_member.dart';
import 'family_member_detail_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<FamilyMember> _members = [];
  bool _isLoading = true;

  final _relationships = [
    'Partner',
    'Mother',
    'Father',
    'Sister',
    'Brother',
    'Daughter',
    'Son',
    'Other',
  ];

  final _ageRanges = [
    '0–12',
    '13–17',
    '18–25',
    '26–35',
    '36–45',
    '46–55',
    '55+',
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('familyMembers')
          .doc(userId)
          .collection('members')
          .get();

      setState(() {
        _members = snapshot.docs
            .map((doc) => FamilyMember.fromMap(doc.data()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddMemberSheet() {
    final nameController = TextEditingController();
    String? selectedRelationship;
    String selectedAgeRange = '26–35';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Family Member',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Basic info only — health details can be added after.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name or nickname *',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRelationship,
                decoration: const InputDecoration(labelText: 'Relationship *'),
                items: _relationships
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedRelationship = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedAgeRange,
                decoration: const InputDecoration(labelText: 'Age range'),
                items: _ageRanges
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedAgeRange = v!),
              ),
              const SizedBox(height: 20),

              // Privacy notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: Color(0xFF92610A),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Family health data is stored separately '
                        'from your personal health records. '
                        'They never mix.',
                        style: TextStyle(
                          color: Color(0xFF92610A),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      selectedRelationship == null) {
                    return;
                  }
                  await _addMember(
                    name: nameController.text.trim(),
                    relationship: selectedRelationship!,
                    ageRange: selectedAgeRange,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Add Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addMember({
    required String name,
    required String relationship,
    required String ageRange,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final member = FamilyMember(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      relationship: relationship,
      ageRange: ageRange,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('familyMembers')
        .doc(userId)
        .collection('members')
        .doc(member.id)
        .set(member.toMap());

    setState(() => _members.add(member));
  }

  Future<void> _deleteMember(FamilyMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.name} and all their health notes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('familyMembers')
        .doc(userId)
        .collection('members')
        .doc(member.id)
        .delete();

    setState(() => _members.remove(member));
  }

  Future<void> _navigateToDetail(FamilyMember member) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyMemberDetailScreen(member: member),
      ),
    );
    if (!mounted) return;
    await _loadMembers(); // refresh after edits
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Profiles')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddMemberSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _members.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('👨‍👩‍👧', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    'No family members yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add a family member',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Data separation banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Family health data is stored separately '
                          'from your personal records',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return _FamilyMemberCard(
                        member: member,
                        onTap: () => _navigateToDetail(member),
                        onDelete: () => _deleteMember(member),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({
    required this.member,
    required this.onTap,
    required this.onDelete,
  });

  final FamilyMember member;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEC407A).withValues(alpha: 0.1),
          child: Text(
            member.name[0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFEC407A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${member.relationship} · ${member.ageRange}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            if (member.conditions.isNotEmpty)
              Text(
                member.conditions.join(', '),
                style: const TextStyle(color: AppTheme.primary, fontSize: 11),
              ),
            if (member.medications.isNotEmpty)
              Text(
                '${member.medications.length} medication(s)',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
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
