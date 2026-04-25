import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/stock_log_entity.dart';

class StockLogModel extends StockLog {
  const StockLogModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.type,
    required super.quantity,
    required super.previousStock,
    required super.newStock,
    super.reason,
    required super.createdAt,
  });

  factory StockLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockLogModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      type: StockLogType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => StockLogType.adjustment,
      ),
      quantity: data['quantity'] ?? 0,
      previousStock: data['previousStock'] ?? 0,
      newStock: data['newStock'] ?? 0,
      reason: data['reason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StockLogModel.fromEntity(StockLog entity) {
    return StockLogModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      type: entity.type,
      quantity: entity.quantity,
      previousStock: entity.previousStock,
      newStock: entity.newStock,
      reason: entity.reason,
      createdAt: entity.createdAt,
    );
  }
}
