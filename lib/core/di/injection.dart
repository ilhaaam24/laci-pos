import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Data Sources
import '../../data/datasources/firebase/product_firebase_datasource.dart';
import '../../data/datasources/firebase/category_firebase_datasource.dart';
import '../../data/datasources/firebase/customer_firebase_datasource.dart';
import '../../data/datasources/firebase/transaction_firebase_datasource.dart';
import '../../data/datasources/firebase/business_firebase_datasource.dart';
import '../../data/datasources/firebase/auth_firebase_datasource.dart';

// Repositories
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';

import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/business_repository.dart';
import '../../domain/repositories/auth_repository.dart';

// BLoCs
import '../../presentation/blocs/product/product_bloc.dart';
import '../../presentation/blocs/category/category_bloc.dart';
import '../../presentation/blocs/customer/customer_bloc.dart';
import '../../presentation/blocs/transaction/transaction_bloc.dart';
import '../../presentation/blocs/business/business_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';

// Services
import '../services/image_upload_service.dart';
import '../services/report_service.dart';
import '../services/receipt_service.dart';
import '../services/transaction_service.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Firebase
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // Services
  getIt.registerLazySingleton<ImageUploadService>(
    () => ImageUploadService(getIt()),
  );

  getIt.registerLazySingleton<ReportService>(() => ReportService(getIt()));

  getIt.registerLazySingleton<ReceiptService>(() => ReceiptService());

  getIt.registerLazySingleton<TransactionService>(
    () => TransactionService(getIt()),
  );

  // Data Sources
  getIt.registerLazySingleton<ProductFirebaseDataSource>(
    () => ProductFirebaseDataSourceImpl(firestore: getIt()),
  );

  getIt.registerLazySingleton<CategoryFirebaseDataSource>(
    () => CategoryFirebaseDataSourceImpl(firestore: getIt()),
  );

  getIt.registerLazySingleton<CustomerFirebaseDataSource>(
    () => CustomerFirebaseDataSourceImpl(firestore: getIt()),
  );

  getIt.registerLazySingleton<TransactionFirebaseDataSource>(
    () => TransactionFirebaseDataSourceImpl(firestore: getIt()),
  );

  getIt.registerLazySingleton<BusinessFirebaseDataSource>(
    () => BusinessFirebaseDataSourceImpl(firestore: getIt()),
  );

  getIt.registerLazySingleton<AuthFirebaseDataSource>(
    () => AuthFirebaseDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(dataSource: getIt()),
  );

  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(dataSource: getIt()),
  );

  getIt.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(dataSource: getIt()),
  );

  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(dataSource: getIt()),
  );

  getIt.registerLazySingleton<BusinessRepository>(
    () => BusinessRepositoryImpl(dataSource: getIt()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: getIt()),
  );

  // BLoCs
  getIt.registerFactory(() => ProductBloc(repository: getIt()));

  getIt.registerFactory(() => CategoryBloc(repository: getIt()));

  getIt.registerFactory(() => CustomerBloc(repository: getIt()));

  getIt.registerFactory(() => TransactionBloc(repository: getIt()));

  getIt.registerFactory(() => BusinessBloc(repository: getIt()));

  getIt.registerFactory(() => AuthBloc(repository: getIt()));
}
