import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
      address: data['address'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
