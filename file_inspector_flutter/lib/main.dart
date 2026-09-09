import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'analyzer_service.dart';
import 'report_view.dart';

void main() => runApp(const FileInspectorApp());

class FileInspectorApp extends StatelessWidget {
  const FileInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Inspector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12161A),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF49D3C6), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<AnalyzedFile> _files = [];
  String? _activeId;
  String? _apiKey;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _apiKey = prefs.getString('anthropic_api_key'));
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('anthropic_api_key', key);
    if (!mounted) return;
    setState(() => _apiKey = key);
  }

  Future<void> _promptForApiKey() async {
    final controller = TextEditingController(text: _apiKey ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anthropic API key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stored locally on this device only, and sent directly to '
              'api.anthropic.com from the app. For a shipped app, proxy '
              'this through your own backend instead.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'sk-ant-...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _saveApiKey(result);
    }
  }

  Future<void> _pickFiles() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      await _promptForApiKey();
      if (_apiKey == null || _apiKey!.isEmpty) return;
    }
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    for (final f in result.files) {
      if (f.bytes == null) continue;
      final id = 'f${++_seq}';
      final analyzed = AnalyzedFile(
        id: id,
        name: f.name,
        sizeBytes: f.size,
        bytes: f.bytes!,
        category: AnalyzerService.detectCategory(f.name),
      );
      setState(() {
        _files.add(analyzed);
        _activeId ??= id;
      });
      _analyze(analyzed);
    }
  }

  Future<void> _analyze(AnalyzedFile f) async {
    setState(() {
      f.status = AnalysisStatus.working;
      f.error = null;
    });
    try {
      final result = await AnalyzerService.analyze(f, _apiKey!);
      if (!mounted) return;
      setState(() {
        f.result = result;
        f.status = AnalysisStatus.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        f.status = AnalysisStatus.error;
        f.error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = _files.where((f) => f.id == _activeId);
    final activeFile = matches.isNotEmpty ? matches.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Inspector'),
        actions: [
          IconButton(icon: const Icon(Icons.key), tooltip: 'API key', onPressed: _promptForApiKey),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Upload file'),
                    ),
                  ),
                ),
                Expanded(
                  child: _files.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No files yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      : ListView.builder(
                          itemCount: _files.length,
                          itemBuilder: (ctx, i) {
                            final f = _files[i];
                            return ListTile(
                              dense: true,
                              selected: f.id == _activeId,
                              leading: _statusDot(f.status),
                              title: Text(f.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                              onTap: () => setState(() => _activeId = f.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: activeFile == null
                ? const Center(child: Text('Upload a file to begin.', style: TextStyle(color: Colors.grey)))
                : ReportView(file: activeFile, onRetry: () => _analyze(activeFile)),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(AnalysisStatus s) {
    Color c;
    switch (s) {
      case AnalysisStatus.working:
        c = Colors.amber;
        break;
      case AnalysisStatus.done:
        c = Colors.teal;
        break;
      case AnalysisStatus.error:
        c = Colors.redAccent;
        break;
      case AnalysisStatus.queued:
        c = Colors.grey;
        break;
    }
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  }
}
