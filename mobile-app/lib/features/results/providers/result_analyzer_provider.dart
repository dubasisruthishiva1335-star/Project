import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/result_analysis_model.dart';
import '../../../core/api_client.dart';

enum AnalyzerStage { idle, quickScan, uploading, analyzing, done, error }

class ResultAnalyzerState {
  final AnalyzerStage stage;
  final String? quickScanPreviewText;
  final ResultAnalysis? result;
  final String? errorMessage;

  const ResultAnalyzerState({
    this.stage = AnalyzerStage.idle,
    this.quickScanPreviewText,
    this.result,
    this.errorMessage,
  });

  ResultAnalyzerState copyWith({
    AnalyzerStage? stage,
    String? quickScanPreviewText,
    ResultAnalysis? result,
    String? errorMessage,
  }) =>
      ResultAnalyzerState(
        stage: stage ?? this.stage,
        quickScanPreviewText: quickScanPreviewText ?? this.quickScanPreviewText,
        result: result ?? this.result,
        errorMessage: errorMessage,
      );
}

class ResultAnalyzerNotifier extends StateNotifier<ResultAnalyzerState> {
  ResultAnalyzerNotifier(this._dio) : super(const ResultAnalyzerState());

  final Dio _dio;
  final _onDeviceRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> analyzeFile(File file, {String? semesterHint}) async {
    state = state.copyWith(stage: AnalyzerStage.quickScan, errorMessage: null);

    // 1) Instant on-device preview
    try {
      final inputImage = InputImage.fromFile(file);
      final recognized = await _onDeviceRecognizer.processImage(inputImage);
      state = state.copyWith(quickScanPreviewText: recognized.text);
    } catch (_) {}

    // 2) Upload + backend analysis
    state = state.copyWith(stage: AnalyzerStage.uploading);
    try {
      final formData = FormData.fromMap({
        if (semesterHint != null) 'semester': semesterHint,
        'file': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
      });

      state = state.copyWith(stage: AnalyzerStage.analyzing);
      final response = await _dio.post(
        '/results/analyze',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final analysis = ResultAnalysis.fromJson(response.data);
      state = state.copyWith(stage: AnalyzerStage.done, result: analysis);
    } on DioException catch (e) {
      // Fallback demo data if backend offline
      final mockAnalysis = ResultAnalysis(
        uploadId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        needsReview: false,
        semester: semesterHint ?? '3yr-1sem',
        subjects: [
          ExtractedSubject(subjectCode: 'CS301', subjectName: 'Data Structures & Algorithms', credits: 4, grade: 'A', gradePoints: 9, isBacklog: false),
          ExtractedSubject(subjectCode: 'CS302', subjectName: 'Database Systems', credits: 4, grade: 'A+', gradePoints: 10, isBacklog: false),
          ExtractedSubject(subjectCode: 'CS303', subjectName: 'Operating Systems', credits: 3, grade: 'B+', gradePoints: 8, isBacklog: false),
          ExtractedSubject(subjectCode: 'CS304', subjectName: 'Computer Networks', credits: 3, grade: 'B', gradePoints: 7, isBacklog: false),
          ExtractedSubject(subjectCode: 'MA301', subjectName: 'Discrete Mathematics', credits: 3, grade: 'A', gradePoints: 9, isBacklog: false),
        ],
        sgpa: 8.85,
        cgpa: 8.72,
        totalBacklogs: 0,
        trend: [
          GpaTrendPoint(semester: '1yr-1sem', sgpa: 8.2),
          GpaTrendPoint(semester: '1yr-2sem', sgpa: 8.5),
          GpaTrendPoint(semester: '2yr-1sem', sgpa: 8.6),
          GpaTrendPoint(semester: '3yr-1sem', sgpa: 8.85),
        ],
        source: AnalysisSource.mock,
        confidence: 1.0,
      );
      state = state.copyWith(stage: AnalyzerStage.done, result: mockAnalysis);
    } catch (e) {
      state = state.copyWith(stage: AnalyzerStage.error, errorMessage: e.toString());
    }
  }

  void reset() => state = const ResultAnalyzerState();

  @override
  void dispose() {
    _onDeviceRecognizer.close();
    super.dispose();
  }
}

final resultAnalyzerProvider =
    StateNotifierProvider<ResultAnalyzerNotifier, ResultAnalyzerState>((ref) {
  return ResultAnalyzerNotifier(ApiClient.instance.dio);
});
