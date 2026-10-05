# Panduan Rilis & Monetisasi Viora (Google Play & Apple App Store)

Dokumen ini berisi panduan langkah demi langkah untuk melakukan build otomatis di cloud (tanpa memerlukan Mac atau setup Android SDK lokal yang rumit) serta mendaftarkan aplikasi di Google Play Store dan Apple App Store agar Anda dapat menerima pembayaran langganan langsung ke rekening bank Anda.

---

## 1. Otomatisasi Cloud Build (GitHub Actions)

Workflow GitHub Actions sudah terpasang di [`.github/workflows/build_release.yml`](.github/workflows/build_release.yml).

### Cara Menggunakannya:
1. Buat repository baru di akun GitHub Anda (disarankan **Private**).
2. Unggah/Push proyek ini ke GitHub:
   ```bash
   git init
   git add .
   git commit -m "feat: setup Viora production release and monetization"
   git branch -M main
   git remote add origin https://github.com/USERNAME_ANDA/viora.git
   git push -u origin main
   ```
3. Buka tab **Actions** di repositori GitHub Anda.
4. Workflow **Build Release (Android & iOS)** akan otomatis berjalan di server cloud Google/Apple.
5. Setelah selesai (sekitar 4-6 menit), Anda dapat langsung mengunduh:
   - **`viora-playstore-aab`** $\rightarrow$ Berkas `.aab` untuk diunggah ke Google Play Console.
   - **`viora-testing-apk`** $\rightarrow$ Berkas `.apk` siap pasang langsung ke HP Android Anda untuk pengujian offline.
   - **`viora-ios-build`** $\rightarrow$ Berkas build iOS untuk App Store Connect.

---

## 2. Informasi Keystore Rilis Android

Kunci enkripsi rilis Android telah dibuat dan tersimpan aman di:
* **Lokasi:** `android/app/upload-keystore.jks`
* **Alias:** `upload`
* **Kata Sandi Toko & Kunci:** `viorasecure2026`
* **Masa Berlaku:** Hingga 20 Februari 2054 (10.000 hari)

*(Simpan berkas `upload-keystore.jks` ini baik-baik sebagai cadangan di tempat aman. Berkas ini diperlukan setiap kali Anda mengunggah pembaruan versi ke Google Play Store).*

---

## 3. Langkah Mendaftarkan Aplikasi & Langganan di Google Play Console

1. Buka [Google Play Console](https://play.google.com/console).
2. Klik **Create app**:
   - **Nama Aplikasi:** Viora
   - **Default language:** Indonesian (id)
   - **App or game:** App
   - **Free or paid:** Free (dengan langganan di dalam aplikasi)
3. Di menu **Monetize** $\rightarrow$ **Subscriptions**, buat 2 paket langganan:
   - **Paket 1 (Tahunan):**
     * **Product ID:** `viora_premium_yearly`
     * **Harga:** Rp179.900 / tahun (atau setara)
   - **Paket 2 (Bulanan):**
     * **Product ID:** `viora_premium_monthly`
     * **Harga:** Rp29.900 / bulan (atau setara)
4. Masukkan nomor rekening bank Anda di menu **Settings** $\rightarrow$ **Payments profile** agar uang hasil penjualan langganan otomatis ditransfer setiap bulan oleh Google.
5. Di menu **Release** $\rightarrow$ **Production**, buat rilis baru dan unggah berkas `.aab` yang telah diunduh dari GitHub Actions.

---

## 4. Langkah Mendaftarkan Aplikasi di Apple App Store

1. Masuk ke [Apple Developer Portal](https://developer.apple.com) & [App Store Connect](https://appstoreconnect.apple.com).
2. Buat App baru dengan Bundle ID `com.viora.viora` (atau domain Anda).
3. Di menu **Subscriptions**, buat grup langganan dan tambahkan 2 ID produk yang sama:
   - `viora_premium_yearly`
   - `viora_premium_monthly`
4. Di menu **Agreements, Tax, and Banking**, isi formulir rekening bank Indonesia Anda.
5. Halaman Premium Viora sudah dilengkapi **Restore Purchases Button**, **Syarat Layanan (EULA)**, dan **Kebijakan Privasi** yang memenuhi ketentuan *Apple Guideline 3.1.2*.

---

## 5. Menguji Fitur Premium Secara Offline / Tanpa Koneksi Toko

Jika Anda memasang file `.apk` di HP Anda sebelum aplikasi resmi tayang di Play Store:
1. Buka tab **Profil** $\rightarrow$ tap **Viora Premium**.
2. Pilih paket langganan $\rightarrow$ tap **Mulai Paket Tahunan / Bulanan**.
3. Aplikasi akan menampilkan dialog uji coba offline dan memungkinkan Anda mengaktifkan status Premium secara instan untuk mencoba seluruh fitur terkunci.
