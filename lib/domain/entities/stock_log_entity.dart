import 'package:equatable/equatable.dart';

enum StockLogType {
  stockIn,      // Adding stock (purchase/restock)
  stockOut,     // Removing stock (manual/damage)
  sale,         // Auto reduction from transaction
  adjustment,   // Manual override/correction
}

class StockLog extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final StockLogType type;
  final int quantity;       // The amount changed (+/-)
  final int previousStock;
  final int newStock;
  final String? reason;
  final DateTime createdAt;

  const StockLog({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.reason,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        type,
        quantity,
        previousStock,
        newStock,
        reason,
        createdAt,
      ];
}
