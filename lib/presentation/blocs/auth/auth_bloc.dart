import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/iap_service.dart';
import '../../../core/services/product_template_service.dart';
import '../../../core/di/injection.dart';
import '../../../data/datasources/local/business_local_datasource.dart';
import '../../../data/datasources/local/local_database.dart';
import '../../../data/models/business_model.dart';

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

class EnterDemoModeRequested extends AuthEvent {}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  SignUpRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}

class SendEmailVerificationRequested extends AuthEvent {}

class CheckEmailVerificationRequested extends AuthEvent {}

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
  final LocalDatabase localDatabase;
  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({
    required this.repository,
    required this.sessionService,
    required this.localDatabase,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<SignInRequested>(_onSignInRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<EnterDemoModeRequested>(_onEnterDemoModeRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    on<SendEmailVerificationRequested>(_onSendEmailVerificationRequested);
    on<CheckEmailVerificationRequested>(_onCheckEmailVerificationRequested);
    on<_AuthStatusChanged>(_onAuthStatusChanged);

    _authStateSubscription = repository.authStateChanges.listen(
      (user) {
        add(_AuthStatusChanged(user));
      },
      onError: (_) {},
    );
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
      if (sessionService.isDemoMode) return;
      sessionService.setUser(null);
      emit(Unauthenticated());
    }
  }

  Future<void> _onEnterDemoModeRequested(
    EnterDemoModeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await localDatabase.clearAllData();
      final now = DateTime.now();

      final demoBusiness = BusinessInfoModel(
        id: SessionService.demoBusinessId,
        businessName: 'Kedai Kopi Demo',
        address: 'Jl. Contoh UMKM No. 10, Jakarta',
        phone: '0812-3456-7890',
        email: 'demo@lacipos.app',
        qrisUrl: '',
        logoUrl: '',
        createdAt: now,
        updatedAt: now,
      );
      await getIt<BusinessLocalDataSource>().upsertBusinessInfo(demoBusiness);

      const demoUser = UserEntity(
        id: SessionService.demoUserId,
        email: 'demo@lacipos.app',
        name: 'Kasir Demo',
        role: UserRole.owner,
        businessId: SessionService.demoBusinessId,
        isEmailVerified: true,
      );
      sessionService.setUser(demoUser);

      try {
        await getIt<ProductTemplateService>().seedTemplate(
          BusinessTemplateType.coffeeShop,
        );
      } catch (_) {}

      emit(Authenticated(demoUser));
    } catch (e) {
      sessionService.setUser(null);
      emit(AuthError('Gagal membuka Mode Demo: $e'));
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
      (user) {
        sessionService.setUser(user);
        if (user.businessId != null) {
          BackgroundService.scheduleDailySummary(user.businessId!);
        }
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.signInWithGoogle();
    result.fold(
      (error) {
        if (error.contains('dibatalkan oleh pengguna')) {
          emit(Unauthenticated());
        } else {
          emit(AuthError(error));
        }
      },
      (user) {
        sessionService.setUser(user);
        if (user.businessId != null) {
          BackgroundService.scheduleDailySummary(user.businessId!);
        }
        emit(Authenticated(user));
      },
    );
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
      (user) {
        sessionService.setUser(user);
        if (user.businessId != null) {
          BackgroundService.scheduleDailySummary(user.businessId!);
        }
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final wasDemo = sessionService.isDemoMode;
    if (!wasDemo) {
      try {
        if (sessionService.businessId != null) {
          await getIt<SyncService>().pushToRemote();
        }
      } catch (_) {}
      try {
        await getIt<IapService>().logout();
      } catch (_) {}
      await repository.signOut();
    }
    // Clear local database on sign out to prevent data leakage
    await localDatabase.clearAllData();
    sessionService.setUser(null);
    emit(Unauthenticated());
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.deleteAccount();
    await result.fold(
      (error) async {
        emit(AuthError(error));
      },
      (_) async {
        await localDatabase.clearAllData();
        sessionService.setUser(null);
        emit(Unauthenticated());
      },
    );
  }

  Future<void> _onSendEmailVerificationRequested(
    SendEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    await repository.sendEmailVerification();
  }

  Future<void> _onCheckEmailVerificationRequested(
    CheckEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await repository.checkEmailVerified();
    result.fold(
      (error) => null,
      (isVerified) {
        if (isVerified && state is Authenticated) {
          final currentUser = (state as Authenticated).user;
          final updatedUser = currentUser.copyWith(isEmailVerified: true);
          sessionService.setUser(updatedUser);
          emit(Authenticated(updatedUser));
        }
      },
    );
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
