import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/product_entity.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;
  AddToCart(this.product);
  @override
  List<Object?> get props => [product];
}

class RemoveFromCart extends CartEvent {
  final String productId;
  RemoveFromCart(this.productId);
  @override
  List<Object?> get props => [productId];
}

class DecreaseQuantity extends CartEvent {
  final String productId;
  DecreaseQuantity(this.productId);
  @override
  List<Object?> get props => [productId];
}

class IncrementQuantity extends CartEvent {
  final String productId;
  IncrementQuantity(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ClearCart extends CartEvent {}

// State
class CartState extends Equatable {
  final List<TransactionItem> items;
  final double totalAmount;

  const CartState({this.items = const [], this.totalAmount = 0});

  @override
  List<Object?> get props => [items, totalAmount];

  CartState copyWith({List<TransactionItem>? items, double? totalAmount}) {
    return CartState(
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
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
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final existingIndex = state.items.indexWhere(
      (i) => i.productId == event.product.id,
    );
    List<TransactionItem> newItems = List.from(state.items);

    if (existingIndex >= 0) {
      final existingItem = newItems[existingIndex];
      newItems[existingIndex] = TransactionItem(
        id: existingItem.id,
        productId: existingItem.productId,
        productName: existingItem.productName,
        price: existingItem.price,
        costPrice: existingItem.costPrice,
        quantity: existingItem.quantity + 1,
        subtotal: (existingItem.quantity + 1) * existingItem.price,
      );
    } else {
      newItems.add(
        TransactionItem(
          id: const Uuid().v4(),
          productId: event.product.id,
          productName: event.product.name,
          price: event.product.price,
          costPrice: event.product.costPrice,
          quantity: 1,
          subtotal: event.product.price,
        ),
      );
    }

    emit(
      state.copyWith(items: newItems, totalAmount: _calculateTotal(newItems)),
    );
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final newItems = state.items
        .where((i) => i.productId != event.productId)
        .toList();
    emit(
      state.copyWith(items: newItems, totalAmount: _calculateTotal(newItems)),
    );
  }

  void _onDecreaseQuantity(DecreaseQuantity event, Emitter<CartState> emit) {
    final index = state.items.indexWhere((i) => i.productId == event.productId);
    if (index < 0) return;

    List<TransactionItem> newItems = List.from(state.items);
    final item = newItems[index];

    if (item.quantity > 1) {
      newItems[index] = TransactionItem(
        id: item.id,
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        costPrice: item.costPrice,
        quantity: item.quantity - 1,
        subtotal: (item.quantity - 1) * item.price,
      );
    } else {
      newItems.removeAt(index);
    }

    emit(
      state.copyWith(items: newItems, totalAmount: _calculateTotal(newItems)),
    );
  }

  void _onIncrementQuantity(IncrementQuantity event, Emitter<CartState> emit) {
    final index = state.items.indexWhere((i) => i.productId == event.productId);
    if (index < 0) return;

    List<TransactionItem> newItems = List.from(state.items);
    final item = newItems[index];

    newItems[index] = TransactionItem(
      id: item.id,
      productId: item.productId,
      productName: item.productName,
      price: item.price,
      costPrice: item.costPrice,
      quantity: item.quantity + 1,
      subtotal: (item.quantity + 1) * item.price,
    );

    emit(
      state.copyWith(items: newItems, totalAmount: _calculateTotal(newItems)),
    );
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  double _calculateTotal(List<TransactionItem> items) {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }
}
