import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/background_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  SignInRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class GoogleSignInRequested extends AuthEvent {}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  SignUpRequested({
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final SessionService sessionService;
  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({
    required this.repository,
    required this.sessionService,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<SignInRequested>(_onSignInRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<_AuthStatusChanged>(_onAuthStatusChanged);

    _authStateSubscription = repository.authStateChanges.listen((user) {
      add(_AuthStatusChanged(user));
    });
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final result = await repository.getCurrentUser();
    result.fold((error) => emit(Unauthenticated()), (user) {
      if (user != null) {
        sessionService.setUser(user);
        if (user.businessId != null) {
          BackgroundService.scheduleDailySummary(user.businessId!);
        }
        emit(Authenticated(user));
      } else {
        sessionService.setUser(null);
        emit(Unauthenticated());
      }
    });
  }

  void _onAuthStatusChanged(_AuthStatusChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      sessionService.setUser(event.user);
      if (event.user!.businessId != null) {
        BackgroundService.scheduleDailySummary(event.user!.businessId!);
      }
      emit(Authenticated(event.user!));
    } else {
      sessionService.setUser(null);
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.signInWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (error) => emit(AuthError(error)),
      (_) {}, // Status will be updated by stream
    );
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.signInWithGoogle();
    result.fold((error) => emit(AuthError(error)), (user) {
      emit(Authenticated(user));
    });
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.signUpWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (error) => emit(AuthError(error)),
      (_) {}, // Status will be updated by stream
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await repository.signOut();
    // Status will be updated by stream
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

class _AuthStatusChanged extends AuthEvent {
  final UserEntity? user;
  _AuthStatusChanged(this.user);
  @override
  List<Object?> get props => [user];
}
