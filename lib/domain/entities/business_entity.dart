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
  final bool isTaxEnabled;
  final double taxRate;
  final String taxName;
  final bool isServiceChargeEnabled;
  final double serviceChargeRate;
  final bool isPriceInclusiveTax;

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
    this.isTaxEnabled = false,
    this.taxRate = 0.0,
    this.taxName = 'Pajak',
    this.isServiceChargeEnabled = false,
    this.serviceChargeRate = 0.0,
    this.isPriceInclusiveTax = false,
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
    bool? isTaxEnabled,
    double? taxRate,
    String? taxName,
    bool? isServiceChargeEnabled,
    double? serviceChargeRate,
    bool? isPriceInclusiveTax,
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
      isTaxEnabled: isTaxEnabled ?? this.isTaxEnabled,
      taxRate: taxRate ?? this.taxRate,
      taxName: taxName ?? this.taxName,
      isServiceChargeEnabled:
          isServiceChargeEnabled ?? this.isServiceChargeEnabled,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      isPriceInclusiveTax: isPriceInclusiveTax ?? this.isPriceInclusiveTax,
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
    isTaxEnabled,
    taxRate,
    taxName,
    isServiceChargeEnabled,
    serviceChargeRate,
    isPriceInclusiveTax,
  ];
}
