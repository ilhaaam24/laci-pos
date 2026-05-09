import 'package:cloud_firestore/cloud_firestore.dart' as f_store;
import '../../domain/entities/transaction_entity.dart';

class TransactionItemModel extends TransactionItem {
  const TransactionItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.price,
    required super.costPrice,
    super.discount = 0,
    required super.subtotal,
    super.businessId,
  });

  factory TransactionItemModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionItemModel(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      costPrice: (map['costPrice'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      businessId: map['businessId'],
    );
  }

  factory TransactionItemModel.fromEntity(TransactionItem entity) {
    return TransactionItemModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      quantity: entity.quantity,
      price: entity.price,
      costPrice: entity.costPrice,
      discount: entity.discount,
      subtotal: entity.subtotal,
      businessId: entity.businessId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'costPrice': costPrice,
      'discount': discount,
      'subtotal': subtotal,
      'businessId': businessId,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'costPrice': costPrice,
      'discount': discount,
      'subtotal': subtotal,
      'businessId': businessId,
    };
  }

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      businessId: json['businessId'],
    );
  }

  TransactionItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    double? costPrice,
    double? discount,
    double? subtotal,
    String? businessId,
  }) {
    return TransactionItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      discount: discount ?? this.discount,
      subtotal: subtotal ?? this.subtotal,
      businessId: businessId ?? this.businessId,
    );
  }

  TransactionItem toEntity() {
    return TransactionItem(
      id: id,
      productId: productId,
      productName: productName,
      quantity: quantity,
      price: price,
      costPrice: costPrice,
      discount: discount,
      subtotal: subtotal,
      businessId: businessId,
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
    super.businessId,
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
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as f_store.Timestamp).toDate()
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as f_store.Timestamp).toDate()
          : null,
      items: items,
      createdBy: data['createdBy'] ?? '',
      businessId: data['businessId'],
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
      businessId: entity.businessId,
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
      'businessId': businessId,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'items': items
          .map((e) => TransactionItemModel.fromEntity(e).toJson())
          .toList(),
      'createdBy': createdBy,
      'businessId': businessId,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      transactionCode: json['transactionCode'] ?? '',
      customerId: json['customerId'],
      customerName: json['customerName'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (json['paymentStatus'] ?? 'unpaid'),
        orElse: () => PaymentStatus.unpaid,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
        orElse: () => TransactionStatus.pending,
      ),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0).toDouble(),
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      items:
          (json['items'] as List?)
              ?.map(
                (e) => TransactionItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdBy: json['createdBy'] ?? '',
      businessId: json['businessId'],
    );
  }

  TransactionModel copyWith({
    String? id,
    String? transactionCode,
    String? customerId,
    String? customerName,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    TransactionStatus? status,
    double? amountPaid,
    double? changeAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? completedAt,
    List<TransactionItem>? items,
    String? createdBy,
    String? businessId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      transactionCode: transactionCode ?? this.transactionCode,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      amountPaid: amountPaid ?? this.amountPaid,
      changeAmount: changeAmount ?? this.changeAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      items: items ?? this.items,
      createdBy: createdBy ?? this.createdBy,
      businessId: businessId ?? this.businessId,
    );
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
      businessId: businessId,
    );
  }
}
