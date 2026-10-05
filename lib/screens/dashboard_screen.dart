import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/purchase_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/calculator.dart';
import 'home_screen.dart';
import 'premium_screen.dart';
import 'result_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserData data;
  const DashboardScreen({super.key, required this.data});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;
  late double _weight;
  double _water = 1.0;
  int _caloriesLogged = 0;
  final Set<String> _completed = {};
  final Set<String> _completedExercises = {};
  final List<double> _weightHistory = [];

  UserData get d => widget.data;

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
    PurchaseService.instance.isPremiumNotifier.addListener(_onPremiumChanged);
  }

  void _onPremiumChanged() {
    if (mounted) setState(() {});
  }

  void _loadPersistedData() {
    final history = StorageService.instance.getWeightHistory(d.currentWeightKg);
    _weightHistory.clear();
    _weightHistory.addAll(history);
    _weight = _weightHistory.isNotEmpty ? _weightHistory.last : d.currentWeightKg;
    _water = StorageService.instance.waterIntake;
    _caloriesLogged = StorageService.instance.caloriesLogged;
    _completed.clear();
    _completed.addAll(StorageService.instance.completedChecklist);
    _completedExercises.clear();
    _completedExercises.addAll(StorageService.instance.completedExercises);
  }

  @override
  void dispose() {
    PurchaseService.instance.isPremiumNotifier.removeListener(_onPremiumChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _overview(),
      _meals(),
      _activity(),
      _progress(),
      _profile(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarySoft,
        height: 72,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded),
              label: 'Makanan'),
          NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: 'Aktivitas'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Progres'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil'),
        ],
      ),
    );
  }

  Widget _overview() {
    final bmi = BodyCalculator.bmi(_weight, d.heightCm);
    final category = BodyCalculator.bmiCategory(bmi);
    final bmr = BodyCalculator.bmr(d.gender, _weight, d.heightCm, d.age);
    final tdee = BodyCalculator.tdee(bmr, d.activityLevel);
    final target =
        BodyCalculator.dailyCalorieTarget(tdee, d.goal, WeightRate.moderate);
    final macros = BodyCalculator.macros(target, d.goal);
    final progress = _progressToGoal();
    final remaining = (d.targetWeightKg - _weight).abs();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            _progressCard(progress, remaining),
            const SizedBox(height: 18),
            _sectionTitle(
                'Ringkasan Hari Ini', 'Pantau kebiasaan sehatmu secara teratur.'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _metricCard(
                      Icons.monitor_weight_outlined,
                      'Berat Badan',
                      '${_weight.toStringAsFixed(1)} kg',
                      'BMI ${bmi.toStringAsFixed(1)}',
                      onTap: _addWeight)),
              const SizedBox(width: 12),
              Expanded(
                  child: _metricCard(Icons.local_fire_department_outlined,
                      'Target Kalori', '${target.round()} kkal', 'Estimasi harian')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _metricCard(Icons.water_drop_outlined, 'Air Minum',
                      '${_water.toStringAsFixed(2)} L', 'Target 2.0 L (+250ml)',
                      onTap: _addWater)),
              const SizedBox(width: 12),
              Expanded(
                  child: _metricCard(Icons.restaurant_outlined, 'Asupan Makanan',
                      '$_caloriesLogged kkal', 'Tap untuk mencatat',
                      onTap: _addFood)),
            ]),
            const SizedBox(height: 20),
            _sectionTitle('Target Nutrisi Makro',
                'Keseimbangan porsi protein, karbohidrat, dan lemak harian.'),
            const SizedBox(height: 10),
            _nutritionCard(target.round(), macros),
            const SizedBox(height: 20),
            _sectionTitle('Checklist Kebiasaan',
                'Disiplin harian untuk hasil yang berkelanjutan.'),
            const SizedBox(height: 10),
            _checkItem('Sarapan tercatat', Icons.restaurant_outlined),
            _checkItem('Minum air cukup', Icons.water_drop_outlined),
            _checkItem('Aktivitas selesai', Icons.fitness_center_outlined),
            const SizedBox(height: 14),
            _premiumCard(),
            const SizedBox(height: 20),
            _sectionTitle(
                'Indeks Massa Tubuh (BMI)', 'Kategori status berat badanmu saat ini.'),
            const SizedBox(height: 10),
            _bmiCard(bmi, category),
          ])),
        ),
      ],
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Selamat Datang',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 3),
                Text(d.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
              ])),
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ResultScreen(data: d))),
            child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.analytics_outlined,
                    color: AppColors.primary)),
          ),
        ]),
      );

  Widget _progressCard(double progress, double remaining) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.glow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Perjalanan Menuju Target',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: .88),
                        fontSize: 13,
                        fontWeight: FontWeight.w600))),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${(progress * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)))
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_weight.toStringAsFixed(1),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800)),
            const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 6),
                child: Text('kg saat ini',
                    style: TextStyle(color: Colors.white70, fontSize: 12))),
            const Spacer(),
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Target: ${d.targetWeightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)))
          ]),
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: .18),
                  valueColor: const AlwaysStoppedAnimation(Colors.white))),
          const SizedBox(height: 10),
          Text(
              remaining < .1
                  ? 'Target tercapai! Pertahankan kebiasaan sehatmu.'
                  : '${remaining.toStringAsFixed(1)} kg lagi menuju target berat idealmu.',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ]),
      );

  Widget _metricCard(
      IconData icon, String title, String value, String subtitle,
      {VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: AppColors.primary, size: 20)),
                if (onTap != null)
                  const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.primary, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
          ]),
        ),
      );

  Widget _nutritionCard(int target, MacroResult macros) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.local_fire_department_rounded,
                color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
                child: Text('$target kkal / hari',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        fontSize: 16))),
            const Text('target',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11))
          ]),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _macro('Protein', '${macros.proteinGram} g')),
            const SizedBox(width: 8),
            Expanded(child: _macro('Karbohidrat', '${macros.carbGram} g')),
            const SizedBox(width: 8),
            Expanded(child: _macro('Lemak Sehat', '${macros.fatGram} g'))
          ]),
        ]),
      );

  Widget _macro(String title, String value) => Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(13)),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontSize: 13)),
        const SizedBox(height: 2),
        Text(title,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5))
      ]));

  Widget _checkItem(String title, IconData icon) {
    final done = _completed.contains(title);
    return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            if (done) {
              _completed.remove(title);
            } else {
              _completed.add(title);
            }
          });
          StorageService.instance.saveCompletedChecklist(_completed);
        },
        child: Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: done
                        ? AppColors.primary.withValues(alpha: .35)
                        : AppColors.border),
                boxShadow: AppShadows.soft),
            child: Row(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color:
                          done ? AppColors.primarySoft : AppColors.background,
                      borderRadius: BorderRadius.circular(11)),
                  child: Icon(done ? Icons.check_rounded : icon,
                      color: done ? AppColors.primary : AppColors.textMuted,
                      size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration:
                              done ? TextDecoration.lineThrough : null))),
              Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: done ? AppColors.primary : AppColors.border,
                  size: 22)
            ])));
  }

  Widget _premiumCard() {
    final isPremium = StorageService.instance.isPremium;
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Member Viora Premium Aktif',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Seluruh panduan menu, analisis, dan jadwal terbuka penuh.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.accent.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.accent),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Viora Premium',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Jadwal makan personal, panduan aktivitas, dan bebas iklan.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  Widget _bmiCard(double bmi, String category) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft),
      child: Row(children: [
        Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.monitor_weight_rounded,
                color: AppColors.primary)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BMI ${bmi.toStringAsFixed(1)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.textDark)),
          const SizedBox(height: 3),
          Text(category,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
        ]))
      ]));

  Widget _meals() {
    final plan = BodyCalculator.mealPlan(d.goal);
    return _tabScaffold('Rencana Makanan', 'Pilihan menu sehat terarah sesuai tujuanmu.', [
      _infoBanner(Icons.restaurant_menu_rounded, 'Pola Makan Seimbang',
          'Menu disusun berdasarkan pembagian kalori dan nutrisi harian untuk menjaga stabilitas energi Anda.'),
      const SizedBox(height: 18),
      _sectionTitle('Rekomendasi Menu Hari Ini', 'Disusun untuk target kalori harianmu.'),
      const SizedBox(height: 10),
      ...plan.map((meal) => _mealTile(meal)),
      const SizedBox(height: 6),
      OutlinedButton.icon(
          onPressed: _addFood,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Catat Asupan Makanan')),
      const SizedBox(height: 14),
      _premiumCard(),
    ]);
  }

  Widget _mealTile(Meal meal) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft),
      child: Row(children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(13)),
            child: Icon(meal.icon, color: AppColors.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(meal.time,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 13.5)),
          const SizedBox(height: 3),
          Text(meal.items.join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11.5, height: 1.35))
        ]))
      ]));

  Widget _activity() {
    final exercises = BodyCalculator.weeklyExercisePlan(d.goal);
    return _tabScaffold(
        'Aktivitas Fisik', 'Gerakan rutin untuk mempercepat pembakaran kalori.', [
      _infoBanner(Icons.directions_run_rounded, 'Konsistensi Bertahap',
          'Mulai dari intensitas yang nyaman dan tingkatkan secara konsisten setiap minggu.'),
      const SizedBox(height: 18),
      _sectionTitle(
          'Target Latihan Mingguan', 'Tandai sesi yang sudah selesai kamu kerjakan.'),
      const SizedBox(height: 10),
      ...exercises.map((e) => _exerciseTile(e)),
    ]);
  }

  Widget _exerciseTile(Exercise e) {
    final done = _completedExercises.contains(e.name);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          if (done) {
            _completedExercises.remove(e.name);
          } else {
            _completedExercises.add(e.name);
          }
        });
        StorageService.instance.saveCompletedExercises(_completedExercises);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done ? AppColors.primary : AppColors.border,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: done ? AppColors.primarySoft : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                done ? Icons.check_rounded : e.icon,
                color: done ? AppColors.primary : AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      fontSize: 13.5,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${e.durationMinutes} menit • '
                    '${e.estimatedKcal} kkal • '
                    'Intensitas ${e.intensity}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: done ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress() {
    final change = _weightHistory.length >= 2
        ? _weightHistory.first - _weightHistory.last
        : 0.0;
    final avg = _weightHistory.isNotEmpty
        ? _weightHistory.reduce((a, b) => a + b) / _weightHistory.length
        : _weight;

    return _tabScaffold('Progres Berat', 'Pantau perubahan berat badan secara berkala.', [
      Row(children: [
        Expanded(
            child: _statBox('Perubahan', '${change.abs().toStringAsFixed(1)} kg',
                change >= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded)),
        const SizedBox(width: 10),
        Expanded(
            child: _statBox('Rata-rata', '${avg.toStringAsFixed(1)} kg',
                Icons.analytics_outlined))
      ]),
      const SizedBox(height: 18),
      _weightChart(),
      const SizedBox(height: 18),
      _sectionTitle('Riwayat Catatan Berat',
          'Data tersimpan aman di penyimpanan lokal perangkat Anda.'),
      const SizedBox(height: 10),
      ...List.generate(_weightHistory.length, (i) => _historyTile(i)),
      const SizedBox(height: 8),
      OutlinedButton.icon(
          onPressed: _addWeight,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Catat Berat Hari Ini')),
      const SizedBox(height: 14),
      _infoBanner(Icons.info_outline_rounded, 'Catatan Fluktuasi Berat',
          'Berat badan wajar mengalami fluktuasi harian akibat cairan dan makanan. Jadikan tren rata-rata mingguan sebagai patokan utama.'),
    ]);
  }

  Widget _statBox(String title, String value, IconData icon) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft),
      child: Row(children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: AppColors.primary, size: 20)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(title,
              style:
                  const TextStyle(fontSize: 10.5, color: AppColors.textMuted))
        ]))
      ]));

  Widget _weightChart() => Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tren Catatan Terakhir',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
        const SizedBox(height: 14),
        SizedBox(
            height: 180,
            child: CustomPaint(
                painter: _WeightChartPainter(_weightHistory, AppColors.primary),
                child: const SizedBox.expand())),
        const SizedBox(height: 8),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Catatan Awal',
              style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
          Text('Terbaru',
              style: TextStyle(fontSize: 9.5, color: AppColors.textMuted))
        ])
      ]));

  Widget _historyTile(int index) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        const Icon(Icons.monitor_weight_outlined,
            color: AppColors.primary, size: 19),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                index == _weightHistory.length - 1
                    ? 'Catatan terkini'
                    : 'Catatan ke-${index + 1}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700))),
        Text('${_weightHistory[index].toStringAsFixed(1)} kg',
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textDark,
                fontWeight: FontWeight.w800))
      ]));

  Widget _profile() {
    final bmr = BodyCalculator.bmr(d.gender, _weight, d.heightCm, d.age);
    final tdee = BodyCalculator.tdee(bmr, d.activityLevel);
    return _tabScaffold('Profil Pengguna', 'Data dasar perhitungan personal Viora.', [
      Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft),
          child: Column(children: [
            Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                    color: AppColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 34)),
            const SizedBox(height: 12),
            Text(d.name,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('${d.age} tahun • ${d.gender.label}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12))
          ])),
      const SizedBox(height: 14),
      _detailRow('Tinggi Badan', '${d.heightCm.toStringAsFixed(0)} cm',
          Icons.height_rounded),
      _detailRow('Berat Awal', '${d.currentWeightKg.toStringAsFixed(1)} kg',
          Icons.monitor_weight_outlined),
      _detailRow('Berat Target', '${d.targetWeightKg.toStringAsFixed(1)} kg',
          Icons.flag_outlined),
      _detailRow(
          'Tingkat Aktivitas', d.activityLevel.label, Icons.directions_run_outlined),
      _detailRow(
          'BMR (Basal Metabolic)', '${bmr.round()} kkal', Icons.local_fire_department_outlined),
      _detailRow('TDEE (Total Kebutuhan)', '${tdee.round()} kkal', Icons.bolt_outlined),
      const SizedBox(height: 12),
      _premiumCard(),
      const SizedBox(height: 16),
      OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ResultScreen(data: d))),
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('Lihat Hasil Analisis & Jadwal Lengkap')),
      const SizedBox(height: 10),
      OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HomeScreen())),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Perbarui Data Tubuh')),
      const SizedBox(height: 10),
      TextButton.icon(
          onPressed: _confirmReset,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
          label: const Text('Atur Ulang Semua Data',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))),
      const SizedBox(height: 8),
      _infoBanner(Icons.privacy_tip_outlined, 'Keamanan Data Pengguna',
          'Data tubuh Anda hanya disimpan di memori lokal perangkat dan tidak dibagikan ke pihak luar tanpa persetujuan Anda.'),
    ]);
  }

  void _confirmReset() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Atur Ulang Semua Data?'),
        content: const Text(
          'Seluruh data profil, catatan berat, air minum, dan progres harian Anda akan dihapus permanen dari perangkat ini.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService.instance.clearAll();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Hapus Data'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value, IconData icon) => Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12))),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)))
      ]));

  Widget _tabScaffold(String title, String subtitle, List<Widget> children) =>
      CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 5),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodyMedium)
                    ]))),
        SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverList(delegate: SliverChildListDelegate(children)))
      ]);

  Widget _infoBanner(IconData icon, String title, String text) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(18)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          const SizedBox(height: 4),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11.5, height: 1.4))
        ]))
      ]));

  Widget _sectionTitle(String title, String subtitle) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5))
      ]);

  double _progressToGoal() {
    final start = d.currentWeightKg;
    final target = d.targetWeightKg;
    if ((start - target).abs() < .1) return 1;
    final total = (start - target).abs();
    final done = d.goal == GoalType.lose
        ? start - _weight
        : d.goal == GoalType.gain
            ? _weight - start
            : 0;
    return (done / total).clamp(0.0, 1.0);
  }

  void _addWater() {
    setState(() => _water = ((_water + 0.25) * 100).round() / 100);
    StorageService.instance.saveWaterIntake(_water);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Catatan air bertambah menjadi ${_water.toStringAsFixed(2)} Liter.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addFood() {
    final nameCtrl = TextEditingController();
    final kcalCtrl = TextEditingController(text: '300');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Catat Asupan Makanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama menu / makanan',
                hintText: 'Misal: Nasi merah & dada ayam',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kcalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Perkiraan kalori',
                suffixText: 'kkal',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final kcal = int.tryParse(kcalCtrl.text) ?? 0;
              if (kcal > 0) {
                setState(() => _caloriesLogged += kcal);
                StorageService.instance.saveCaloriesLogged(_caloriesLogged);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    nameCtrl.text.trim().isNotEmpty
                        ? '${nameCtrl.text.trim()} ($kcal kkal) berhasil dicatat.'
                        : '$kcal kkal berhasil dicatat.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _addWeight() {
    final controller = TextEditingController(text: _weight.toStringAsFixed(1));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Catat Berat Badan'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Berat saat ini',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value == null || value < 25 || value > 300) return;
              setState(() {
                _weight = value;
                _weightHistory.add(value);
                if (_weightHistory.length > 14) {
                  _weightHistory.removeAt(0);
                }
              });
              StorageService.instance.saveWeightHistory(_weightHistory);
              final updatedUser = d.copyWith(currentWeightKg: value);
              StorageService.instance.saveUserData(updatedUser);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Berat berhasil diperbarui ke ${value.toStringAsFixed(1)} kg.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _WeightChartPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b) - .5;
    final max = values.reduce((a, b) => a > b ? a : b) + .5;
    final dx = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - ((values[i] - min) / (max - min) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final grid = Paint()
      ..color = const Color(0xFFE8EEEC)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - ((values[i] - min) / (max - min) * size.height);
      canvas.drawCircle(Offset(x, y), 4.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
