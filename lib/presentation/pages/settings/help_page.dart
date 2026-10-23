import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String _selectedCategory = 'Semua';

  final List<Map<String, dynamic>> _faqCategories = [
    {
      'category': 'Printer & Struk',
      'icon': "assets/icons/printer.svg",
      'color': const Color(0xFF0EA5E9),
      'items': [
        {
          'question': 'Printer Bluetooth tidak terdeteksi saat dipindai?',
          'answer':
              '1. Pastikan Bluetooth dan Lokasi (GPS) pada perangkat Anda sudah aktif.\n'
              '2. Pastikan printer menyala dan kertas terpasang dengan baik.\n'
              '3. Buka menu Pengaturan > Pengaturan Printer, lalu tekan "Pindai Perangkat".\n'
              '4. Jika printer pernah disambungkan di menu Bluetooth HP, coba hapus atau lupakan perangkat tersebut terlebih dahulu, lalu hubungkan kembali langsung dari aplikasi Laci POS.',
        },
        {
          'question': 'Kertas keluar tetapi kosong / tidak tercetak tulisan?',
          'answer':
              'Penyebab paling sering adalah posisi gulungan kertas terbalik. Buka penutup printer, balik arah gulungan kertasnya, lalu tutup kembali hingga rapat.',
        },
        {
          'question': 'Bagaimana cara mengatur nama toko & catatan di struk?',
          'answer':
              'Masuk ke menu Pengaturan > Kustomisasi Struk. Anda dapat mengatur logo toko, nama usaha, pesan salam pembuka, catatan di bagian bawah struk (misal: "Barang yang dibeli tidak dapat ditukar"), serta opsi cetak barcode transaksi.',
        },
      ],
    },
    {
      'category': 'Stok & Produk',
      'icon': "assets/icons/product.svg",
      'color': const Color(0xFF10B981),
      'items': [
        {
          'question': 'Mengapa produk tidak bisa ditambahkan ke keranjang?',
          'answer':
              'Aplikasi Laci POS secara otomatis membatasi pesanan agar tidak melebihi sisa stok di toko. Jika stok tersisa hanya 5, kasir tidak dapat memasukkan item ke-6 ke keranjang belanja. Untuk menambah atau memperbarui stok, buka menu Pengaturan > Kelola Produk > pilih produk > perbarui jumlah stok.',
        },
        {
          'question':
              'Bagaimana cara menjual produk tanpa batasan stok (makanan / jasa)?',
          'answer':
              'Buka menu Pengaturan > Kelola Produk > pilih produk yang ingin diatur. Pada bagian "Lacak Stok Produk", matikan pilihannya. Produk atau menu tersebut dapat langsung dijual tanpa batasan jumlah stok.',
        },
        {
          'question': 'Alat pemindai (scanner) tidak membaca barcode produk?',
          'answer':
              '1. Pastikan izin kamera sudah diaktifkan untuk aplikasi Laci POS.\n'
              '2. Pastikan barcode pada produk terlihat jelas, tidak buram, kotor, atau terkena pantulan cahaya berlebih.\n'
              '3. Anda juga dapat mencari produk dengan mengetikkan nama atau kode produk langsung di kolom pencarian kasir.',
        },
      ],
    },
    {
      'category': 'Transaksi & Pembayaran',
      'icon': "assets/icons/transaction.svg",
      'color': const Color(0xFFF59E0B),
      'items': [
        {
          'question': 'Bagaimana cara menyimpan pesanan sementara (Open Bill)?',
          'answer':
              'Jika ada pelanggan yang ingin memesan terlebih dahulu atau menunda pembayaran, tekan tombol "Tahan Pesanan" (Open Bill) di kasir. Anda dapat memberi nama pesanan atau nomor meja, lalu membukanya kembali kapan saja dari tombol "Open Bill" di bagian atas kasir.',
        },
        {
          'question': 'Pelanggan sudah bayar QRIS tapi struk belum keluar?',
          'answer':
              'Periksa pemberitahuan atau mutasi saldo di aplikasi rekening/dompet digital Anda. Jika pembayaran sudah masuk, Anda dapat menyelesaikan transaksi di kasir dengan memilih metode QRIS / Transfer lalu cetak struk untuk pelanggan.',
        },
        {
          'question': 'Bagaimana cara membatalkan transaksi yang salah bayar?',
          'answer':
              'Buka menu Laporan Transaksi > pilih transaksi yang ingin dibatalkan > pilih tombol batalkan transaksi sesuai dengan kebijakan toko Anda.',
        },
      ],
    },
    {
      'category': 'Shift Kasir & Uang Laci',
      'icon': "assets/icons/shift.svg",
      'color': const Color(0xFF8B5CF6),
      'items': [
        {
          'question': 'Apa fungsi buka dan tutup shift kasir?',
          'answer':
              'Fitur shift digunakan untuk mencatat uang modal awal di laci kasir, mencatat uang keluar/masuk operasional (misal beli es batu atau perlengkapan), serta mencocokkan total uang fisik di laci saat pergantian jam kerja kasir.',
        },
        {
          'question': 'Bagaimana jika ada selisih uang saat tutup shift?',
          'answer':
              'Ketik jumlah uang fisik yang ada di laci kasir saat menutup shift. Aplikasi akan otomatis menghitung apakah uang laci pas, lebih, atau kurang. Catatan ini tersimpan rapi untuk diperiksa oleh pemilik toko di menu Pengaturan > Riwayat Shift Kasir.',
        },
      ],
    },
    {
      'category': 'Offline & Sinkronisasi',
      'icon': "assets/icons/sync.svg",
      'color': const Color(0xFFEC4899),
      'items': [
        {
          'question':
              'Apakah aplikasi tetap bisa dipakai saat tidak ada internet?',
          'answer':
              'Ya, tentu saja! Semua data transaksi Anda tersimpan aman langsung di perangkat kasir ini. Anda tetap bisa melayani kasir, menahan pesanan, dan mencetak struk walau tanpa koneksi internet. Semua data akan otomatis diperbarui saat perangkat kembali terhubung ke internet.',
        },
        {
          'question':
              'Bagaimana cara memperbarui data ke server secara manual?',
          'answer':
              'Masuk ke menu Pengaturan > Sistem & Informasi > tekan tombol "Sinkronkan" di samping status Sinkronisasi Data untuk memperbarui data toko Anda.',
        },
      ],
    },
  ];

  Future<void> _launchWhatsApp() async {
    final message = Uri.encodeComponent(
      'Halo Tim Bantuan Laci POS, saya memerlukan bantuan terkait aplikasi Laci POS di toko saya.',
    );
    final whatsappUrl = Uri.parse('https://wa.me/6281615697675?text=$message');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        AppToast.showWarning(context, 'Tidak dapat membuka aplikasi WhatsApp');
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.showWarning(
        context,
        'Gagal membuka WhatsApp: periksa aplikasi WhatsApp Anda',
      );
    }
  }

  Future<void> _launchEmail() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@lacipos.id',
      query:
          'subject=Bantuan Laci POS&body=Halo Tim Bantuan Laci POS,%0A%0ASaya memerlukan bantuan terkait hal berikut:%0A- Nama Toko:%0A- Pertanyaan / Kendala:%0A',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        AppToast.showWarning(context, 'Tidak dapat membuka aplikasi Email');
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.showWarning(context, 'Gagal membuka aplikasi email');
    }
  }

  List<Map<String, dynamic>> get _filteredFaq {
    if (_selectedCategory == 'Semua') {
      return _faqCategories;
    }
    return _faqCategories
        .where((cat) => cat['category'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredFaq;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pusat Bantuan & Kendala',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Category Filter Chips
          _buildCategoryPills(isDark),
          const SizedBox(height: 20),

          // 3. Contact Support Section (Clean Grouped Card)
          _buildSectionHeader('HUBUNGI BANTUAN', isDark),
          _buildCardGroup([
            _buildActionTile(
              iconData: "assets/icons/whatsapp.svg",
              iconColor: const Color(0xFF16A34A),
              iconBgColor: isDark
                  ? const Color(0xFF14532D).withValues(alpha: 0.35)
                  : const Color(0xFFDCFCE7),
              title: 'Chat WhatsApp',
              subtitle: 'Hubungi tim bantuan kami langsung',
              onTap: _launchWhatsApp,
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildActionTile(
              iconData: "assets/icons/email.svg",
              iconColor: const Color(0xFF0284C7),
              iconBgColor: isDark
                  ? const Color(0xFF0C4A6E).withValues(alpha: 0.35)
                  : const Color(0xFFE0F2FE),
              title: 'Kirim Email',
              subtitle: 'support@lacipos.id',
              onTap: _launchEmail,
              isDark: isDark,
            ),
          ], isDark),
          const SizedBox(height: 22),

          // 4. FAQ Section Header
          _buildSectionHeader('PANDUAN & SOLUSI KENDALA', isDark),

          // 5. FAQ List Accordions
          ...filtered.map((cat) => _buildFaqCategoryCard(cat, isDark)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildActionTile({
    required String iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(iconData, height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPills(bool isDark) {
    final categories = [
      {"name": "Semua", "icon": "assets/icons/all.svg"},
      {"name": "Printer & Struk", "icon": "assets/icons/printer.svg"},
      {"name": "Stok & Produk", "icon": "assets/icons/product.svg"},
      {
        "name": "Transaksi & Pembayaran",
        "icon": "assets/icons/transaction.svg",
      },
      {"name": "Shift Kasir & Uang Laci", "icon": "assets/icons/shift.svg"},
      {"name": "Offline & Sinkronisasi", "icon": "assets/icons/offline.svg"},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat['name']!),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  cat['name']!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaqCategoryCard(Map<String, dynamic> cat, bool isDark) {
    final title = cat['category'] as String;
    final icon = cat['icon'] as String;
    final items = cat['items'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: _selectedCategory != 'Semua',
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: SvgPicture.asset(icon, height: 32, width: 32),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              '${items.length} solusi',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            children: items.map<Widget>((item) {
              final q = item['question'] as String;
              final a = item['answer'] as String;

              return Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.help_outline_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 23),
                      child: Text(
                        a,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
