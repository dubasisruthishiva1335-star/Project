import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../services/auth_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late StudentProfile _student;
  bool _editing = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usnCtrl;
  late final TextEditingController _collegeCtrl;
  late String _branch;
  late int _semester;
  bool _saving = false;

  final List<String> _branches = ['CSE', 'ECE', 'AI_ML', 'EEE', 'MECH', 'CIVIL', 'GENERAL'];

  @override
  void initState() {
    super.initState();
    _student = AuthService.instance.currentStudent;
    _nameCtrl = TextEditingController(text: _student.fullName);
    _usnCtrl = TextEditingController(text: _student.usn);
    _collegeCtrl = TextEditingController(text: _student.college);
    _branch = _student.branch;
    _semester = _student.semester;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usnCtrl.dispose();
    _collegeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    final updated = StudentProfile(
      id: _student.id,
      fullName: _nameCtrl.text.trim(),
      email: _student.email,
      usn: _usnCtrl.text.trim().toUpperCase(),
      college: _collegeCtrl.text.trim(),
      branch: _branch,
      semester: _semester,
      avatarUrl: _student.avatarUrl,
    );

    // Save profile via AuthService
    await AuthService.instance.registerWithEmail(
      fullName: updated.fullName,
      email: updated.email,
      password: '',
      usn: updated.usn,
      branch: updated.branch,
      semester: updated.semester,
      college: updated.college,
    );

    setState(() {
      _student = updated;
      _editing = false;
      _saving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Student Profile updated successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to sign out of your MyVault account?',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Student Profile & Vault ID',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined, color: const Color(0xFF00F2FE)),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3D Digital Student ID Badge Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: University Logo & Chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00F2FE).withValues(alpha: 0.2),
                              ),
                              child: const Icon(Icons.account_balance_rounded, color: Color(0xFF00F2FE), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('MYVAULT SCHOLAR ID', style: TextStyle(color: Color(0xFF00F2FE), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                Text(_student.college, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                              SizedBox(width: 4),
                              Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Student Name & USN
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: MyVaultColors.metalGlossGradient,
                            border: Border.all(color: const Color(0xFF00F2FE), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _student.fullName.isNotEmpty ? _student.fullName[0].toUpperCase() : 'S',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _student.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _student.usn,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF00F2FE), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _student.email,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Tags: Branch & Semester
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A26),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            'Branch: ${_student.branch}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A26),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            'Semester ${_student.semester}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Edit Mode or Info View
              if (_editing) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A26),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Profile Details', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Name
                      const Text('FULL NAME', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0B0E14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // USN
                      const Text('USN / ROLL NO.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usnCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0B0E14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Branch & Semester
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('BRANCH', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(color: const Color(0xFF0B0E14), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E293B))),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _branch,
                                      dropdownColor: const Color(0xFF131A26),
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => _branch = v);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SEMESTER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(color: const Color(0xFF0B0E14), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E293B))),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _semester,
                                      dropdownColor: const Color(0xFF131A26),
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text('Sem $s'))).toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => _semester = v);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F2FE),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _saving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Text('Save Profile Updates', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Vault Storage & Security Overview
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A26),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vault Features & Cloud Storage', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      _infoRow(Icons.cloud_done_rounded, 'AWS S3 Permanent Storage', 'Enabled (eu-north-1)'),
                      _infoRow(Icons.lock_outline_rounded, 'Document Vault Encryption', 'AES-256 Enabled'),
                      _infoRow(Icons.verified_user_rounded, 'Firebase Auth Sync', 'Connected (myvault-9d7f3)'),
                      _infoRow(Icons.sync_rounded, 'Real-Time Semester Filter', 'Synced with Admin Portal'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Account Actions
              OutlinedButton.icon(
                onPressed: () => context.push('/auth'),
                icon: const Icon(Icons.switch_account_rounded, size: 18, color: Color(0xFF00F2FE)),
                label: const Text('Switch Account / Sign In with Another Email', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF131A26),
                  side: const BorderSide(color: Color(0xFF1E293B)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                label: const Text('Sign Out of MyVault', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00F2FE), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
