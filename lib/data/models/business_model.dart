import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessInfoModel {
  final String id;
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessInfoModel({
    required this.id,
    required this.businessName,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
