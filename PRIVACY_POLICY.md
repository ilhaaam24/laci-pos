# Kebijakan Privasi Laci POS

**Aplikasi:** Laci POS  
**Package ID:** com.ilhaaam24.lacipos  
**Tanggal Efektif:** Oktober 2026  
**Terakhir Diperbarui:** 24 Oktober 2026  

---

### 1. Pendahuluan
Selamat datang di **Laci POS**. Kami menghormati dan berkomitmen penuh untuk melindungi privasi serta keamanan data para pemilik bisnis, kasir, dan pengguna aplikasi kami. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, serta menjaga informasi yang Anda berikan saat menggunakan aplikasi kasir Laci POS.

Dengan mengunduh, memasang, dan menggunakan aplikasi Laci POS, Anda menyetujui praktik penanganan data yang diuraikan dalam Kebijakan Privasi ini.

---

### 2. Data yang Kami Kumpulkan
Untuk menunjang operasional kasir dan kelancaran pencatatan usaha Anda, kami mengumpulkan data-data berikut:
- **Informasi Akun Pengguna:** Alamat email, nama usaha/toko, dan nomor telepon yang Anda masukkan saat mendaftar atau login akun menggunakan Firebase Authentication.
- **Data Transaksi & Katalog Produk:** Nama produk, kategori, harga jual, harga modal, jumlah stok, catatan kas masuk/keluar, ringkasan shift kasir, dan riwayat transaksi penjualan.
- **Logo Toko & Preferensi Struk:** Gambar logo toko yang Anda pilih dari perangkat Anda untuk dicetak pada struk kasir, serta catatan kaki struk (*receipt footer*).
- **Data Perangkat & Diagnostik Sistem:** Model perangkat, versi sistem operasi Android, dan log kesalahan sistem (*crash logs*) semata-mata untuk menjaga kestabilan aplikasi.

---

### 3. Penggunaan Izin Khusus Perangkat (Device Permissions)
Laci POS hanya meminta izin perangkat yang benar-benar esensial untuk menjalankan fungsi aplikasi:

- **📷 Izin Kamera (CAMERA):**  
  Digunakan secara langsung saat kasir mengaktifkan fitur pemindai barcode / QR code barang. Aplikasi **TIDAK PERNAH** mengambil foto, merekam video secara diam-diam, mengenali wajah, atau menyimpan rekaman visual kamera Anda ke server mana pun.

- **🖨️ Izin Bluetooth & Perangkat Sekitar (BLUETOOTH_CONNECT & BLUETOOTH_SCAN):**  
  Digunakan semata-mata untuk memindai dan menghubungkan perangkat dengan printer kasir thermal Bluetooth agar struk pesanan dapat dicetak. Kami **TIDAK** melacak atau menyimpan data lokasi fisik pengguna melalui Bluetooth.

- **🖼️ Izin Akses Galeri & Media (READ_EXTERNAL_STORAGE / MEDIA):**  
  Digunakan hanya saat Anda secara eksplisit memilih gambar logo toko dari galeri perangkat Anda untuk ditampilkan pada kepala struk kasir.

---

### 4. Penyimpanan & Keamanan Data
Laci POS mengutamakan keamanan dan kemudahan operasional Anda:
- **Penyimpanan Lokal Mandiri:** Basis data transaksi dan katalog Anda disimpan secara lokal di memori internal perangkat Anda sehingga aplikasi dapat tetap digunakan tanpa koneksi internet (*offline mode*).
- **Sinkronisasi Cloud yang Aman:** Jika Anda mengaktifkan akun online, data disinkronkan menggunakan infrastruktur Google Cloud Firestore dengan enkripsi standar industri (*encryption in transit and at rest*).

---

### 5. Layanan Pihak Ketiga
Aplikasi ini terintegrasi dengan penyedia layanan pihak ketiga tepercaya untuk mendukung autentikasi dan infrastruktur cloud:
- **Google Play Services (Google LLC):** Distribusi aplikasi & pustaka inti Android.
- **Firebase Authentication (Google LLC):** Autentikasi login email yang aman.
- **Cloud Firestore (Google LLC):** Penyimpanan cloud basis data terenkripsi.

---

### 6. Permintaan Penghapusan Akun & Data (Data Deletion Request)
Sesuai dengan Kebijakan Data Pengguna Google Play, Anda memiliki hak penuh untuk meminta penghapusan akun serta seluruh data usaha Anda kapan saja.

Untuk mengajukan penghapusan akun dan data terkait:
- Kirimkan email ke **support@lacipos.id** (atau **ilhambagas2424@gmail.com**) dengan subjek: `Permintaan Penghapusan Akun Laci POS`.
- Sertakan alamat email yang terdaftar pada akun Laci POS Anda.
- Tim kami akan memproses dan menghapus akun beserta seluruh data transaksi cloud Anda secara permanen dalam waktu maksimal 7 (tujuh) hari kerja.

---

### 7. Privasi Anak-Anak (Children's Privacy)
Aplikasi Laci POS dirancang secara khusus untuk keperluan operasional usaha dagang dan UMKM, serta tidak ditujukan untuk anak-anak di bawah usia 13 tahun. Kami tidak secara sengaja mengumpulkan data pribadi dari anak-anak.

---

### 8. Perubahan Kebijakan Privasi
Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu guna menyesuaikan dengan pembaruan fitur atau regulasi hukum yang berlaku. Setiap perubahan penting akan diberitahukan melalui halaman ini dengan memperbarui tanggal "Terakhir Diperbarui".

---

### 9. Kontak Resmi Pengembang
Jika Anda memiliki pertanyaan, saran, atau masukan mengenai Kebijakan Privasi ini, silakan hubungi kami:
- **Email Dukungan:** support@lacipos.id
- **Email Alternatif:** ilhambagas2424@gmail.com
- **Aplikasi:** Laci POS (com.ilhaaam24.lacipos)
