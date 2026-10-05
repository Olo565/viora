import 'package:flutter/material.dart';
import '../models/user_data.dart';

enum WeightRate { slow, moderate, fast }

extension WeightRateX on WeightRate {
  double get kgPerWeek {
    switch (this) {
      case WeightRate.slow:
        return 0.25;
      case WeightRate.moderate:
        return 0.5;
      case WeightRate.fast:
        return 0.75;
    }
  }

  String get label {
    switch (this) {
      case WeightRate.slow:
        return 'Santai';
      case WeightRate.moderate:
        return 'Normal';
      case WeightRate.fast:
        return 'Cepat';
    }
  }

  String get sublabel => '${kgPerWeek.toStringAsFixed(2)} kg / minggu';
}

class Meal {
  final String time;
  final IconData icon;
  final List<String> items;
  const Meal({required this.time, required this.icon, required this.items});
}

/// Ikon vektor per waktu makan — konsisten di semua goal (bukan emoji),
/// biar tampilannya rapi & tidak terkesan template AI.
class MealIcons {
  static const IconData breakfast = Icons.free_breakfast_rounded;
  static const IconData lunch = Icons.lunch_dining_rounded;
  static const IconData dinner = Icons.dinner_dining_rounded;
  static const IconData snack = Icons.icecream_rounded;
}

class DayMealPlan {
  final String day;
  final List<Meal> meals;
  const DayMealPlan({required this.day, required this.meals});
}

enum ScheduleType { meal, hydration, exercise }

class ScheduleItem {
  final TimeOfDay time;
  final String title;
  final String description;
  final IconData icon;
  final ScheduleType type;
  const ScheduleItem({
    required this.time,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
  });

  String get timeLabel =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class MacroResult {
  final int proteinGram;
  final int carbGram;
  final int fatGram;
  const MacroResult(this.proteinGram, this.carbGram, this.fatGram);
}

/// Satu sesi olahraga/aktivitas fisik yang mendukung program diet —
/// penurunan/kenaikan berat badan nggak cuma soal makanan.
class Exercise {
  final String name;
  final int durationMinutes;
  final int estimatedKcal;
  final String intensity;
  final IconData icon;
  const Exercise({
    required this.name,
    required this.durationMinutes,
    required this.estimatedKcal,
    required this.intensity,
    required this.icon,
  });
}

/// Rincian kalori & makro untuk satu waktu makan (hasil bagi dari total
/// kebutuhan harian), biar user tahu persis porsi tiap waktu makan.
class MealNutrition {
  final double kcal;
  final int proteinGram;
  final int carbGram;
  final int fatGram;
  const MealNutrition({
    required this.kcal,
    required this.proteinGram,
    required this.carbGram,
    required this.fatGram,
  });
}

class BodyCalculator {
  /// BMI = berat(kg) / tinggi(m)^2
  static double bmi(double weightKg, double heightCm) {
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  static String bmiCategory(double bmiValue) {
    if (bmiValue < 18.5) return 'Kurus';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Kelebihan Berat Badan';
    return 'Obesitas';
  }

  /// Rentang berat ideal berdasarkan BMI sehat 18.5 - 24.9
  static (double min, double max) idealWeightRange(double heightCm) {
    final h = heightCm / 100;
    final min = 18.5 * h * h;
    final max = 24.9 * h * h;
    return (min, max);
  }

  /// BMR memakai rumus Mifflin-St Jeor
  static double bmr(Gender gender, double weightKg, double heightCm, int age) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == Gender.male ? base + 5 : base - 161;
  }

  static double tdee(double bmrValue, ActivityLevel level) =>
      bmrValue * level.multiplier;

  static int durationWeeks(double weightDifferenceKg, WeightRate rate) {
    if (weightDifferenceKg <= 0) return 0;
    return (weightDifferenceKg / rate.kgPerWeek).ceil();
  }

