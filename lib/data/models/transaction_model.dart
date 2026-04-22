import 'package:cloud_firestore/cloud_firestore.dart' as f_store;
import '../../domain/entities/transaction_entity.dart';

class TransactionItemModel extends TransactionItem {
  const TransactionItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.price,
    super.discount = 0,
    required super.subtotal,
  });

  factory TransactionItemModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionItemModel(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }

  factory TransactionItemModel.fromEntity(TransactionItem entity) {
    return TransactionItemModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      quantity: entity.quantity,
      price: entity.price,
      discount: entity.discount,
      subtotal: entity.subtotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'subtotal': subtotal,
    };
  }

  TransactionItem toEntity() {
    return TransactionItem(
      id: id,
      productId: productId,
      productName: productName,
      quantity: quantity,
      price: price,
      discount: discount,
      subtotal: subtotal,
    );
  }
}

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.transactionCode,
    super.customerId,
    super.customerName,
    required super.subtotal,
    super.taxAmount = 0,
    super.discountAmount = 0,
    required super.totalAmount,
    required super.paymentMethod,
    super.paymentStatus = PaymentStatus.unpaid,
    super.status = TransactionStatus.pending,
    super.amountPaid = 0,
    super.changeAmount = 0,
    super.notes,
    required super.createdAt,
    super.completedAt,
    required super.items,
    required super.createdBy,
  });

  factory TransactionModel.fromFirestore(
    f_store.DocumentSnapshot doc,
    List<TransactionItem> items,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      transactionCode: data['transactionCode'] ?? '',
      customerId: data['customerId'],
      customerName: data['customerName'],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (data['paymentStatus'] ?? 'unpaid'),
        orElse: () => PaymentStatus.unpaid,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => TransactionStatus.pending,
      ),
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
      changeAmount: (data['changeAmount'] ?? 0).toDouble(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as f_store.Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as f_store.Timestamp).toDate()
          : null,
      items: items,
      createdBy: data['createdBy'] ?? '',
    );
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      transactionCode: entity.transactionCode,
      customerId: entity.customerId,
      customerName: entity.customerName,
      subtotal: entity.subtotal,
      taxAmount: entity.taxAmount,
      discountAmount: entity.discountAmount,
      totalAmount: entity.totalAmount,
      paymentMethod: entity.paymentMethod,
      paymentStatus: entity.paymentStatus,
      status: entity.status,
      amountPaid: entity.amountPaid,
      changeAmount: entity.changeAmount,
      notes: entity.notes,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
      items: entity.items,
      createdBy: entity.createdBy,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'transactionCode': transactionCode,
      'customerId': customerId,
      'customerName': customerName,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus.name,
      'status': status.name,
      'amountPaid': amountPaid,
      'changeAmount': changeAmount,
      'notes': notes,
      'createdAt': f_store.Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? f_store.Timestamp.fromDate(completedAt!)
          : null,
      'createdBy': createdBy,
    };
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      transactionCode: transactionCode,
      customerId: customerId,
      customerName: customerName,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      status: status,
      amountPaid: amountPaid,
      changeAmount: changeAmount,
      notes: notes,
      createdAt: createdAt,
      completedAt: completedAt,
      items: items,
      createdBy: createdBy,
    );
  }
}
