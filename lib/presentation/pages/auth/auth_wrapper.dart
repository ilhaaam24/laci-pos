import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laci/domain/entities/user_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/report/report_bloc.dart';
import '../../blocs/promo/promo_bloc.dart';
import '../../blocs/users/users_bloc.dart';
import '../main_page.dart';
import 'login_page.dart';
import 'business_setup_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          return BlocBuilder<BusinessBloc, BusinessState>(
            builder: (context, businessState) {
              final currentBusinessId = authState.user.businessId;
              final loadedBusinessId = businessState.businessInfo?.id;

              // Force reload if business ID doesn't match current user (prevents "nyangkut" data)
              final needsReload = loadedBusinessId != currentBusinessId;

              if (needsReload && !businessState.isLoading) {
                // Force reload all blocs to prevent data leakage between businesses
                context.read<BusinessBloc>().add(LoadBusinessInfo());
                context.read<ProductBloc>().add(LoadProducts());
                context.read<CategoryBloc>().add(LoadCategories());
                context.read<CustomerBloc>().add(LoadCustomers());
                context.read<ReportBloc>().add(LoadDailyReport(DateTime.now()));
                context.read<PromoBloc>().add(LoadPromos());
                context.read<UsersBloc>().add(LoadUsers());

                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (businessState.isLoading &&
                  (businessState.businessInfo == null || needsReload)) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
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

              return const MainPage();
            },
          );
        } else if (authState is Unauthenticated || authState is AuthError) {
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
