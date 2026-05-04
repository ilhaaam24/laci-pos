import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:intl/intl.dart';
import '../constants/firebase_collections.dart';

class ReportService {
  final FirebaseFirestore firestore;

  ReportService(this.firestore);

  // Daily Report
  Future<Map<String, dynamic>> getDailyReport(
    String businessId,
    DateTime date,
  ) async {
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));
    return await _getReport(businessId, startDate, endDate);
  }

  // Weekly Report
  Future<Map<String, dynamic>> getWeeklyReport(
    String businessId,
    DateTime date,
  ) async {
    final startDate = date.subtract(Duration(days: date.weekday - 1));
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final endDate = normalizedStart.add(const Duration(days: 7));
    return await _getReport(businessId, normalizedStart, endDate);
  }

  // Monthly Report
  Future<Map<String, dynamic>> getMonthlyReport(
    String businessId,
    DateTime date,
  ) async {
    final startDate = DateTime(date.year, date.month, 1);
    final endDate = DateTime(date.year, date.month + 1, 1);
    return await _getReport(businessId, startDate, endDate);
  }

  // Custom Range Report
  Future<Map<String, dynamic>> getCustomRangeReport({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(const Duration(days: 1));
    return await _getReport(businessId, start, end);
  }

  Future<Map<String, dynamic>> _getReport(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await firestore
        .collection(FirebaseCollections.transactions)
        .where('businessId', isEqualTo: businessId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
        .get();

    double totalRevenue = 0;
    double totalCost = 0;
    int totalTransactions = snapshot.docs.length;
    int totalItems = 0;
    Map<String, Map<String, dynamic>> productSales = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalRevenue += (data['totalAmount'] ?? 0).toDouble();

      // Get items count and cost
      final itemsSnapshot = await doc.reference
          .collection(FirebaseCollections.transactionItems)
          .get();
      totalItems += itemsSnapshot.docs.length;

      for (var itemDoc in itemsSnapshot.docs) {
        final itemData = itemDoc.data();
        final productId = itemData['productId'] as String;
        final productName = itemData['productName'] as String;
        final quantity = itemData['quantity'] ?? 0;
        final costPrice = itemData['costPrice'] ?? 0;
        final subtotal = (itemData['subtotal'] ?? 0).toDouble();

        totalCost += (costPrice * quantity).toDouble();

        // Best Selling Logic
        if (productSales.containsKey(productId)) {
          productSales[productId]!['totalQuantity'] += quantity;
          productSales[productId]!['totalRevenue'] += subtotal;
        } else {
          productSales[productId] = {
            'productId': productId,
            'productName': productName,
            'totalQuantity': quantity,
            'totalRevenue': subtotal,
          };
        }
      }
    }

    // Sort best selling products
    final bestSellingProducts = productSales.values.toList()
      ..sort(
        (a, b) =>
            (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int),
      );

    // Calculate daily sales for chart (last 7 days by default or current range)
    Map<String, double> dailySales = {};
    for (int i = 0; i < 7; i++) {
      final date = endDate.subtract(Duration(days: i));
      final label = DateFormat('E', 'en_US').format(date);
      dailySales[label] = 0;
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['createdAt'] as Timestamp).toDate();
      final label = DateFormat('E', 'en_US').format(date);
      if (dailySales.containsKey(label)) {
        dailySales[label] =
            (dailySales[label] ?? 0) + (data['totalAmount'] ?? 0).toDouble();
      }
    }

    // New Customers count
    final customersSnapshot = await firestore
        .collection(FirebaseCollections.customers)
        .where('businessId', isEqualTo: businessId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
        .get();
    final newCustomers = customersSnapshot.docs.length;

    // Fetch product images for best sellers
    final List<Map<String, dynamic>> enrichedBestSellers = [];
    for (var item in bestSellingProducts.take(5)) {
      final productDoc = await firestore
          .collection(FirebaseCollections.products)
          .doc(item['productId'])
          .get();
      enrichedBestSellers.add({
        ...item,
        'imageUrl': productDoc.exists ? productDoc.data()!['imageUrl'] : null,
      });
    }

    final totalProfit = totalRevenue - totalCost;

    return {
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'totalProfit': totalProfit,
      'totalTransactions': totalTransactions,
      'totalItems': totalItems,
      'bestSellingProducts': enrichedBestSellers,
      'dailySales': dailySales,
      'newCustomers': newCustomers,
      'averageTransaction': totalTransactions > 0
          ? totalRevenue / totalTransactions
          : 0,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  // Best Selling Products
  Future<List<Map<String, dynamic>>> getBestSellingProducts({
    required String businessId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    // Get all transactions in date range
    final transactionsSnapshot = await firestore
        .collection(FirebaseCollections.transactions)
        .where('businessId', isEqualTo: businessId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    // Aggregate product sales
    Map<String, Map<String, dynamic>> productSales = {};

    for (var transDoc in transactionsSnapshot.docs) {
      final itemsSnapshot = await transDoc.reference
          .collection(FirebaseCollections.transactionItems)
          .get();

      for (var itemDoc in itemsSnapshot.docs) {
        final data = itemDoc.data();
        final productId = data['productId'] as String;
        final productName = data['productName'] as String;
        final quantity = data['quantity'] as int;
        final subtotal = (data['subtotal'] as num).toDouble();

        if (productSales.containsKey(productId)) {
          productSales[productId]!['totalQuantity'] += quantity;
          productSales[productId]!['totalRevenue'] += subtotal;
        } else {
          productSales[productId] = {
            'productId': productId,
            'productName': productName,
            'totalQuantity': quantity,
            'totalRevenue': subtotal,
          };
        }
      }
    }

    // Convert to list and sort
    final sortedProducts = productSales.values.toList()
      ..sort(
        (a, b) =>
            (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int),
      );

    return sortedProducts.take(limit).toList();
  }

  // Sales by Category
  Future<Map<String, double>> getSalesByCategory({
    required String businessId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final transactionsSnapshot = await firestore
        .collection(FirebaseCollections.transactions)
        .where('businessId', isEqualTo: businessId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    Map<String, double> categorySales = {};

    for (var transDoc in transactionsSnapshot.docs) {
      final itemsSnapshot = await transDoc.reference
          .collection(FirebaseCollections.transactionItems)
          .get();

      for (var itemDoc in itemsSnapshot.docs) {
        final data = itemDoc.data();
        final productId = data['productId'] as String;
        final subtotal = (data['subtotal'] as num).toDouble();

        // Get product to find category
        final productDoc = await firestore
            .collection(FirebaseCollections.products)
            .doc(productId)
            .get();

        if (productDoc.exists) {
          final categoryId = productDoc.data()!['categoryId'] as String;

          // Get category name
          final categoryDoc = await firestore
              .collection(FirebaseCollections.categories)
              .doc(categoryId)
              .get();

          if (categoryDoc.exists) {
            final categoryName = categoryDoc.data()!['name'] as String;

            categorySales[categoryName] =
                (categorySales[categoryName] ?? 0) + subtotal;
          }
        }
      }
    }

    return categorySales;
  }
}
