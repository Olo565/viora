import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.light;

  @override
  void initState() {
    super.initState();
    final existing = StorageService.instance.getUserData();
    if (existing != null) {
      _nameCtrl.text = existing.name == 'Kamu' ? '' : existing.name;
      _ageCtrl.text = existing.age.toString();
      _heightCtrl.text = existing.heightCm.toStringAsFixed(0);
      _currentWeightCtrl.text = existing.currentWeightKg.toStringAsFixed(1);
      _targetWeightCtrl.text = existing.targetWeightKg.toStringAsFixed(1);
      _gender = existing.gender;
      _activity = existing.activityLevel;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  double _parseNumber(String value) => double.parse(value.replaceAll(',', '.'));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final data = UserData(
      name: _nameCtrl.text.trim().isEmpty ? 'Pengguna' : _nameCtrl.text.trim(),
      gender: _gender,
      age: int.parse(_ageCtrl.text),
      heightCm: _parseNumber(_heightCtrl.text),
      currentWeightKg: _parseNumber(_currentWeightCtrl.text),
      targetWeightKg: _parseNumber(_targetWeightCtrl.text),
      activityLevel: _activity,
    );
    await StorageService.instance.saveUserData(data);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(data: data, isFromOnboarding: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          return SingleChildScrollView(
            padding:
                EdgeInsets.fromLTRB(wide ? 42 : 20, 20, wide ? 42 : 20, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 760 : 600),
                child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _brandHeader(),
                          const SizedBox(height: 28),
                          _heroCard(),
                          const SizedBox(height: 24),
                          const Text('Kenali kondisi tubuhmu',
                              style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 5),
                          const Text(
                              'Isi data dasar untuk mendapatkan ringkasan awal yang dipersonalisasi.',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12.5)),
                          const SizedBox(height: 20),
                          _fieldLabel('Nama', optional: true),
                          TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.person_outline_rounded),
                                  hintText: 'Nama kamu')),
                          const SizedBox(height: 18),
                          _fieldLabel('Jenis kelamin'),
                          Row(children: [
                            _choice(
                                'Pria',
                                Icons.male_rounded,
                                _gender == Gender.male,
                                () => setState(() => _gender = Gender.male)),
                            const SizedBox(width: 12),
                            _choice(
                                'Wanita',
                                Icons.female_rounded,
                                _gender == Gender.female,
                                () => setState(() => _gender = Gender.female)),
                          ]),
                          const SizedBox(height: 18),
                          Row(children: [
                            Expanded(
                                child: _numberField(
                                    _ageCtrl, 'Usia', 'tahun', 18, 100)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _numberField(
                                    _heightCtrl, 'Tinggi badan', 'cm', 100, 250,
                                    decimal: true)),
                          ]),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                                child: _numberField(_currentWeightCtrl,
                                    'Berat saat ini', 'kg', 25, 300,
                                    decimal: true)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _numberField(_targetWeightCtrl,
                                    'Berat target', 'kg', 25, 300,
                                    decimal: true)),
                          ]),
                          const SizedBox(height: 18),
                          _fieldLabel('Aktivitas harian'),
                          DropdownButtonFormField<ActivityLevel>(
                            initialValue: _activity,
                            decoration: const InputDecoration(
                                prefixIcon:
                                    Icon(Icons.directions_run_outlined)),
                            items: ActivityLevel.values
                                .map((a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a.label,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _activity = v ?? ActivityLevel.light),
                          ),
                          const SizedBox(height: 22),
                          _notice(),
                          const SizedBox(height: 20),
                          SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                  onPressed: _submit,
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label:
                                      const Text('Lihat rekomendasi Viora'))),
                        ])),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _brandHeader() => Row(children: [
        Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(15)),
            child:
                const Icon(Icons.eco_rounded, color: Colors.white, size: 25)),
        const SizedBox(width: 12),
        const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('VIORA',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2)),
          Text('Mulai Perubahanmu.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5))
        ])),
        IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded,
                color: AppColors.textMuted)),
      ]);

  Widget _heroCard() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft),
      child: Row(children: [
        Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(17)),
            child: const Icon(Icons.insights_rounded,
                color: AppColors.primary, size: 27)),
        const SizedBox(width: 14),
        const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rencanakan dengan data',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          SizedBox(height: 4),
          Text(
              'Viora membantu memantau berat, kalori, makanan, dan aktivitas dalam satu tempat.',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 11.5, height: 1.4))
        ])),
      ]));

  Widget _fieldLabel(String label, {bool optional = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
        if (optional) ...[
          const SizedBox(width: 6),
          const Text('Opsional',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10.5))
        ]
      ]));

  Widget _choice(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 21),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primaryDark : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label,
          String unit, num min, num max,
          {bool decimal = false}) =>
      TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          decoration: InputDecoration(labelText: label, suffixText: unit),
          validator: (value) {
            final n = double.tryParse(value?.replaceAll(',', '.') ?? '');
            if (n == null) return 'Masukkan angka';
            if (n < min || n > max) return '$min–$max';
            return null;
          });

  Widget _notice() => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.primarySoft.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(16)),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 19),
        SizedBox(width: 10),
        Expanded(
            child: Text(
                'Hasil Viora adalah estimasi untuk membantu pemantauan gaya hidup, bukan diagnosis medis.',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 10.8, height: 1.4)))
      ]));
}
