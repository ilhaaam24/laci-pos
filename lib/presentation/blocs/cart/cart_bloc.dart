import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/product_variant.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/held_order_entity.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;
  final ProductVariant? selectedVariant;
  final List<ModifierOption> selectedModifiers;
  final String? notes;
  final int quantity;

  AddToCart(
    this.product, {
    this.selectedVariant,
    this.selectedModifiers = const [],
    this.notes,
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [
    product,
    selectedVariant,
    selectedModifiers,
    notes,
    quantity,
  ];
}

class RemoveFromCart extends CartEvent {
  final String itemId;
  RemoveFromCart(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class DecreaseQuantity extends CartEvent {
  final String itemId;
  DecreaseQuantity(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class IncrementQuantity extends CartEvent {
  final String itemId;
  IncrementQuantity(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class ClearCart extends CartEvent {}

class SetCartCustomer extends CartEvent {
  final Customer? customer;
  SetCartCustomer(this.customer);
  @override
  List<Object?> get props => [customer];
}

class LoadHeldOrderIntoCart extends CartEvent {
  final HeldOrder order;
  LoadHeldOrderIntoCart(this.order);
  @override
  List<Object?> get props => [order];
}

class SetCartItems extends CartEvent {
  final List<TransactionItem> items;
  final Customer? customer;
  final String? heldOrderId;
  final String? orderName;
  final String? notes;

  SetCartItems(
    this.items, {
    this.customer,
    this.heldOrderId,
    this.orderName,
    this.notes,
  });

  @override
  List<Object?> get props => [items, customer, heldOrderId, orderName, notes];
}

// State
class CartState extends Equatable {
  final List<TransactionItem> items;
  final double totalAmount;
  final Customer? customer;
  final String? heldOrderId;
  final String? orderName;
  final String? notes;

  const CartState({
    this.items = const [],
    this.totalAmount = 0,
    this.customer,
    this.heldOrderId,
    this.orderName,
    this.notes,
  });

  @override
  List<Object?> get props => [
    items,
    totalAmount,
    customer,
    heldOrderId,
    orderName,
    notes,
  ];

  CartState copyWith({
    List<TransactionItem>? items,
    double? totalAmount,
    Customer? customer,
    bool clearCustomer = false,
    String? heldOrderId,
    bool clearHeldOrder = false,
    String? orderName,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      customer: clearCustomer ? null : (customer ?? this.customer),
      heldOrderId: clearHeldOrder ? null : (heldOrderId ?? this.heldOrderId),
      orderName: clearHeldOrder ? null : (orderName ?? this.orderName),
      notes: clearHeldOrder ? null : (notes ?? this.notes),
    );
  }
}

// BLoC
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<DecreaseQuantity>(_onDecreaseQuantity);
    on<IncrementQuantity>(_onIncrementQuantity);
    on<ClearCart>(_onClearCart);
    on<SetCartCustomer>(_onSetCartCustomer);
    on<LoadHeldOrderIntoCart>(_onLoadHeldOrderIntoCart);
    on<SetCartItems>(_onSetCartItems);
  }

  void _onLoadHeldOrderIntoCart(
    LoadHeldOrderIntoCart event,
    Emitter<CartState> emit,
  ) {
    emit(
      CartState(
        items: List.from(event.order.items),
        totalAmount: _calculateTotal(event.order.items),
        customer: event.order.customer,
        heldOrderId: event.order.id,
        orderName: event.order.orderName,
        notes: event.order.notes,
      ),
    );
  }

  void _onSetCartItems(SetCartItems event, Emitter<CartState> emit) {
    emit(
      CartState(
        items: List.from(event.items),
        totalAmount: _calculateTotal(event.items),
        customer: event.customer,
        heldOrderId: event.heldOrderId,
        orderName: event.orderName,
        notes: event.notes,
      ),
    );
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final qtyToAdd = event.quantity > 0 ? event.quantity : 1;

    // Check stock if product tracks stock
    final int? maxStock;
    if (event.product.trackStock) {
      final availableStock =
          (event.selectedVariant != null && event.selectedVariant!.stock > 0)
          ? event.selectedVariant!.stock
          : event.product.stock;

      maxStock = availableStock;

      final currentCartQty = state.items
          .where((i) {
            if (i.productId != event.product.id) return false;
            if (event.selectedVariant != null &&
                event.selectedVariant!.stock > 0) {
              return i.selectedVariant?.id == event.selectedVariant!.id;
            }
            return true;
          })
          .fold<int>(0, (sum, i) => sum + i.quantity);

      if (currentCartQty + qtyToAdd > availableStock) {
        // Stock limit exceeded, reject addition
        return;
      }
    } else {
      maxStock = null;
    }

    // Check if an identical item exists in the cart:
    // same product, same variant, same modifiers, same notes
    final existingIndex = state.items.indexWhere((i) {
      if (i.productId != event.product.id) return false;
      if (i.selectedVariant?.id != event.selectedVariant?.id) return false;
      if (!_areModifiersEqual(i.selectedModifiers, event.selectedModifiers)) {
        return false;
      }
      if ((i.notes ?? '').trim() != (event.notes ?? '').trim()) return false;
      return true;
    });

    List<TransactionItem> newItems = List.from(state.items);
    final basePrice = event.selectedVariant?.price ?? event.product.price;
    final costPrice =
        event.selectedVariant?.costPrice ?? event.product.costPrice;
    final modifiersCost = event.selectedModifiers.fold(
      0.0,
      (sum, m) => sum + m.price,
    );
    final effectiveUnitPrice = basePrice + modifiersCost;

    if (existingIndex >= 0) {
      final existingItem = newItems[existingIndex];
      final newQty = existingItem.quantity + qtyToAdd;
      newItems[existingIndex] = existingItem.copyWith(
        quantity: newQty,
        subtotal: newQty * existingItem.unitPrice,
        maxStock: maxStock,
      );
    } else {
      newItems.add(
        TransactionItem(
          id: const Uuid().v4(),
          productId: event.product.id,
          productName: event.product.name,
          price: basePrice,
          costPrice: costPrice,
          quantity: qtyToAdd,
          subtotal: qtyToAdd * effectiveUnitPrice,
          businessId: event.product.businessId,
          selectedVariant: event.selectedVariant,
          selectedModifiers: event.selectedModifiers,
          notes: event.notes?.trim().isEmpty == true
              ? null
              : event.notes?.trim(),
          maxStock: maxStock,
        ),
      );
    }

    emit(
      state.copyWith(items: newItems, totalAmount: _calculateTotal(newItems)),
    );
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final newItems = state.items
        .where((i) => i.id != event.itemId && i.productId != event.itemId)
        .toList();
    emit(
      state.copyWith(items: newItems, totalAmount: _calculateTotal(newItems)),
    );
  }

  void _onDecreaseQuantity(DecreaseQuantity event, Emitter<CartState> emit) {
    var index = state.items.indexWhere((i) => i.id == event.itemId);
    if (index < 0) {
      index = state.items.indexWhere((i) => i.productId == event.itemId);
    }
    if (index < 0) return;

    List<TransactionItem> newItems = List.from(state.items);
    final item = newItems[index];

    if (item.quantity > 1) {
      newItems[index] = item.copyWith(
        quantity: item.quantity - 1,
        subtotal: (item.quantity - 1) * item.unitPrice,
      );
    } else {
      newItems.removeAt(index);
    }

    emit(
      state.copyWith(items: newItems, totalAmount: _calculateTotal(newItems)),
    );
  }

  void _onIncrementQuantity(IncrementQuantity event, Emitter<CartState> emit) {
    var index = state.items.indexWhere((i) => i.id == event.itemId);
    if (index < 0) {
      index = state.items.indexWhere((i) => i.productId == event.itemId);
    }
    if (index < 0) return;

    List<TransactionItem> newItems = List.from(state.items);
    final item = newItems[index];

    if (item.maxStock != null) {
      final currentTotalQty = newItems
          .where((i) {
            if (i.productId != item.productId) return false;
            if (item.selectedVariant != null &&
                item.selectedVariant!.stock > 0) {
              return i.selectedVariant?.id == item.selectedVariant!.id;
            }
            return true;
          })
          .fold<int>(0, (sum, i) => sum + i.quantity);

      if (currentTotalQty >= item.maxStock!) {
        // Cannot exceed max stock
        return;
      }
    }

    newItems[index] = item.copyWith(
      quantity: item.quantity + 1,
      subtotal: (item.quantity + 1) * item.unitPrice,
    );

    emit(
      state.copyWith(items: newItems, totalAmount: _calculateTotal(newItems)),
    );
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  void _onSetCartCustomer(SetCartCustomer event, Emitter<CartState> emit) {
    emit(
      state.copyWith(
        customer: event.customer,
        clearCustomer: event.customer == null,
      ),
    );
  }

  double _calculateTotal(List<TransactionItem> items) {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  bool _areModifiersEqual(List<ModifierOption> a, List<ModifierOption> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((m) => m.id).toSet();
    final bIds = b.map((m) => m.id).toSet();
    return aIds.containsAll(bIds);
  }
}
