import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StudentProfile {
  final String id;
  final String fullName;
  final String email;
  final String usn;
  final String college;
  final String branch;
  final int semester;
  final String avatarUrl;

  StudentProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.usn,
    required this.college,
    required this.branch,
    required this.semester,
    required this.avatarUrl,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _storage = const FlutterSecureStorage();
  StudentProfile? _currentStudent;

  StudentProfile get currentStudent => _currentStudent ?? StudentProfile(
    id: 'student_1042',
    fullName: 'Abhimanu S.',
    email: 'abhimanu.s@myvault.edu',
    usn: '2026-ECE-1042',
    college: 'College of Engineering & Technology',
    branch: 'ECE',
    semester: 1,
    avatarUrl: '',
  );

  bool get isAuthenticated => true;

  Future<void> signInWithGoogle() async {
    // Simulated Google OAuth authentication flow
    _currentStudent = StudentProfile(
      id: 'student_${DateTime.now().millisecondsSinceEpoch}',
      fullName: 'Abhimanu S.',
      email: 'abhimanu.s@myvault.edu',
      usn: '2026-ECE-1042',
      college: 'College of Engineering & Technology',
      branch: 'ECE',
      semester: 1,
      avatarUrl: '',
    );
    await _storage.write(key: 'jwt_auth_token', value: 'jwt_mock_token_myvault_2026');
  }

  Future<void> signOut() async {
    await _storage.delete(key: 'jwt_auth_token');
  }
}
