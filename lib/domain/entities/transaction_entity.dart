import 'package:equatable/equatable.dart';

enum TransactionStatus { pending, completed, cancelled, refunded }

enum PaymentStatus { unpaid, paid, partial }

class TransactionEntity extends Equatable {
  final String id;
  final String transactionCode;
  final String? customerId;
  final String? customerName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final TransactionStatus status;
  final double amountPaid;
  final double changeAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<TransactionItem> items;
  final String createdBy; // User ID yang melakukan transaksi
  final String? businessId;

  const TransactionEntity({
    required this.id,
    required this.transactionCode,
    this.customerId,
    this.customerName,
    required this.subtotal,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.unpaid,
    this.status = TransactionStatus.pending,
    this.amountPaid = 0,
    this.changeAmount = 0,
    this.notes,
    required this.createdAt,
    this.completedAt,
    required this.items,
    required this.createdBy,
    this.businessId,
  });

  double get grandTotal => subtotal + taxAmount - discountAmount;

  @override
  List<Object?> get props => [
    id,
    transactionCode,
    customerId,
    customerName,
    subtotal,
    taxAmount,
    discountAmount,
    totalAmount,
    paymentMethod,
    paymentStatus,
    status,
    amountPaid,
    changeAmount,
    notes,
    createdAt,
    completedAt,
    items,
    createdBy,
    businessId,
  ];
}

class TransactionItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double costPrice;
  final double discount;
  final double subtotal;

  const TransactionItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.costPrice,
    this.discount = 0,
    required this.subtotal,
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    quantity,
    price,
    costPrice,
    discount,
    subtotal,
  ];
}
