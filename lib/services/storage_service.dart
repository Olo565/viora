import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _keyUserData = 'viora_user_data';
  static const String _keyOnboardingDone = 'viora_onboarding_done';
  static const String _keyIsPremium = 'viora_is_premium';
  static const String _keyWeightHistory = 'viora_weight_history';
  static const String _keyWaterIntake = 'viora_water_intake';
  static const String _keyCaloriesLogged = 'viora_calories_logged';
  static const String _keyCompletedChecklist = 'viora_completed_checklist';
  static const String _keyCompletedExercises = 'viora_completed_exercises';
  static const String _keySelectedWeightRate = 'viora_selected_weight_rate';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Onboarding & User Data ---
  bool get hasCompletedOnboarding =>
      _prefs?.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    final p = await _ensurePrefs();
    await p.setBool(_keyOnboardingDone, value);
  }

  UserData? getUserData() {
    if (_prefs == null) return null;
    final raw = _prefs!.getString(_keyUserData);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserData(UserData data) async {
    final p = await _ensurePrefs();
    final jsonStr = jsonEncode(data.toJson());
    await p.setString(_keyUserData, jsonStr);
    await setOnboardingCompleted(true);
  }

  // --- Premium Entitlement ---
  bool get isPremium => _prefs?.getBool(_keyIsPremium) ?? false;

  Future<void> setPremium(bool value) async {
    final p = await _ensurePrefs();
    await p.setBool(_keyIsPremium, value);
  }

  // --- Weight History ---
  List<double> getWeightHistory(double initialWeight) {
    if (_prefs == null) return [initialWeight];
    final list = _prefs!.getStringList(_keyWeightHistory);
    if (list == null || list.isEmpty) {
      return [initialWeight];
    }
    return list.map((e) => double.tryParse(e) ?? initialWeight).toList();
  }

  Future<void> saveWeightHistory(List<double> history) async {
    final p = await _ensurePrefs();
    final list = history.map((e) => e.toStringAsFixed(1)).toList();
    await p.setStringList(_keyWeightHistory, list);
  }

  // --- Daily Water Intake ---
  double get waterIntake => _prefs?.getDouble(_keyWaterIntake) ?? 1.0;

  Future<void> saveWaterIntake(double liters) async {
    final p = await _ensurePrefs();
    await p.setDouble(_keyWaterIntake, liters);
  }

  // --- Daily Calories Logged ---
  int get caloriesLogged => _prefs?.getInt(_keyCaloriesLogged) ?? 0;

  Future<void> saveCaloriesLogged(int kcal) async {
    final p = await _ensurePrefs();
    await p.setInt(_keyCaloriesLogged, kcal);
  }

  // --- Daily Checklist ---
  Set<String> get completedChecklist {
    if (_prefs == null) return {};
    final list = _prefs!.getStringList(_keyCompletedChecklist);
    return list?.toSet() ?? {};
  }

  Future<void> saveCompletedChecklist(Set<String> items) async {
    final p = await _ensurePrefs();
    await p.setStringList(_keyCompletedChecklist, items.toList());
  }

  // --- Completed Exercises ---
  Set<String> get completedExercises {
    if (_prefs == null) return {};
    final list = _prefs!.getStringList(_keyCompletedExercises);
    return list?.toSet() ?? {};
  }

  Future<void> saveCompletedExercises(Set<String> items) async {
    final p = await _ensurePrefs();
    await p.setStringList(_keyCompletedExercises, items.toList());
  }

  // --- Weight Rate ---
  int get selectedWeightRateIndex =>
      _prefs?.getInt(_keySelectedWeightRate) ?? 1;

  Future<void> saveSelectedWeightRateIndex(int index) async {
    final p = await _ensurePrefs();
    await p.setInt(_keySelectedWeightRate, index);
  }

  // --- Reset All Data ---
  Future<void> clearAll() async {
    final p = await _ensurePrefs();
    await p.clear();
  }
}
