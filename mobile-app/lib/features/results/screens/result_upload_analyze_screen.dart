import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/colors.dart';
import '../providers/result_analyzer_provider.dart';
import 'performance_dashboard_screen.dart';

class ResultUploadAnalyzeScreen extends ConsumerStatefulWidget {
  const ResultUploadAnalyzeScreen({super.key});

  @override
  ConsumerState<ResultUploadAnalyzeScreen> createState() => _ResultUploadAnalyzeScreenState();
}

class _ResultUploadAnalyzeScreenState extends ConsumerState<ResultUploadAnalyzeScreen> {
  Future<void> _pickAndAnalyze({required bool fromCamera}) async {
    File? picked;

    if (fromCamera) {
      final xfile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
      if (xfile != null) picked = File(xfile.path);
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        picked = File(result.files.single.path!);
      }
    }

    if (picked == null) return;
    await ref.read(resultAnalyzerProvider.notifier).analyzeFile(picked);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(resultAnalyzerProvider, (prev, next) {
      if (next.stage == AnalyzerStage.done && next.result != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PerformanceDashboardScreen(analysis: next.result!),
          ),
        );
      }
    });

    final state = ref.watch(resultAnalyzerProvider);

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Upload Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: state.stage == AnalyzerStage.idle || state.stage == AnalyzerStage.error
            ? _buildPickerState(state)
            : _buildAnalyzingState(state),
      ),
    );
  }

  Widget _buildPickerState(ResultAnalyzerState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GlassDropzone(
          onCamera: () => _pickAndAnalyze(fromCamera: true),
          onFile: () => _pickAndAnalyze(fromCamera: false),
        ),
        if (state.stage == AnalyzerStage.error) ...[
          const SizedBox(height: 16),
          Text(
            state.errorMessage ?? 'Something went wrong',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildAnalyzingState(ResultAnalyzerState state) {
    final labels = {
      AnalyzerStage.quickScan: 'Scanning document…',
      AnalyzerStage.uploading: 'Uploading…',
      AnalyzerStage.analyzing: 'AI analyzing your result…',
    };

    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [MyVaultColors.accentCyan.withValues(alpha: 0.12), MyVaultColors.accentBlue.withValues(alpha: 0.06)],
          ),
          border: Border.all(color: MyVaultColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 3, color: MyVaultColors.accentCyan),
            ),
            const SizedBox(height: 20),
            Text(
              labels[state.stage] ?? 'Working…',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (state.quickScanPreviewText != null && state.stage != AnalyzerStage.quickScan) ...[
              const SizedBox(height: 12),
              Text(
                'Quick preview captured — refining with AI…',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GlassDropzone extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onFile;

  const _GlassDropzone({required this.onCamera, required this.onFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MyVaultColors.accentCyan.withValues(alpha: 0.15), MyVaultColors.accentBlue.withValues(alpha: 0.08)],
        ),
        border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 40, color: MyVaultColors.accentCyan),
          const SizedBox(height: 12),
          const Text(
            'Upload your marksheet',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'JPG, PNG, or PDF — AI will read and analyze it automatically',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.camera_alt_outlined, color: MyVaultColors.accentCyan),
                  label: const Text('Camera', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: MyVaultColors.accentCyan),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onFile,
                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                  label: const Text('Choose File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyVaultColors.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
