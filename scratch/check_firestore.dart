import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('transactions').get();
  print('Total Transactions: ${snapshot.docs.length}');
  for (var doc in snapshot.docs) {
    print('Transaction: ${doc.id} - ${doc.data()}');
  }
}
