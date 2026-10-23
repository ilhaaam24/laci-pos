import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/product_repository.dart';

// Events
abstract class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {}

class ResetProducts extends ProductEvent {}

class _ProductsUpdated extends ProductEvent {
  final Either<String, List<Product>> result;
  _ProductsUpdated(this.result);
  @override
  List<Object?> get props => [result];
}

class LoadProductsByCategory extends ProductEvent {
  final String categoryId;
  LoadProductsByCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class CreateProduct extends ProductEvent {
  final Product product;
  CreateProduct(this.product);
  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends ProductEvent {
  final Product product;
  UpdateProduct(this.product);
  @override
  List<Object?> get props => [product];
}

class DeleteProduct extends ProductEvent {
  final String id;
  DeleteProduct(this.id);
  @override
  List<Object?> get props => [id];
}

// States
class ProductState extends Equatable {
  final List<Product> products;
  final String? message;
  final bool isLoading;
  final bool isSuccess;

  const ProductState({
    this.products = const [],
    this.message,
    this.isLoading = false,
    this.isSuccess = false,
  });

  ProductState copyWith({
    List<Product>? products,
    String? message,
    bool? isLoading,
    bool? isSuccess,
  }) {
    return ProductState(
      products: products ?? this.products,
      message: message,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [products, message, isLoading, isSuccess];
}

class ProductActionSuccess extends ProductState {
  const ProductActionSuccess(String message, List<Product> products)
    : super(message: message, products: products, isSuccess: true);
}

class ProductError extends ProductState {
  const ProductError(String message, List<Product> products)
    : super(message: message, products: products, isLoading: false);
}

// BLoC
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;
  StreamSubscription<Either<String, List<Product>>>? _productsSubscription;

  ProductBloc({required this.repository}) : super(const ProductState()) {
    on<LoadProducts>(_onLoadProducts);
    on<_ProductsUpdated>(_onProductsUpdated);
    on<ResetProducts>(_onResetProducts);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _productsSubscription?.cancel();
    _productsSubscription = repository.getProducts().listen((result) {
      add(_ProductsUpdated(result));
    });
  }

  void _onProductsUpdated(
    _ProductsUpdated event,
    Emitter<ProductState> emit,
  ) {
    event.result.fold(
      (error) => emit(ProductError(error, state.products)),
      (products) => emit(
        ProductState(
          products: products,
          isLoading: false,
          isSuccess: true,
        ),
      ),
    );
  }

  Future<void> _onResetProducts(
    ResetProducts event,
    Emitter<ProductState> emit,
  ) async {
    await _productsSubscription?.cancel();
    _productsSubscription = null;
    emit(const ProductState());
  }

  Future<void> _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _productsSubscription?.cancel();
    _productsSubscription = repository.getProductsByCategory(event.categoryId).listen((result) {
      add(_ProductsUpdated(result));
    });
  }

  Future<void> _onCreateProduct(
    CreateProduct event,
    Emitter<ProductState> emit,
  ) async {
    final result = await repository.createProduct(event.product);
    result.fold(
      (error) => emit(ProductError(error, state.products)),
      (_) => emit(
        ProductActionSuccess('Produk berhasil ditambahkan', state.products),
      ),
    );
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductState> emit,
  ) async {
    final result = await repository.updateProduct(event.product);
    result.fold(
      (error) => emit(ProductError(error, state.products)),
      (_) => emit(
        ProductActionSuccess('Produk berhasil diperbarui', state.products),
      ),
    );
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    final result = await repository.deleteProduct(event.id);
    result.fold(
      (error) => emit(ProductError(error, state.products)),
      (_) =>
          emit(ProductActionSuccess('Produk berhasil dihapus', state.products)),
    );
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}
