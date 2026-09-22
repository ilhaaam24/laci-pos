import 'package:equatable/equatable.dart';
import 'customer_entity.dart';
import 'product_variant.dart';
import 'transaction_entity.dart';

/// Represents a held or open order (e.g. for dine-in tables or queue waiting)
class HeldOrder extends Equatable {
  final String id;
  final String orderName; // e.g. "Meja 04", "Meja VIP 1", "Take Away 02"
  final String? customerName;
  final Customer? customer;
  final List<TransactionItem> items;
  final double subtotal;
  final double totalAmount;
  final String? notes; // e.g. "Dine In", "Tunggu teman"
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? businessId;

  const HeldOrder({
    required this.id,
    required this.orderName,
    this.customerName,
    this.customer,
    required this.items,
    required this.subtotal,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.businessId,
  });

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  String get summaryText {
    if (items.isEmpty) return '0 item';
    final firstItems = items.take(2).map((i) => '${i.quantity}x ${i.displayName}').join(', ');
    if (items.length > 2) {
      return '$firstItems, +${items.length - 2} lainnya';
    }
    return firstItems;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderName': orderName,
    'customerName': customerName,
    'customer': customer != null ? _customerToJson(customer!) : null,
    'items': items.map((i) => _itemToJson(i)).toList(),
    'subtotal': subtotal,
    'totalAmount': totalAmount,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
    'businessId': businessId,
  };

  factory HeldOrder.fromJson(Map<String, dynamic> json) {
    return HeldOrder(
      id: json['id'] as String? ?? '',
      orderName: json['orderName'] as String? ?? 'Pesanan',
      customerName: json['customerName'] as String?,
      customer: json['customer'] != null
          ? _customerFromJson(json['customer'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => _itemFromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
      businessId: json['businessId'] as String?,
    );
  }

  HeldOrder copyWith({
    String? id,
    String? orderName,
    String? customerName,
    Customer? customer,
    bool clearCustomer = false,
    List<TransactionItem>? items,
    double? subtotal,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? businessId,
  }) {
    return HeldOrder(
      id: id ?? this.id,
      orderName: orderName ?? this.orderName,
      customerName: customerName ?? this.customerName,
      customer: clearCustomer ? null : (customer ?? this.customer),
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      businessId: businessId ?? this.businessId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderName,
    customerName,
    customer,
    items,
    subtotal,
    totalAmount,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    businessId,
  ];

  static Map<String, dynamic> _itemToJson(TransactionItem item) => {
    'id': item.id,
    'productId': item.productId,
    'productName': item.productName,
    'quantity': item.quantity,
    'price': item.price,
    'costPrice': item.costPrice,
    'discount': item.discount,
    'subtotal': item.subtotal,
    'businessId': item.businessId,
    'selectedVariant': item.selectedVariant?.toJson(),
    'selectedModifiers': item.selectedModifiers.map((m) => m.toJson()).toList(),
    'notes': item.notes,
  };

  static TransactionItem _itemFromJson(Map<String, dynamic> json) => TransactionItem(
    id: json['id'] as String? ?? '',
    productId: json['productId'] as String? ?? '',
    productName: json['productName'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    businessId: json['businessId'] as String?,
    selectedVariant: json['selectedVariant'] != null
        ? ProductVariant.fromJson(json['selectedVariant'] as Map<String, dynamic>)
        : null,
    selectedModifiers: (json['selectedModifiers'] as List<dynamic>?)
            ?.map((m) => ModifierOption.fromJson(m as Map<String, dynamic>))
            .toList() ??
        const [],
    notes: json['notes'] as String?,
  );

  static Map<String, dynamic> _customerToJson(Customer c) => {
    'id': c.id,
    'name': c.name,
    'email': c.email,
    'phone': c.phone,
    'address': c.address,
    'totalSpent': c.totalSpent,
    'loyaltyPoints': c.loyaltyPoints,
    'createdAt': c.createdAt.toIso8601String(),
    'updatedAt': c.updatedAt.toIso8601String(),
    'businessId': c.businessId,
  };

  static Customer _customerFromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
    loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    businessId: json['businessId'] as String?,
  );
}
