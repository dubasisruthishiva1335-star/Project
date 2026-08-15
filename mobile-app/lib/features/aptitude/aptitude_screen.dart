import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';

class AptitudeScreen extends StatefulWidget {
  const AptitudeScreen({super.key});

  @override
  State<AptitudeScreen> createState() => _AptitudeScreenState();
}

class _AptitudeScreenState extends State<AptitudeScreen> {
  List<dynamic> _questions = [];
  bool _loading = true;
  String? _error;
  String? _selectedCategory;
  final List<String> _categories = ['All', 'Quantitative', 'Logical', 'Verbal', 'Technical'];

  final Map<int, bool> _revealed = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions({String? category}) async {
    setState(() { _loading = true; _error = null; _revealed.clear(); });
    try {
      final res = await ApiClient.instance.dio.get(
        '/aptitude',
        queryParameters: (category != null && category != 'All')
            ? {'category': category.toLowerCase()}
            : {},
      );
      setState(() {
        _questions = res.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load aptitude questions.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: MyVaultColors.obsidian,
        appBar: AppBar(
          backgroundColor: MyVaultColors.obsidian,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
            onPressed: () => context.go('/home'),
          ),
          title: ShaderMask(
            shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
            child: const Text(
              'Aptitude & AI Coach',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        body: Column(
          children: [
            // AI Interview & Aptitude Coach Action Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: InkWell(
                onTap: () => context.go('/ai-interview'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        MyVaultColors.accentBlue.withValues(alpha: 0.35),
                        MyVaultColors.accentCyan.withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: MyVaultColors.accentBlue,
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Campus Placement Coach',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Practice Technical, HR & Aptitude with real-time AI scoring & feedback.',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: MyVaultColors.accentCyan, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((cat) {
                  final selected = (_selectedCategory ?? 'All') == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat);
                        _loadQuestions(category: cat);
                      },
                      selectedColor: MyVaultColors.accentBlue.withValues(alpha: 0.3),
                      backgroundColor: MyVaultColors.glassFill,
                      side: BorderSide(
                        color: selected
                            ? MyVaultColors.accentBlue
                            : MyVaultColors.glassBorder,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? MyVaultColors.accentCyan : Colors.white60,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      checkmarkColor: MyVaultColors.accentCyan,
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
                  : _error != null
                      ? _buildError()
                      : _questions.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: () => _loadQuestions(category: _selectedCategory),
                              color: MyVaultColors.accentCyan,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: _questions.length,
                                itemBuilder: (ctx, i) => _buildCard(i, _questions[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index, Map<String, dynamic> q) {
    final revealed = _revealed[index] ?? false;
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
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [MyVaultColors.accentBlue, MyVaultColors.accentCyan],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (q['category'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: MyVaultColors.accentBlue.withValues(alpha: 0.15),
                    ),
                    child: Text(
                      q['category'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: MyVaultColors.accentBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              q['question'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),

            if (q['options'] != null) ...[
              const SizedBox(height: 12),
              ...((q['options'] as List<dynamic>).asMap().entries.map((entry) {
                final optIndex = entry.key;
                final opt = entry.value.toString();
                final letters = ['A', 'B', 'C', 'D'];
                final isCorrect = revealed && opt == q['answer'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isCorrect
                        ? const Color(0xFF00C48C).withValues(alpha: 0.15)
                        : MyVaultColors.glassFill,
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF00C48C).withValues(alpha: 0.5)
                          : MyVaultColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${optIndex < letters.length ? letters[optIndex] : optIndex + 1}.',
                        style: TextStyle(
                          color: isCorrect ? const Color(0xFF00C48C) : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            color: isCorrect ? const Color(0xFF00C48C) : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF00C48C), size: 16),
                    ],
                  ),
                );
              })),
            ],

            const SizedBox(height: 12),

            if (!revealed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _revealed[index] = true),
                  icon: const Icon(Icons.visibility_rounded, size: 15),
                  label: const Text('Show Answer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MyVaultColors.accentCyan,
                    side: BorderSide(color: MyVaultColors.accentCyan.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else if (q['answer'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF00C48C).withValues(alpha: 0.08),
                  border: Border.all(color: const Color(0xFF00C48C).withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF00C48C), size: 15),
                        SizedBox(width: 6),
                        Text('Answer', style: TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(q['answer'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    if (q['explanation'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        q['explanation'],
                        style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ],
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
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 60),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadQuestions,
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
          Icon(Icons.psychology_outlined, color: Colors.white12, size: 70),
          SizedBox(height: 16),
          Text('No questions available yet', style: TextStyle(color: Colors.white38, fontSize: 15)),
        ],
      ),
    );
  }
}
