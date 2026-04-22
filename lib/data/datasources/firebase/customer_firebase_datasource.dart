import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/data/models/customer_mode.dart';
import '../../../core/constants/firebase_collections.dart';

abstract class CustomerFirebaseDataSource {
  Stream<List<CustomerModel>> getCustomers();
  Future<CustomerModel> getCustomerById(String id);
  Future<String> createCustomer(CustomerModel customer);
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
}

class CustomerFirebaseDataSourceImpl implements CustomerFirebaseDataSource {
  final FirebaseFirestore firestore;

  CustomerFirebaseDataSourceImpl({required this.firestore});

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.customers);

  @override
  Stream<List<CustomerModel>> getCustomers() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => CustomerModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) throw Exception('Customer not found');
    return CustomerModel.fromFirestore(doc);
  }

  @override
  Future<String> createCustomer(CustomerModel customer) async {
    final docRef = await _collection.add(customer.toFirestore());
    return docRef.id;
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    await _collection.doc(customer.id).update(customer.toFirestore());
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _collection.doc(id).delete();
  }
}
