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
      backgroundColor: MyVaultColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyVaultColors.metalBlack, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          analysis.semester ?? 'Performance Dashboard',
          style: const TextStyle(color: MyVaultColors.metalBlack, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: MyVaultColors.whiteShadingGradient,
        ),
        child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildReviewBanner() => const _Banner(
        icon: Icons.info_outline,
        color: Color(0xFFD97706),
        text: 'AI confidence was low on some fields — please verify against your original marksheet.',
      );

  Widget _buildMockBanner() => const _Banner(
        icon: Icons.science_outlined,
        color: Color(0xFF2563EB),
        text: 'Showing calculated sample performance dashboard.',
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(color: MyVaultColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
      );

  // ---------------- Stat cards (bento grid) ----------------
  Widget _buildStatCardsGrid() {
    final cards = [
      _StatCardData('SGPA', analysis.sgpa?.toStringAsFixed(2) ?? '—', Icons.grade_outlined,
          [const Color(0xFF2563EB), const Color(0xFF0EA5E9)]),
      _StatCardData('CGPA', analysis.cgpa?.toStringAsFixed(2) ?? '—', Icons.workspace_premium_outlined,
          [const Color(0xFF7C3AED), const Color(0xFF2563EB)]),
      _StatCardData('Backlogs', '${analysis.totalBacklogs}', Icons.error_outline,
          analysis.totalBacklogs > 0 ? [Colors.orangeAccent, Colors.redAccent] : [const Color(0xFF059669), const Color(0xFF10B981)]),
      _StatCardData('Credits', analysis.subjects.fold<double>(0, (s, e) => s + e.credits).toStringAsFixed(0),
          Icons.school_outlined, [MyVaultColors.metalBlack, const Color(0xFF2C323B)]),
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
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: subjects.isEmpty
          ? const Center(child: Text('No subject data to display', style: TextStyle(color: MyVaultColors.textMuted)))
          : BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: subjects.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (s.gradePoints ?? 0).toDouble(),
                        gradient: MyVaultColors.metalGradient,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, _) => Text(
                        val.toInt().toString(),
                        style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= subjects.length) return const SizedBox.shrink();
                        final name = subjects[idx].subjectName;
                        final short = name.length > 5 ? name.substring(0, 5) : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(short, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
    );
  }

  // ---------------- Line chart: semester trend ----------------
  Widget _buildGpaTrendChart() {
    final trend = analysis.trend;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: 4,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.sgpa)).toList(),
              isCurved: true,
              color: MyVaultColors.metalBlack,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: MyVaultColors.metalBlack,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0x120F172A),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (val, _) => Text(
                  val.toStringAsFixed(1),
                  style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(trend[idx].semester, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // ---------------- Subject list ----------------
  Widget _buildSubjectList() {
    return Column(
      children: analysis.subjects
          .map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.subjectName, style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('${s.credits.toStringAsFixed(0)} Credits', style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: s.isBacklog ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: s.isBacklog ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7)),
                    ),
                    child: Text(
                      s.grade ?? (s.gradePoints?.toStringAsFixed(0) ?? '—'),
                      style: TextStyle(
                        color: s.isBacklog ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  const _StatCardData(this.title, this.value, this.icon, this.gradientColors);
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.title, style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.gradientColors.first.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.gradientColors.first, size: 16),
              ),
            ],
          ),
          Text(data.value, style: const TextStyle(color: MyVaultColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12))),
        ],
      ),
    );
  }
}
