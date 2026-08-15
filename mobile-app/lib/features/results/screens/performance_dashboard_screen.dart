import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/colors.dart';
import '../models/result_analysis_model.dart';

class PerformanceDashboardScreen extends StatelessWidget {
  final ResultAnalysis analysis;
  const PerformanceDashboardScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(analysis.semester ?? 'Performance Dashboard', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis.needsReview) _buildReviewBanner(),
            if (analysis.source == AnalysisSource.mock) _buildMockBanner(),
            _buildStatCardsGrid(),
            const SizedBox(height: 24),
            _sectionTitle('Subject-wise Marks & Grade Points'),
            const SizedBox(height: 12),
            _buildSubjectBarChart(),
            const SizedBox(height: 28),
            if (analysis.trend.length > 1) ...[
              _sectionTitle('GPA Growth Trend'),
              const SizedBox(height: 12),
              _buildGpaTrendChart(),
              const SizedBox(height: 28),
            ],
            _sectionTitle('Subject Breakdown'),
            const SizedBox(height: 12),
            _buildSubjectList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBanner() => const _Banner(
        icon: Icons.info_outline,
        color: Colors.amberAccent,
        text: 'AI confidence was low on some fields — please verify against your original marksheet.',
      );

  Widget _buildMockBanner() => const _Banner(
        icon: Icons.science_outlined,
        color: MyVaultColors.accentCyan,
        text: 'Showing calculated sample performance dashboard.',
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
      );

  // ---------------- Stat cards (bento grid) ----------------
  Widget _buildStatCardsGrid() {
    final cards = [
      _StatCardData('SGPA', analysis.sgpa?.toStringAsFixed(2) ?? '—', Icons.grade_outlined,
          [MyVaultColors.accentCyan, MyVaultColors.accentBlue]),
      _StatCardData('CGPA', analysis.cgpa?.toStringAsFixed(2) ?? '—', Icons.workspace_premium_outlined,
          [const Color(0xFF7C3AFF), MyVaultColors.accentBlue]),
      _StatCardData('Backlogs', '${analysis.totalBacklogs}', Icons.error_outline,
          analysis.totalBacklogs > 0 ? [Colors.orangeAccent, Colors.redAccent] : [const Color(0xFF00C48C), Colors.teal]),
      _StatCardData('Credits', analysis.subjects.fold<double>(0, (s, e) => s + e.credits).toStringAsFixed(0),
          Icons.school_outlined, [MyVaultColors.accentBlue, Colors.blueAccent]),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards.map((c) => _StatCard(data: c)).toList(),
    );
  }

  // ---------------- Bar chart: subject-wise marks/points ----------------
  Widget _buildSubjectBarChart() {
    final subjects = analysis.subjects;
    final maxY = subjects.isEmpty
        ? 10.0
        : subjects.map((s) => s.gradePoints ?? 0).fold<double>(0, (a, b) => a > b ? a : b) + 2;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: _glassDecoration(),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= subjects.length) return const SizedBox.shrink();
                  final code = subjects[i].subjectCode ?? (subjects[i].subjectName.length >= 3 ? subjects[i].subjectName.substring(0, 3) : subjects[i].subjectName);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(code, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            for (int i = 0; i < subjects.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: subjects[i].gradePoints ?? 0,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: subjects[i].isBacklog
                          ? [Colors.redAccent, Colors.orangeAccent]
                          : [MyVaultColors.accentBlue, MyVaultColors.accentCyan],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- Line chart: GPA trend across semesters ----------------
  Widget _buildGpaTrendChart() {
    final trend = analysis.trend;
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: _glassDecoration(),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 10,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(trend[i].semester,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (int i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i].sgpa)],
              isCurved: true,
              gradient: const LinearGradient(colors: [MyVaultColors.accentCyan, MyVaultColors.accentBlue]),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [MyVaultColors.accentCyan.withValues(alpha: 0.15), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectList() {
    return Column(
      children: analysis.subjects.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _glassDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.subjectName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    if (s.subjectCode != null)
                      Text(s.subjectCode!,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
              Text('${s.credits} cr', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (s.isBacklog ? Colors.redAccent : MyVaultColors.accentCyan).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.grade ?? '—',
                  style: TextStyle(
                    color: s.isBacklog ? Colors.redAccent : MyVaultColors.accentCyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  BoxDecoration _glassDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
        ),
        border: Border.all(color: MyVaultColors.glassBorder),
      );
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  _StatCardData(this.label, this.value, this.icon, this.gradient);
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.gradient[0].withValues(alpha: 0.18), data.gradient[1].withValues(alpha: 0.06)],
        ),
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(data.icon, color: data.gradient[0], size: 22),
          Text(data.value,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(data.label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Banner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12))),
        ],
      ),
    );
  }
}
