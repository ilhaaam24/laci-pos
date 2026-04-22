import 'package:equatable/equatable.dart';

class BusinessInfo extends Equatable {
  final String id;
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessInfo({
    required this.id,
    required this.businessName,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    businessName,
    address,
    phone,
    email,
    logoUrl,
    createdAt,
    updatedAt,
  ];
}
