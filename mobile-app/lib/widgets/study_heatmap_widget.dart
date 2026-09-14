import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../services/study_activity_service.dart';

class StudyHeatmapWidget extends StatefulWidget {
  const StudyHeatmapWidget({super.key});

  @override
  State<StudyHeatmapWidget> createState() => _StudyHeatmapWidgetState();
}

class _StudyHeatmapWidgetState extends State<StudyHeatmapWidget> {
  int _streak = 0;
  int _totalHours = 0;
  Map<String, DailyStudyActivity> _activities = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final streak = await StudyActivityService.instance.getCurrentStreakDays();
    final hours = await StudyActivityService.instance.getTotalHoursStudied();
    final acts = await StudyActivityService.instance.getActivityMap();

    if (mounted) {
      setState(() {
        _streak = streak;
        _totalHours = hours;
        _activities = acts;
        _loading = false;
      });
    }
  }

  Color _getColorForMinutes(int mins) {
    if (mins == 0) return const Color(0xFFF1F5F9);
    if (mins < 15) return const Color(0xFF93C5FD);
    if (mins < 45) return const Color(0xFF3B82F6);
    return const Color(0xFF1D4ED8);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final now = DateTime.now();
    final List<DateTime> last14Days = List.generate(14, (i) => now.subtract(Duration(days: 13 - i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_streak Day${_streak == 1 ? '' : 's'} Study Streak',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: MyVaultColors.metalBlack),
                      ),
                      Text(
                        '$_totalHours Total Hours Studied',
                        style: const TextStyle(fontSize: 11, color: MyVaultColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active Learner',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Daily Activity (Last 14 Days):',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MyVaultColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: last14Days.map((d) {
              final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              final act = _activities[key];
              final mins = act?.minutesStudied ?? 0;
              final isToday = d.day == now.day && d.month == now.month;

              return Tooltip(
                message: '${d.day}/${d.month}: $mins mins',
                child: Column(
                  children: [
                    Container(
                      width: 16,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _getColorForMinutes(mins),
                        borderRadius: BorderRadius.circular(4),
                        border: isToday ? Border.all(color: MyVaultColors.metalBlack, width: 1.5) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 9,
                        color: isToday ? MyVaultColors.metalBlack : const Color(0xFF94A3B8),
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
