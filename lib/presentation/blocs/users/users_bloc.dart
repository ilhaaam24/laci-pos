import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/user_repository.dart';

// Events
abstract class UsersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUsers extends UsersEvent {}

class InviteUser extends UsersEvent {
  final String email;
  final String password;
  final UserRole role;
  InviteUser(this.email, this.password, this.role);
  @override
  List<Object?> get props => [email, password, role];
}

class CreateStaffWithPin extends UsersEvent {
  final String name;
  final UserRole role;
  final String pin;
  final String? email;

  CreateStaffWithPin({
    required this.name,
    required this.role,
    required this.pin,
    this.email,
  });

  @override
  List<Object?> get props => [name, role, pin, email];
}

class UpdateStaffPin extends UsersEvent {
  final String uid;
  final String newPin;

  UpdateStaffPin({required this.uid, required this.newPin});

  @override
  List<Object?> get props => [uid, newPin];
}

class UpdateUserRole extends UsersEvent {
  final String uid;
  final UserRole role;
  UpdateUserRole(this.uid, this.role);
  @override
  List<Object?> get props => [uid, role];
}

// States
class UsersState extends Equatable {
  final List<UserEntity> users;
  final String? message;
  final bool isLoading;
  final bool isSuccess;

  const UsersState({
    this.users = const [],
    this.message,
    this.isLoading = false,
    this.isSuccess = false,
  });

  UsersState copyWith({
    List<UserEntity>? users,
    String? message,
    bool? isLoading,
    bool? isSuccess,
  }) {
    return UsersState(
      users: users ?? this.users,
      message: message,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [users, message, isLoading, isSuccess];
}

// BLoC
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UserRepository repository;

  UsersBloc({required this.repository}) : super(const UsersState()) {
    on<LoadUsers>(_onLoadUsers);
    on<UpdateUserRole>(_onUpdateUserRole);
    on<InviteUser>(_onInviteUser);
    on<CreateStaffWithPin>(_onCreateStaffWithPin);
    on<UpdateStaffPin>(_onUpdateStaffPin);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.getUsers();
    result.fold(
      (error) => emit(state.copyWith(message: error, isLoading: false)),
      (users) {
        try {
          getIt<StaffAuthService>().cacheStaffList(users);
        } catch (_) {}
        emit(state.copyWith(users: users, isLoading: false, isSuccess: true));
      },
    );
  }

  Future<void> _onUpdateUserRole(
    UpdateUserRole event,
    Emitter<UsersState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.updateUserRole(event.uid, event.role);
    result.fold(
      (error) => emit(state.copyWith(message: error, isLoading: false)),
      (_) {
        add(LoadUsers()); // Refresh list
      },
    );
  }

  Future<void> _onInviteUser(InviteUser event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.addUser(
      event.email,
      event.password,
      event.role,
    );
    result.fold(
      (error) => emit(state.copyWith(message: error, isLoading: false)),
      (_) {
        emit(
          state.copyWith(
            isLoading: false,
            isSuccess: true,
            message: 'Berhasil mengundang user',
          ),
        );
        add(LoadUsers()); // Refresh list
      },
    );
  }

  Future<void> _onCreateStaffWithPin(
    CreateStaffWithPin event,
    Emitter<UsersState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.addStaffWithPin(
      name: event.name,
      role: event.role,
      pin: event.pin,
      email: event.email,
    );
    result.fold(
      (error) => emit(state.copyWith(message: error, isLoading: false)),
      (_) {
        emit(
          state.copyWith(
            isLoading: false,
            isSuccess: true,
            message: 'Staf baru "${event.name}" dengan PIN berhasil ditambahkan!',
          ),
        );
        add(LoadUsers()); // Refresh list and cache
      },
    );
  }

  Future<void> _onUpdateStaffPin(
    UpdateStaffPin event,
    Emitter<UsersState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.updateStaffPin(event.uid, event.newPin);
    result.fold(
      (error) => emit(state.copyWith(message: error, isLoading: false)),
      (_) {
        emit(
          state.copyWith(
            isLoading: false,
            isSuccess: true,
            message: 'PIN staf berhasil diperbarui!',
          ),
        );
        add(LoadUsers()); // Refresh list and cache
      },
    );
  }
}
