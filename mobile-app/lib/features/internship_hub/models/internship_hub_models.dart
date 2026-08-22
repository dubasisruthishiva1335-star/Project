class CourseModel {
  final String id;
  final String title;
  final String category;
  final String level;
  final String duration;
  final int lessonsCount;
  final bool isFree;
  final String description;
  final List<String> learnings;
  final String? fileUrl;

  CourseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.duration,
    required this.lessonsCount,
    required this.isFree,
    required this.description,
    required this.learnings,
    this.fileUrl,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Course Title',
      category: json['category'] ?? 'Mobile',
      level: json['level'] ?? 'Beginner',
      duration: json['duration'] ?? '8 Hours',
      lessonsCount: json['lessonsCount'] ?? 6,
      isFree: json['isFree'] ?? true,
      description: json['description'] ?? '',
      learnings: List<String>.from(json['learnings'] ?? []),
      fileUrl: json['fileUrl'],
    );
  }
}

class OpportunityModel {
  final String id;
  final String title;
  final String company;
  final String type;
  final String branch;
  final String? stipend;
  final String? location;
  final String? deadline;
  final String? description;
  final String applyUrl;
  final String? fileUrl;
  final String postedAt;

  OpportunityModel({
    required this.id,
    required this.title,
    required this.company,
    required this.type,
    required this.branch,
    this.stipend,
    this.location,
    this.deadline,
    this.description,
    required this.applyUrl,
    this.fileUrl,
    required this.postedAt,
  });

  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    return OpportunityModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Position',
      company: json['company'] ?? 'Company',
      type: json['type'] ?? 'INTERNSHIP',
      branch: json['branch'] ?? 'All Branches',
      stipend: json['stipend'],
      location: json['location'],
      deadline: json['deadline'],
      description: json['description'],
      applyUrl: json['applyUrl'] ?? json['apply_url'] ?? 'https://myvault-project.vercel.app',
      fileUrl: json['fileUrl'] ?? json['file_url'],
      postedAt: json['postedAt'] ?? json['posted_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class CertificateModel {
  final String id;
  final String studentName;
  final String courseTitle;
  final String certificateNumber;
  final String pdfUrl;
  final String issuedAt;

  CertificateModel({
    required this.id,
    required this.studentName,
    required this.courseTitle,
    required this.certificateNumber,
    required this.pdfUrl,
    required this.issuedAt,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'] ?? '',
      studentName: json['studentName'] ?? 'Rahul Kumar',
      courseTitle: json['title'] ?? json['courseTitle'] ?? 'Industrial Development',
      certificateNumber: json['certificateNumber'] ?? 'IH-2026-00125',
      pdfUrl: json['pdfUrl'] ?? 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
      issuedAt: json['issuedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
