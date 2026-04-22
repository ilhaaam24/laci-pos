import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/repositories/category_repository.dart';

// Events
abstract class CategoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {}

class CreateCategory extends CategoryEvent {
  final Category category;
  CreateCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class UpdateCategory extends CategoryEvent {
  final Category category;
  UpdateCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class DeleteCategory extends CategoryEvent {
  final String id;
  DeleteCategory(this.id);
  @override
  List<Object?> get props => [id];
}

// States
class CategoryState extends Equatable {
  final List<Category> categories;
  final String? message;
  final bool isLoading;
  final bool isSuccess;

  const CategoryState({
    this.categories = const [],
    this.message,
    this.isLoading = false,
    this.isSuccess = false,
  });

  CategoryState copyWith({
    List<Category>? categories,
    String? message,
    bool? isLoading,
    bool? isSuccess,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      message: message,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [categories, message, isLoading, isSuccess];
}

class CategoryActionSuccess extends CategoryState {
  const CategoryActionSuccess(String message, List<Category> categories)
    : super(message: message, categories: categories, isSuccess: true);
}

class CategoryError extends CategoryState {
  const CategoryError(String message, List<Category> categories)
    : super(message: message, categories: categories, isLoading: false);
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;

  CategoryBloc({required this.repository}) : super(const CategoryState()) {
    on<LoadCategories>(_onLoadCategories);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach(
      repository.getCategories(),
      onData: (result) {
        return result.fold(
          (error) => CategoryError(error, state.categories),
          (categories) => CategoryState(
            categories: categories,
            isLoading: false,
            isSuccess: true,
          ),
        );
      },
    );
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final result = await repository.createCategory(event.category);
    result.fold(
      (error) => emit(CategoryError(error, state.categories)),
      (_) => emit(
        CategoryActionSuccess(
          'Kategori berhasil ditambahkan',
          state.categories,
        ),
      ),
    );
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final result = await repository.updateCategory(event.category);
    result.fold(
      (error) => emit(CategoryError(error, state.categories)),
      (_) => emit(
        CategoryActionSuccess('Kategori berhasil diperbarui', state.categories),
      ),
    );
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final result = await repository.deleteCategory(event.id);
    result.fold(
      (error) => emit(CategoryError(error, state.categories)),
      (_) => emit(
        CategoryActionSuccess('Kategori berhasil dihapus', state.categories),
      ),
    );
  }
}
