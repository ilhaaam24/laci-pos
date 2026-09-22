import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/business_entity.dart';

class BusinessInfoModel extends BusinessInfo {
  const BusinessInfoModel({
    required super.id,
    required super.businessName,
    super.address,
    super.phone,
    super.email,
    super.logoUrl,
    super.qrisUrl,
    required super.createdAt,
    required super.updatedAt,
    super.isTaxEnabled = false,
    super.taxRate = 0.0,
    super.taxName = 'Pajak',
    super.isServiceChargeEnabled = false,
    super.serviceChargeRate = 0.0,
    super.isPriceInclusiveTax = false,
  });

  factory BusinessInfoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessInfoModel(
      id: doc.id,
      businessName: data['businessName'] ?? '',
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      logoUrl: data['logoUrl'],
      qrisUrl: data['qrisUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isTaxEnabled: data['isTaxEnabled'] ?? false,
      taxRate: (data['taxRate'] ?? 0.0).toDouble(),
      taxName: data['taxName'] ?? 'Pajak',
      isServiceChargeEnabled: data['isServiceChargeEnabled'] ?? false,
      serviceChargeRate: (data['serviceChargeRate'] ?? 0.0).toDouble(),
      isPriceInclusiveTax: data['isPriceInclusiveTax'] ?? false,
    );
  }

  factory BusinessInfoModel.fromEntity(BusinessInfo entity) {
    return BusinessInfoModel(
      id: entity.id,
      businessName: entity.businessName,
      address: entity.address,
      phone: entity.phone,
      email: entity.email,
      logoUrl: entity.logoUrl,
      qrisUrl: entity.qrisUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isTaxEnabled: entity.isTaxEnabled,
      taxRate: entity.taxRate,
      taxName: entity.taxName,
      isServiceChargeEnabled: entity.isServiceChargeEnabled,
      serviceChargeRate: entity.serviceChargeRate,
      isPriceInclusiveTax: entity.isPriceInclusiveTax,
    );
  }

  BusinessInfo toEntity() {
    return BusinessInfo(
      id: id,
      businessName: businessName,
      address: address,
      phone: phone,
      email: email,
      logoUrl: logoUrl,
      qrisUrl: qrisUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isTaxEnabled: isTaxEnabled,
      taxRate: taxRate,
      taxName: taxName,
      isServiceChargeEnabled: isServiceChargeEnabled,
      serviceChargeRate: serviceChargeRate,
      isPriceInclusiveTax: isPriceInclusiveTax,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessName': businessName,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'qrisUrl': qrisUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isTaxEnabled': isTaxEnabled,
      'taxRate': taxRate,
      'taxName': taxName,
      'isServiceChargeEnabled': isServiceChargeEnabled,
      'serviceChargeRate': serviceChargeRate,
      'isPriceInclusiveTax': isPriceInclusiveTax,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'qrisUrl': qrisUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isTaxEnabled': isTaxEnabled,
      'taxRate': taxRate,
      'taxName': taxName,
      'isServiceChargeEnabled': isServiceChargeEnabled,
      'serviceChargeRate': serviceChargeRate,
      'isPriceInclusiveTax': isPriceInclusiveTax,
    };
  }

  factory BusinessInfoModel.fromJson(Map<String, dynamic> json) {
    return BusinessInfoModel(
      id: json['id'] ?? '',
      businessName: json['businessName'] ?? '',
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      logoUrl: json['logoUrl'],
      qrisUrl: json['qrisUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isTaxEnabled: json['isTaxEnabled'] ?? false,
      taxRate: (json['taxRate'] ?? 0.0).toDouble(),
      taxName: json['taxName'] ?? 'Pajak',
      isServiceChargeEnabled: json['isServiceChargeEnabled'] ?? false,
      serviceChargeRate: (json['serviceChargeRate'] ?? 0.0).toDouble(),
      isPriceInclusiveTax: json['isPriceInclusiveTax'] ?? false,
    );
  }
}
