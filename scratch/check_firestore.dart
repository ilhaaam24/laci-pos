import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('transactions').limit(5).get();

  print('Found ${snapshot.docs.length} transactions');
  for (var doc in snapshot.docs) {
    print(
      'ID: ${doc.id}, businessId: ${doc.data()['businessId']}, totalAmount: ${doc.data()['totalAmount']}',
    );
  }
}
