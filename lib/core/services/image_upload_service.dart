import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ImageUploadService {
  final FirebaseStorage _storage;
  final ImagePicker _picker = ImagePicker();

  ImageUploadService(this._storage);

  Future<String?> pickAndUploadImage({
    required String folder,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Upload to Firebase Storage
      final file = File(pickedFile.path);
      final fileName = '${const Uuid().v4()}.jpg';
      final ref = _storage.ref().child('$folder/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
