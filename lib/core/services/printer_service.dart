import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/business_entity.dart';
import 'package:intl/intl.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _connectedDeviceName;
  String? get connectedDeviceName => _connectedDeviceName;

  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted;
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
    }
    return result;
  }

  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    _isConnected = false;
    _connectedDeviceName = null;
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

  Future<List<int>> _generateReceipt(
    TransactionEntity transaction,
    BusinessInfo? businessInfo,
  ) async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

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
    if (businessInfo?.phone != null) {
      bytes += generator.text('Telp: ${businessInfo!.phone}');
    }

    bytes += generator.hr();
    bytes += generator.text('No: ${transaction.transactionCode}');
    bytes += generator.text(
      'Tgl: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}',
    );
    if (transaction.customerName != null) {
      bytes += generator.text('Plg: ${transaction.customerName}');
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

    bytes += generator.hr();
    bytes += generator.feed(1);
    bytes += generator.text(
      'Terima Kasih',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Sudah Berbelanja',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
