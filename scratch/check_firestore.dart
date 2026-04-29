import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  try {
    final batch = firestore.batch();

    // Ambil dokumen dari koleksi 'products'
    final productsSnapshot = await firestore.collection('products').get();

    for (var productDoc in productsSnapshot.docs) {
      final currentStock = productDoc['stock'];

      if (currentStock is! int || currentStock < 0) {
        batch.update(productDoc.reference, {
          'stock': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  } catch (e) {
    print(e);
  }
}
