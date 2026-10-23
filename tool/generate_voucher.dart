import 'dart:io';
import 'package:laci/core/services/license_service.dart';

void main(List<String> args) {
  stdout.writeln('==============================================');
  stdout.writeln('   LACI POS PRO - VOUCHER CODE GENERATOR     ');
  stdout.writeln('==============================================');

  String? plan;
  String? orderId;

  if (args.length >= 2) {
    plan = args[0].toLowerCase();
    orderId = args[1].toUpperCase();
  } else {
    stdout.writeln('\nPilih Paket Langganan:');
    stdout.writeln('  1. Bulanan  (30 Hari)');
    stdout.writeln('  2. Tahunan  (365 Hari)');
    stdout.writeln('  3. Lifetime (Permanen)');
    stdout.write('Pilihan [1/2/3] (default 2): ');
    final choice = stdin.readLineSync()?.trim();

    if (choice == '1') {
      plan = 'monthly';
    } else if (choice == '3') {
      plan = 'lifetime';
    } else {
      plan = 'yearly';
    }

    stdout.write('Masukkan ID Order / No. HP Merchant / Nama Toko (misal: INV001 / 0812): ');
    orderId = stdin.readLineSync()?.trim().toUpperCase();
    if (orderId == null || orderId.isEmpty) {
      orderId = 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  // Sanitize order ID to alphanumeric
  orderId = orderId.replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (orderId.isEmpty) orderId = 'ORD1';

  final voucherCode = LicenseService.generateVoucherCode(
    plan: plan,
    orderId: orderId,
  );

  final planLabel = plan == 'monthly'
      ? 'Bulanan (30 Hari)'
      : plan == 'yearly'
          ? 'Tahunan (365 Hari)'
          : 'Lifetime (Permanen)';

  stdout.writeln('\n----------------------------------------------');
  stdout.writeln('HASIL GENERATE KODE VOUCHER');
  stdout.writeln('----------------------------------------------');
  stdout.writeln('Paket       : $planLabel');
  stdout.writeln('ID Order    : $orderId');
  stdout.writeln('Kode Lisensi: $voucherCode');
  stdout.writeln('----------------------------------------------');
  stdout.writeln('\nTemplate Pesan WhatsApp untuk Pelanggan:');
  stdout.writeln('----------------------------------------------');
  stdout.writeln(
    'Halo! Terima kasih telah berlangganan Laci POS Pro ($planLabel).\n\n'
    'Berikut kode aktivasi lisensi Pro toko Anda:\n'
    '*$voucherCode*\n\n'
    'Cara aktivasi di aplikasi Laci POS:\n'
    '1. Buka aplikasi Laci POS\n'
    '2. Masuk ke menu "Pengaturan"\n'
    '3. Pilih "Aktivasi Lisensi Pro"\n'
    '4. Masukkan kode di atas lalu tekan "Aktivasi Sekarang"\n\n'
    'Selamat menikmati seluruh fitur premium Laci POS!',
  );
  stdout.writeln('==============================================\n');
}
