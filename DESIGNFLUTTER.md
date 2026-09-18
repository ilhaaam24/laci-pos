# DESIGN.md — [Nama Produk]

> File ini adalah rujukan wajib untuk siapa pun (manusia atau AI agent) yang
> menulis UI di project ini. Tujuannya satu: setiap layar terasa dirancang
> untuk produk ini secara spesifik, bukan template generik.
>
> Kalau ada keputusan di kode yang tidak bisa dijelaskan alasannya dari
> dokumen ini, itu tandanya harus direvisi.

## 1. Konteks Produk

Isi ini dulu sebelum apa pun — inilah yang membuat pilihan desain di bawah
"masuk akal" dan bukan asal comot.

- **Produk ini apa:** (misal: aplikasi pencatat keuangan pribadi untuk
  freelancer Indonesia)
- **Siapa penggunanya:** (umur, konteks pakai — sambil jalan? di meja kerja?)
- **Rasa/mood yang ingin ditimbulkan:** (tenang & terpercaya? cepat & tegas?
  hangat & personal?) — sebutkan 3 kata sifat, bukan lebih.
- **Bukan ini:** sebutkan 1-2 kompetitor/referensi yang JANGAN ditiru, dan
  kenapa. (Ini menghindarkan agent balik ke default "gaya SaaS generik".)

## 2. Anti-Pola — Hal yang DILARANG

AI agent cenderung jatuh ke pola ini kalau tidak diberi arah. Larang eksplisit:

- ❌ Seed color Material 3 default (`#6750A4` / ungu bawaan) — harus pakai
  palet di bagian 3.
- ❌ `Card` dengan elevation + radius yang sama untuk SEMUA jenis konten.
  Elevation dan radius harus punya arti (level hierarki), bukan default rata.
- ❌ `ListTile` bawaan tanpa modifikasi untuk list yang punya karakter visual
  sendiri (misal daftar transaksi vs daftar kontak harus terlihat beda).
- ❌ Font default (Roboto/Poppins/Inter) tanpa alasan — pakai typeface yang
  ditentukan di bagian 4.
- ❌ Panah `→` / `Icons.arrow_forward_ios` ditempel otomatis di semua tombol
  atau link "lihat semua".
- ❌ Gradient dekoratif yang tidak menyampaikan informasi apa pun.
- ❌ Spacing acak — semua jarak harus kelipatan dari skala di bagian 5.
- ❌ Empty state / error state generik (`Text('Tidak ada data')`,
  `Text('Error occurred')`). Setiap state kosong harus dirancang (lihat
  bagian 8).
- ❌ Efek fade-slide-up di semua widget saat load. Motion harus disengaja,
  lihat bagian 7.
- ❌ Mengabaikan perbedaan idiom iOS vs Android kalau app-nya cross-platform
  (lihat bagian 9).

## 3. Warna

