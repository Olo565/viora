enum Gender { male, female }

extension GenderX on Gender {
  String get label => this == Gender.male ? 'Pria' : 'Wanita';
}

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

extension ActivityLevelX on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Jarang olahraga';
      case ActivityLevel.light:
        return 'Olahraga ringan (1-3x/minggu)';
      case ActivityLevel.moderate:
        return 'Olahraga sedang (3-5x/minggu)';
      case ActivityLevel.active:
        return 'Aktif (6-7x/minggu)';
      case ActivityLevel.veryActive:
        return 'Sangat aktif / fisik berat';
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }
}

enum GoalType { lose, gain, maintain }

class UserData {
  final String name;
  final Gender gender;
  final int age;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final ActivityLevel activityLevel;

  UserData({
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activityLevel,
  });

  GoalType get goal {
    final diff = targetWeightKg - currentWeightKg;
    if (diff.abs() < 0.5) return GoalType.maintain;
    return diff < 0 ? GoalType.lose : GoalType.gain;
  }

  double get weightDifferenceKg => (targetWeightKg - currentWeightKg).abs();

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender.name,
        'age': age,
        'heightCm': heightCm,
        'currentWeightKg': currentWeightKg,
        'targetWeightKg': targetWeightKg,
        'activityLevel': activityLevel.name,
      };

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        name: json['name'] as String? ?? 'Kamu',
        gender: Gender.values.firstWhere(
          (e) => e.name == json['gender'],
          orElse: () => Gender.male,
        ),
        age: (json['age'] as num?)?.toInt() ?? 25,
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 170.0,
        currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 70.0,
        targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 65.0,
        activityLevel: ActivityLevel.values.firstWhere(
          (e) => e.name == json['activityLevel'],
          orElse: () => ActivityLevel.light,
        ),
      );

  UserData copyWith({
    String? name,
    Gender? gender,
    int? age,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
  }) {
    return UserData(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}

