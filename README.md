# 🧾 Laci POS — Modern Offline-First Point of Sale

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20BLoC-brightgreen)](#arsitektur--teknologi)
[![Database](https://img.shields.io/badge/Database-Drift%20(SQLite)%20%2B%20Firestore-orange)](#arsitektur--teknologi)
[![License Model](https://img.shields.io/badge/Model-Freemium%20(Voucher%20%26%20IAP%20Ready)-blueviolet)](#model-bisnis--freemium)

**Laci POS** adalah aplikasi kasir pintar (*Point of Sale*) multi-platform (Android, iOS, macOS) yang dirancang khusus untuk UMKM Indonesia. Dibangun dengan pendekatan **Offline-First**, aplikasi tetap berfungsi 100% saat tidak ada koneksi internet dan melakukan sinkronisasi otomatis ke cloud saat online.

---

## 🌟 Fitur Utama

### 🛒 Kasir & Transaksi Cepat
- **In-place Barcode/QR Scanner**: Pemindaian barcode produk langsung dari layar kasir tanpa jeda.
- **Held Orders (Pending Order)**: Simpan transaksi pelanggan sementara dan buka kembali kapan saja.
- **Kalkulasi Pajak & Service Charge**: Pengaturan dinamis persentase PPN dan biaya layanan.
- **Metode Pembayaran Fleksibel**: Tunai, QRIS, Transfer Bank, dan Debit dengan kalkulasi kembalian otomatis.

### 👥 Multi-Kasir & Manajemen Shift
- **PIN Cepat Kasir**: Penguncian layar kasir dengan otentikasi PIN 4-digit instan.
- **Buka & Tutup Kasir (Cash Drawer)**: Pencatatan modal awal kasir (*starting float*) dan rekonsiliasi uang fisik saat tutup shift.
- **Shift Handover (Serah Terima Kas)**: Fitur estafet modal kasir antar kasir tanpa selisih pembukuan.

### 🖨️ Cetak Struk & Kustomisasi
- **Thermal Bluetooth Printer**: Dukungan printer thermal 58mm & 80mm via ESC/POS protocol.
- **Format Struk Fleksibel**: Pilihan cetak teks cepat (*raw ESC/POS*) atau cetak grafis bitmap struk rapi.
- **Kustomisasi Struk**: Pasang logo toko, ubah catatan kaki (*footer*), dan atur tampilan watermark.

### 📊 Laporan Finansial & HPP
- **Analisis Laba Kotor**: Perhitungan omset vs Modal Pokok (HPP) untuk mengetahui laba bersih riil.
- **Visualisasi Grafik**: Grafik tren penjualan harian dan bulanan.
- **Export Excel & PDF**: Unduh rekapitulasi transaksi untuk keperluan akuntansi toko.

---

## 💎 Model Bisnis & Freemium

Aplikasi ini menerapkan arsitektur **Freemium** yang ramah UMKM sekaligus siap untuk monetisasi:

| Fitur | Free Tier | Pro Tier 👑 |
|---|---|---|
| **Katalog Produk** | Hingga 150 Produk | **Tanpa Batas (Unlimited)** |
| **Kasir & Transaksi** | Multi-transaksi harian | **Multi-transaksi harian** |
| **Multi-Kasir & PIN** | 1 Akun Kasir | **Banyak Kasir + Hak Akses Staf** |
| **Cetak Struk Thermal** | Ya (Dengan Watermark) | **Logo Sendiri & Bebas Watermark** |
| **Laporan & HPP** | Ringkasan Penjualan | **Analisis Laba Bersih, HPP, & Export PDF/Excel** |
| **Cloud Sync & Backup** | Local Database (Drift) | **Auto Cloud Backup Multi-Perangkat** |

### 🔑 Arsitektur Lisensi Pro
1. **Kode Voucher Lisensi (Offline & Standalone)**:
   - Menggunakan `LicenseService` dengan verifikasi kriptografi (*HMAC SHA-256 signature validation*).
   - Pengguna dapat mengaktifkan lisensi Pro secara instan via kode voucher tanpa ketergantungan toko aplikasi pihak ketiga.
2. **Pemesanan via Admin WhatsApp**:
   - Lembar *Upgrade Pro* terintegrasi langsung dengan link dinamis WhatsApp Admin untuk pemesanan paket bulanan/tahunan.
3. **In-App Purchase (IAP) Ready Architecture**:
   - Menggunakan pola antarmuka `IapService` (`NoopIapService` terpasang secara default untuk build ringan tanpa dependency store).
   - Implementasi lengkap RevenueCat (`purchases_flutter`) telah disiapkan dan diarsipkan di `docs/references/revenuecat/` untuk memudahkan aktivasi store billing kapan saja.

---

## 🏗️ Arsitektur & Teknologi

Proyek ini dibangun mengikuti prinsip **Clean Architecture**:

```
lib/
├── core/                  # Utilitas bersama, tema, DI, dan services inti
│   ├── di/                # Dependency Injection (GetIt)
│   ├── services/          # Printer, Sync, Shift, Voucher License, & IAP Services
│   └── style/             # Design token & tema warna
├── data/                  # Implementasi Data Source & Repository
│   ├── datasources/
│   │   ├── local/         # Drift SQLite Database (Offline-first)
│   │   └── firebase/      # Cloud Firestore & Authentication
│   ├── models/            # DTO / Data Models
│   └── repositories/      # Repositories Implementation
├── domain/                # Business Logic & Entities murni
│   ├── entities/          # Product, Transaction, Shift, Business Entities
│   └── repositories/      # Repository Contracts
└── presentation/          # UI Layer (BLoC + Widgets)
    ├── blocs/             # State Management (flutter_bloc)
    ├── pages/             # Layar POS, Produk, Laporan, Pengaturan, Shift
    └── widgets/           # Reusable UI Components
```

### Tech Stack
- **Framework**: Flutter 3.x (Dart 3.x)
- **State Management**: BLoC / Cubit (`flutter_bloc`)
- **Dependency Injection**: `get_it` + `injectable`
- **Database Lokal**: `drift` (SQLite with reactive streams)
- **Cloud Backend**: Firebase (Auth, Cloud Firestore, Storage)
- **Image Hosting**: Cloudinary API
- **Periferal Kasir**: `print_bluetooth_thermal`, `esc_pos_utils_plus`, `mobile_scanner`

---

## 🚀 Menjalankan Proyek Secara Lokal

### Prasyarat
- Flutter SDK (>= 3.11.4)
- Xcode (untuk macOS/iOS) atau Android Studio (untuk Android)

### Instalasi
```bash
# 1. Clone repositori
git clone https://github.com/ilhaaam24/laci-pos.git
cd laci-pos

# 2. Pasang dependensi
flutter pub get

# 3. Jalankan pengujian unit & widget test
flutter test

# 4. Jalankan aplikasi (Contoh: simulator iOS atau Android)
flutter run -d ios
# atau
flutter run -d android
```

---

## 🧪 Pengujian (Testing)

Proyek ini dilengkapi dengan cakupan unit test dan widget test komprehensif (150+ tests):
```bash
flutter test
```

Semua pengujian mencakup:
- Kalkulasi kasir, diskon, pajak, dan kembalian.
- Logika otentikasi PIN staf dan shift handover kasir.
- Verifikasi lisensi voucher Pro & parsing masa aktif.
- Responsivitas komponen UI pada berbagai ukuran layar ponsel dan tablet.