  /// 1 kg lemak tubuh ~ 7700 kkal. Dipakai untuk hitung defisit/surplus harian.
  static double dailyCalorieTarget(
      double tdeeValue, GoalType goal, WeightRate rate) {
    final dailyAdjustment = (rate.kgPerWeek * 7700) / 7;
    switch (goal) {
      case GoalType.lose:
        final target = tdeeValue - dailyAdjustment;
        return target; // estimasi; aplikasi produksi perlu validasi keselamatan tambahan
      case GoalType.gain:
        return tdeeValue + dailyAdjustment;
      case GoalType.maintain:
        return tdeeValue;
    }
  }

  static MacroResult macros(double calorieTarget, GoalType goal) {
    double proteinPct, carbPct, fatPct;
    switch (goal) {
      case GoalType.lose:
        proteinPct = 0.35;
        carbPct = 0.35;
        fatPct = 0.30;
        break;
      case GoalType.gain:
        proteinPct = 0.25;
        carbPct = 0.50;
        fatPct = 0.25;
        break;
      case GoalType.maintain:
        proteinPct = 0.30;
        carbPct = 0.40;
        fatPct = 0.30;
        break;
    }
    final proteinGram = (calorieTarget * proteinPct / 4).round();
    final carbGram = (calorieTarget * carbPct / 4).round();
    final fatGram = (calorieTarget * fatPct / 9).round();
    return MacroResult(proteinGram, carbGram, fatGram);
  }

  static List<Meal> mealPlan(GoalType goal) {
    switch (goal) {
      case GoalType.lose:
        return const [
          Meal(time: 'Sarapan', icon: MealIcons.breakfast, items: [
            'Oatmeal + potongan buah segar',
            '2 putih telur rebus',
            'Teh tawar / air lemon hangat',
          ]),
          Meal(time: 'Makan Siang', icon: MealIcons.lunch, items: [
            'Dada ayam panggang / kukus 100g',
            'Nasi merah porsi kecil',
            'Tumis / rebus sayuran hijau',
          ]),
          Meal(time: 'Makan Malam', icon: MealIcons.dinner, items: [
            'Ikan kukus atau tahu-tempe panggang',
            'Sayur bening / salad tanpa dressing berat',
            'Porsi karbohidrat disesuaikan dengan kebutuhan harian',
          ]),
          Meal(time: 'Camilan', icon: MealIcons.snack, items: [
            'Buah potong (apel, pir, jeruk)',
            'Segenggam kecil almond / kacang tanpa garam',
          ]),
        ];
      case GoalType.gain:
        return const [
          Meal(time: 'Sarapan', icon: MealIcons.breakfast, items: [
            'Telur utuh 2-3 butir + roti gandum',
            'Alpukat / selai kacang',
            'Susu tinggi protein',
          ]),
          Meal(time: 'Makan Siang', icon: MealIcons.lunch, items: [
            'Nasi porsi penuh + daging sapi/ayam 150g',
            'Tempe atau tahu goreng',
            'Sayur + jus buah tanpa gula tambahan',
          ]),
          Meal(time: 'Makan Malam', icon: MealIcons.dinner, items: [
            'Ikan / ayam + nasi',
            'Sayur santan ringan atau tumisan minyak zaitun',
            'Segelas susu sebelum tidur',
          ]),
          Meal(time: 'Camilan', icon: MealIcons.snack, items: [
            'Kacang-kacangan, pisang, atau yogurt',
            'Smoothie protein + oats',
          ]),
        ];
      case GoalType.maintain:
        return const [
          Meal(time: 'Sarapan', icon: MealIcons.breakfast, items: [
            'Roti gandum + telur + sayur',
            'Buah secukupnya',
          ]),
          Meal(time: 'Makan Siang', icon: MealIcons.lunch, items: [
            'Nasi porsi sedang + lauk protein',
            'Sayur berwarna-warni',
          ]),
          Meal(time: 'Makan Malam', icon: MealIcons.dinner, items: [
            'Protein + sayur, porsi seimbang',
          ]),
          Meal(time: 'Camilan', icon: MealIcons.snack, items: [
            'Buah atau kacang secukupnya',
          ]),
        ];
    }
  }

  static const List<String> weekDays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  /// Index hari ini (0 = Senin ... 6 = Minggu), sesuai DateTime.now().weekday (1-7).
  static int todayIndex() => DateTime.now().weekday - 1;

