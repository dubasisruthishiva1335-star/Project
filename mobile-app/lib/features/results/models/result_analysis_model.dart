class ExtractedSubject {
  final String? subjectCode;
  final String subjectName;
  final double credits;
  final double? maxMarks;
  final double? obtainedMarks;
  final String? grade;
  final double? gradePoints;
  final bool isBacklog;

  ExtractedSubject({
    this.subjectCode,
    required this.subjectName,
    required this.credits,
    this.maxMarks,
    this.obtainedMarks,
    this.grade,
    this.gradePoints,
    required this.isBacklog,
  });

  factory ExtractedSubject.fromJson(Map<String, dynamic> json) => ExtractedSubject(
        subjectCode: json['subjectCode'],
        subjectName: json['subjectName'] ?? 'Unknown Subject',
        credits: (json['credits'] ?? 0).toDouble(),
        maxMarks: json['maxMarks']?.toDouble(),
        obtainedMarks: json['obtainedMarks']?.toDouble(),
        grade: json['grade'],
        gradePoints: json['gradePoints']?.toDouble(),
        isBacklog: json['isBacklog'] ?? false,
      );
}

class GpaTrendPoint {
  final String semester;
  final double sgpa;

  GpaTrendPoint({required this.semester, required this.sgpa});

  factory GpaTrendPoint.fromJson(Map<String, dynamic> json) => GpaTrendPoint(
        semester: json['semester'] ?? '',
        sgpa: (json['sgpa'] as num).toDouble(),
      );
}

enum AnalysisSource { visionOcr, claudeAi, onDeviceOcr, mock }

AnalysisSource _sourceFromString(String s) {
  switch (s) {
    case 'vision_ocr':
      return AnalysisSource.visionOcr;
    case 'claude_ai':
      return AnalysisSource.claudeAi;
    case 'on_device_ocr':
      return AnalysisSource.onDeviceOcr;
    default:
      return AnalysisSource.mock;
  }
}

class ResultAnalysis {
  final String uploadId;
  final bool needsReview;
  final String? semester;
  final List<ExtractedSubject> subjects;
  final double? sgpa;
  final double? cgpa;
  final int totalBacklogs;
  final List<GpaTrendPoint> trend;
  final AnalysisSource source;
  final double confidence;

  ResultAnalysis({
    required this.uploadId,
    required this.needsReview,
    required this.semester,
    required this.subjects,
    required this.sgpa,
    required this.cgpa,
    required this.totalBacklogs,
    required this.trend,
    required this.source,
    required this.confidence,
  });

  factory ResultAnalysis.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? {};
    return ResultAnalysis(
      uploadId: json['uploadId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      needsReview: json['status'] == 'needs_review',
      semester: analysis['semester'],
      subjects: (analysis['subjects'] as List? ?? [])
          .map((s) => ExtractedSubject.fromJson(s))
          .toList(),
      sgpa: analysis['sgpa']?.toDouble(),
      cgpa: json['cgpa']?.toDouble(),
      totalBacklogs: json['totalBacklogs'] ?? 0,
      trend: (json['trend'] as List? ?? [])
          .map((t) => GpaTrendPoint.fromJson(t))
          .toList(),
      source: _sourceFromString(analysis['source'] ?? 'mock'),
      confidence: (analysis['confidence'] as num? ?? 1.0).toDouble(),
    );
  }
}
