import 'package:equatable/equatable.dart';
import 'product_variant.dart';

enum TransactionStatus { pending, completed, cancelled, refunded }

enum PaymentStatus { unpaid, paid, partial }

enum PaymentType { cash, qris, debit, transfer }

class PaymentDetail extends Equatable {
  final PaymentType type;
  final double amount;
  final String? reference;
  final DateTime timestamp;

  const PaymentDetail({
    required this.type,
    required this.amount,
    this.reference,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [type, amount, reference, timestamp];

  String get typeName {
    switch (type) {
      case PaymentType.cash:
        return 'Cash';
      case PaymentType.qris:
        return 'QRIS';
      case PaymentType.debit:
        return 'Debit Card';
      case PaymentType.transfer:
        return 'Transfer Bank';
    }
  }
}

class TransactionEntity extends Equatable {
  final String id;
  final String transactionCode;
  final String? customerId;
  final String? customerName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final List<PaymentDetail> payments;
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
    required this.payments,
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

  String get paymentMethodDisplay {
    if (payments.isEmpty) return 'No Payment';
    if (payments.length == 1) return payments.first.typeName;
    return 'Multiple (${payments.length})';
  }

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
    payments,
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
  final String? businessId;
  final ProductVariant? selectedVariant;
  final List<ModifierOption> selectedModifiers;
  final String? notes;

  const TransactionItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.costPrice,
    this.discount = 0,
    required this.subtotal,
    this.businessId,
    this.selectedVariant,
    this.selectedModifiers = const [],
    this.notes,
  });

  /// The effective price for 1 unit including variant base and modifier additions.
  double get unitPrice {
    final vPrice = selectedVariant?.price ?? price;
    final modPrice = selectedModifiers.fold(0.0, (sum, m) => sum + m.price);
    return vPrice + modPrice;
  }

  /// Display name that includes variant if present (e.g. "Kopi Susu (Large)").
  String get displayName {
    if (selectedVariant != null && selectedVariant!.name.isNotEmpty) {
      return '$productName (${selectedVariant!.name})';
    }
    return productName;
  }

  /// Formatted comma-separated list of selected modifiers.
  String get modifiersDisplay {
    if (selectedModifiers.isEmpty) return '';
    return selectedModifiers
        .map((m) => m.price > 0 ? '+${m.name}' : m.name)
        .join(', ');
  }

  TransactionItem copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    double? costPrice,
    double? discount,
    double? subtotal,
    String? businessId,
    ProductVariant? selectedVariant,
    List<ModifierOption>? selectedModifiers,
    String? notes,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      discount: discount ?? this.discount,
      subtotal: subtotal ?? this.subtotal,
      businessId: businessId ?? this.businessId,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      notes: notes ?? this.notes,
    );
  }

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
    businessId,
    selectedVariant,
    selectedModifiers,
    notes,
  ];
}

