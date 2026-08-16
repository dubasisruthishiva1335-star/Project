class QuizQuestionLms {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestionLms({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestionLms.fromJson(Map<String, dynamic> json) => QuizQuestionLms(
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correctIndex: json['correctIndex'] ?? 0,
      );
}

class UserProgressLms {
  final int watchedSeconds;
  final double percentage;
  final bool completed;

  UserProgressLms({
    required this.watchedSeconds,
    required this.percentage,
    required this.completed,
  });

  factory UserProgressLms.fromJson(Map<String, dynamic> json) => UserProgressLms(
        watchedSeconds: json['watchedSeconds'] ?? 0,
        percentage: (json['percentage'] as num? ?? 0).toDouble(),
        completed: json['completed'] ?? false,
      );
}

class UserSubmissionLms {
  final String id;
  final String status; // 'pending' | 'approved' | 'rejected'
  final int? score;
  final String? feedback;
  final String? githubUrl;
  final String? liveUrl;

  UserSubmissionLms({
    required this.id,
    required this.status,
    this.score,
    this.feedback,
    this.githubUrl,
    this.liveUrl,
  });

  factory UserSubmissionLms.fromJson(Map<String, dynamic> json) => UserSubmissionLms(
        id: json['id'] ?? '',
        status: json['status'] ?? 'pending',
        score: json['score'],
        feedback: json['feedback'],
        githubUrl: json['githubUrl'],
        liveUrl: json['liveUrl'],
      );
}

class LessonLms {
  final String id;
  final String title;
  final String? description;
  final String type; // 'video' | 'pdf' | 'article' | 'quiz' | 'assignment' | 'project'
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? pdfUrl;
  final int durationSeconds;
  final int orderIndex;
  final bool isRequired;
  final List<QuizQuestionLms> quizQuestions;
  final Map<String, dynamic> assignmentDetails;
  final UserProgressLms userProgress;
  final UserSubmissionLms? userSubmission;

  LessonLms({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.videoUrl,
    this.thumbnailUrl,
    this.pdfUrl,
    required this.durationSeconds,
    required this.orderIndex,
    required this.isRequired,
    required this.quizQuestions,
    required this.assignmentDetails,
    required this.userProgress,
    this.userSubmission,
  });

  factory LessonLms.fromJson(Map<String, dynamic> json) => LessonLms(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Lesson',
        description: json['description'],
        type: json['type'] ?? 'video',
        videoUrl: json['videoUrl'],
        thumbnailUrl: json['thumbnailUrl'],
        pdfUrl: json['pdfUrl'],
        durationSeconds: json['durationSeconds'] ?? 0,
        orderIndex: json['orderIndex'] ?? 1,
        isRequired: json['isRequired'] ?? true,
        quizQuestions: (json['quizQuestions'] as List? ?? [])
            .map((q) => QuizQuestionLms.fromJson(q))
            .toList(),
        assignmentDetails: json['assignmentDetails'] as Map<String, dynamic>? ?? {},
        userProgress: json['userProgress'] != null
            ? UserProgressLms.fromJson(json['userProgress'])
            : UserProgressLms(watchedSeconds: 0, percentage: 0, completed: false),
        userSubmission: json['userSubmission'] != null
            ? UserSubmissionLms.fromJson(json['userSubmission'])
            : null,
      );
}

class ModuleLms {
  final String id;
  final String title;
  final String? description;
  final int orderIndex;
  final List<LessonLms> lessons;

  ModuleLms({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
    required this.lessons,
  });

  factory ModuleLms.fromJson(Map<String, dynamic> json) => ModuleLms(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Module',
        description: json['description'],
        orderIndex: json['orderIndex'] ?? 1,
        lessons: (json['lessons'] as List? ?? [])
            .map((l) => LessonLms.fromJson(l))
            .toList(),
      );
}

class InternshipLms {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String level;
  final String category;
  final String? thumbnailUrl;
  final List<String> skills;
  final bool isCertificateEnabled;
  final Map<String, dynamic> certificateRules;
  final String status;
  final List<ModuleLms> modules;

  InternshipLms({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.level,
    required this.category,
    this.thumbnailUrl,
    required this.skills,
    required this.isCertificateEnabled,
    required this.certificateRules,
    required this.status,
    required this.modules,
  });

  factory InternshipLms.fromJson(Map<String, dynamic> json) => InternshipLms(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Internship',
        description: json['description'] ?? '',
        duration: json['duration'] ?? '45 Days',
        level: json['level'] ?? 'Beginner',
        category: json['category'] ?? 'Development',
        thumbnailUrl: json['thumbnailUrl'],
        skills: List<String>.from(json['skills'] ?? []),
        isCertificateEnabled: json['isCertificateEnabled'] ?? true,
        certificateRules: json['certificateRules'] as Map<String, dynamic>? ?? {},
        status: json['status'] ?? 'published',
        modules: (json['modules'] as List? ?? [])
            .map((m) => ModuleLms.fromJson(m))
            .toList(),
      );
}

class CertificateDataLms {
  final String certificateNumber;
  final String pdfUrl;
  final String verificationToken;
  final String issuedAt;

  CertificateDataLms({
    required this.certificateNumber,
    required this.pdfUrl,
    required this.verificationToken,
    required this.issuedAt,
  });

  factory CertificateDataLms.fromJson(Map<String, dynamic> json) => CertificateDataLms(
        certificateNumber: json['certificateNumber'] ?? '',
        pdfUrl: json['pdfUrl'] ?? '',
        verificationToken: json['verificationToken'] ?? '',
        issuedAt: json['issuedAt'] ?? '',
      );
}
