import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laci/core/services/held_order_service.dart';
import 'package:laci/domain/entities/held_order_entity.dart';
import 'package:laci/domain/entities/customer_entity.dart';
import 'package:laci/domain/entities/product_variant.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'package:laci/presentation/blocs/cart/cart_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeldOrder Entity Tests', () {
    test('HeldOrder serialization & deserialization with items, variant, and customer', () {
      final now = DateTime.now();
      final customer = Customer(
        id: 'cust_01',
        name: 'Pak Budi',
        phone: '081234567890',
        businessId: 'biz_01',
        createdAt: now,
        updatedAt: now,
      );

      const variant = ProductVariant(
        id: 'var_01',
        name: 'Large',
        price: 21000,
        costPrice: 10000,
        stock: 50,
      );

      const modifier = ModifierOption(
        id: 'mod_01',
        name: 'Extra Shot Espresso',
        price: 5000,
      );

      final item = TransactionItem(
        id: 'item_01',
        productId: 'prod_01',
        productName: 'Kopi Susu Gula Aren',
        price: 18000,
        costPrice: 8000,
        quantity: 2,
        subtotal: 52000,
        selectedVariant: variant,
        selectedModifiers: [modifier],
        notes: 'Less ice, less sugar',
      );

      final order = HeldOrder(
        id: 'held_01',
        orderName: 'Meja 05',
        customerName: 'Pak Budi',
        customer: customer,
        items: [item],
        subtotal: 52000,
        totalAmount: 52000,
        notes: 'Jangan pakai sedotan plastik',
        createdAt: now,
        updatedAt: now,
        createdBy: 'Kasir 1',
      );

      final json = order.toJson();
      expect(json['id'], 'held_01');
      expect(json['orderName'], 'Meja 05');
      expect(json['customerName'], 'Pak Budi');
      expect(json['customer']['id'], 'cust_01');
      expect(json['items'], isA<List>());
      expect(json['items'].length, 1);
      expect(json['notes'], 'Jangan pakai sedotan plastik');
      expect(json['createdBy'], 'Kasir 1');

      final fromJson = HeldOrder.fromJson(json);
      expect(fromJson.id, order.id);
      expect(fromJson.orderName, order.orderName);
      expect(fromJson.customerName, order.customerName);
      expect(fromJson.customer?.phone, '081234567890');
      expect(fromJson.items.length, 1);
      expect(fromJson.items.first.productName, 'Kopi Susu Gula Aren');
      expect(fromJson.items.first.quantity, 2);
      expect(fromJson.items.first.notes, 'Less ice, less sugar');
      expect(fromJson.items.first.selectedVariant?.name, 'Large');
      expect(fromJson.items.first.selectedModifiers.first.name, 'Extra Shot Espresso');
      expect(fromJson.subtotal, 52000);
      expect(fromJson.totalAmount, 52000);
      expect(fromJson.createdBy, 'Kasir 1');
    });

    test('HeldOrder totalQuantity and summaryText calculation', () {
      final now = DateTime(2026, 9, 22, 14, 30);
      final item1 = TransactionItem(
        id: 'item_1',
        productId: 'p_1',
        productName: 'Kopi Tubruk',
        price: 10000,
        costPrice: 4000,
        quantity: 3,
        subtotal: 30000,
      );
      final item2 = TransactionItem(
        id: 'item_2',
        productId: 'p_2',
        productName: 'Roti Bakar',
        price: 15000,
        costPrice: 7000,
        quantity: 2,
        subtotal: 30000,
      );

      final order = HeldOrder(
        id: 'held_02',
        orderName: 'Meja VIP',
        items: [item1, item2],
        subtotal: 60000,
        totalAmount: 60000,
        createdAt: now,
        updatedAt: now,
        createdBy: 'Kasir',
      );

      expect(order.totalQuantity, 5); // 3 + 2
      expect(order.summaryText, '3x Kopi Tubruk, 2x Roti Bakar');
    });
  });

  group('HeldOrderService Storage Tests', () {
    late HeldOrderService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = HeldOrderService();
      await service.init();
      await service.clearAllHeldOrders();
    });

    test('Initial state is empty', () {
      expect(service.heldOrders, isEmpty);
      expect(service.heldOrderCount, 0);
      expect(service.heldOrderCountNotifier.value, 0);
    });

    test('Save and retrieve held orders with correct ordering', () async {
      final now = DateTime.now();
      final order1 = HeldOrder(
        id: 'h_1',
        orderName: 'Meja 01',
        items: [
          TransactionItem(
            id: 'i_1',
            productId: 'p_1',
            productName: 'Espresso',
            price: 15000,
            costPrice: 6000,
            quantity: 1,
            subtotal: 15000,
          ),
        ],
        subtotal: 15000,
        totalAmount: 15000,
        createdAt: now,
        updatedAt: now,
        createdBy: 'Kasir',
      );

      await service.saveHeldOrder(order1);

      expect(service.heldOrderCount, 1);
      expect(service.heldOrderCountNotifier.value, 1);
      expect(service.heldOrders.length, 1);
      expect(service.heldOrders.first.orderName, 'Meja 01');

      // Add second order updated 5 minutes later
      final order2 = HeldOrder(
        id: 'h_2',
        orderName: 'Meja 02',
        items: [
          TransactionItem(
            id: 'i_2',
            productId: 'p_2',
            productName: 'Croissant',
            price: 25000,
            costPrice: 12000,
            quantity: 2,
            subtotal: 50000,
          ),
        ],
        subtotal: 50000,
        totalAmount: 50000,
        createdAt: now.add(const Duration(minutes: 5)),
        updatedAt: now.add(const Duration(minutes: 5)),
        createdBy: 'Kasir',
      );

      await service.saveHeldOrder(order2);

      expect(service.heldOrderCount, 2);
      expect(service.heldOrderCountNotifier.value, 2);
      // Newest should be first (sorted by updatedAt descending)
      expect(service.heldOrders.first.id, 'h_2');
      expect(service.heldOrders.last.id, 'h_1');
    });

    test('Update existing held order keeps ID and updates fields', () async {
      final now = DateTime.now();
      final order = HeldOrder(
        id: 'h_update',
        orderName: 'Meja 03',
        items: [
          TransactionItem(
            id: 'i_1',
            productId: 'p_1',
            productName: 'Americano',
            price: 18000,
            costPrice: 7000,
            quantity: 1,
            subtotal: 18000,
          ),
        ],
        subtotal: 18000,
        totalAmount: 18000,
        createdAt: now,
        updatedAt: now,
        createdBy: 'Kasir',
      );

      await service.saveHeldOrder(order);
      expect(service.heldOrderCount, 1);

      // Cashier adds another item to Meja 03
      final updatedOrder = HeldOrder(
        id: 'h_update',
        orderName: 'Meja 03 (Indoor)',
        items: [
          TransactionItem(
            id: 'i_1',
            productId: 'p_1',
            productName: 'Americano',
            price: 18000,
            costPrice: 7000,
            quantity: 1,
            subtotal: 18000,
          ),
          TransactionItem(
            id: 'i_2',
            productId: 'p_2',
            productName: 'Cheese Cake',
            price: 32000,
            costPrice: 15000,
            quantity: 1,
            subtotal: 32000,
          ),
        ],
        subtotal: 50000,
        totalAmount: 50000,
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 10)),
        createdBy: 'Kasir',
      );

      await service.saveHeldOrder(updatedOrder);

      // Count remains 1
      expect(service.heldOrderCount, 1);
      final fetched = service.getHeldOrder('h_update');
      expect(fetched, isNotNull);
      expect(fetched!.orderName, 'Meja 03 (Indoor)');
      expect(fetched.items.length, 2);
      expect(fetched.totalAmount, 50000);
    });

    test('Remove held order decrements count and updates notifier', () async {
      final now = DateTime.now();
      final order = HeldOrder(
        id: 'h_del',
        orderName: 'Meja 04',
        items: [],
        subtotal: 0,
        totalAmount: 0,
        createdAt: now,
        updatedAt: now,
        createdBy: 'Kasir',
      );

      await service.saveHeldOrder(order);
      expect(service.heldOrderCount, 1);

      await service.removeHeldOrder('h_del');
      expect(service.heldOrderCount, 0);
      expect(service.heldOrders, isEmpty);
      expect(service.heldOrderCountNotifier.value, 0);
    });
  });

  group('CartBloc LoadHeldOrderIntoCart Integration Tests', () {
    test('LoadHeldOrderIntoCart populates cart with items, notes, orderName, and heldOrderId', () async {
      final cartBloc = CartBloc();
      final now = DateTime.now();

      final customer = Customer(
        id: 'c_vip',
        name: 'Ibu Ratna',
        phone: '0811223344',
        businessId: 'biz_01',
        createdAt: now,
        updatedAt: now,
      );

      final item = TransactionItem(
        id: 'item_101',
        productId: 'prod_101',
        productName: 'Matcha Latte',
        price: 24000,
        costPrice: 11000,
        quantity: 2,
        subtotal: 48000,
        notes: 'Hot, oat milk',
      );

      final heldOrder = HeldOrder(
        id: 'hold_999',
        orderName: 'Meja 07',
        customerName: 'Ibu Ratna',
        customer: customer,
        items: [item],
        subtotal: 48000,
        totalAmount: 48000,
        notes: 'Pelanggan VIP',
        createdAt: now,
        updatedAt: now,
        createdBy: 'Kasir Utama',
      );

      cartBloc.add(LoadHeldOrderIntoCart(heldOrder));

      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          return state.items.length == 1 &&
              state.items.first.productName == 'Matcha Latte' &&
              state.totalAmount == 48000 &&
              state.heldOrderId == 'hold_999' &&
              state.orderName == 'Meja 07' &&
              state.notes == 'Pelanggan VIP' &&
              state.customer?.name == 'Ibu Ratna';
        })),
      );

      // Now clear cart should reset heldOrderId, orderName, and notes
      cartBloc.add(ClearCart());

      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          return state.items.isEmpty &&
              state.totalAmount == 0.0 &&
              state.heldOrderId == null &&
              state.orderName == null &&
              state.notes == null &&
              state.customer == null;
        })),
      );

      await cartBloc.close();
    });
  });
}
