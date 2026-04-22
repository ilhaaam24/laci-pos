import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../domain/repositories/business_repository.dart';

// Events
abstract class BusinessEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadBusinessInfo extends BusinessEvent {}

class UpdateBusinessInfo extends BusinessEvent {
  final BusinessInfo businessInfo;
  UpdateBusinessInfo(this.businessInfo);
  @override
  List<Object?> get props => [businessInfo];
}

// States
class BusinessState extends Equatable {
  final BusinessInfo? businessInfo;
  final String? message;
  final bool isLoading;
  final bool isSuccess;

  const BusinessState({
    this.businessInfo,
    this.message,
    this.isLoading = false,
    this.isSuccess = false,
  });

  BusinessState copyWith({
    BusinessInfo? businessInfo,
    String? message,
    bool? isLoading,
    bool? isSuccess,
  }) {
    return BusinessState(
      businessInfo: businessInfo ?? this.businessInfo,
      message: message,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [businessInfo, message, isLoading, isSuccess];
}

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessRepository repository;

  BusinessBloc({required this.repository}) : super(const BusinessState()) {
    on<LoadBusinessInfo>(_onLoadBusinessInfo);
    on<UpdateBusinessInfo>(_onUpdateBusinessInfo);
  }

  Future<void> _onLoadBusinessInfo(
    LoadBusinessInfo event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.getBusinessInfo();
    result.fold(
      (error) => emit(
        state.copyWith(isLoading: false, message: error, isSuccess: false),
      ),
      (info) => emit(
        state.copyWith(isLoading: false, businessInfo: info, isSuccess: true),
      ),
    );
  }

  Future<void> _onUpdateBusinessInfo(
    UpdateBusinessInfo event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.updateBusinessInfo(event.businessInfo);
    result.fold(
      (error) => emit(
        state.copyWith(isLoading: false, message: error, isSuccess: false),
      ),
      (_) => emit(
        state.copyWith(
          isLoading: false,
          businessInfo: event.businessInfo,
          message: 'Info bisnis berhasil diperbarui',
          isSuccess: true,
        ),
      ),
    );
  }
}
