import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/promo_entity.dart';
import '../../../domain/repositories/promo_repository.dart';

// Events
abstract class PromoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPromos extends PromoEvent {}

class CreatePromo extends PromoEvent {
  final PromoEntity promo;
  CreatePromo(this.promo);
  @override
  List<Object?> get props => [promo];
}

class UpdatePromo extends PromoEvent {
  final PromoEntity promo;
  UpdatePromo(this.promo);
  @override
  List<Object?> get props => [promo];
}

class DeletePromo extends PromoEvent {
  final String id;
  DeletePromo(this.id);
  @override
  List<Object?> get props => [id];
}

// States
class PromoState extends Equatable {
  final List<PromoEntity> promos;
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? message;

  const PromoState({
    this.promos = const [],
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.message,
  });

  PromoState copyWith({
    List<PromoEntity>? promos,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? message,
  }) {
    return PromoState(
      promos: promos ?? this.promos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? false,
      message: message,
    );
  }

  @override
  List<Object?> get props => [promos, isLoading, error, isSuccess, message];
}

// BLoC
class PromoBloc extends Bloc<PromoEvent, PromoState> {
  final PromoRepository repository;
  StreamSubscription? _subscription;

  PromoBloc({required this.repository}) : super(const PromoState()) {
    on<LoadPromos>(_onLoadPromos);
    on<CreatePromo>(_onCreatePromo);
    on<UpdatePromo>(_onUpdatePromo);
    on<DeletePromo>(_onDeletePromo);
    on<_InternalUpdatePromos>((event, emit) {
      emit(state.copyWith(
        promos: event.promos,
        error: event.error,
        isLoading: false,
      ));
    });
  }

  Future<void> _onLoadPromos(LoadPromos event, Emitter<PromoState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _subscription?.cancel();
    _subscription = repository.getPromos().listen((result) {
      result.fold(
        (l) => add(_InternalUpdatePromos(error: l)),
        (r) => add(_InternalUpdatePromos(promos: r)),
      );
    });
  }

  Future<void> _onCreatePromo(CreatePromo event, Emitter<PromoState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.createPromo(event.promo);
    result.fold(
      (l) => emit(state.copyWith(isLoading: false, error: l)),
      (r) => emit(state.copyWith(isLoading: false, isSuccess: true, message: 'Promo berhasil ditambahkan')),
    );
  }

  Future<void> _onUpdatePromo(UpdatePromo event, Emitter<PromoState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.updatePromo(event.promo);
    result.fold(
      (l) => emit(state.copyWith(isLoading: false, error: l)),
      (r) => emit(state.copyWith(isLoading: false, isSuccess: true, message: 'Promo berhasil diperbarui')),
    );
  }

  Future<void> _onDeletePromo(DeletePromo event, Emitter<PromoState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.deletePromo(event.id);
    result.fold(
      (l) => emit(state.copyWith(isLoading: false, error: l)),
      (r) => emit(state.copyWith(isLoading: false, isSuccess: true, message: 'Promo berhasil dihapus')),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class _InternalUpdatePromos extends PromoEvent {
  final List<PromoEntity> promos;
  final String? error;
  _InternalUpdatePromos({this.promos = const [], this.error});
  @override
  List<Object?> get props => [promos, error];
}
