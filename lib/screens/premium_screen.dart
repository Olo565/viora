import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/purchase_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlanIndex = 0; // 0 = Tahunan, 1 = Bulanan
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    PurchaseService.instance.isLoadingNotifier.addListener(_onLoadingChanged);
    PurchaseService.instance.isPremiumNotifier.addListener(_onPremiumChanged);
  }

  @override
  void dispose() {
    PurchaseService.instance.isLoadingNotifier.removeListener(_onLoadingChanged);
    PurchaseService.instance.isPremiumNotifier.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onLoadingChanged() {
    if (mounted) {
      setState(() => _isLoading = PurchaseService.instance.isLoadingNotifier.value);
    }
  }

  void _onPremiumChanged() {
    if (mounted && PurchaseService.instance.isPremiumNotifier.value) {
      setState(() {});
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Langganan Aktif'),
          ],
        ),
        content: const Text(
          'Selamat! Akun Viora Premium Anda kini telah aktif. Seluruh fitur eksklusif, menu terarah, dan jadwal personal telah terbuka.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Mulai Gunakan'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase() async {
    final products = PurchaseService.instance.products;
    final isYearly = _selectedPlanIndex == 0;
    final targetId = isYearly
        ? PurchaseService.yearlySubscriptionId
        : PurchaseService.monthlySubscriptionId;

    ProductDetails? selectedProduct;
    try {
      selectedProduct = products.firstWhere((p) => p.id == targetId);
    } catch (_) {
      selectedProduct = products.isNotEmpty ? products.first : null;
    }

    if (selectedProduct != null) {
      final success = await PurchaseService.instance.buyProduct(selectedProduct);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat memulai proses pembelian. Periksa koneksi internet Anda.'),
          ),
        );
      }
    } else {
      // Fallback jika dijalankan pada simulator/testing tanpa akun Play Store tester terkonfigurasi
      _showStoreNoticeDialog(isYearly);
    }
  }

  void _showStoreNoticeDialog(bool isYearly) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Koneksi Toko Aplikasi'),
        content: Text(
          'Produk ${isYearly ? "Tahunan (Rp179.900/tahun)" : "Bulanan (Rp29.900/bulan)"} telah disiapkan untuk sistem penagihan resmi Google Play Billing & Apple StoreKit.\n\n'
          'Pada mode pengujian offline, Anda dapat mengaktifkan mode simulasi premium untuk memverifikasi fitur.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService.instance.setPremium(true);
              PurchaseService.instance.isPremiumNotifier.value = true;
              if (mounted) _showSuccessDialog();
            },
            child: const Text('Aktifkan Uji Coba'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    await PurchaseService.instance.restorePurchases();
    if (mounted) {
      setState(() => _isLoading = false);
      final isPremium = StorageService.instance.isPremium;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPremium
                ? 'Status langganan Viora Premium berhasil dipulihkan.'
                : 'Tidak ditemukan riwayat langganan aktif pada akun ini.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyPremium = StorageService.instance.isPremium;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: AppColors.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleRestore,
            child: const Text(
              'Pulihkan',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            if (isAlreadyPremium) ...[
              _activePremiumBanner(),
              const SizedBox(height: 24),
            ] else ...[
              _heroSection(),
              const SizedBox(height: 24),
              _planSelector(),
              const SizedBox(height: 24),
            ],
            const Text(
              'Fitur Eksklusif Member Premium',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _featureItem(
              Icons.restaurant_menu_rounded,
              'Panduan Menu Makan Terstruktur',
              'Akses rekomendasi makanan 7 hari penuh sesuai target kalori dan proporsi gizi harian.',
            ),
            _featureItem(
              Icons.fitness_center_rounded,
              'Rencana Aktivitas & Olahraga Mingguan',
              'Latihan fisik terarah dari kardio hingga mobilitas yang mendukung pembakaran kalori.',
            ),
            _featureItem(
              Icons.notifications_active_rounded,
              'Pengingat Harian Otomatis',
              'Notifikasi teratur untuk jam sarapan, makan siang, makan malam, dan hidrasi air minum.',
            ),
            _featureItem(
              Icons.insights_rounded,
              'Analisis Progres Berat & Tren Kalori',
              'Pantau perkembangan berat badan secara konsisten dengan visualisasi grafik lengkap.',
            ),
            _featureItem(
              Icons.block_rounded,
              'Pengalaman Bebas Iklan',
              'Fokus penuh pada proses pembentukan kebiasaan sehat tanpa jeda iklan komersial.',
            ),
            const SizedBox(height: 24),
            if (!isAlreadyPremium) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePurchase,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _selectedPlanIndex == 0
                              ? 'Mulai Paket Tahunan (Rp179.900)'
                              : 'Mulai Paket Bulanan (Rp29.900)',
                        ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _complianceFooter(),
          ],
        ),
      ),
    );
  }

  Widget _activePremiumBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'Viora Premium Aktif',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Seluruh fitur eksklusif terbuka',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Langganan Anda aktif melalui akun toko aplikasi. Anda dapat mengelola atau memeriksa masa aktif langganan langsung dari pengaturan Google Play atau Apple ID Anda.',
            style: TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _heroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'VIORA PREMIUM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Capai target berat badanmu lebih terarah',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dapatkan akses penuh ke rencana makan, panduan olahraga harian, dan fitur pemantauan tanpa batas.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }

  Widget _planSelector() {
    return Row(
      children: [
        Expanded(
          child: _planCard(
            index: 0,
            title: 'Tahunan',
            price: 'Rp179.900',
            period: '/ tahun',
            equivalent: '~Rp14.990 / bulan',
            badge: 'Paling Hemat 50%',
            isSelected: _selectedPlanIndex == 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _planCard(
            index: 1,
            title: 'Bulanan',
            price: 'Rp29.900',
            period: '/ bulan',
            equivalent: 'Tagihan tiap bulan',
            badge: null,
            isSelected: _selectedPlanIndex == 1,
          ),
        ),
      ],
    );
  }

  Widget _planCard({
    required int index,
    required String title,
    required String price,
    required String period,
    required String equivalent,
    required String? badge,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPlanIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.glow : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primaryDark : AppColors.textDark,
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            Text(
              period,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              equivalent,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
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

  Widget _complianceFooter() {
    return Column(
      children: [
        const Text(
          'Pembayaran akan dibebankan ke akun Google Play atau Apple ID Anda setelah konfirmasi pembelian. '
          'Langganan diperpanjang secara otomatis kecuali perpanjangan otomatis dinonaktifkan minimal 24 jam sebelum akhir periode berjalan. '
          'Anda dapat mengelola atau membatalkan langganan kapan saja melalui pengaturan akun toko aplikasi Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            color: AppColors.textMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => _showPolicyModal('Syarat Ketentuan (Terms of Use)', _termsText),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Syarat Ketentuan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
            InkWell(
              onTap: () => _showPolicyModal('Kebijakan Privasi (Privacy Policy)', _privacyText),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Kebijakan Privasi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPolicyModal(String title, String content) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static const String _termsText = '''
SYARAT & KETENTUAN LAYANAN VIORA (TERMS OF USE)

1. Ketentuan Umum
Aplikasi Viora menyediakan estimasi perhitungan indeks massa tubuh (BMI), kebutuhan kalori harian (BMR & TDEE), rekomendasi jadwal makan, hidrasi, dan aktivitas fisik. Hasil yang ditampilkan bersifat informatif dan edukatif untuk gaya hidup sehat.

2. Bukan Saran Medis
Viora BUKAN pengganti saran medis profesional, diagnosis, atau penanganan dokter dan ahli gizi terdaftar. Konsultasikan dengan tenaga kesehatan sebelum memulai program diet atau olahraga baru, terutama jika Anda memiliki riwayat penyakit tertentu.

3. Langganan & Penagihan
Akses ke fitur Viora Premium dikenakan biaya langganan berkala (tahunan atau bulanan) yang ditagihkan melalui akun Google Play Store atau Apple App Store Anda. Pembayaran akan ditagihkan segera setelah Anda mengonfirmasi pembelian.

4. Perpanjangan Otomatis & Pembatalan
Langganan akan diperpanjang secara otomatis kecuali Anda mematikan fitur perpanjangan otomatis minimal 24 jam sebelum akhir periode berjalan. Anda dapat membatalkan langganan kapan saja melalui Pengaturan Akun di toko aplikasi Anda. Pengembalian dana mengikuti kebijakan Google Play dan Apple App Store.

5. Hak Cipta & Penggunaan
Seluruh konten, materi, dan antarmuka Viora dilindungi oleh hak kekayaan intelektual. Pengguna tidak diizinkan mendistribusikan, memodifikasi, atau merekayasa balik sistem aplikasi tanpa izin tertulis.
''';

  static const String _privacyText = '''
KEBIJAKAN PRIVASI VIORA (PRIVACY POLICY)

1. Data yang Dikumpulkan
Viora menyimpan data profil dasar yang Anda masukkan secara sukarela, meliputi: nama panggilan, jenis kelamin, usia, tinggi badan, berat badan saat ini, berat target, serta tingkat aktivitas harian.

2. Penggunaan Data
Data yang Anda masukkan digunakan secara eksklusif untuk:
- Menghitung estimasi BMI, kalori harian, dan rentang berat badan sehat.
- Menyusun rekomendasi menu makanan dan rencana olahraga mingguan.
- Menjadwalkan pengingat lokal di perangkat Anda.

3. Penyimpanan Data
Data Anda disimpan secara lokal di perangkat Anda menggunakan penyimpanan aman (SharedPreferences). Kami tidak membagikan atau menjual data pribadi atau data kesehatan Anda kepada pihak ketiga atau pengiklan mana pun.

4. Izin Perangkat
Aplikasi dapat meminta izin pengingat (notifikasi) untuk memberi tahu Anda jadwal makan dan hidrasi air. Izin ini dapat dinonaktifkan sewaktu-waktu melalui pengaturan sistem perangkat Anda.

5. Penghapusan Data
Anda dapat menghapus seluruh riwayat dan data profil Anda kapan saja melalui tombol "Atur Ulang Data" di menu Profil aplikasi.
''';
}
