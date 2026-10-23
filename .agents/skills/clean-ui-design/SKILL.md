---
name: clean-ui-design
description: >-
  Use this skill whenever designing, building, or refactoring Flutter UI screens, dialogs, bottom sheets, or widgets in Laci POS. Enforces a clean, uncluttered layout with generous breathing room (no cramped widgets), focused high-signal information hierarchy (to-the-point), responsive overflow-safe layouts, and strict adherence to the project's established AppColors palette and design tokens.
---

# Clean UI Design Skill — Laci POS

Panduan resmi untuk merancang dan mengimplementasikan antarmuka (UI) Flutter di Laci POS yang **bersih (clean)**, **rapi (well-aligned)**, **memiliki ruang bernapas (tidak mepet)**, dan **fokus pada esensi (to the point)** dengan tetap mempertahankan **palet warna resmi proyek**.

---

## 1. Prinsip Desain: To The Point & High Signal

1. **Tampilkan yang Dibutuhkan Saja**:
   - Hindari teks dekoratif yang tidak fungsional, ikon ganda yang mubazir, atau banner berulang.
   - Utamakan konten inti: *Nama item, angka/nominal, status, aksi langsung*.
   - Kurangi beban visual (*visual noise*) agar pengguna (kasir/pemilik toko) dapat mengambil keputusan cepat dalam 1–2 detik.
2. **Hierarki Visual 3 Tingkat**:
   - **Tingkat 1 (Hero/Utama)**: Nominal harga, judul layar, tombol CTA utama. Gunakan `fontWeight: FontWeight.w700` atau `w800`, `color: AppColors.textPrimary` atau `AppColors.primary`.
   - **Tingkat 2 (Deskriptif)**: Label field, nama produk, subtitle singkat. Gunakan `fontWeight: FontWeight.w500` / `w600`, ukuran 13–14px.
   - **Tingkat 3 (Meta/Sekunder)**: Kode SKU, timestamp, rincian catatan. Gunakan `color: AppColors.textSecondary` / `textDisabled`, ukuran 11–12px.
3. **Aksi Jelas & Ringkas**:
   - Teks tombol langsung menyatakan aksi spesifik: *"Bayar Sekarang"*, *"Simpan Produk"*, *"Beli Lisensi"*, bukan *"Submit"* atau *"Klik Disini"*.

---

## 2. Spacing & Layout: Anti-Mepet (Breathing Room)

Semua jarak (padding, margin, gap, `SizedBox`) **HARUS** mengikuti skala kelipatan 4/8-point berikut:

```dart
// Skala Spacing Baku (pixels)
const double space4  = 4;   // Jarak mikro (antar icon dan text kecil)
const double space8  = 8;   // Jarak elemen rapat (antar badge, gap kecil)
const double space12 = 12;  // Jarak standar antar baris dalam card
const double space16 = 16;  // Padding internal card / margin standar layar
const double space20 = 20;  // Spacing antar sub-seksi
const double space24 = 24;  // Spacing antar seksi besar / modal header
const double space32 = 32;  // Spacing pemisah layout besar
```

### Aturan Jarak agar Widget Tidak Mepet:
- **Tepi Layar / Sheet Margin**: Minimal `16px` (mobile) atau `24px` (tablet).
- **Internal Card Padding**: Minimal `14px` s/d `16px`. Jangan pernah membuat card dengan padding < 10px karena akan membuat teks terasa terjepit.
- **Jarak Antar Item dalam List**: Minimal `SizedBox(height: 10)` s/d `12`.
- **Jarak Antar Tombol**: Minimal `SizedBox(height: 10)` s/d `12` (vertikal) atau `8` s/d `10` (horizontal).
- **Jarak Icon & Teks**: Gunakan `SizedBox(width: 8)`.

---

## 3. Palet Warna Resmi Proyek (`AppColors`)

**Dilarang keras melakukan hardcode warna hex sembarangan.** Gunakan selalu token resmi dari `lib/core/style/app_colors.dart`:

```dart
import 'package:laci/core/style/app_colors.dart';
```

