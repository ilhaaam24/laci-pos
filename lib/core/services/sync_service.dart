import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:laci/core/constants/sync_status.dart';
import 'package:laci/core/services/connectivity_service.dart';
import 'package:laci/core/services/session_service.dart';
import 'package:laci/data/datasources/firebase/business_firebase_datasource.dart';
import 'package:laci/data/datasources/firebase/category_firebase_datasource.dart';
import 'package:laci/data/datasources/firebase/customer_firebase_datasource.dart';
import 'package:laci/data/datasources/firebase/product_firebase_datasource.dart';
import 'package:laci/data/datasources/firebase/promo_firebase_datasource.dart';
import 'package:laci/data/datasources/firebase/stock_log_firebase_datasource.dart';
import 'package:laci/data/datasources/firebase/transaction_firebase_datasource.dart';
import 'package:laci/data/datasources/local/business_local_datasource.dart';
import 'package:laci/data/datasources/local/category_local_datasource.dart';
import 'package:laci/data/datasources/local/customer_local_datasource.dart';
import 'package:laci/data/datasources/local/local_database.dart';
import 'package:laci/data/datasources/local/product_local_datasource.dart';
import 'package:laci/data/datasources/local/promo_local_datasource.dart';
import 'package:laci/data/datasources/local/stock_log_local_datasource.dart';
import 'package:laci/data/datasources/local/transaction_local_datasource.dart';
import 'package:laci/data/models/business_model.dart';
import 'package:laci/data/models/category_model.dart';
import 'package:laci/data/models/customer_model.dart';
import 'package:laci/data/models/product_model.dart';
import 'package:laci/data/models/promo_model.dart';
import 'package:laci/data/models/stock_log_model.dart';
import 'package:laci/data/models/transaction_model.dart';

class SyncService {
  final LocalDatabase localDatabase;
  final ProductLocalDataSource productLocal;
  final CategoryLocalDataSource categoryLocal;
  final CustomerLocalDataSource customerLocal;
  final TransactionLocalDataSource transactionLocal;
  final PromoLocalDataSource promoLocal;
  final StockLogLocalDataSource stockLogLocal;
  final BusinessLocalDataSource businessLocal;

  final ProductFirebaseDataSource productRemote;
  final CategoryFirebaseDataSource categoryRemote;
  final CustomerFirebaseDataSource customerRemote;
  final TransactionFirebaseDataSource transactionRemote;
  final PromoFirebaseDataSource promoRemote;
  final StockLogFirebaseDataSource stockLogRemote;
  final BusinessFirebaseDataSource businessRemote;

  final ConnectivityService connectivityService;
  final SessionService sessionService;

  final StreamController<AppSyncState> _syncStateController =
      StreamController<AppSyncState>.broadcast();

  Stream<AppSyncState> get syncState => _syncStateController.stream;

  AppSyncState _currentState = AppSyncState.idle;
  AppSyncState get currentState => _currentState;

  DateTime? _lastSyncAttempt;

  SyncService({
    required this.localDatabase,
    required this.productLocal,
    required this.categoryLocal,
    required this.customerLocal,
    required this.transactionLocal,
    required this.promoLocal,
    required this.stockLogLocal,
    required this.businessLocal,
    required this.productRemote,
    required this.categoryRemote,
    required this.customerRemote,
    required this.transactionRemote,
    required this.promoRemote,
    required this.stockLogRemote,
    required this.businessRemote,
    required this.connectivityService,
    required this.sessionService,
  }) {
    // Automatically trigger sync when connection is restored
    connectivityService.onlineStream.listen((isOnline) {
      log('SyncService: Connectivity changed to $isOnline');
      if (isOnline) {
        log('Connection restored, triggering sync...');
        fullSync();
      } else {
        _updateState(AppSyncState.offline);
      }
    });
  }

  void _updateState(AppSyncState state) {
    _currentState = state;
    _syncStateController.add(state);
  }

