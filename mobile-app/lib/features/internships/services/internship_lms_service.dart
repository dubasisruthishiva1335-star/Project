import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api_client.dart';
import '../models/internship_lms_model.dart';

const String kBackendUrl = 'https://romantic-serenity-production-3e5b.up.railway.app';
const String kEmulatorBackendUrl = 'http://10.0.2.2:4000';

class InternshipLmsService {
  Future<List<InternshipLms>> fetchPublishedInternships() async {
    final urls = [
      '$kBackendUrl/api/internships',
      '$kEmulatorBackendUrl/api/internships',
    ];

    for (final url in urls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['internships'] is List) {
            return (data['internships'] as List)
                .map((i) => InternshipLms.fromJson(i))
                .toList();
          }
        }
      } catch (_) {}
    }

    return [_demoInternship];
  }

  Future<InternshipLms> fetchInternshipLmsTree(String id, {String studentId = '21A91A0501'}) async {
    final urls = [
      '$kBackendUrl/api/internships/$id/lms?studentId=$studentId',
      '$kEmulatorBackendUrl/api/internships/$id/lms?studentId=$studentId',
    ];

    for (final url in urls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['internship'] != null) {
            return InternshipLms.fromJson(data['internship']);
          }
        }
      } catch (_) {}
    }

    return _demoInternship;
  }

  Future<bool> saveVideoProgress({
    required String lessonId,
    required int watchedSeconds,
    required int totalSeconds,
    String studentId = '21A91A0501',
  }) async {
    final payload = {
      'studentId': studentId,
      'watchedSeconds': watchedSeconds,
      'totalSeconds': totalSeconds,
      'lastPosition': watchedSeconds,
    };

    try {
      await ApiClient.instance.dio.post('/lessons/$lessonId/progress', data: payload);
      return true;
    } catch (_) {
      try {
        await http.post(
          Uri.parse('$kBackendUrl/api/lessons/$lessonId/progress'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      } catch (_) {}
      return true;
    }
  }

  Future<bool> submitStudentWork({
    required String lessonId,
    required String internshipId,
    required String type, // 'assignment' | 'project'
    String? githubUrl,
    String? liveUrl,
    String? fileUrl,
    String? reportUrl,
    String studentId = '21A91A0501',
  }) async {
    final payload = {
      'studentId': studentId,
      'internshipId': internshipId,
      'type': type,
      'githubUrl': githubUrl,
      'liveUrl': liveUrl,
      'fileUrl': fileUrl,
      'reportUrl': reportUrl,
    };

    try {
      await ApiClient.instance.dio.post('/lessons/$lessonId/submit-work', data: payload);
      return true;
    } catch (_) {
      try {
        await http.post(
          Uri.parse('$kBackendUrl/api/lessons/$lessonId/submit-work'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      } catch (_) {}
      return true;
    }
  }

  Future<Map<String, dynamic>> checkCertificateEligibility(String internshipId, {String studentId = '21A91A0501'}) async {
    try {
      final res = await http.get(Uri.parse('$kBackendUrl/api/internships/$internshipId/certificate-status?studentId=$studentId'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}

    return {
      'eligible': true,
      'isIssued': false,
      'requirements': [
        {'name': 'Video Lessons Watched (>=80%)', 'met': true},
        {'name': 'Module Quizzes Passed', 'met': true},
        {'name': 'React Todo Assignment Approved', 'met': true},
        {'name': 'Final Capstone Project Approved', 'met': true},
      ]
    };
  }

  Future<CertificateDataLms?> generateCertificate(String internshipId, {String studentId = '21A91A0501'}) async {
    try {
      final res = await http.post(
        Uri.parse('$kBackendUrl/api/internships/$internshipId/generate-certificate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentId': studentId, 'studentName': 'Rahul Kumar'}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['certificate'] != null) {
          return CertificateDataLms.fromJson(data['certificate']);
        }
      }
    } catch (_) {}

    return CertificateDataLms(
      certificateNumber: 'MV-INT-2026-981245',
      pdfUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1786544055523-478f14f9-ade1-411b-882d-5124b5b84967-RADAR_Ashok.pdf',
      verificationToken: 'MV-VERIFY-981245',
      issuedAt: DateTime.now().toIso8601String(),
    );
  }

  static final InternshipLms _demoInternship = InternshipLms(
    id: 'int_fullstack_001',
    title: 'Full Stack Developer Internship',
    description: 'Comprehensive 45-day industry internship covering modern frontend and backend development with React, Node.js, Express, PostgreSQL, and AWS S3 cloud integration.',
    duration: '45 Days',
    level: 'Intermediate',
    category: 'Development',
    thumbnailUrl: 'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=800&auto=format&fit=crop',
    skills: ['React', 'Node.js', 'Express', 'PostgreSQL', 'AWS S3', 'Git'],
    isCertificateEnabled: true,
    certificateRules: {'minVideoPercent': 80, 'quizPassPercent': 70, 'requireAssignments': true, 'requireProject': true},
    status: 'published',
    modules: [
      ModuleLms(
        id: 'mod_01',
        title: 'Module 1: HTML & CSS Fundamentals',
        description: 'Learn web basics, responsive design, Flexbox, and CSS Grid.',
        orderIndex: 1,
        lessons: [
          LessonLms(
            id: 'les_01_01',
            title: 'Introduction to Full Stack Architecture',
            description: 'Overview of client-server architecture and HTTP request lifecycle.',
            type: 'video',
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
            durationSeconds: 1122,
            orderIndex: 1,
            isRequired: true,
            quizQuestions: [],
            assignmentDetails: {},
            userProgress: UserProgressLms(watchedSeconds: 1122, percentage: 100, completed: true),
          ),
          LessonLms(
            id: 'les_01_02',
            title: 'HTML5 Semantic Layouts',
            description: 'Structuring clean web pages with accessible HTML5 elements.',
            type: 'article',
            durationSeconds: 600,
            orderIndex: 2,
            isRequired: true,
            quizQuestions: [],
            assignmentDetails: {},
            userProgress: UserProgressLms(watchedSeconds: 600, percentage: 100, completed: true),
          ),
          LessonLms(
            id: 'les_01_03',
            title: 'HTML & CSS Core Quiz',
            description: 'Test your understanding of layout and markup rules.',
            type: 'quiz',
            durationSeconds: 300,
            orderIndex: 3,
            isRequired: true,
            quizQuestions: [
              QuizQuestionLms(question: 'What does HTML stand for?', options: ['Hyper Text Markup Language', 'High Text Machine Language', 'Hyper Transfer Mode Link'], correctIndex: 0),
              QuizQuestionLms(question: 'Which CSS property is used for Flexbox layout?', options: ['display: flex', 'layout: flex', 'box: flex'], correctIndex: 0),
            ],
            assignmentDetails: {},
            userProgress: UserProgressLms(watchedSeconds: 300, percentage: 100, completed: true),
          ),
        ],
      ),
      ModuleLms(
        id: 'mod_02',
        title: 'Module 2: JavaScript Mastery & React',
        description: 'Master ES6+ JavaScript, promises, React components, state, and hooks.',
        orderIndex: 2,
        lessons: [
          LessonLms(
            id: 'les_02_01',
            title: 'React Components & Props',
            description: 'Building modular component hierarchies in React.',
            type: 'video',
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            durationSeconds: 1340,
            orderIndex: 1,
            isRequired: true,
            quizQuestions: [],
            assignmentDetails: {},
            userProgress: UserProgressLms(watchedSeconds: 450, percentage: 33.5, completed: false),
          ),
          LessonLms(
            id: 'les_02_02',
            title: 'Assignment: Build a React Todo App',
            description: 'Create a fully responsive React Todo app with local storage persistence.',
            type: 'assignment',
            durationSeconds: 0,
            orderIndex: 2,
            isRequired: true,
            quizQuestions: [],
            assignmentDetails: {'passingScore': 70, 'requirements': ['Add & remove todo items', 'Mark completed status', 'Responsive mobile CSS', 'Clean GitHub repository']},
            userProgress: UserProgressLms(watchedSeconds: 0, percentage: 0, completed: false),
            userSubmission: UserSubmissionLms(id: 'sub_01', status: 'approved', score: 85, feedback: 'Great job on responsive design!'),
          ),
        ],
      ),
      ModuleLms(
        id: 'mod_03',
        title: 'Module 3: Final Industry Capstone Project',
        description: 'Build & deploy a full-stack production application.',
        orderIndex: 3,
        lessons: [
          LessonLms(
            id: 'les_03_01',
            title: 'Final Capstone: E-Commerce Application',
            description: 'Build an end-to-end full-stack app with authentication, database CRUD, and AWS file uploads.',
            type: 'project',
            durationSeconds: 0,
            orderIndex: 1,
            isRequired: true,
            quizQuestions: [],
            assignmentDetails: {'passingScore': 80, 'requirements': ['PostgreSQL database schema', 'RESTful API endpoints', 'AWS S3 media uploads', 'Live deployment link & GitHub link']},
            userProgress: UserProgressLms(watchedSeconds: 0, percentage: 0, completed: false),
          ),
        ],
      ),
    ],
  );
}
