import 'package:equatable/equatable.dart';

class BusinessInfo extends Equatable {
  final String id;
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? qrisUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessInfo({
    required this.id,
    required this.businessName,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.qrisUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessInfo copyWith({
    String? id,
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? qrisUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessInfo(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      qrisUrl: qrisUrl ?? this.qrisUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    businessName,
    address,
    phone,
    email,
    logoUrl,
    qrisUrl,
    createdAt,
    updatedAt,
  ];
}
