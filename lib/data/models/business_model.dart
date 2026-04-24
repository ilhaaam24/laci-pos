import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessInfoModel {
  final String id;
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? qrisUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessInfoModel({
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
}
