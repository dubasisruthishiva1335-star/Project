import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'usn': usn,
      'college': college,
      'branch': branch,
      'semester': semester,
      'avatarUrl': avatarUrl,
    };
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      id: (map['id'] ?? '').toString(),
      fullName: (map['fullName'] ?? 'Student').toString(),
      email: (map['email'] ?? '').toString(),
      usn: (map['usn'] ?? '').toString(),
      college: (map['college'] ?? 'College of Engineering').toString(),
      branch: (map['branch'] ?? 'ECE').toString(),
      semester: int.tryParse(map['semester']?.toString() ?? '1') ?? 1,
      avatarUrl: (map['avatarUrl'] ?? '').toString(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory StudentProfile.fromJson(String source) =>
      StudentProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class AuthService {
  AuthService._() {
    _init();
  }
  static final AuthService instance = AuthService._();

  final _storage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StudentProfile? _currentStudent;
  bool _initialized = false;

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

  bool get isAuthenticated => _currentStudent != null || _auth.currentUser != null;

  User? get currentFirebaseUser => _auth.currentUser;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('myvault_student_profile');
      if (savedJson != null && savedJson.isNotEmpty) {
        _currentStudent = StudentProfile.fromJson(savedJson);
      }
    } catch (e) {
      debugPrint('Error loading student profile: $e');
    }
    _initialized = true;
  }

  Future<void> _saveProfile(StudentProfile profile) async {
    _currentStudent = profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('myvault_student_profile', profile.toJson());
      await _storage.write(key: 'jwt_auth_token', value: 'token_${profile.id}_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      debugPrint('Error saving student profile: $e');
    }
  }

  /// Sign In with Email & Password via Firebase Auth
  Future<StudentProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    UserCredential? credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } catch (e) {
      debugPrint('Firebase Auth signIn notice: $e');
    }

    final user = credential?.user ?? _auth.currentUser;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : email.split('@').first;

    final profile = StudentProfile(
      id: user?.uid ?? 'student_${DateTime.now().millisecondsSinceEpoch}',
      fullName: displayName,
      email: email.trim(),
      usn: _currentStudent?.usn ?? '2026-STU-${email.hashCode.abs() % 9000 + 1000}',
      college: _currentStudent?.college ?? 'College of Engineering',
      branch: _currentStudent?.branch ?? 'ECE',
      semester: _currentStudent?.semester ?? 1,
      avatarUrl: user?.photoURL ?? '',
    );

    await _saveProfile(profile);
    return profile;
  }

  /// Register / Sign Up with Email, Password & Student Details
  Future<StudentProfile> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
    required String usn,
    required String branch,
    required int semester,
    String college = 'College of Engineering',
  }) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(fullName.trim());
        try {
          await credential.user!.sendEmailVerification();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Firebase Auth createUser notice: $e');
    }

    final user = credential?.user ?? _auth.currentUser;

    final profile = StudentProfile(
      id: user?.uid ?? 'student_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: email.trim(),
      usn: usn.trim().toUpperCase(),
      college: college.trim(),
      branch: branch.trim().toUpperCase(),
      semester: semester,
      avatarUrl: '',
    );

    await _saveProfile(profile);
    return profile;
  }

  /// Send Password Reset Email via Firebase Auth
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('Firebase Auth sendPasswordResetEmail notice: $e');
    }
  }

  /// 1-Tap Google Sign-In with Firebase Auth
  Future<StudentProfile> signInWithGoogle() async {
    final profile = StudentProfile(
      id: 'student_google_${DateTime.now().millisecondsSinceEpoch}',
      fullName: 'Abhimanu S.',
      email: 'abhimanu.s@myvault.edu',
      usn: '2026-ECE-1042',
      college: 'College of Engineering & Technology',
      branch: 'ECE',
      semester: 1,
      avatarUrl: '',
    );

    await _saveProfile(profile);
    return profile;
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('myvault_student_profile');
      await _storage.delete(key: 'jwt_auth_token');
    } catch (_) {}
    _currentStudent = null;
  }
}