Definisikan sebagai token, bukan hex ditulis ulang di tiap file.

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const primary = Color(0xFF______);   // <- isi, alasan pemilihan: ...
  static const secondary = Color(0xFF______);
  static const surface = Color(0xFF______);
  static const surfaceAlt = Color(0xFF______); // untuk membedakan level, bukan shadow abu generik
  static const onSurface = Color(0xFF______);
  static const success = Color(0xFF______);
  static const warning = Color(0xFF______);
  static const danger = Color(0xFF______);
}
```

- Sebutkan **kenapa** warna primer ini, dikaitkan ke bagian 1 (mis. "biru
  kehijauan tenang, bukan biru korporat generik, karena target user butuh
  rasa aman saat urus uang").
- Tentukan mode gelap sekarang, bukan belakangan — `ColorScheme.dark` bukan
  sekadar invert.

## 4. Tipografi

- Typeface: **[nama font]** — alasan pemilihan (bukan "karena populer").
- Satu keluarga font cukup; kalau dua, harus kontras jelas (mis. serif untuk
  angka besar, sans untuk UI).
- Skala tipe (isi sesuai `ThemeData.textTheme`):

| Style | Size | Weight | Pemakaian |
|---|---|---|---|
| displayLarge | 32 | 700 | Angka besar / hero |
| titleLarge | 20 | 600 | Judul layar |
| bodyLarge | 16 | 400 | Konten utama |
| bodySmall | 13 | 400 | Meta/caption |
| labelMedium | 12 | 500 | Tag/badge |

- **Larang** ALL CAPS untuk label kecuali memang singkatan resmi.
- **Larang** menonjolkan satu kata dalam judul dengan warna/italic berbeda
  kecuali betul-betul untuk highlight fungsional (mis. jumlah uang).

## 5. Spacing & Grid

Gunakan skala tetap — semua `padding`/`gap`/`SizedBox` HARUS dari daftar ini:

```
4, 8, 12, 16, 24, 32, 48, 64
```

- Margin luar layar: 16 (mobile), 24 (tablet ke atas).
- Radius token, bukan angka bebas:
  - `radiusSm = 8` — untuk chip, badge
  - `radiusMd = 12` — untuk card konten
  - `radiusLg = 20` — untuk sheet/modal
  - Radius besar (>20) hanya untuk elemen yang memang jadi fokus utama.

## 6. Komponen — Aturan Spesifik

Untuk tiap komponen kunci, tulis aturan konkret, bukan "gunakan Material
default":

- **Tombol utama:** bentuk, warna, kapan pakai filled vs outlined vs text.
  CTA harus bilang tindakan yang tepat ("Simpan transaksi", bukan "Submit").
- **Card transaksi/list item:** layout spesifik (misal: ikon kategori kiri,
  nominal kanan rata, warna nominal merah/hijau sesuai jenis) — bukan
  `ListTile` polos.
- **AppBar:** rata kiri/tengah? ada elevation saat scroll atau tidak?
- **Bottom navigation / nav rail:** kapan pindah dari bottom nav ke rail
  (breakpoint lebar layar berapa).
- **Input field:** border style, kapan menampilkan validasi inline.

## 7. Motion

- Satu momen animasi yang jadi "signature" — sebutkan yang mana (mis.
  transisi saat kartu transaksi ditambahkan).
- Durasi standar: micro-interaction 150–200ms, transisi layar 250–300ms,
  curve `Curves.easeOutCubic` sebagai default.
- Motion hanya untuk merespons aksi user (buka, tutup, konfirmasi) — bukan
  hiasan saat halaman pertama kali load.
- Hormati `MediaQuery.disableAnimations` (reduced motion).

## 8. State Kosong, Error, Loading

Tiap state ini dirancang, bukan ditulis text generik:

- **Empty state:** ilustrasi/ikon + kalimat ajakan bertindak yang spesifik
  konteks (mis. "Belum ada transaksi bulan ini" + tombol "Catat transaksi
  pertama").
- **Error state:** jelaskan apa yang terjadi & langkah berikutnya, dengan
  suara antarmuka (bukan minta maaf), mis. "Gagal memuat transaksi. Coba
  lagi." + tombol retry — bukan cuma teks merah.
- **Loading:** skeleton yang menyerupai bentuk akhir konten, bukan spinner
  generik di tengah layar kalau kontennya berupa list/card.

## 9. Adaptif Platform (jika cross-platform)

- Kapan pakai widget Cupertino vs Material (mis. dialog konfirmasi destruktif
  pakai gaya native masing-masing platform).
- Ikon back: chevron di iOS, arrow di Android — via `Theme.of(context).platform`.
- Haptic feedback: kapan dipakai (mis. konfirmasi delete).

## 10. Voice & Copy

- Bahasa: [Indonesia informal / formal / campur]
- Kata kerja aktif untuk semua tombol dan judul aksi.
- Nama fitur dari sudut pandang user, bukan istilah teknis (mis. "Pengingat",
  bukan "Notification Config").
- Konsisten: tombol "Simpan" selalu memicu pesan "Tersimpan", bukan "Berhasil
  disimpan" di satu tempat dan "Saved!" di tempat lain.

## 11. Checklist Sebelum Merge

- [ ] Tidak ada warna/hex hardcode di luar `AppColors`
- [ ] Tidak ada spacing di luar skala bagian 5
- [ ] Setiap Card/ListTile custom, bukan default polos
- [ ] Empty/error/loading state dirancang, bukan placeholder text
- [ ] Dark mode dicek, bukan cuma invert warna
- [ ] Motion cuma merespons aksi user, bukan hiasan
- [ ] Sudah dibandingkan dengan produk di bagian 1 "Bukan ini" — tidak mirip