| Token | Nilai Hex | Peruntukan |
|---|---|---|
| `AppColors.primary` | `#009951` (Deep Emerald) | Aksi utama, tombol CTA, status aktif, aksen brand |
| `AppColors.primaryLight` | `#E6F4F2` | Background badge/chip aktif, container icon soft |
| `AppColors.secondary` | `#0EA5E9` (Sky Blue) | Aksi sekunder, status transfer, tombol info |
| `AppColors.secondaryLight` | `#E0F2FE` | Background chip sekunder |
| `AppColors.warning` | `#F59E0B` / `#D97706` | Aksen PRO tier, badge promo/diskon, peringatan |
| `AppColors.success` | `#10B981` | Transaksi lunas, stok aman, pesan berhasil |
| `AppColors.error` | `#EF4444` | Stok habis, tindakan destruktif (Hapus), error |
| `AppColors.background` | `#F7F9FB` | Kanvas latar belakang layar (Light) |
| `AppColors.darkBackground`| `#1E293B` | Kanvas latar belakang layar (Dark) |
| `AppColors.surface` | `#FFFFFF` | Background kartu, dialog, dan lembar sheet (Light) |
| `AppColors.textPrimary` | `#0F172A` (Slate 900) | Teks utama, judul, angka nominal |
| `AppColors.textSecondary` | `#64748B` (Slate 500) | Teks pendukung, subtitle, label filter |
| `AppColors.textDisabled` | `#94A3B8` (Slate 400) | Placeholder input, divider sekunder |
| `AppColors.border` | `#E2E8F0` | Garis pembatas kartu & input (Light) |

### Penanganan Dark Mode:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final bgColor = isDark ? const Color(0xFF1E293B) : AppColors.surface;
final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
final borderColor = isDark ? const Color(0xFF334155) : AppColors.border;
final textColor = isDark ? Colors.white : AppColors.textPrimary;
final subtextColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
```

---

## 4. Standar Bentuk & Komponen Visual

1. **Border Radius Skala Baku**:
   - `radiusSm` = `6–8` : Tag, badge, chip status
   - `radiusMd` = `12–14` : Card konten, text field, tombol aksi
   - `radiusLg` = `16–24` : Modal bottom sheet, dialog container
2. **Gaya Kartu (Card Styling)**:
   - Gunakan pendekatan **Border-First** (garis tepi halus `1.0px` dengan `borderColor`), daripada drop shadow tebal yang membuat tampilan kusam.
   - Jika membutuhkan shadow, gunakan shadow lembut dan tipis:
     ```dart
     boxShadow: [
       BoxShadow(
         color: Colors.black.withValues(alpha: 0.04),
         blurRadius: 8,
         offset: const Offset(0, 2),
       ),
     ]
     ```
3. **Tipografi**:
   - Font resmi: Plus Jakarta Sans via `GoogleFonts.plusJakartaSans`.
   - Hindari lebih dari 3 ukuran teks berbeda dalam satu kartu untuk mencegah kesan berantakan.

---

## 5. Pola Anti-Overflow & Responsif

Setiap widget harus tahan uji di layar sempit (**320px–360px**) tanpa menghasilkan *yellow-and-black stripes*:

1. **Teks Dinamis di dalam Row**:
   - **Wajib** dibungkus dengan `Expanded` atau `Flexible` disertai `maxLines` dan `overflow: TextOverflow.ellipsis`.
2. **Grup Badge / Kombinasi Harga**:
   - Gunakan `Wrap` daripada `Row` untuk tag, badge, atau harga coret agar otomatis turun ke baris baru jika layar sempit:
     ```dart
     Wrap(
       crossAxisAlignment: WrapCrossAlignment.center,
       spacing: 8,
       runSpacing: 4,
       children: [
         Text('Rp 49.000', ...),
         Text('Rp 149.000', style: TextStyle(decoration: TextDecoration.lineThrough)),
       ],
     )
     ```
3. **Tombol dengan Teks Panjang**:
   - Bungkus teks tombol dengan `Flexible` dan `FittedBox(fit: BoxFit.scaleDown)` agar teks menyesuaikan proporsional saat dibuka di layar sempit atau pengaturan font besar.
4. **Modal Bottom Sheet & Dialog**:
   - **Wajib** membungkus isi dengan `SingleChildScrollView` dan `SafeArea(top: false)` agar tidak overflow saat keyboard muncul atau layar pendek dalam orientasi landscape.

---

## 6. Template Snippet: Kartu Bersih & Proporsional

Contoh implementasi kartu yang rapi, tidak mepet, dan to the point:

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: borderColor),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Katalog Produk',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelola harga, stok, dan varian',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textDisabled),
        ],
      ),
    ],
  ),
)
```

---

## 7. Checklist Validasi Desain Sebelum Selesai

- [ ] **To The Point**: Informasi yang ditampilkan bernilai tinggi dan bebas dari elemen dekoratif yang tidak perlu.
- [ ] **Tidak Mepet**: Padding card minimal 14–16px, jarak antar seksi 16–24px, skala spacing kelipatan 4/8.
- [ ] **Warna Konsisten**: Seluruh warna diambil dari `AppColors` tanpa hardcoded hex liar.
- [ ] **Bebas Overflow**: Telah menggunakan `Expanded`/`Flexible`/`Wrap`/`FittedBox` di dalam `Row`.
- [ ] **Dukungan Dark Mode**: Kontras teks dan border terlihat jelas dan nyaman di mode gelap maupun terang.
