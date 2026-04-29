import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import '../constants/firebase_collections.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
      final businessId = inputData?['businessId'];

      if (task == "dailySalesSummary" && businessId != null) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

        final querySnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollections.transactions)
            .where('businessId', isEqualTo: businessId)
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
            )
            .get();

        double totalSales = 0;
        int totalTransactions = querySnapshot.docs.length;

        for (var doc in querySnapshot.docs) {
          totalSales += (doc.data()['totalAmount'] ?? 0).toDouble();
        }

        final notificationService = NotificationService();
        await notificationService.init();
        await notificationService.showSalesSummary(
          totalSales: totalSales,
          totalTransactions: totalTransactions,
        );
      }
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> scheduleDailySummary(String businessId) async {
    await Workmanager().registerPeriodicTask(
      "dailySalesSummaryTask",
      "dailySalesSummary",
      frequency: const Duration(hours: 24),
      inputData: {'businessId': businessId},
      initialDelay: _calculateInitialDelay(),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Duration _calculateInitialDelay() {
    final now = DateTime.now();
    // Schedule for 9 PM
    var scheduledTime = DateTime(now.year, now.month, now.day, 21, 0, 0);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime.difference(now);
  }
}
