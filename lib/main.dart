import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:laci/core/themes/theme.dart';
import 'package:laci/firebase_options.dart';
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
import 'presentation/blocs/users/users_bloc.dart';
import 'presentation/blocs/shift/shift_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/printer_service.dart';
import 'core/services/receipt_settings_service.dart';
import 'core/services/held_order_service.dart';
import 'core/services/iap_service.dart';
import 'presentation/pages/auth/auth_wrapper.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return true;
  };

  try {
    try {
      await initializeDateFormatting(
        'id_ID',
        null,
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('initializeDateFormatting warning: $e');
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('Firebase.initializeApp warning: $e');
    }

    try {
      final clientId = Platform.isIOS
          ? DefaultFirebaseOptions.currentPlatform.iosClientId
          : null;
      await GoogleSignIn.instance
          .initialize(
            clientId: clientId,
            serverClientId: DefaultFirebaseOptions.webClientId,
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('GoogleSignIn.initialize warning: $e');
    }

    await initializeDependencies();
    await _initSecondaryServices();
  } catch (e, stack) {
    debugPrint('Fatal main initialization error: $e\n$stack');
  } finally {
    // ALWAYS remove splash screen so the app never hangs on splash
    FlutterNativeSplash.remove();
  }

  runApp(const MyApp());
}

Future<void> _initSecondaryServices() async {
  try {
    await PrinterService().init().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('PrinterService init error: $e');
  }

  try {
    await ReceiptSettingsService().init().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('ReceiptSettingsService init error: $e');
  }

  try {
    await HeldOrderService().init().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('HeldOrderService init error: $e');
  }

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await BackgroundService.init().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('BackgroundService init error: $e');
    }

    try {
      await getIt<NotificationService>().init().timeout(
        const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }

    try {
      await getIt<IapService>().initialize().timeout(
        const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('IapService init error: $e');
    }
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
        BlocProvider(create: (_) => getIt<UsersBloc>()),
        BlocProvider(
          create: (_) => getIt<ShiftBloc>()..add(CheckActiveShift()),
        ),
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
