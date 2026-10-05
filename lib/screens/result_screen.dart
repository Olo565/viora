import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../theme/app_theme.dart';
// AppShadows ikut ter-export dari app_theme.dart
import '../utils/calculator.dart';
import '../widgets/bmi_gauge.dart';
import '../widgets/timeline_tile.dart';
import '../services/notification_service.dart';
import 'dashboard_screen.dart';

class ResultScreen extends StatefulWidget {
  final UserData data;
  final bool isFromOnboarding;
  const ResultScreen({
    super.key,
    required this.data,
    this.isFromOnboarding = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  WeightRate _rate = WeightRate.moderate;
  int _selectedDay = BodyCalculator.todayIndex();
  bool _remindersOn = false;
  bool _loadingReminder = false;

  static const double _wideBreakpoint = 900;

  Future<void> _toggleReminders(List<ScheduleItem> schedule) async {
    setState(() => _loadingReminder = true);
    try {
      if (_remindersOn) {
        await NotificationService.instance.cancelAll();
        setState(() => _remindersOn = false);
      } else {
        final granted = await NotificationService.instance.requestPermission();
        if (granted) {
          await NotificationService.instance.scheduleDailySchedule(schedule);
          setState(() => _remindersOn = true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Izin notifikasi ditolak. Aktifkan lewat pengaturan HP.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loadingReminder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final bmiValue = BodyCalculator.bmi(d.currentWeightKg, d.heightCm);
    final category = BodyCalculator.bmiCategory(bmiValue);
    final idealRange = BodyCalculator.idealWeightRange(d.heightCm);
    final bmrValue =
        BodyCalculator.bmr(d.gender, d.currentWeightKg, d.heightCm, d.age);
    final tdeeValue = BodyCalculator.tdee(bmrValue, d.activityLevel);
    final goal = d.goal;
    final weeks = BodyCalculator.durationWeeks(d.weightDifferenceKg, _rate);
    final calorieTarget =
        BodyCalculator.dailyCalorieTarget(tdeeValue, goal, _rate);
    final macro = BodyCalculator.macros(calorieTarget, goal);
    final weeklyPlan = BodyCalculator.weeklyMealPlan(goal);
    final today = BodyCalculator.todayIndex();
    final schedule = BodyCalculator.dailySchedule(
      weeklyPlan[_selectedDay],
      _selectedDay,
      goal,
      calorieTarget,
      macro,
    );

    final summarySection =
        _buildSummarySection(d, bmiValue, category, idealRange);
    final planSection = _buildPlanSection(goal, weeks, calorieTarget, macro);
    final scheduleSection = _buildScheduleSection(today, schedule);
    final tipSection = _buildTipCard();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Analisis'),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;
          return SingleChildScrollView(
            padding:
                EdgeInsets.fromLTRB(isWide ? 32 : 20, 4, isWide ? 32 : 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1100 : 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.task_alt_rounded,
                            color: AppColors.primary, size: isWide ? 26 : 22),
                        const SizedBox(width: 8),
                        Text(
                          'Halo, ${d.name}',
                          style: TextStyle(
                              fontSize: isWide ? 24 : 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Berikut ringkasan tubuh dan rencana menuju target beratmu.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                    ),
                    const SizedBox(height: 20),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                                children: [...summarySection, ...planSection]),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 6,
                            child: Column(children: [
                              ...scheduleSection,
                              ...tipSection,
                              _buildContinueButton(d),
                            ]),
                          ),
                        ],
                      )
                    else
                      Column(children: [
                        ...summarySection,
                        ...planSection,
                        ...scheduleSection,
                        ...tipSection,
                        _buildContinueButton(d),
                      ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueButton(UserData d) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => DashboardScreen(data: d)),
              (route) => false,
            );
          },
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Buka Dashboard Utama'),
        ),
      ),
    );
  }

