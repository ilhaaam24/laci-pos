import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
  }

  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase not initialized');
    }
    return _firestore!;
  }

  static FirebaseStorage get storage {
    if (_storage == null) {
      throw Exception('Firebase Storage not initialized');
    }
    return _storage!;
  }
}
