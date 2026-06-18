import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:laci/core/services/connectivity_service.dart';
import 'package:laci/core/themes/theme.dart';
import 'package:laci/core/services/notification_service.dart';
import 'package:laci/core/services/background_service.dart';
import 'package:laci/presentation/blocs/users/users_bloc.dart';

import 'core/di/injection.dart';

import 'presentation/blocs/product/product_bloc.dart';
import 'presentation/blocs/category/category_bloc.dart';
import 'presentation/blocs/customer/customer_bloc.dart';
import 'presentation/blocs/transaction/transaction_bloc.dart';
import 'presentation/blocs/business/business_bloc.dart';
import 'presentation/blocs/cart/cart_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/report/report_bloc.dart';
import 'presentation/blocs/promo/promo_bloc.dart';

import 'presentation/pages/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize Google Sign In
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '747380789752-gpu0fjfv3k45a5o1aktjqs4b244j3mm4.apps.googleusercontent.com',
    );

    // Initialize Dependencies
    await initializeDependencies();

    // Initialize Connectivity Service
    await getIt<ConnectivityService>().init();

    // Initialize Notification Service
    try {
      await getIt<NotificationService>().init();
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }

    // Initialize Background Service (Workmanager)
    await BackgroundService.init();

    runApp(const MyApp());
  } catch (error, stackTrace) {
    debugPrint('Fatal Startup Error: $error\n$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal Memulai Aplikasi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ProductBloc>()..add(LoadProducts())),
        BlocProvider(
          create: (_) => getIt<CategoryBloc>()..add(LoadCategories()),
        ),
        BlocProvider(
          create: (_) => getIt<CustomerBloc>()..add(LoadCustomers()),
        ),
        BlocProvider(create: (_) => getIt<TransactionBloc>()),
        BlocProvider(
          create: (_) => getIt<BusinessBloc>()..add(LoadBusinessInfo()),
        ),
        BlocProvider(create: (_) => CartBloc()),
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(AppStarted())),
        BlocProvider(
          create: (_) =>
              getIt<ReportBloc>()..add(LoadDailyReport(DateTime.now())),
        ),
        BlocProvider(create: (_) => getIt<PromoBloc>()..add(LoadPromos())),
        BlocProvider(create: (_) => getIt<UsersBloc>()..add(LoadUsers())),
      ],
      child: MaterialApp(
        title: 'Laci POS',
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        theme: AppThemeLegacy.lightTheme,
        darkTheme: AppThemeLegacy.darkTheme,
        themeMode: ThemeMode.system,
      ),
    );
  }
}