  /// Jadwal makan 7 hari penuh, menu berbeda tiap hari supaya tidak monoton,
  /// tapi tetap konsisten dengan target kalori & goal (turun/naik/pertahankan).
  static List<DayMealPlan> weeklyMealPlan(GoalType goal) {
    late List<List<String>> breakfast, lunch, dinner, snack;

    switch (goal) {
      case GoalType.lose:
        breakfast = [
          ['Oatmeal + potongan pisang', 'Teh tawar hangat'],
          ['2 telur rebus + tomat', 'Air lemon hangat'],
          ['Roti gandum + telur orak-arik', 'Susu rendah lemak'],
          ['Bubur ayam tanpa kulit, nasi sedikit', 'Buah pepaya'],
          ['Smoothie bayam + pisang + susu rendah lemak', '-'],
          ['Ubi rebus + telur rebus', 'Teh hijau tawar'],
          ['Salad buah + yogurt plain', 'Air putih'],
        ];
        lunch = [
          ['Dada ayam panggang 100g + nasi merah', 'Tumis brokoli'],
          ['Ikan bakar + nasi merah porsi kecil', 'Salad sayur'],
          ['Tumis tahu tempe + nasi merah', 'Sup sayur bening'],
          ['Dada ayam kukus + kentang rebus', 'Sayur bayam'],
          ['Ikan kukus + nasi merah', 'Capcay rebus'],
          ['Sup ayam sayuran', 'Nasi merah porsi kecil'],
          ['Tahu tempe bacem rendah gula + nasi merah', 'Lalapan segar'],
        ];
        dinner = [
          ['Ikan kukus + tumis kangkung (tanpa nasi)', ''],
          ['Dada ayam panggang + salad (tanpa nasi)', ''],
          ['Sup tahu sayuran (tanpa nasi)', ''],
          ['Telur dadar sayur + lalapan (tanpa nasi)', ''],
          ['Ikan bakar + tumis buncis (tanpa nasi)', ''],
          ['Ayam suwir tanpa kulit + sayur rebus', ''],
          ['Sup jamur tahu (tanpa nasi)', ''],
        ];
        snack = [
          ['Buah apel'],
          ['Segenggam kecil almond'],
          ['Yogurt plain rendah lemak'],
          ['Buah jeruk'],
          ['Edamame rebus'],
          ['Buah pir'],
          ['Infused water + timun'],
        ];
        break;

      case GoalType.gain:
        breakfast = [
          ['Telur 3 butir + roti gandum + selai kacang', 'Susu full cream'],
          ['Nasi uduk + ayam suwir + telur', 'Jus alpukat'],
          ['Oatmeal + pisang + madu + kacang', 'Susu tinggi protein'],
          ['Roti lapis telur + keju + alpukat', 'Susu coklat'],
          ['Nasi goreng + telur ceplok', 'Jus mangga'],
          ['Bubur kacang hijau + roti', 'Susu full cream'],
          ['Pancake pisang + madu', 'Smoothie protein'],
        ];
        lunch = [
          ['Nasi + rendang/daging sapi + tempe', 'Sayur santan'],
          ['Nasi + ayam goreng + tahu', 'Sup sayur'],
          ['Nasi + ikan goreng + telur dadar', 'Tumis kangkung'],
          ['Nasi + sate ayam + lontong', 'Gado-gado'],
          ['Nasi + gulai ayam + tempe', 'Sayur asem'],
          ['Nasi + soto daging', 'Kerupuk + tempe goreng'],
          ['Nasi + ayam bakar + tahu goreng', 'Lalapan sambal'],
        ];
        dinner = [
          ['Nasi + ikan goreng + sayur santan', 'Susu sebelum tidur'],
          ['Nasi + ayam panggang + tempe', 'Susu sebelum tidur'],
          ['Nasi + telur balado + tahu', 'Susu sebelum tidur'],
          ['Nasi + daging semur + sayur', 'Susu sebelum tidur'],
          ['Nasi + ikan bakar + tumis tauge', 'Susu sebelum tidur'],
          ['Nasi + ayam kecap + tempe', 'Susu sebelum tidur'],
          ['Nasi + sup iga sapi', 'Susu sebelum tidur'],
        ];
        snack = [
          ['Pisang + selai kacang'],
          ['Kacang campur (mixed nuts)'],
          ['Yogurt + granola'],
          ['Smoothie oats + susu'],
          ['Roti + keju'],
          ['Kurma + susu'],
          ['Alpukat kocok + madu'],
        ];
        break;

      case GoalType.maintain:
        breakfast = [
          ['Roti gandum + telur + sayur'],
          ['Nasi + telur + tempe'],
          ['Oatmeal + buah'],
          ['Bubur ayam'],
          ['Roti + selai + susu'],
          ['Nasi uduk sederhana + telur'],
          ['Pancake + buah'],
        ];
        lunch = [
          ['Nasi + ayam + sayur'],
          ['Nasi + ikan + sayur'],
          ['Nasi + tahu tempe + sayur'],
          ['Nasi + daging + sayur'],
          ['Nasi + telur + sayur'],
          ['Soto ayam + nasi'],
          ['Nasi + ayam bakar + lalapan'],
        ];
        dinner = [
          ['Sayur + protein, porsi seimbang'],
          ['Sup + nasi porsi kecil'],
          ['Tumis sayur + tahu/tempe'],
          ['Ikan + sayur'],
          ['Ayam + sayur'],
          ['Sup sayur + telur'],
          ['Nasi + lauk ringan'],
        ];
        snack = [
          ['Buah secukupnya'],
          ['Segenggam kacang'],
          ['Yogurt'],
          ['Buah secukupnya'],
          ['Biskuit gandum'],
          ['Buah secukupnya'],
          ['Puding buah'],
        ];
        break;
    }

    return List.generate(7, (i) {
      return DayMealPlan(
        day: weekDays[i],
        meals: [
          Meal(
              time: 'Sarapan',
              icon: MealIcons.breakfast,
              items: breakfast[i].where((e) => e.trim().isNotEmpty).toList()),
          Meal(
              time: 'Makan Siang',
              icon: MealIcons.lunch,
              items: lunch[i].where((e) => e.trim().isNotEmpty).toList()),
          Meal(
              time: 'Makan Malam',
              icon: MealIcons.dinner,
              items: dinner[i].where((e) => e.trim().isNotEmpty).toList()),
          Meal(
              time: 'Camilan',
              icon: MealIcons.snack,
              items: snack[i].where((e) => e.trim().isNotEmpty).toList()),
        ],
      );
    });
  }