  List<Widget> _buildSummarySection(UserData d, double bmiValue,
      String category, (double, double) idealRange) {
    return [
      _card(
        child: Column(
          children: [
            BmiGauge(bmiValue: bmiValue, category: category),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat('Berat Ideal',
                    '${idealRange.$1.toStringAsFixed(0)}-${idealRange.$2.toStringAsFixed(0)} kg'),
                _miniStat('Tinggi', '${d.heightCm.toStringAsFixed(0)} cm'),
                _miniStat('Usia', '${d.age} th'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _card(
        child: Row(
          children: [
            Expanded(
                child: _goalStat(
                    'Sekarang',
                    '${d.currentWeightKg.toStringAsFixed(1)} kg',
                    AppColors.textDark)),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
            Expanded(
                child: _goalStat(
                    'Target',
                    '${d.targetWeightKg.toStringAsFixed(1)} kg',
                    AppColors.primary)),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildPlanSection(
      GoalType goal, int weeks, double calorieTarget, MacroResult macro) {
    return [
      _label(_goalTitle(goal)),
      const SizedBox(height: 10),
      if (goal != GoalType.maintain) ...[
        Row(
          children: WeightRate.values.map((r) {
            final selected = r == _rate;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _rate = r),
                child: Container(
                  margin: EdgeInsets.only(right: r != WeightRate.fast ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border),
                    boxShadow: selected ? AppShadows.glow : AppShadows.soft,
                  ),
                  child: Column(
                    children: [
                      Text(r.label,
                          style: TextStyle(
                              color:
                                  selected ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      Text(r.sublabel,
                          style: TextStyle(
                              color: selected
                                  ? Colors.white70
                                  : AppColors.textMuted,
                              fontSize: 10.5)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _card(
          color: AppColors.primarySoft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary),
              const SizedBox(width: 10),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Text(
                    'Estimasi tercapai dalam ±$weeks minggu (~${(weeks / 4.3).toStringAsFixed(1)} bulan)',
                    key: ValueKey(weeks),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ] else ...[
        _card(
          color: AppColors.primarySoft,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Berat badanmu sudah dekat target. Fokus jaga pola makan seimbang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      _label('Kebutuhan Kalori Harian'),
      const SizedBox(height: 10),
      _card(
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.25), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                '${calorieTarget.toStringAsFixed(0)} kkal / hari',
                key: ValueKey(calorieTarget.round()),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _macroBar('Protein', macro.proteinGram, AppColors.primary),
                _macroBar('Karbo', macro.carbGram, AppColors.gold),
                _macroBar('Lemak', macro.fatGram, AppColors.accent),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildScheduleSection(int today, List<ScheduleItem> schedule) {
    return [
      _label('Jadwal Harian: Makan, Minum & Olahraga'),
      const SizedBox(height: 2),
      const Text(
        'Lengkap sama jam, kalori & gram gizinya tiap waktu makan, plus olahraga pendukung — diet nggak cuma dari makanan.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: BodyCalculator.weekDays.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final selected = i == _selectedDay;
            final isToday = i == today;
            return GestureDetector(
              onTap: () => setState(() => _selectedDay = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      BodyCalculator.weekDays[i].substring(0, 3),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: selected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              selected ? Colors.white24 : AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Hari ini',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.accent,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 13),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      ...List.generate(
          schedule.length,
          (i) => TimelineTile(
              item: schedule[i], isLast: i == schedule.length - 1)),
      const SizedBox(height: 4),
      _card(
        color: _remindersOn ? AppColors.primarySoft : Colors.white,
        child: Row(
          children: [
            Icon(
              _remindersOn
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _remindersOn ? 'Pengingat aktif' : 'Pengingat belum aktif',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textDark),
                  ),
                  const Text(
                    'Notifikasi otomatis di tiap jam makan & minum di atas.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            _loadingReminder
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2))
                : Switch(
                    value: _remindersOn,
                    activeThumbColor: AppColors.primary,
                    onChanged: (_) => _toggleReminders(schedule),
                  ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildTipCard() {
    return [
      _card(
        color: AppColors.accentSoft,
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Perbanyak air putih, tidur cukup 7-8 jam, dan gabungkan dengan olahraga rutin. '
                'Hasil di atas adalah estimasi umum — konsultasikan ke ahli gizi/dokter untuk kondisi kesehatan khusus. '
                'Notifikasi pengingat hanya berjalan penuh saat aplikasi di-install sebagai app Android/iOS, bukan lewat browser.',
                style: TextStyle(
                    color: AppColors.textDark, fontSize: 12.5, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  String _goalTitle(GoalType goal) {
    switch (goal) {
      case GoalType.lose:
        return 'Pilih Kecepatan Turun Berat Badan';
      case GoalType.gain:
        return 'Pilih Kecepatan Naik Berat Badan';
      case GoalType.maintain:
        return 'Status Berat Badan';
    }
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            fontSize: 15.5),
      );

  Widget _card({required Widget child, Color color = AppColors.surface}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }

  Widget _miniStat(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      );

  Widget _goalStat(String label, String value, Color color) => Column(
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      );

  Widget _macroBar(String label, int gram, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('${gram}g',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: color, fontSize: 15)),
          const SizedBox(height: 4),
          Container(
              height: 6,
              width: 40,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
