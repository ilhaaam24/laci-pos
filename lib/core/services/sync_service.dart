import 'dart:async';
import 'dart:convert';
import 'dart:developer';
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

    _updateState(AppSyncState.syncing);
    try {
      log('Starting full sync...');
      
      // 1. First push pending changes to remote
      await pushToRemote();
      
      // 2. Then pull latest data from remote
      await pullFromRemote();
      
      _updateState(AppSyncState.idle);
      log('Full sync completed successfully.');
    } catch (e) {
      log('Sync error: $e');
      _updateState(AppSyncState.error);
    }
  }

  /// Push pending operations from the local sync queue to Firebase
  Future<void> pushToRemote() async {
    final pendingEntries = await localDatabase.getPendingSyncEntries();
    if (pendingEntries.isEmpty) return;

    log('Pushing ${pendingEntries.length} pending operations to remote...');

    for (final entry in pendingEntries) {
      try {
        await _processSyncEntry(entry);
        await localDatabase.completeSyncEntry(entry.id);
      } catch (e) {
        log('Failed to process sync entry ${entry.id}: $e');
        await localDatabase.failSyncEntry(entry.id);
      }
    }
  }

  Future<void> _processSyncEntry(SyncQueueEntry entry) async {
    final data = entry.data != null ? jsonDecode(entry.data!) as Map<String, dynamic> : null;
    
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

  Future<void> _syncProduct(String op, String id, Map<String, dynamic>? data) async {
    if (op == 'delete') {
      await productRemote.deleteProduct(id);
      await productLocal.hardDelete(id);
    } else {
      final model = await productLocal.getProductById(id);
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

  Future<void> _syncCategory(String op, String id, Map<String, dynamic>? data) async {
    if (op == 'delete') {
      await categoryRemote.deleteCategory(id);
      await categoryLocal.hardDelete(id);
    } else {
      final model = await categoryLocal.getCategoryById(id);
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

  Future<void> _syncCustomer(String op, String id, Map<String, dynamic>? data) async {
    if (op == 'delete') {
      await customerRemote.deleteCustomer(id);
      await customerLocal.hardDelete(id);
    } else {
      final model = await customerLocal.getCustomerById(id);
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

  Future<void> _syncTransaction(String op, String id, Map<String, dynamic>? data) async {
    if (op == 'create') {
      final model = await transactionLocal.getTransactionById(id);
      if (model != null) {
        await transactionRemote.createTransaction(model);
        await transactionLocal.markAsSynced(id);
      }
    }
  }

  Future<void> _syncPromo(String op, String id, Map<String, dynamic>? data) async {
    if (op == 'delete') {
      await promoRemote.deletePromo(id);
      await promoLocal.hardDelete(id);
    } else {
      // Need to implement getPromoById in promoLocal if needed, or use a general approach
      // For now, assume we pull all and sync back
    }
  }

  Future<void> _syncBusiness(String op, String id, Map<String, dynamic>? data) async {
    final model = await businessLocal.getBusinessInfo();
    if (model != null && model.id == id) {
      await businessRemote.updateBusinessInfo(model);
    }
  }

  Future<void> _syncStockLog(String op, String id, Map<String, dynamic>? data) async {
    if (op == 'create') {
      // Assuming stock logs are created alongside transactions or manual adjustments
      // and we just need to ensure they reach the server.
    }
  }

  /// Pull all data from Firebase to populate local database
  Future<void> pullFromRemote() async {
    log('Pulling data from remote...');
    
    // 1. Pull Products
    final products = await productRemote.getProducts().first;
    await productLocal.upsertFromRemote(products);
    
    // 2. Pull Categories
    final categories = await categoryRemote.getCategories().first;
    await categoryLocal.upsertFromRemote(categories);
    
    // 3. Pull Customers
    final customers = await customerRemote.getCustomers().first;
    await customerLocal.upsertFromRemote(customers);
    
    // 4. Pull Transactions (Maybe limit this to last 30 days?)
    final transactions = await transactionRemote.getTransactions().first;
    await transactionLocal.upsertFromRemote(transactions);
    
    // 5. Pull Promos
    final promos = await promoRemote.getPromos().first;
    await promoLocal.upsertFromRemote(promos);

    // 6. Pull Business Info
    final business = await businessRemote.getBusinessInfo();
    await businessLocal.upsertBusinessInfo(business);
    
    log('Pull completed.');
  }

  void dispose() {
    _syncStateController.close();
  }
}
