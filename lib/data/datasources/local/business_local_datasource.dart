import 'package:drift/drift.dart';
import 'local_database.dart';
import '../../models/business_model.dart';

class BusinessLocalDataSource {
  final LocalDatabase db;

  BusinessLocalDataSource(this.db);

  Future<BusinessInfoModel?> getBusinessInfo() async {
    final result = await db.select(db.localBusinessInfo).getSingleOrNull();
    if (result == null) return null;

    return BusinessInfoModel(
      id: result.id,
      businessName: result.businessName,
      address: result.address,
      phone: result.phone,
      email: result.email,
      logoUrl: result.logoUrl,
      qrisUrl: result.qrisUrl,
      createdAt: result.createdAt,
      updatedAt: result.updatedAt,
    );
  }

  Future<void> upsertBusinessInfo(BusinessInfoModel business) async {
    await db
        .into(db.localBusinessInfo)
        .insertOnConflictUpdate(
          LocalBusinessInfoCompanion.insert(
            id: business.id,
            businessName: business.businessName,
            address: Value(business.address),
            phone: Value(business.phone),
            email: Value(business.email),
            logoUrl: Value(business.logoUrl),
            qrisUrl: Value(business.qrisUrl),
            createdAt: business.createdAt,
            updatedAt: business.updatedAt,
            syncStatus: const Value('synced'),
            lastSyncAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> markAsSynced(String id) async {
    await (db.update(
      db.localBusinessInfo,
    )..where((t) => t.id.equals(id))).write(
      LocalBusinessInfoCompanion(
        syncStatus: const Value('synced'),
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }
}
