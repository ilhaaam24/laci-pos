import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final double totalSpent;
  final DateTime? lastTransactionDate;
  final int loyaltyPoints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? businessId;

  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.totalSpent = 0,
    this.lastTransactionDate,
    this.loyaltyPoints = 0,
    required this.createdAt,
    required this.updatedAt,
    this.businessId,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    address,
    totalSpent,
    lastTransactionDate,
    loyaltyPoints,
    createdAt,
    updatedAt,
    businessId,
  ];
}
