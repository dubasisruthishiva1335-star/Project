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
      backgroundColor: MyVaultColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyVaultColors.metalBlack, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Upload Result', style: TextStyle(color: MyVaultColors.metalBlack, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: MyVaultColors.whiteShadingGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: state.stage == AnalyzerStage.idle || state.stage == AnalyzerStage.error
              ? _buildPickerState(state)
              : _buildAnalyzingState(state),
        ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: MyVaultColors.metalBlack, strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              labels[state.stage] ?? 'Processing…',
              style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Running OCR & calculating SGPA / Grade stats…',
              style: TextStyle(color: MyVaultColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: MyVaultColors.metalGradient,
            ),
            child: const Icon(Icons.document_scanner_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload Marksheet / Result',
            style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 6),
          const Text(
            'Take a photo or pick a PDF/Image of your semester marksheet.',
            style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18, color: MyVaultColors.metalBlack),
                  label: const Text('Camera', style: TextStyle(color: MyVaultColors.metalBlack, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    backgroundColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: MyVaultColors.metalGradient,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onFile,
                    icon: const Icon(Icons.folder_open_rounded, size: 18, color: Colors.white),
                    label: const Text('Browse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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
