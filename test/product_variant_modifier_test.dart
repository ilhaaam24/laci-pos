import 'package:flutter_test/flutter_test.dart';
import 'package:laci/domain/entities/product_entity.dart';
import 'package:laci/domain/entities/product_variant.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'package:laci/presentation/blocs/cart/cart_bloc.dart';

Product _createTestProduct({
  required String id,
  required String name,
  required double price,
  double costPrice = 0,
  int stock = 100,
  List<ProductVariant> variants = const [],
  List<ModifierGroup> modifierGroups = const [],
}) {
  final now = DateTime.now();
  return Product(
    id: id,
    categoryId: 'cat_default',
    name: name,
    price: price,
    costPrice: costPrice,
    stock: stock,
    createdAt: now,
    updatedAt: now,
    variants: variants,
    modifierGroups: modifierGroups,
  );
}

void main() {
  group('Product Variant & Modifier Entity Tests', () {
    test('ProductVariant serialization and deserialization', () {
      const variant = ProductVariant(
        id: 'var_1',
        name: 'Large',
        price: 24000,
        costPrice: 12000,
        stock: 50,
        sku: 'KOPI-LG',
      );

      final json = variant.toJson();
      expect(json['id'], 'var_1');
      expect(json['name'], 'Large');
      expect(json['price'], 24000.0);
      expect(json['costPrice'], 12000.0);
      expect(json['stock'], 50);
      expect(json['sku'], 'KOPI-LG');

      final fromJson = ProductVariant.fromJson(json);
      expect(fromJson, equals(variant));
    });

    test('ModifierOption and ModifierGroup allowMultiple behavior', () {
      const option1 = ModifierOption(
        id: 'opt_1',
        name: 'Boba',
        price: 4000,
      );
      const option2 = ModifierOption(
        id: 'opt_2',
        name: 'Extra Shot',
        price: 5000,
      );

      const multiGroup = ModifierGroup(
        id: 'grp_topping',
        name: 'Topping',
        allowMultiple: true,
        options: [option1, option2],
      );

      expect(multiGroup.allowMultiple, true);
      expect(multiGroup.isMultiple, true);

      const singleGroup = ModifierGroup(
        id: 'grp_sugar',
        name: 'Tingkat Gula',
        allowMultiple: false,
        options: [
          ModifierOption(id: 's_1', name: 'Normal Sugar', price: 0),
          ModifierOption(id: 's_2', name: 'Less Sugar', price: 0),
        ],
      );

      expect(singleGroup.allowMultiple, false);
      expect(singleGroup.isMultiple, false);

      final json = multiGroup.toJson();
      final fromJson = ModifierGroup.fromJson(json);
      expect(fromJson.allowMultiple, true);
      expect(fromJson.options.length, 2);
    });

    test('Product entity hasVariants and hasModifiers flags', () {
      final plainProduct = _createTestProduct(
        id: 'p_plain',
        name: 'Air Mineral',
        price: 5000,
      );
      expect(plainProduct.hasVariants, false);
      expect(plainProduct.hasModifiers, false);

      final variantProduct = _createTestProduct(
        id: 'p_coffee',
        name: 'Kopi Susu',
        price: 18000,
        variants: const [
          ProductVariant(id: 'v1', name: 'Regular', price: 18000),
          ProductVariant(id: 'v2', name: 'Large', price: 24000),
        ],
      );
      expect(variantProduct.hasVariants, true);
      expect(variantProduct.hasModifiers, false);

      final modifierProduct = _createTestProduct(
        id: 'p_tea',
        name: 'Teh Manis',
        price: 8000,
        modifierGroups: const [
          ModifierGroup(
            id: 'm1',
            name: 'Es Batu',
            options: [
              ModifierOption(id: 'o1', name: 'Normal Ice', price: 0),
              ModifierOption(id: 'o2', name: 'Less Ice', price: 0),
            ],
          ),
        ],
      );
      expect(modifierProduct.hasVariants, false);
      expect(modifierProduct.hasModifiers, true);
    });
  });

  group('TransactionItem Variant & Modifier Tests', () {
    test('TransactionItem calculates unitPrice and formats displayName correctly', () {
      const variant = ProductVariant(
        id: 'v_large',
        name: 'Large',
        price: 24000,
        costPrice: 10000,
      );

      const boba = ModifierOption(
        id: 'm_boba',
        name: 'Boba',
        price: 4000,
      );

      const extraShot = ModifierOption(
        id: 'm_shot',
        name: 'Extra Shot',
        price: 5000,
      );

      const item = TransactionItem(
        id: 'item_1',
        productId: 'p_coffee',
        productName: 'Kopi Susu',
        quantity: 2,
        price: 18000,
        costPrice: 10000,
        subtotal: 66000, // (24000 + 4000 + 5000) * 2 = 33000 * 2 = 66000
        selectedVariant: variant,
        selectedModifiers: [boba, extraShot],
        notes: 'Less ice please',
      );

      expect(item.unitPrice, 33000.0);
      expect(item.displayName, 'Kopi Susu (Large)');
      expect(item.modifiersDisplay, '+Boba, +Extra Shot');
      expect(item.notes, 'Less ice please');
    });

    test('TransactionItem without variant uses base product price and name', () {
      const item = TransactionItem(
        id: 'item_2',
        productId: 'p_water',
        productName: 'Air Mineral',
        quantity: 3,
        price: 5000,
        costPrice: 2000,
        subtotal: 15000,
      );

      expect(item.unitPrice, 5000.0);
      expect(item.displayName, 'Air Mineral');
      expect(item.modifiersDisplay, isEmpty);
    });
  });

  group('CartBloc with Variants and Modifiers Tests', () {
    late CartBloc cartBloc;

    setUp(() {
      cartBloc = CartBloc();
    });

    tearDown(() {
      cartBloc.close();
    });

    test('1-tap add for simple product adds item and increments quantity', () async {
      final product = _createTestProduct(
        id: 'p1',
        name: 'Roti Bakar',
        price: 15000,
      );

      cartBloc.add(AddToCart(product));
      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          return state.items.length == 1 &&
              state.items.first.quantity == 1 &&
              state.totalAmount == 15000;
        })),
      );

      // Add same simple product again -> increments quantity to 2
      cartBloc.add(AddToCart(product));
      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          return state.items.length == 1 &&
              state.items.first.quantity == 2 &&
              state.totalAmount == 30000;
        })),
      );
    });

    test('Different variants for same product create distinct cart line items', () async {
      final product = _createTestProduct(
        id: 'p_coffee',
        name: 'Kopi Susu',
        price: 18000,
      );

      const variantReg = ProductVariant(
        id: 'v_reg',
        name: 'Regular',
        price: 18000,
      );

      const variantLarge = ProductVariant(
        id: 'v_lg',
        name: 'Large',
        price: 24000,
      );

      // Add Regular
      cartBloc.add(AddToCart(product, selectedVariant: variantReg));
      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          return state.items.length == 1 &&
              state.items.first.selectedVariant?.name == 'Regular' &&
              state.totalAmount == 18000;
        })),
      );

      // Add Large -> creates separate cart item
      cartBloc.add(AddToCart(product, selectedVariant: variantLarge));
      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          return state.items.length == 2 &&
              state.items.any((i) => i.selectedVariant?.name == 'Regular') &&
              state.items.any((i) => i.selectedVariant?.name == 'Large') &&
              state.totalAmount == 42000; // 18000 + 24000
        })),
      );
    });

    test('Item with modifiers calculates total price correctly and supports quantity changes', () async {
      final product = _createTestProduct(
        id: 'p_tea',
        name: 'Milk Tea',
        price: 15000,
      );

      const boba = ModifierOption(
        id: 'm_boba',
        name: 'Boba',
        price: 4000,
      );

      cartBloc.add(
        AddToCart(
          product,
          selectedModifiers: const [boba],
          notes: 'No Sugar',
        ),
      );

      late String itemId;
      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          if (state.items.isNotEmpty) {
            itemId = state.items.first.id;
          }
          // unit price = 15000 + 4000 = 19000
          return state.items.length == 1 &&
              state.totalAmount == 19000 &&
              state.items.first.notes == 'No Sugar';
        })),
      );

      // Increment quantity
      cartBloc.add(IncrementQuantity(itemId));
      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          return state.items.first.quantity == 2 && state.totalAmount == 38000;
        })),
      );

      // Decrease quantity
      cartBloc.add(DecreaseQuantity(itemId));
      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          return state.items.first.quantity == 1 && state.totalAmount == 19000;
        })),
      );

      // Remove from cart
      cartBloc.add(RemoveFromCart(itemId));
      await expectLater(
        cartBloc.stream,
        emits(predicate<CartState>((state) {
          return state.items.isEmpty && state.totalAmount == 0;
        })),
      );
    });
  });
}
