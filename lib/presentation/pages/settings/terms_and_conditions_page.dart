import 'package:flutter/material.dart';

import '../../../core/style/app_colors.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  final List<Map<String, dynamic>> _sections = const [
    {
      'number': '01',
      'title': 'Definisi & Ketentuan Umum',
      'content':
          'Laci POS adalah aplikasi kasir digital yang dirancang untuk membantu operasional penjualan, pencatatan transaksi, kelola stok barang, dan laporan keuangan usaha.\n\n'
          'Dengan menggunakan aplikasi ini, Anda menyatakan telah membaca dan menyetujui seluruh ketentuan yang tercantum. Ketentuan ini berlaku bagi pemilik usaha maupun staf yang mengoperasikan aplikasi.',
    },
    {
      'number': '02',
      'title': 'Akun Pengguna, Peran & Keamanan',
      'content':
          '• Pemilik usaha bertanggung jawab penuh atas pembuatan akun dan pengaturan hak akses staf (seperti admin dan kasir).\n'
          '• Setiap pengguna wajib menjaga kerahasiaan kata sandi atau PIN akses masing-masing.\n'
          '• Segala aktivitas transaksi yang dilakukan menggunakan akun terdaftar menjadi tanggung jawab pemilik akun.\n'
          '• Jika ditemukan aktivitas mencurigakan atau perubahan perangkat yang tidak sah, segera perbarui kata sandi Anda.',
    },
    {
      'number': '03',
      'title': 'Penyimpanan Data Lokal & Sinkronisasi Cloud',
      'content':
          '• Seluruh data transaksi, produk, dan pelanggan tersimpan langsung di memori perangkat Anda, sehingga operasional kasir tetap dapat berjalan lancar tanpa koneksi internet (offline).\n'
          '• Saat perangkat terhubung ke internet, data akan disinkronkan secara otomatis ke server sebagai pencadangan (backup) dan pembaruan lintas perangkat.\n'
          '• Pastikan perangkat Anda terhubung ke internet secara berkala agar riwayat penjualan selalu tercadangkan dengan aman.',
    },
    {
      'number': '04',
      'title': 'Pencatatan Transaksi, Stok & Perhitungan Pajak',
      'content':
          '• Pengguna bertanggung jawab atas ketepatan harga jual, harga modal, jumlah stok masuk dan keluar, serta data transaksi yang dimasukkan.\n'
          '• Perhitungan otomatis seperti diskon, pajak, dan biaya layanan disediakan sebagai alat bantu hitung. Pemilik usaha tetap bertanggung jawab memastikan kepatuhan pajak sesuai aturan usaha setempat.\n'
          '• Fitur pengingat stok disediakan untuk mempermudah pemantauan dan mencegah penjualan melebihi stok yang ada.',
    },
    {
      'number': '05',
      'title': 'Perangkat Keras & Layanan Pihak Ketiga',
      'content':
          '• Laci POS mendukung penggunaan printer struk Bluetooth dan pemindai barcode untuk mempermudah proses checkout di kasir.\n'
          '• Kompatibilitas printer dapat berbeda tergantung tipe dan merek perangkat keras yang digunakan.\n'
          '• Pembayaran non-tunai (seperti QRIS, kartu debit, atau transfer bank) mengikuti ketentuan dari pihak bank atau penyedia pembayaran resmi yang Anda gunakan.',
    },
    {
      'number': '06',
      'title': 'Hak Kekayaan Intelektual',
      'content':
          'Seluruh hak cipta, merek, desain tampilan, dan logo Laci POS adalah milik sah pengembang Laci POS. Pengguna tidak diperkenankan menyalin, memodifikasi, merekayasa balik, atau mendistribusikan ulang aplikasi ini tanpa izin tertulis.',
    },
    {
      'number': '07',
      'title': 'Batasan Tanggung Jawab & Jaminan',
      'content':
          '• Kami berupaya menjaga performa aplikasi tetap stabil dan aman untuk penggunaan sehari-hari.\n'
          '• Pengembang Laci POS tidak bertanggung jawab atas kerugian usaha yang disebabkan oleh kesalahan input operasional kasir, kerusakan fisik perangkat keras, atau kehilangan data akibat perangkat yang dimodifikasi (root/jailbreak).',
    },
    {
      'number': '08',
      'title': 'Perubahan Ketentuan & Kontak Resmi',
      'content':
          'Ketentuan ini dapat diperbarui sewaktu-waktu seiring penyempurnaan fitur aplikasi. Perubahan penting akan diinformasikan melalui pembaruan aplikasi.\n\n'
          'Jika Anda memiliki pertanyaan mengenai ketentuan ini, silakan hubungi tim kami:\n'
          '• Email: support@lacipos.id\n'
          '• Kebijakan Privasi: sites.google.com/view/lacipos-privacypolicy',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Syarat & Ketentuan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // 1. Clean Document Header
              _buildHeader(isDark),
              const SizedBox(height: 20),

              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 24),

              // 2. Clean Sections Flow (No Card Salad)
              ..._sections.asMap().entries.map((entry) {
                final idx = entry.key;
                final sec = entry.value;
                final isLast = idx == _sections.length - 1;
                return _buildSectionItem(sec, isDark, isLast);
              }),

              const SizedBox(height: 8),

              // 3. Minimalist Footer
              _buildFooter(isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Syarat & Ketentuan Penggunaan Layanan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ketentuan penggunaan aplikasi kasir Laci POS untuk mendukung operasional pencatatan transaksi dan pengelolaan usaha Anda secara aman.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionItem(Map<String, dynamic> sec, bool isDark, bool isLast) {
    final number = sec['number'] as String;
    final title = sec['title'] as String;
    final content = sec['content'] as String;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                number,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        'Dengan menggunakan aplikasi Laci POS, Anda menyetujui seluruh ketentuan di atas. Ketentuan ini diperbarui secara berkala demi kenyamanan dan keamanan usaha Anda.',
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
