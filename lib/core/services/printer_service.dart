import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../domain/entities/shift_entity.dart';
import '../../../domain/entities/held_order_entity.dart';
import 'package:intl/intl.dart';
import 'receipt_settings_service.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  static const String _prefPrinterMac = 'pref_printer_mac';
  static const String _prefPrinterName = 'pref_printer_name';
  static const String _prefPaperSize = 'pref_printer_paper_size';
  static const String _prefAutoReconnect = 'pref_printer_auto_reconnect';
  static const String _prefAutoDrawerKick = 'pref_printer_auto_drawer_kick';

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _connectedDeviceName;
  String? get connectedDeviceName => _connectedDeviceName;

  String? _savedMacAddress;
  String? get savedMacAddress => _savedMacAddress;

  String? _savedDeviceName;
  String? get savedDeviceName => _savedDeviceName;

  String _paperSize = '58';
  String get paperSizeString => _paperSize;
  PaperSize get paperSize => _paperSize == '80' ? PaperSize.mm80 : PaperSize.mm58;

  bool _autoReconnect = true;
  bool get autoReconnect => _autoReconnect;

  bool _autoDrawerKick = true;
  bool get autoDrawerKick => _autoDrawerKick;

  bool _isAutoConnecting = false;
  bool get isAutoConnecting => _isAutoConnecting;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedMacAddress = prefs.getString(_prefPrinterMac);
      _savedDeviceName = prefs.getString(_prefPrinterName);
      _paperSize = prefs.getString(_prefPaperSize) ?? '58';
      _autoReconnect = prefs.getBool(_prefAutoReconnect) ?? true;
      _autoDrawerKick = prefs.getBool(_prefAutoDrawerKick) ?? true;

      if (_autoReconnect &&
          _savedMacAddress != null &&
          _savedMacAddress!.isNotEmpty) {
        await tryAutoConnect();
      }
    } catch (_) {}
  }

  Future<bool> tryAutoConnect() async {
    if (_isConnected || _isAutoConnecting) return _isConnected;
    if (_savedMacAddress == null || _savedMacAddress!.isEmpty) return false;

    _isAutoConnecting = true;
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        _isAutoConnecting = false;
        return false;
      }

      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: _savedMacAddress!,
      );
      _isConnected = result;
      if (result) {
        _connectedDeviceName = _savedDeviceName;
      }
      return result;
    } catch (_) {
      return false;
    } finally {
      _isAutoConnecting = false;
    }
  }

  Future<void> setPaperSize(String size) async {
    _paperSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPaperSize, size);
  }

  Future<void> setAutoReconnect(bool enabled) async {
    _autoReconnect = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoReconnect, enabled);
  }

  Future<void> setAutoDrawerKick(bool enabled) async {
    _autoDrawerKick = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoDrawerKick, enabled);
  }

  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
        (statuses[Permission.bluetoothConnect]?.isGranted ?? false);
  }

  Future<List<BluetoothInfo>> getBluetoothDevices() async {
    final bool permission = await checkPermissions();
    if (!permission) return [];

    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> connect(String macAddress, String name) async {
    final bool result = await PrintBluetoothThermal.connect(
      macPrinterAddress: macAddress,
    );
    _isConnected = result;
    if (result) {
      _connectedDeviceName = name;
      _savedMacAddress = macAddress;
      _savedDeviceName = name;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefPrinterMac, macAddress);
      await prefs.setString(_prefPrinterName, name);
    }
    return result;
  }

  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    _isConnected = false;
    _connectedDeviceName = null;
  }

  Future<void> forgetDevice() async {
    await disconnect();
    _savedMacAddress = null;
    _savedDeviceName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPrinterMac);
    await prefs.remove(_prefPrinterName);
  }

  Future<bool> openCashDrawer() async {
    if (!_isConnected) return false;
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(paperSize, profile);
      List<int> bytes = [];
      bytes += generator.drawer();
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    }
  }

  Future<bool> printTestReceipt({BusinessInfo? businessInfo}) async {
    if (!_isConnected) return false;
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(paperSize, profile);
      List<int> bytes = [];

      bytes += generator.setStyles(
        const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(businessInfo?.businessName ?? 'LACI POS');
      bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
      bytes += generator.text('UJI COBA CETAK STRUK BERHASIL');
      bytes += generator.text('Ukuran Kertas: $_paperSize mm');
      bytes += generator.text(
        'Waktu: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
      );
      bytes += generator.hr();
      bytes += generator.text('Printer thermal terhubung dan siap digunakan!');
      bytes += generator.feed(2);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    }
  }

  Future<bool> printReceipt({
    required TransactionEntity transaction,
    BusinessInfo? businessInfo,
  }) async {
    if (!_isConnected) return false;

    List<int> bytes = await _generateReceipt(transaction, businessInfo);
    final bool result = await PrintBluetoothThermal.writeBytes(bytes);
    return result;
  }

  Future<bool> printShiftReport({
    required ShiftEntity shift,
    required ShiftSummary summary,
    BusinessInfo? businessInfo,
  }) async {
    if (!_isConnected) return false;

    List<int> bytes = await _generateShiftReport(shift, summary, businessInfo);
    final bool result = await PrintBluetoothThermal.writeBytes(bytes);
    return result;
  }

  Future<bool> printHeldOrderProforma({
    required HeldOrder order,
    BusinessInfo? businessInfo,
  }) async {
    if (!_isConnected) return false;

    List<int> bytes = await _generateHeldOrderProforma(order, businessInfo);
    final bool result = await PrintBluetoothThermal.writeBytes(bytes);
    return result;
  }

  Future<List<int>> _generateHeldOrderProforma(
    HeldOrder order,
    BusinessInfo? businessInfo,
  ) async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);

    bytes += generator.setStyles(
      const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.text('--- TAGIHAN SEMENTARA ---');
    bytes += generator.text('(BELUM LUNAS)');
    bytes += generator.text(businessInfo?.businessName ?? 'TOKO LACI POS');

    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    if (businessInfo?.phone != null) {
      bytes += generator.text('Telp: ${businessInfo!.phone}');
    }

    bytes += generator.hr();
    bytes += generator.text('Pesanan / Meja: ${order.orderName}');
    bytes += generator.text(
      'Waktu: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
    );
    if (order.createdBy.isNotEmpty) {
      bytes += generator.text('Kasir: ${order.createdBy}');
    }
    if (order.customerName != null && order.customerName!.trim().isNotEmpty) {
      bytes += generator.text('Pelanggan: ${order.customerName!.trim()}');
    }
    if (order.notes != null && order.notes!.trim().isNotEmpty) {
      bytes += generator.text('Catatan: ${order.notes!.trim()}');
    }
    bytes += generator.hr();

    for (var item in order.items) {
      bytes += generator.text(
        item.displayName,
        styles: const PosStyles(bold: true),
      );
      if (item.selectedModifiers.isNotEmpty) {
        bytes += generator.text(
          ' + ${item.modifiersDisplay}',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
      if (item.notes != null && item.notes!.trim().isNotEmpty) {
        bytes += generator.text(
          ' * ${item.notes!.trim()}',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
      bytes += generator.row([
        PosColumn(
          text: '${item.quantity} x ${item.unitPrice.toInt()}',
          width: 8,
        ),
        PosColumn(
          text: item.subtotal.toInt().toString(),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'TOTAL SEMENTARA', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
        text: order.totalAmount.toInt().toString(),
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += generator.hr();
    bytes += generator.setStyles(
      const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    bytes += generator.text('* BUKAN BUKTI PEMBAYARAN SAH *');
    bytes += generator.text('Silakan bawa ke kasir untuk pelunasan');
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> _generateReceipt(
    TransactionEntity transaction,
    BusinessInfo? businessInfo,
  ) async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final cfg = ReceiptSettingsService().config;

    bytes += generator.setStyles(
      const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(businessInfo?.businessName ?? 'TOKO LACI POS');

    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    if (cfg.headerMessage.trim().isNotEmpty) {
      bytes += generator.text(cfg.headerMessage.trim());
    }
    if (cfg.showAddress && businessInfo?.address != null) {
      bytes += generator.text(businessInfo!.address!);
    }
    if (cfg.showPhone && businessInfo?.phone != null) {
      bytes += generator.text('Telp: ${businessInfo!.phone}');
    }

    bytes += generator.hr();
    bytes += generator.text('No: ${transaction.transactionCode}');
    bytes += generator.text(
      'Tgl: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}',
    );
    if (cfg.showCashierName && transaction.createdBy.isNotEmpty) {
      bytes += generator.text('Kasir: ${transaction.createdBy}');
    }
    if (cfg.showCustomerName &&
        transaction.customerName != null &&
        transaction.customerName!.isNotEmpty) {
      bytes += generator.text('Plg: ${transaction.customerName}');
    }
    if (cfg.showTableNumber &&
        transaction.notes != null &&
        transaction.notes!.trim().isNotEmpty) {
      bytes += generator.text('Tipe: ${transaction.notes!.trim()}');
    }
    bytes += generator.hr();

    for (var item in transaction.items) {
      bytes += generator.text(
        item.displayName,
        styles: const PosStyles(bold: true),
      );
      if (item.selectedModifiers.isNotEmpty) {
        bytes += generator.text(
          ' + ${item.modifiersDisplay}',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
      if (cfg.showItemNotes &&
          item.notes != null &&
          item.notes!.trim().isNotEmpty) {
        bytes += generator.text(
          ' * ${item.notes!.trim()}',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
      bytes += generator.row([
        PosColumn(
          text: '${item.quantity} x ${item.unitPrice.toInt()}',
          width: 8,
        ),
        PosColumn(
          text: item.subtotal.toInt().toString(),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 8),
      PosColumn(
        text: transaction.subtotal.toInt().toString(),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    if (transaction.taxAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Pajak', width: 8),
        PosColumn(
          text: transaction.taxAmount.toInt().toString(),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    if (transaction.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Diskon', width: 8),
        PosColumn(
          text: '-${transaction.discountAmount.toInt()}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'Total', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
        text: transaction.totalAmount.toInt().toString(),
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    bytes += generator.hr();
    for (var payment in transaction.payments) {
      bytes += generator.row([
        PosColumn(text: payment.typeName, width: 8),
        PosColumn(
          text: payment.amount.toInt().toString(),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (transaction.changeAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Kembali', width: 8),
        PosColumn(
          text: transaction.changeAmount.toInt().toString(),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    // Auto-kick cash drawer for cash transactions
    final hasCash =
        transaction.payments.any((p) => p.type == PaymentType.cash);
    if (_autoDrawerKick && (hasCash || transaction.payments.isEmpty)) {
      bytes += generator.drawer();
    }

    bytes += generator.hr();
    bytes += generator.feed(1);
    if (cfg.footerMessage.trim().isNotEmpty) {
      bytes += generator.text(
        cfg.footerMessage.trim(),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    if (cfg.footerNote.trim().isNotEmpty) {
      bytes += generator.text(
        cfg.footerNote.trim(),
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (cfg.socialMediaOrWifi.trim().isNotEmpty) {
      bytes += generator.text(
        cfg.socialMediaOrWifi.trim(),
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> _generateShiftReport(
    ShiftEntity shift,
    ShiftSummary summary,
    BusinessInfo? businessInfo,
  ) async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final curFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Header Store Name
    bytes += generator.setStyles(
      const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(businessInfo?.businessName ?? 'TOKO LACI POS');

    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    if (businessInfo?.address != null) {
      bytes += generator.text(businessInfo!.address!);
    }
    bytes += generator.hr();

    // Report Title
    final isZReport = shift.isClosed;
    bytes += generator.text(
      isZReport ? 'LAPORAN TUTUP SHIFT' : 'REKAP SEMENTARA SHIFT',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.text(
      isZReport ? '(Z-REPORT)' : '(X-REPORT)',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.hr();

    // Cashier & Time Info
    bytes += generator.text('Kasir: ${shift.userName}');
    bytes += generator.text(
      'Buka : ${DateFormat('dd/MM/yy HH:mm').format(shift.startTime)}',
    );
    if (shift.endTime != null) {
      bytes += generator.text(
        'Tutup: ${DateFormat('dd/MM/yy HH:mm').format(shift.endTime!)}',
      );
    } else {
      bytes += generator.text('Tutup: (Shift Aktif)');
    }
    bytes += generator.hr();

    // Sales Summary Breakdown
    bytes += generator.row([
      PosColumn(text: 'Modal Awal', width: 7),
      PosColumn(
        text: curFmt.format(shift.startCash),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Total Nota', width: 7),
      PosColumn(
        text: '${summary.totalTransactions} Transaksi',
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Penjualan Tunai', width: 7),
      PosColumn(
        text: curFmt.format(summary.totalCashSales),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    if (summary.totalQrisSales > 0) {
      bytes += generator.row([
        PosColumn(text: 'QRIS', width: 7),
        PosColumn(
          text: curFmt.format(summary.totalQrisSales),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    if (summary.totalDebitSales > 0) {
      bytes += generator.row([
        PosColumn(text: 'Debit EDC', width: 7),
        PosColumn(
          text: curFmt.format(summary.totalDebitSales),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    if (summary.totalTransferSales > 0) {
      bytes += generator.row([
        PosColumn(text: 'Transfer Bank', width: 7),
        PosColumn(
          text: curFmt.format(summary.totalTransferSales),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL OMSET',
        width: 7,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: curFmt.format(summary.totalSales),
        width: 5,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += generator.hr();

    // Petty Cash In / Out
    bytes += generator.row([
      PosColumn(text: '(+) Kas Masuk', width: 7),
      PosColumn(
        text: curFmt.format(summary.totalCashIn),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: '(-) Kas Keluar', width: 7),
      PosColumn(
        text: curFmt.format(summary.totalCashOut),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();
    final expectedDrawerCash = summary.expectedCashInDrawer;
    bytes += generator.row([
      PosColumn(
        text: 'Uang Seharusnya',
        width: 7,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: curFmt.format(expectedDrawerCash),
        width: 5,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    if (shift.isClosed && shift.endCashActual != null) {
      bytes += generator.row([
        PosColumn(
          text: 'Uang Fisik Di Laci',
          width: 7,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: curFmt.format(shift.endCashActual!),
          width: 5,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      final diff = shift.cashDifference ?? 0;
      final diffText = diff == 0
          ? 'PAS (Rp 0)'
          : diff > 0
              ? 'LEBIH +${curFmt.format(diff)}'
              : 'KURANG ${curFmt.format(diff)}';

      bytes += generator.row([
        PosColumn(
          text: 'SELISIH KAS',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: diffText,
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }

    if (shift.notes != null && shift.notes!.trim().isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.text('Catatan: ${shift.notes!.trim()}');
    }

    bytes += generator.feed(1);
    bytes += generator.row([
      PosColumn(
        text: '[ Kasir ]',
        width: 6,
        styles: const PosStyles(align: PosAlign.center),
      ),
      PosColumn(
        text: '[ Supervisor ]',
        width: 6,
        styles: const PosStyles(align: PosAlign.center),
      ),
    ]);
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