  /// Distribusi kalori & makro harian ke tiap waktu makan.
  static const Map<String, double> _mealFraction = {
    'Sarapan': 0.25,
    'Makan Siang': 0.35,
    'Makan Malam': 0.30,
    'Camilan': 0.10,
  };

  static MealNutrition nutritionFor(
      String mealLabel, double calorieTarget, MacroResult macro) {
    final frac = _mealFraction[mealLabel] ?? 0.25;
    return MealNutrition(
      kcal: calorieTarget * frac,
      proteinGram: (macro.proteinGram * frac).round(),
      carbGram: (macro.carbGram * frac).round(),
      fatGram: (macro.fatGram * frac).round(),
    );
  }

  static String _nutritionLabel(MealNutrition n) =>
      '~${n.kcal.round()} kkal • P${n.proteinGram}g K${n.carbGram}g L${n.fatGram}g';

  /// Variasi minuman tiap hari biar nggak monoton cuma "air putih" mulu.
  static const List<String> _drinkVariants = [
    '1 gelas air putih',
    '1 gelas infused water lemon',
    '1 gelas air putih hangat',
    '1 gelas teh hijau tawar',
    '1 gelas infused water timun-mint',
    '1 gelas air putih',
    '1 gelas air kelapa (tanpa gula tambahan)',
  ];

