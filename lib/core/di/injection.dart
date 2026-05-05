import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:laci/core/services/cloudinary_service.dart';
import 'package:laci/core/services/connectivity_service.dart';
import 'package:laci/core/services/sync_service.dart';
import 'package:laci/data/datasources/firebase/stock_log_firebase_datasource.dart';
import 'package:laci/data/datasources/local/business_local_datasource.dart';
import 'package:laci/data/datasources/local/category_local_datasource.dart';
import 'package:laci/data/datasources/local/customer_local_datasource.dart';
import 'package:laci/data/datasources/local/local_database.dart';
import 'package:laci/data/datasources/local/product_local_datasource.dart';
import 'package:laci/data/datasources/local/promo_local_datasource.dart';
import 'package:laci/data/datasources/local/stock_log_local_datasource.dart';
import 'package:laci/data/datasources/local/transaction_local_datasource.dart';

// Data Sources
import '../../data/datasources/firebase/product_firebase_datasource.dart';
import '../../data/datasources/firebase/category_firebase_datasource.dart';
import '../../data/datasources/firebase/customer_firebase_datasource.dart';
import '../../data/datasources/firebase/transaction_firebase_datasource.dart';
import '../../data/datasources/firebase/business_firebase_datasource.dart';
import '../../data/datasources/firebase/auth_firebase_datasource.dart';
import '../../data/datasources/firebase/promo_firebase_datasource.dart';
import '../../data/datasources/firebase/user_firebase_datasource.dart';

// Repositories
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/promo_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';

import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/business_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/promo_repository.dart';
import '../../domain/repositories/user_repository.dart';

// BLoCs
import '../../presentation/blocs/product/product_bloc.dart';
import '../../presentation/blocs/category/category_bloc.dart';
import '../../presentation/blocs/customer/customer_bloc.dart';
import '../../presentation/blocs/transaction/transaction_bloc.dart';
import '../../presentation/blocs/business/business_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/report/report_bloc.dart';
import '../../presentation/blocs/promo/promo_bloc.dart';
import '../../presentation/blocs/users/users_bloc.dart';

// Services
import '../services/image_upload_service.dart';
import '../services/report_service.dart';
import '../services/receipt_service.dart';
import '../services/transaction_service.dart';
import '../services/stock_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Firebase
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // Database
  final localDb = LocalDatabase();
  getIt.registerLazySingleton<LocalDatabase>(() => localDb);

  // Services
  getIt.registerLazySingleton<SessionService>(() => SessionService());
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  
  getIt.registerLazySingleton<ImageUploadService>(
    () => ImageUploadService(getIt()),
  );

  getIt.registerLazySingleton<CloudinaryService>(() => CloudinaryService());

  getIt.registerLazySingleton<ReportService>(() => ReportService(getIt()));

  getIt.registerLazySingleton<ReceiptService>(() => ReceiptService());

  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  // Local Data Sources
  getIt.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<PromoLocalDataSource>(
    () => PromoLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<BusinessLocalDataSource>(
    () => BusinessLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<StockLogLocalDataSource>(
    () => StockLogLocalDataSource(getIt()),
  );

  // Firebase Data Sources
  getIt.registerLazySingleton<ProductFirebaseDataSource>(
    () => ProductFirebaseDataSourceImpl(
      firestore: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<CategoryFirebaseDataSource>(
    () => CategoryFirebaseDataSourceImpl(
      firestore: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<CustomerFirebaseDataSource>(
    () => CustomerFirebaseDataSourceImpl(
      firestore: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<TransactionFirebaseDataSource>(
    () => TransactionFirebaseDataSourceImpl(
      firestore: getIt(),
      notificationService: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<BusinessFirebaseDataSource>(
    () => BusinessFirebaseDataSourceImpl(
      firestore: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<AuthFirebaseDataSource>(
    () => AuthFirebaseDataSourceImpl(),
  );

  getIt.registerLazySingleton<PromoFirebaseDataSource>(
    () => PromoFirebaseDataSourceImpl(
      firestore: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<UserFirebaseDataSource>(
    () =>
        UserFirebaseDataSourceImpl(firestore: getIt(), sessionService: getIt()),
  );

  getIt.registerLazySingleton<StockLogFirebaseDataSource>(
    () => StockLogFirebaseDataSourceImpl(
      firestore: getIt(),
      sessionService: getIt(),
    ),
  );

  // Advanced Services
  getIt.registerLazySingleton<TransactionService>(
    () => TransactionService(
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
    ),
  );

  getIt.registerLazySingleton<StockService>(
    () => StockService(
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
    ),
  );

  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      localDatabase: getIt(),
      productLocal: getIt(),
      categoryLocal: getIt(),
      customerLocal: getIt(),
      transactionLocal: getIt(),
      promoLocal: getIt(),
      stockLogLocal: getIt(),
      businessLocal: getIt(),
      productRemote: getIt(),
      categoryRemote: getIt(),
      customerRemote: getIt(),
      transactionRemote: getIt(),
      promoRemote: getIt(),
      stockLogRemote: getIt(),
      businessRemote: getIt(),
      connectivityService: getIt(),
      sessionService: getIt(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      localDatabase: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      localDatabase: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      localDatabase: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<BusinessRepository>(
    () => BusinessRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      localDatabase: getIt(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: getIt(), userDataSource: getIt()),
  );

  getIt.registerLazySingleton<PromoRepository>(
    () => PromoRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      localDatabase: getIt(),
      sessionService: getIt(),
    ),
  );

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(dataSource: getIt(), sessionService: getIt()),
  );

  // BLoCs
  getIt.registerFactory(() => ProductBloc(repository: getIt()));

  getIt.registerFactory(() => CategoryBloc(repository: getIt()));

  getIt.registerFactory(() => CustomerBloc(repository: getIt()));

  getIt.registerFactory(() => TransactionBloc(repository: getIt()));

  getIt.registerFactory(() => BusinessBloc(repository: getIt()));

  getIt.registerFactory(
    () => AuthBloc(repository: getIt(), sessionService: getIt()),
  );

  getIt.registerFactory(
    () => ReportBloc(reportService: getIt(), sessionService: getIt()),
  );

  getIt.registerFactory(() => PromoBloc(repository: getIt()));

  getIt.registerFactory(() => UsersBloc(repository: getIt()));
}
