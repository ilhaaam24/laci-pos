import 'package:flutter_test/flutter_test.dart';
import 'package:laci/domain/entities/product_entity.dart';
import 'package:laci/domain/entities/product_variant.dart';
import 'package:laci/presentation/blocs/cart/cart_bloc.dart';

Product _buildProduct({
  required String id,
  required String name,
  required double price,
  required int stock,
  bool trackStock = true,
  List<ProductVariant> variants = const [],
  List<ModifierGroup> modifierGroups = const [],
}) {
  final now = DateTime.now();
  return Product(
    id: id,
    categoryId: 'cat_test',
    name: name,
    price: price,
    costPrice: price * 0.5,
    stock: stock,
    trackStock: trackStock,
    createdAt: now,
    updatedAt: now,
    variants: variants,
    modifierGroups: modifierGroups,
  );
}

void main() {
  group('Cart Stock Validation Tests', () {
    late CartBloc cartBloc;

    setUp(() {
      cartBloc = CartBloc();
    });

    tearDown(() {
      cartBloc.close();
    });

    test('Cannot add to cart beyond available stock (e.g. stock 5, cannot add 6th)', () async {
      final product = _buildProduct(
        id: 'p_stock_5',
        name: 'Kopi Susu Gula Aren',
        price: 18000,
        stock: 5,
        trackStock: true,
      );

      // Add 5 items sequentially
      for (int i = 1; i <= 5; i++) {
        cartBloc.add(AddToCart(product));
      }

      await expectLater(
        cartBloc.stream,
        emitsThrough(predicate<CartState>((state) {
          return state.items.length == 1 && state.items.first.quantity == 5;
        })),
      );

      // Attempt to add 6th item -> should be rejected, state remains at quantity: 5
      cartBloc.add(AddToCart(product));

      // Wait a tick for any potential event processing
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cartBloc.state.items.first.quantity, 5);
      expect(cartBloc.state.totalAmount, 5 * 18000);
    });

    test('Cannot add bulk quantity that exceeds stock in a single AddToCart event', () async {
      final product = _buildProduct(
        id: 'p_stock_3',
        name: 'Croissant Coklat',
        price: 25000,
        stock: 3,
        trackStock: true,
      );

      // Try to add 4 items directly when stock is 3
      cartBloc.add(AddToCart(product, quantity: 4));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Cart should remain empty
      expect(cartBloc.state.items.isEmpty, isTrue);
      expect(cartBloc.state.totalAmount, 0);

      // Now add valid quantity (3) -> should succeed
      cartBloc.add(AddToCart(product, quantity: 3));

      await expectLater(
        cartBloc.stream,
        emitsThrough(predicate<CartState>((state) {
          return state.items.length == 1 && state.items.first.quantity == 3;
        })),
      );

      expect(cartBloc.state.items.first.quantity, 3);
    });

    test('IncrementQuantity cannot increase item quantity beyond maxStock', () async {
      final product = _buildProduct(
        id: 'p_stock_2',
        name: 'Es Teh Manis',
        price: 5000,
        stock: 2,
        trackStock: true,
      );

      cartBloc.add(AddToCart(product, quantity: 2));

      await expectLater(
        cartBloc.stream,
        emitsThrough(predicate<CartState>((state) {
          return state.items.length == 1 && state.items.first.quantity == 2;
        })),
      );

      final itemId = cartBloc.state.items.first.id;

      // Try to increment when already at max stock (2)
      cartBloc.add(IncrementQuantity(itemId));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Quantity must still be 2
      expect(cartBloc.state.items.first.quantity, 2);
    });

    test('Allows unlimited additions when trackStock is false (e.g. F&B custom / services)', () async {
      final product = _buildProduct(
        id: 'p_unlimited',
        name: 'Jasa Desain / Cooked Menu',
        price: 50000,
        stock: 0,
        trackStock: false,
      );

      cartBloc.add(AddToCart(product, quantity: 15));

      await expectLater(
        cartBloc.stream,
        emitsThrough(predicate<CartState>((state) {
          return state.items.length == 1 && state.items.first.quantity == 15;
        })),
      );

      expect(cartBloc.state.items.first.quantity, 15);
      expect(cartBloc.state.items.first.maxStock, isNull);
    });

    test('Validates variant-specific stock independently', () async {
      const variantSmall = ProductVariant(
        id: 'v_small',
        name: 'Small',
        price: 15000,
        stock: 2,
      );
      const variantLarge = ProductVariant(
        id: 'v_large',
        name: 'Large',
        price: 20000,
        stock: 4,
      );

      final product = _buildProduct(
        id: 'p_variants',
        name: 'Kopi Susu Variant',
        price: 15000,
        stock: 6,
        trackStock: true,
        variants: [variantSmall, variantLarge],
      );

      // Add 2 Small -> reaches Small variant stock limit (2)
      cartBloc.add(AddToCart(product, selectedVariant: variantSmall, quantity: 2));

      await expectLater(
        cartBloc.stream,
        emitsThrough(predicate<CartState>((state) {
          return state.items.any((i) => i.selectedVariant?.id == 'v_small' && i.quantity == 2);
        })),
      );

      // Try to add 3rd Small -> should be rejected
      cartBloc.add(AddToCart(product, selectedVariant: variantSmall, quantity: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        cartBloc.state.items.firstWhere((i) => i.selectedVariant?.id == 'v_small').quantity,
        2,
      );

      // But can still add Large variant up to its own stock (4)
      cartBloc.add(AddToCart(product, selectedVariant: variantLarge, quantity: 3));

      await expectLater(
        cartBloc.stream,
        emitsThrough(predicate<CartState>((state) {
          return state.items.any((i) => i.selectedVariant?.id == 'v_large' && i.quantity == 3);
        })),
      );

      expect(
        cartBloc.state.items.firstWhere((i) => i.selectedVariant?.id == 'v_large').quantity,
        3,
      );
    });

    test('Multiple cart items of same product with different notes share the same stock limit', () async {
      final product = _buildProduct(
        id: 'p_shared_stock',
        name: 'Nasi Goreng Spesial',
        price: 30000,
        stock: 4,
        trackStock: true,
      );

      // Line item 1: 2 portion with "Pedas"
      cartBloc.add(AddToCart(product, notes: 'Pedas', quantity: 2));

      // Line item 2: 2 portion with "Tidak Pedas" -> Total 4 (reaches stock limit)
      cartBloc.add(AddToCart(product, notes: 'Tidak Pedas', quantity: 2));

      await expectLater(
        cartBloc.stream,
        emitsThrough(predicate<CartState>((state) {
          return state.items.length == 2 &&
              state.items.fold<int>(0, (sum, i) => sum + i.quantity) == 4;
        })),
      );

      // Try to increment item 1
      final item1Id = cartBloc.state.items.firstWhere((i) => i.notes == 'Pedas').id;
      cartBloc.add(IncrementQuantity(item1Id));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Sum of both items must still be 4
      final totalQty = cartBloc.state.items.fold<int>(0, (sum, i) => sum + i.quantity);
      expect(totalQty, 4);
    });
  });
}