  /// Jadwal olahraga mingguan — beda fokus tergantung tujuan (turun fokus
  /// kardio, naik fokus latihan beban, pertahankan dicampur).
  static List<Exercise> weeklyExercisePlan(GoalType goal) {
    switch (goal) {
      case GoalType.lose:
        return const [
          Exercise(
              name: 'Jalan Cepat',
              durationMinutes: 30,
              estimatedKcal: 150,
              intensity: 'Ringan',
              icon: Icons.directions_walk_rounded),
          Exercise(
              name: 'Jogging Ringan',
              durationMinutes: 25,
              estimatedKcal: 220,
              intensity: 'Sedang',
              icon: Icons.directions_run_rounded),
          Exercise(
              name: 'HIIT 20 Menit (jumping jack, mountain climber)',
              durationMinutes: 20,
              estimatedKcal: 200,
              intensity: 'Berat',
              icon: Icons.fitness_center_rounded),
          Exercise(
              name: 'Bersepeda Santai',
              durationMinutes: 30,
              estimatedKcal: 180,
              intensity: 'Sedang',
              icon: Icons.directions_bike_rounded),
          Exercise(
              name: 'Renang',
              durationMinutes: 30,
              estimatedKcal: 250,
              intensity: 'Sedang',
              icon: Icons.pool_rounded),
          Exercise(
              name: 'Yoga & Stretching',
              durationMinutes: 20,
              estimatedKcal: 90,
              intensity: 'Ringan',
              icon: Icons.self_improvement_rounded),
          Exercise(
              name: 'Jalan Santai + Peregangan (pemulihan)',
              durationMinutes: 20,
              estimatedKcal: 100,
              intensity: 'Ringan',
              icon: Icons.directions_walk_rounded),
        ];
      case GoalType.gain:
        return const [
          Exercise(
              name: 'Latihan Beban Dasar (squat, push up, lunges)',
              durationMinutes: 30,
              estimatedKcal: 180,
              intensity: 'Sedang',
              icon: Icons.fitness_center_rounded),
          Exercise(
              name: 'Latihan Tubuh Bagian Atas',
              durationMinutes: 25,
              estimatedKcal: 150,
              intensity: 'Sedang',
              icon: Icons.fitness_center_rounded),
          Exercise(
              name: 'Latihan Tubuh Bagian Bawah & Core',
              durationMinutes: 30,
              estimatedKcal: 190,
              intensity: 'Berat',
              icon: Icons.fitness_center_rounded),
          Exercise(
              name: 'Istirahat Aktif: Jalan Santai',
              durationMinutes: 20,
              estimatedKcal: 90,
              intensity: 'Ringan',
              icon: Icons.directions_walk_rounded),
          Exercise(
              name: 'Full Body Circuit Training',
              durationMinutes: 30,
              estimatedKcal: 200,
              intensity: 'Berat',
              icon: Icons.fitness_center_rounded),
          Exercise(
              name: 'Yoga & Mobility',
              durationMinutes: 20,
              estimatedKcal: 80,
              intensity: 'Ringan',
              icon: Icons.self_improvement_rounded),
          Exercise(
              name: 'Latihan Fungsional Ringan',
              durationMinutes: 25,
              estimatedKcal: 150,
              intensity: 'Sedang',
              icon: Icons.sports_gymnastics_rounded),
        ];
      case GoalType.maintain:
        return const [
          Exercise(
              name: 'Jalan Kaki',
              durationMinutes: 25,
              estimatedKcal: 130,
              intensity: 'Ringan',
              icon: Icons.directions_walk_rounded),
          Exercise(
              name: 'Bersepeda',
              durationMinutes: 25,
              estimatedKcal: 160,
              intensity: 'Sedang',
              icon: Icons.directions_bike_rounded),
          Exercise(
              name: 'Latihan Beban Ringan',
              durationMinutes: 25,
              estimatedKcal: 150,
              intensity: 'Sedang',
              icon: Icons.fitness_center_rounded),
          Exercise(
              name: 'Yoga',
              durationMinutes: 20,
              estimatedKcal: 90,
              intensity: 'Ringan',
              icon: Icons.self_improvement_rounded),
          Exercise(
              name: 'Badminton / Olahraga Tim',
              durationMinutes: 30,
              estimatedKcal: 200,
              intensity: 'Sedang',
              icon: Icons.sports_tennis_rounded),
          Exercise(
              name: 'Renang Santai',
              durationMinutes: 25,
              estimatedKcal: 180,
              intensity: 'Sedang',
              icon: Icons.pool_rounded),
          Exercise(
              name: 'Peregangan & Istirahat Aktif',
              durationMinutes: 15,
              estimatedKcal: 60,
              intensity: 'Ringan',
              icon: Icons.self_improvement_rounded),
        ];
    }
  }

