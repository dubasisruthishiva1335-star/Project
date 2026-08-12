import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<dynamic> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.dio.get('/results');
      setState(() {
        _results = res.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Please log in to view your results.';
        _loading = false;
      });
    }
  }

  Color _gradeColor(String? grade) {
    if (grade == null) return Colors.white54;
    if (grade.startsWith('O') || grade.startsWith('A+')) return const Color(0xFF00C48C);
    if (grade.startsWith('A')) return const Color(0xFF3E7BFF);
    if (grade.startsWith('B')) return const Color(0xFFFFB800);
    if (grade.startsWith('C')) return Colors.orange;
    return Colors.redAccent;
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
        title: ShaderMask(
          shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
          child: const Text(
            'My Results',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
          : _error != null
              ? _buildError()
              : _results.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadResults,
                      color: MyVaultColors.accentCyan,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) => _buildCard(_results[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(Map<String, dynamic> result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: MyVaultColors.glassFill,
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0x333E7BFF), Color(0x3300D9F5)],
                    ),
                  ),
                  child: Text(
                    'Semester ${result['semester'] ?? '-'}',
                    style: const TextStyle(
                      color: MyVaultColors.accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                if (result['sgpa'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('SGPA', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      Text(
                        result['sgpa'].toString(),
                        style: TextStyle(
                          color: _gradeColor(result['sgpa'].toString()),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (result['title'] != null) ...[
              const SizedBox(height: 10),
              Text(
                result['title'],
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],

            if (result['description'] != null) ...[
              const SizedBox(height: 6),
              Text(
                result['description'],
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],

            if (result['fileUrl'] != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(result['fileUrl'] as String);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('View Result PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E7BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 60),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadResults,
              style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grade_outlined, color: Colors.white12, size: 70),
          SizedBox(height: 16),
          Text('No results available yet', style: TextStyle(color: Colors.white38, fontSize: 15)),
          SizedBox(height: 6),
          Text('Results will appear here once uploaded', style: TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }
}
