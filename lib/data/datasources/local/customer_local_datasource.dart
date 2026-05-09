import 'package:drift/drift.dart';
import 'package:laci/data/models/customer_model.dart';
import 'local_database.dart';

/// Local data source for Customer operations using Drift/SQLite.
class CustomerLocalDataSource {
  final LocalDatabase _db;

  CustomerLocalDataSource(this._db);

  Stream<List<CustomerModel>> watchCustomers(String businessId) {
    final query = _db.select(_db.localCustomers)
      ..where(
        (t) =>
            t.businessId.equals(businessId) &
            t.syncStatus.equals('pendingDelete').not(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map(
      (rows) => rows.map((row) => _rowToModel(row)).toList(),
    );
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final query = _db.select(_db.localCustomers)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  Future<void> upsertCustomer(
    CustomerModel customer, {
    String syncStatus = 'pendingUpload',
  }) async {
    await _db
        .into(_db.localCustomers)
        .insertOnConflictUpdate(
          LocalCustomersCompanion.insert(
            id: customer.id,
            name: customer.name,
            email: Value(customer.email),
            phone: Value(customer.phone),
            address: Value(customer.address),
            totalSpent: Value(customer.totalSpent),
            lastTransactionDate: Value(customer.lastTransactionDate),
            loyaltyPoints: Value(customer.loyaltyPoints),
            createdAt: customer.createdAt,
            updatedAt: customer.updatedAt,
            businessId: Value(customer.businessId),
            syncStatus: Value(syncStatus),
            lastSyncAt: Value(syncStatus == 'synced' ? DateTime.now() : null),
          ),
        );
  }

  Future<void> markAsDeleted(String id) async {
    await (_db.update(_db.localCustomers)..where((t) => t.id.equals(id))).write(
      const LocalCustomersCompanion(syncStatus: Value('pendingDelete')),
    );
  }

  Future<void> hardDelete(String id) async {
    await (_db.delete(_db.localCustomers)..where((t) => t.id.equals(id))).go();
  }

  Future<void> upsertFromRemote(List<CustomerModel> customers) async {
    await _db.batch((batch) {
      for (final cust in customers) {
        batch.insert(
          _db.localCustomers,
          LocalCustomersCompanion.insert(
            id: cust.id,
            name: cust.name,
            email: Value(cust.email),
            phone: Value(cust.phone),
            address: Value(cust.address),
            totalSpent: Value(cust.totalSpent),
            lastTransactionDate: Value(cust.lastTransactionDate),
            loyaltyPoints: Value(cust.loyaltyPoints),
            createdAt: cust.createdAt,
            updatedAt: cust.updatedAt,
            businessId: Value(cust.businessId),
            syncStatus: const Value('synced'),
            lastSyncAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<CustomerModel>> getPendingSync() async {
    final query = _db.select(_db.localCustomers)
      ..where((t) => t.syncStatus.equals('synced').not());
    final rows = await query.get();
    return rows.map((row) => _rowToModel(row)).toList();
  }

  Future<void> markAsSynced(String id) async {
    await (_db.update(_db.localCustomers)..where((t) => t.id.equals(id))).write(
      LocalCustomersCompanion(
        syncStatus: const Value('synced'),
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }

  CustomerModel _rowToModel(LocalCustomer row) {
    return CustomerModel(
      id: row.id,
      name: row.name,
      email: row.email,
      phone: row.phone,
      address: row.address,
      totalSpent: row.totalSpent,
      lastTransactionDate: row.lastTransactionDate,
      loyaltyPoints: row.loyaltyPoints,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      businessId: row.businessId,
    );
  }
}
