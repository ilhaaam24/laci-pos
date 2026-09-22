import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laci/core/services/printer_service.dart';
import 'package:laci/core/services/whatsapp_service.dart';
import 'package:laci/domain/entities/business_entity.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Printer Hardware & Configuration Tests', () {
    test('PrinterService defaults to 58mm paper size and auto-reconnect enabled', () async {
      final printerService = PrinterService();
      await printerService.init();

      expect(printerService.paperSize, equals(PaperSize.mm58));
      expect(printerService.paperSizeString, equals('58'));
      expect(printerService.autoReconnect, isTrue);
      expect(printerService.autoDrawerKick, isTrue);
    });

    test('PrinterService setPaperSize persists 80mm to SharedPreferences', () async {
      final printerService = PrinterService();
      await printerService.init();

      await printerService.setPaperSize('80');
      expect(printerService.paperSize, equals(PaperSize.mm80));
      expect(printerService.paperSizeString, equals('80'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_printer_paper_size'), equals('80'));

      // Switch back to 58mm
      await printerService.setPaperSize('58');
      expect(printerService.paperSize, equals(PaperSize.mm58));
      expect(printerService.paperSizeString, equals('58'));
      expect(prefs.getString('pref_printer_paper_size'), equals('58'));
    });

    test('PrinterService autoReconnect and autoDrawerKick toggle and persist', () async {
      final printerService = PrinterService();
      await printerService.init();

      await printerService.setAutoReconnect(false);
      expect(printerService.autoReconnect, isFalse);

      await printerService.setAutoDrawerKick(false);
      expect(printerService.autoDrawerKick, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pref_printer_auto_reconnect'), isFalse);
      expect(prefs.getBool('pref_printer_auto_drawer_kick'), isFalse);
    });

    test('PrinterService loads persisted printer address and config correctly', () async {
      SharedPreferences.setMockInitialValues({
        'pref_printer_mac': '00:11:22:33:44:55',
        'pref_printer_name': 'Thermal Printer 80',
        'pref_printer_paper_size': '80',
        'pref_printer_auto_reconnect': true,
        'pref_printer_auto_drawer_kick': true,
      });

      final printerService = PrinterService();
      await printerService.init();

      expect(printerService.savedMacAddress, equals('00:11:22:33:44:55'));
      expect(printerService.savedDeviceName, equals('Thermal Printer 80'));
      expect(printerService.paperSize, equals(PaperSize.mm80));
      expect(printerService.autoReconnect, isTrue);
      expect(printerService.autoDrawerKick, isTrue);
    });
  });

  group('Table Number & Receipt Integration Tests', () {
    test('TransactionEntity properly stores table number in notes', () {
      final now = DateTime.now();
      const tableNote = 'Dine In (Meja 05)';
      final transaction = TransactionEntity(
        id: 'trx_table_01',
        transactionCode: 'INV-20260922001',
        subtotal: 45000,
        totalAmount: 45000,
        amountPaid: 50000,
        changeAmount: 5000,
        createdAt: now,
        createdBy: 'Kasir Utama',
        notes: tableNote,
        payments: [
          PaymentDetail(
            type: PaymentType.cash,
            amount: 50000,
            timestamp: now,
          ),
        ],
        items: const [
          TransactionItem(
            id: 'item_1',
            productId: 'p1',
            productName: 'Nasi Goreng Spesial',
            quantity: 1,
            price: 45000,
            costPrice: 20000,
            subtotal: 45000,
          ),
        ],
      );

      expect(transaction.notes, equals('Dine In (Meja 05)'));
    });

    test('WhatsappService includes table number in receipt message when notes present', () {
      final now = DateTime(2026, 9, 22, 10, 30);
      final transaction = TransactionEntity(
        id: 'trx_table_02',
        transactionCode: 'INV-20260922002',
        customerName: 'Siti Rahma',
        subtotal: 35000,
        totalAmount: 35000,
        amountPaid: 35000,
        changeAmount: 0,
        createdAt: now,
        createdBy: 'Kasir Utama',
        notes: 'Dine In (VIP 1)',
        payments: [
          PaymentDetail(
            type: PaymentType.cash,
            amount: 35000,
            timestamp: now,
          ),
        ],
        items: const [
          TransactionItem(
            id: 'item_1',
            productId: 'p2',
            productName: 'Iced Matcha Latte',
            quantity: 1,
            price: 35000,
            costPrice: 15000,
            subtotal: 35000,
          ),
        ],
      );

      final businessInfo = BusinessInfo(
        id: 'biz_01',
        businessName: 'Laci Cafe & Resto',
        createdAt: now,
        updatedAt: now,
      );

      final message = WhatsappService.buildReceiptMessage(
        transaction: transaction,
        businessInfo: businessInfo,
      );

      expect(message.contains('Layanan / Meja: Dine In (VIP 1)'), isTrue);
      expect(message.contains('Iced Matcha Latte'), isTrue);
      expect(message.contains('Siti Rahma'), isTrue);
    });
  });
}