  /// Full bi-directional sync
  Future<void> fullSync() async {
    if (!connectivityService.isOnline) {
      _updateState(AppSyncState.offline);
      return;
    }

    if (_currentState == AppSyncState.syncing) return;

    // Prevent spamming sync if it failed recently
    if (_currentState == AppSyncState.error && _lastSyncAttempt != null) {
      final cooldown = DateTime.now().difference(_lastSyncAttempt!);
      if (cooldown < const Duration(seconds: 10)) {
        log('Sync cooldown in effect (${cooldown.inSeconds}s), skipping...');
        return;
      }
    }

    if (sessionService.businessId == null) {
      log('SyncService: No businessId found, skipping sync.');
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      log('SyncService: User not authenticated in Firebase, skipping sync.');
      return;
    }

    _lastSyncAttempt = DateTime.now();
    _updateState(AppSyncState.syncing);
    try {
      log('Starting full sync... from: ${StackTrace.current}');

      // 1. First push pending changes to remote
      await pushToRemote();

      // 2. Then pull latest data from remote
      await pullFromRemote();

      _updateState(AppSyncState.idle);
      log('Full sync completed successfully.');
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        log('Sync error: Missing Firestore index. Check Firebase Console.');
        log('Error detail: ${e.message}');
      } else {
        log('Sync error (Firebase): ${e.code} - ${e.message}');
      }
      _updateState(AppSyncState.error);
    } catch (e) {
      log('Sync error: $e');
      _updateState(AppSyncState.error);
    }
  }

  /// Push pending operations from the local sync queue to Firebase
  Future<void> pushToRemote() async {
    final currentBusinessId = sessionService.businessId;
    if (currentBusinessId == null) return;

    final pendingEntries = await localDatabase.getPendingSyncEntries();
    if (pendingEntries.isEmpty) return;

    // Filter entries for the current business
    final myEntries = pendingEntries
        .where((e) => e.businessId == currentBusinessId)
        .toList();

    final skippedEntries = pendingEntries
        .where((e) => e.businessId != currentBusinessId)
        .toList();

    if (skippedEntries.isNotEmpty) {
      log(
        'SyncService: Skipping ${skippedEntries.length} entries that do not match current business ID ($currentBusinessId)',
      );
      for (var entry in skippedEntries) {
        log(
          '  - Entry ${entry.id}: Entity=${entry.syncEntityName}, Op=${entry.operation}, BusinessId=${entry.businessId}',
        );
      }
    }

    if (myEntries.isEmpty) return;

    log(
      'Pushing ${myEntries.length} pending operations for business $currentBusinessId to remote...',
    );

    for (final entry in myEntries) {
      try {
        await _processSyncEntry(entry);
        await localDatabase.completeSyncEntry(entry.id);
      } catch (e) {
        log(
          'SyncService: Failed to process sync entry ${entry.id} (${entry.syncEntityName}): $e',
        );

        // If the database is locked, we should stop the sync process entirely
        // and not try to call failSyncEntry (which would also likely fail)
        if (e.toString().contains('database is locked')) {
          rethrow;
        }

        await localDatabase.failSyncEntry(entry.id);
      }
    }
  }

  Future<void> _processSyncEntry(SyncQueueEntry entry) async {
    final data = entry.data != null
        ? jsonDecode(entry.data!) as Map<String, dynamic>
        : null;

    switch (entry.syncEntityName) {
      case 'products':
        await _syncProduct(entry.operation, entry.documentId, data);
        break;
      case 'categories':
        await _syncCategory(entry.operation, entry.documentId, data);
        break;
      case 'customers':
        await _syncCustomer(entry.operation, entry.documentId, data);
        break;
      case 'transactions':
        await _syncTransaction(entry.operation, entry.documentId, data);
        break;
      case 'promos':
        await _syncPromo(entry.operation, entry.documentId, data);
        break;
      case 'business_info':
        await _syncBusiness(entry.operation, entry.documentId, data);
        break;
      case 'stock_logs':
        await _syncStockLog(entry.operation, entry.documentId, data);
        break;
    }
  }

  // --- Entity Specific Sync Logic ---

  Future<void> _syncProduct(
    String op,
    String id,
    Map<String, dynamic>? data,
  ) async {
    if (op == 'delete') {
      await productRemote.deleteProduct(id);
      await productLocal.hardDelete(id);
    } else {
      ProductModel? model;
      if (data != null) {
        model = ProductModel.fromJson(data);
      } else {
        model = await productLocal.getProductById(id);
      }

      if (model != null) {
        if (op == 'create') {
          await productRemote.createProduct(model);
        } else {
          await productRemote.updateProduct(model);
        }
        await productLocal.markAsSynced(id);
      }
    }
  }

  Future<void> _syncCategory(
    String op,
    String id,
    Map<String, dynamic>? data,
  ) async {
    if (op == 'delete') {
      await categoryRemote.deleteCategory(id);
      await categoryLocal.hardDelete(id);
    } else {
      CategoryModel? model;
      if (data != null) {
        model = CategoryModel.fromJson(data);
      } else {
        model = await categoryLocal.getCategoryById(id);
      }

      if (model != null) {
        if (op == 'create') {
          await categoryRemote.createCategory(model);
        } else {
          await categoryRemote.updateCategory(model);
        }
        await categoryLocal.markAsSynced(id);
      }
    }
  }

  Future<void> _syncCustomer(
    String op,
    String id,
    Map<String, dynamic>? data,
  ) async {
    if (op == 'delete') {
      await customerRemote.deleteCustomer(id);
      await customerLocal.hardDelete(id);
    } else {
      CustomerModel? model;
      if (data != null) {
        model = CustomerModel.fromJson(data);
      } else {
        model = await customerLocal.getCustomerById(id);
      }

      if (model != null) {
        if (op == 'create') {
          await customerRemote.createCustomer(model);
        } else {
          await customerRemote.updateCustomer(model);
        }
        await customerLocal.markAsSynced(id);
      }
    }
  }

  Future<void> _syncTransaction(
    String op,
    String id,
    Map<String, dynamic>? data,
  ) async {
    if (op == 'create') {
      TransactionModel? model;
      if (data != null) {
        model = TransactionModel.fromJson(data);
      } else {
        model = await transactionLocal.getTransactionById(id);
      }

      if (model != null) {
        await transactionRemote.createTransaction(model);
        await transactionLocal.markAsSynced(id);
      }
    }
  }

  Future<void> _syncPromo(
    String op,
    String id,
    Map<String, dynamic>? data,
  ) async {
    if (op == 'delete') {
      await promoRemote.deletePromo(id);
      await promoLocal.hardDelete(id);
    } else {
      PromoModel? model;
      if (data != null) {
        model = PromoModel.fromJson(data);
      } else {
        // Fallback or implementation of getPromoById needed
      }

      if (model != null) {
        if (op == 'create') {
          await promoRemote.createPromo(model);
        } else {
          await promoRemote.updatePromo(model);
        }
        await promoLocal.markAsSynced(id);
      }
    }
  }

  Future<void> _syncBusiness(
    String op,
    String id,
    Map<String, dynamic>? data,
  ) async {
    if (op == 'update') {
      BusinessInfoModel? model;
      if (data != null) {
        model = BusinessInfoModel.fromJson(data);
      } else {
        model = await businessLocal.getBusinessInfo(id);
      }

      if (model != null && model.id == id) {
        await businessRemote.updateBusinessInfo(model);
        await businessLocal.markAsSynced(id);
      }
    }
  }

  Future<void> _syncStockLog(
    String op,
    String id,
    Map<String, dynamic>? data,
  ) async {
    if (op == 'create') {
      StockLogModel? model;
      if (data != null) {
        model = StockLogModel.fromJson(data);
      } else {
        model = await stockLogLocal.getStockLogById(id);
      }

      if (model != null) {
        await stockLogRemote.createStockLog(model);
        await stockLogLocal.markAsSynced(id);
      }
    }
  }

  /// Pull all data from Firebase to populate local database
  Future<void> pullFromRemote() async {
    log('Pulling data from remote...');

    // 1. Pull Products
    final products = await productRemote.getProducts().first;
    await productLocal.upsertFromRemote(products);

    // 2. Pull Categories
    var categories = await categoryRemote.getCategories().first;
    final currentBusinessId = sessionService.businessId;
    if (categories.isEmpty && (currentBusinessId?.isNotEmpty ?? false)) {
      log('SyncService: No categories found for business $currentBusinessId, seeding defaults...');
      final seeded = await categoryRemote.seedDefaultCategories(currentBusinessId!);
      if (seeded.isNotEmpty) {
        categories = seeded;
      }
    }
    await categoryLocal.upsertFromRemote(categories);

    // 3. Pull Customers
    final customers = await customerRemote.getCustomers().first;
    await customerLocal.upsertFromRemote(customers);

    // 4. Pull Transactions (Maybe limit this to last 30 days?)
    final transactions = await transactionRemote.getTransactions().first;
    await transactionLocal.upsertFromRemote(transactions);

    // 5. Pull Stock Logs
    final stockLogs = await stockLogRemote.getStockLogs().first;
    await stockLogLocal.upsertFromRemote(stockLogs);

    // 6. Pull Promos
    final promos = await promoRemote.getPromos().first;
    await promoLocal.upsertFromRemote(promos);

    // 7. Pull Business Info
    final business = await businessRemote.getBusinessInfo();
    log(
      'SyncService: Pulled business info: ${business.id} (${business.businessName})',
    );
    await businessLocal.upsertBusinessInfo(business);
    log('SyncService: Upserted business info to local');

    log('Pull completed.');
  }

  void dispose() {
    _syncStateController.close();
  }
}