  /// Gabungkan jam makan + minum + olahraga + rincian gizi jadi satu
  /// timeline harian, biar user tahu persis "jam segini ngapain, makan apa,
  /// berapa kalori & gramnya" sampai malam — bukan cuma dari makanan doang.
  static List<ScheduleItem> dailySchedule(
    DayMealPlan dayPlan,
    int dayIndex,
    GoalType goal,
    double calorieTarget,
    MacroResult macro,
  ) {
    final byLabel = {for (final m in dayPlan.meals) m.time: m};
    final breakfast = byLabel['Sarapan']!;
    final lunch = byLabel['Makan Siang']!;
    final dinner = byLabel['Makan Malam']!;
    final snack = byLabel['Camilan']!;
    final exercise = weeklyExercisePlan(goal)[dayIndex];
    final drink = _drinkVariants[dayIndex];

    String mealDesc(Meal m) =>
        '${m.items.join(' • ')}\n${_nutritionLabel(nutritionFor(m.time, calorieTarget, macro))}';

    return [
      ScheduleItem(
        time: const TimeOfDay(hour: 6, minute: 30),
        title: 'Minum Air',
        description: '$drink saat bangun tidur',
        icon: Icons.local_drink_rounded,
        type: ScheduleType.hydration,
      ),
      ScheduleItem(
        time: const TimeOfDay(hour: 7, minute: 0),
        title: breakfast.time,
        description: mealDesc(breakfast),
        icon: breakfast.icon,
        type: ScheduleType.meal,
      ),
      ScheduleItem(
        time: const TimeOfDay(hour: 9, minute: 30),
        title: 'Minum Air',
        description: drink,
        icon: Icons.local_drink_rounded,
        type: ScheduleType.hydration,
      ),
      ScheduleItem(
        time: const TimeOfDay(hour: 12, minute: 0),
        title: lunch.time,
        description: mealDesc(lunch),
        icon: lunch.icon,
        type: ScheduleType.meal,
      ),
      ScheduleItem(
        time: const TimeOfDay(hour: 14, minute: 0),
        title: 'Minum Air',
        description: drink,
        icon: Icons.local_drink_rounded,
        type: ScheduleType.hydration,
      ),
      ScheduleItem(
        time: const TimeOfDay(hour: 15, minute: 30),
        title: snack.time,
        description: mealDesc(snack),
        icon: snack.icon,
        type: ScheduleType.meal,
      ),
      ScheduleItem(
        time: const TimeOfDay(hour: 16, minute: 30),
        title: exercise.name,
        description:
            '${exercise.durationMinutes} menit • ~${exercise.estimatedKcal} kkal terbakar • Intensitas ${exercise.intensity}',
        icon: exercise.icon,
        type: ScheduleType.exercise,
      ),
      ScheduleItem(
        time: const TimeOfDay(hour: 17, minute: 30),
        title: 'Minum Air',
        description: drink,
        icon: Icons.local_drink_rounded,
        type: ScheduleType.hydration,
      ),
      ScheduleItem(
        time: const TimeOfDay(hour: 18, minute: 30),
        title: dinner.time,
        description: mealDesc(dinner),
        icon: dinner.icon,
        type: ScheduleType.meal,
      ),
      ScheduleItem(
        time: const TimeOfDay(hour: 21, minute: 0),
        title: 'Minum Air',
        description: '$drink sebelum tidur',
        icon: Icons.local_drink_rounded,
        type: ScheduleType.hydration,
      ),
    ];
  }
}
