import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_database.g.dart';

// ============================================================
// TABLE DEFINITIONS
// ============================================================

/// Local mirror of Firebase 'products' collection.
class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  RealColumn get costPrice => real()();
  IntColumn get stock => integer()();
  IntColumn get stockThreshold => integer().withDefault(const Constant(5))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get sku => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get businessId => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of Firebase 'categories' collection.
class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get businessId => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of Firebase 'customers' collection.
class LocalCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get businessId => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of Firebase 'transactions' collection.
class LocalTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get transactionCode => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real()();
  TextColumn get paymentMethod => text()();
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('unpaid'))();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  RealColumn get amountPaid => real().withDefault(const Constant(0))();
  RealColumn get changeAmount => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get businessId => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of Firebase 'transaction_items' subcollection.
class LocalTransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get price => real()();
  RealColumn get costPrice => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get subtotal => real()();
  TextColumn get businessId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of Firebase 'promos' collection.
class LocalPromos extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get value => real()();
  RealColumn get minPurchase => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get businessId => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of Firebase 'stock_logs' collection.
class LocalStockLogs extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  TextColumn get type => text()();
  IntColumn get quantity => integer()();
  IntColumn get previousStock => integer()();
  IntColumn get newStock => integer()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get businessId => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of Firebase 'business_info' collection.
class LocalBusinessInfo extends Table {
  TextColumn get id => text()();
  TextColumn get businessName => text()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get qrisUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Queue of operations pending sync to Firebase.
class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncEntityName => text()();
  TextColumn get documentId => text()();

  /// Operation type: 'create', 'update', 'delete'
  TextColumn get operation => text()();

  /// JSON-encoded data payload for create/update operations
  TextColumn get data => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// 'pending', 'processing', 'failed'
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
}

// ============================================================
// DATABASE CLASS
// ============================================================

@DriftDatabase(tables: [
  LocalProducts,
  LocalCategories,
  LocalCustomers,
  LocalTransactions,
  LocalTransactionItems,
  LocalPromos,
  LocalStockLogs,
  LocalBusinessInfo,
  SyncQueueEntries,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  /// For testing with an in-memory database
  LocalDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations go here
      },
    );
  }

  // ============================================================
  // SYNC QUEUE OPERATIONS
  // ============================================================

  /// Add an operation to the sync queue.
  Future<void> addToSyncQueue({
    required String syncEntityName,
    required String documentId,
    required String operation,
    String? data,
  }) async {
    await into(syncQueueEntries).insert(
      SyncQueueEntriesCompanion.insert(
        syncEntityName: syncEntityName,
        documentId: documentId,
        operation: operation,
        data: Value(data),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Get all pending sync queue entries, ordered by creation time.
  Future<List<SyncQueueEntry>> getPendingSyncEntries() async {
    return (select(syncQueueEntries)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Mark a sync queue entry as completed and remove it.
  Future<void> completeSyncEntry(int entryId) async {
    await (delete(syncQueueEntries)..where((t) => t.id.equals(entryId))).go();
  }

  /// Mark a sync queue entry as failed and increment retry count.
  Future<void> failSyncEntry(int entryId) async {
    final entry = await (select(syncQueueEntries)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    if (entry != null) {
      await (update(syncQueueEntries)..where((t) => t.id.equals(entryId)))
          .write(SyncQueueEntriesCompanion(
        status: const Value('failed'),
        retryCount: Value(entry.retryCount + 1),
      ));
    }
  }

  /// Reset failed entries back to pending for retry.
  Future<void> retryFailedEntries() async {
    await (update(syncQueueEntries)
          ..where((t) =>
              t.status.equals('failed') & t.retryCount.isSmallerThanValue(5)))
        .write(const SyncQueueEntriesCompanion(
      status: Value('pending'),
    ));
  }

  /// Count pending sync operations.
  Future<int> getPendingSyncCount() async {
    final count = countAll();
    final query = selectOnly(syncQueueEntries)
      ..where(syncQueueEntries.status.equals('pending'))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Clear all data (used when switching business/user).
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(localProducts).go();
      await delete(localCategories).go();
      await delete(localCustomers).go();
      await delete(localTransactions).go();
      await delete(localTransactionItems).go();
      await delete(localPromos).go();
      await delete(localStockLogs).go();
      await delete(localBusinessInfo).go();
      await delete(syncQueueEntries).go();
    });
  }
}

// ============================================================
// DATABASE CONNECTION
// ============================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'laci_pos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
