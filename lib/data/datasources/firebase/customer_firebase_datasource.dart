import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/core/constants/firebase_collections.dart';
import 'package:laci/data/models/customer_model.dart';

import '../../../core/services/session_service.dart';

abstract class CustomerFirebaseDataSource {
  Stream<List<CustomerModel>> getCustomers();
  Future<CustomerModel> getCustomerById(String id);
  Future<String> createCustomer(CustomerModel customer);
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
}

class CustomerFirebaseDataSourceImpl implements CustomerFirebaseDataSource {
  final FirebaseFirestore firestore;
  final SessionService sessionService;

  CustomerFirebaseDataSourceImpl({
    required this.firestore,
    required this.sessionService,
  });

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.customers);

  String get _businessId => sessionService.businessId ?? '';

  @override
  Stream<List<CustomerModel>> getCustomers() {
    return _collection
        .where('businessId', isEqualTo: _businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CustomerModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) throw Exception('Customer not found');
    final customer = CustomerModel.fromFirestore(doc);
    if (customer.businessId != _businessId) {
      throw Exception('Unauthorized access to customer');
    }
    return customer;
  }

  @override
  Future<String> createCustomer(CustomerModel customer) async {
    if (_businessId.isEmpty) {
      throw Exception('Business ID is missing. Please re-login.');
    }
    final data = customer.toFirestore();
    data['businessId'] = _businessId;
    final docRef = await _collection.add(data);
    return docRef.id;
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    if (_businessId.isEmpty) {
      throw Exception('Business ID is missing. Please re-login.');
    }
    final data = customer.toFirestore();
    data['businessId'] = _businessId;
    await _collection.doc(customer.id).update(data);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _collection.doc(id).delete();
  }
}
