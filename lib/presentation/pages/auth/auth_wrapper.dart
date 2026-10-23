import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laci/domain/entities/user_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/report/report_bloc.dart';
import '../../blocs/promo/promo_bloc.dart';
import '../../blocs/users/users_bloc.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/di/injection.dart';
import '../main_page.dart';
import 'login_page.dart';
import 'business_setup_page.dart';
import 'email_verification_page.dart';
import '../../../core/services/onboarding_service.dart';
import '../onboarding/onboarding_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _lastUserId;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final seen = await OnboardingService.hasCompletedOnboarding();
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = seen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          // If email is not verified, require email verification first
          if (!authState.user.isEmailVerified) {
            return EmailVerificationPage(user: authState.user);
          }

          return BlocBuilder<BusinessBloc, BusinessState>(
            builder: (context, businessState) {
              // Check for errors first (only if isSuccess is false)
              if (businessState.message != null &&
                  !businessState.isLoading &&
                  !businessState.isSuccess) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gagal memuat data bisnis:\n${businessState.message}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<BusinessBloc>().add(
                                LoadBusinessInfo(),
                              );
                              getIt<SyncService>().fullSync();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                          TextButton(
                            onPressed: () => context.read<AuthBloc>().add(
                              SignOutRequested(),
                            ),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final currentBusinessId = authState.user.businessId;
              final loadedBusinessId = businessState.businessInfo?.id;
              final currentUserId = authState.user.id;

              // Force reload if business ID doesn't match OR user has changed (account switch)
              final needsReload =
                  loadedBusinessId != currentBusinessId ||
                  _lastUserId != currentUserId;

              if (needsReload && !businessState.isLoading) {
                log(
                  'AuthWrapper: Session change detected! User: $currentUserId, Business: $currentBusinessId. Reloading...',
                );

                // Update tracker
                _lastUserId = currentUserId;

                // 1. Clear cart from previous session
                context.read<CartBloc>().add(ClearCart());

                // 2. Reset blocs to prevent stale data leakage
                context.read<ProductBloc>().add(ResetProducts());
                context.read<CategoryBloc>().add(ResetCategories());
                context.read<CustomerBloc>().add(ResetCustomers());
                context.read<TransactionBloc>().add(ResetTransactions());
                context.read<BusinessBloc>().add(ResetBusinessInfo());

                // 3. Force reload all blocs with new session data
                context.read<BusinessBloc>().add(LoadBusinessInfo());
                context.read<ProductBloc>().add(LoadProducts());
                context.read<CategoryBloc>().add(LoadCategories());
                context.read<CustomerBloc>().add(LoadCustomers());
                context.read<TransactionBloc>().add(LoadTransactions());
                context.read<ReportBloc>().add(LoadDailyReport(DateTime.now()));
                context.read<PromoBloc>().add(LoadPromos());
                context.read<UsersBloc>().add(LoadUsers());

                // Trigger sync for the new session
                getIt<SyncService>().fullSync();

                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Menyiapkan data bisnis...'),
                      ],
                    ),
                  ),
                );
              }

              if (businessState.isLoading &&
                  (businessState.businessInfo == null || needsReload)) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat informasi bisnis...'),
                      ],
                    ),
                  ),
                );
              }

              // Check if onboarding is needed:
              // 1. User is Owner/Admin
              // 2. Business name is still default "Toko Saya"
              final isNewBusiness =
                  businessState.businessInfo?.businessName == 'Toko Saya';
              final isOwner =
                  authState.user.role.isOwner || authState.user.role.isAdmin;

              if (isOwner && isNewBusiness) {
                return const BusinessSetupPage();
              }

              return MainPage(key: MainPage.globalKey);
            },
          );
        } else if (authState is Unauthenticated ||
            authState is AuthError ||
            (authState is AuthLoading && _lastUserId == null)) {
          if (authState is Unauthenticated) {
            _lastUserId = null;
          }
          if (!_hasSeenOnboarding) {
            return OnboardingPage(
              onComplete: () {
                setState(() {
                  _hasSeenOnboarding = true;
                });
              },
            );
          }
          return const LoginPage();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
