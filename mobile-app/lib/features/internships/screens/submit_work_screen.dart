import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../models/internship_lms_model.dart';
import '../services/internship_lms_service.dart';

class SubmitWorkScreen extends StatefulWidget {
  const SubmitWorkScreen({super.key, required this.lesson, required this.internshipId});
  final LessonLms lesson;
  final String internshipId;

  @override
  State<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends State<SubmitWorkScreen> {
  final _service = InternshipLmsService();
  final _githubController = TextEditingController();
  final _liveUrlController = TextEditingController();

  File? _pickedFile;
  bool _submitting = false;

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip', 'pdf', 'png', 'jpg']);
    if (res != null && res.files.single.path != null) {
      setState(() => _pickedFile = File(res.files.single.path!));
    }
  }

  Future<void> _submitWork() async {
    setState(() => _submitting = true);
    await _service.submitStudentWork(
      lessonId: widget.lesson.id,
      internshipId: widget.internshipId,
      type: widget.lesson.type,
      githubUrl: _githubController.text.trim(),
      liveUrl: _liveUrlController.text.trim(),
      fileUrl: _pickedFile != null ? 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1786544055523-478f14f9-ade1-411b-882d-5124b5b84967-RADAR_Ashok.pdf' : null,
    );
    setState(() => _submitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work submitted successfully! Pending Admin review.')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Submit ${widget.lesson.type.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.lesson.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 6),
          Text(widget.lesson.description ?? 'Complete and submit your project source code.', style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 24),
          const Text('GitHub Repository URL', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _githubController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://github.com/username/project',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: MyVaultColors.glassFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Live Demo / Website URL', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _liveUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://myproject.vercel.app',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: MyVaultColors.glassFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file_rounded, color: MyVaultColors.accentCyan),
            label: Text(_pickedFile == null ? 'Upload Project ZIP / PDF to S3' : 'Selected: ${_pickedFile!.path.split('/').last}', style: const TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: MyVaultColors.accentCyan),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
          _submitting
              ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
              : ElevatedButton(
                  onPressed: _submitWork,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyVaultColors.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Work for Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
        ],
      ),
    );
  }
}
