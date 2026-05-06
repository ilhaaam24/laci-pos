import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.name,
    super.email,
    super.phone,
    super.address,
    super.totalSpent = 0,
    super.lastTransactionDate,
    super.loyaltyPoints = 0,
    required super.createdAt,
    required super.updatedAt,
    super.businessId,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
      address: data['address'],
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      lastTransactionDate: data['lastTransactionDate'] != null
          ? (data['lastTransactionDate'] as Timestamp).toDate()
          : null,
      loyaltyPoints: data['loyaltyPoints'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      businessId: data['businessId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'totalSpent': totalSpent,
      'lastTransactionDate': lastTransactionDate != null
          ? Timestamp.fromDate(lastTransactionDate!)
          : null,
      'loyaltyPoints': loyaltyPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'businessId': businessId,
    };
  }

  factory CustomerModel.fromEntity(Customer entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      address: entity.address,
      totalSpent: entity.totalSpent,
      lastTransactionDate: entity.lastTransactionDate,
      loyaltyPoints: entity.loyaltyPoints,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      businessId: entity.businessId,
    );
  }

  @override
  CustomerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    double? totalSpent,
    DateTime? lastTransactionDate,
    int? loyaltyPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? businessId,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalSpent: totalSpent ?? this.totalSpent,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessId: businessId ?? this.businessId,
    );
  }
}
