import 'dart:typed_data';

enum FileCategory { image, pdf, docx, csv, sheet, text, unknown }

enum AnalysisStatus { queued, working, done, error }

class ContentDetectedItem {
  final String label;
  final String value;
  ContentDetectedItem(this.label, this.value);

  factory ContentDetectedItem.fromJson(Map<String, dynamic> j) =>
      ContentDetectedItem((j['label'] ?? '').toString(), (j['value'] ?? '').toString());
}

class AnalysisResult {
  final String? summary;
  final List<ContentDetectedItem> contentDetected;
  final String? extractedText;
  final Map<String, dynamic>? structure;
  final List<String> recommendations;
  final int? confidence;

  AnalysisResult({
    this.summary,
    this.contentDetected = const [],
    this.extractedText,
    this.structure,
    this.recommendations = const [],
    this.confidence,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> j) {
    return AnalysisResult(
      summary: j['summary']?.toString(),
      contentDetected: (j['contentDetected'] as List<dynamic>? ?? [])
          .map((e) => ContentDetectedItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      extractedText: j['extractedText']?.toString(),
      structure: j['structure'] is Map ? Map<String, dynamic>.from(j['structure'] as Map) : null,
      recommendations: (j['recommendations'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      confidence: j['confidence'] is int
          ? j['confidence'] as int
          : (j['confidence'] is double ? (j['confidence'] as double).round() : null),
    );
  }
}

class AnalyzedFile {
  final String id;
  final String name;
  final int sizeBytes;
  final Uint8List bytes;
  final FileCategory category;
  AnalysisStatus status;
  AnalysisResult? result;
  String? error;

  AnalyzedFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.bytes,
    required this.category,
    this.status = AnalysisStatus.queued,
    this.result,
    this.error,
  });
}
