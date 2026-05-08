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
    );
  }
}
