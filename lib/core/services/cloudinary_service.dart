import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final ImagePicker _picker = ImagePicker();
  Future<String> uploadImage(ImageSource source) async {
    // Pick image
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return '';
    }

    File imageFile = File(pickedFile.path);

    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split("/").last,
        ),
        'upload_preset': 'product_pos',
      });

      final response = await Dio().post(
        'https://api.cloudinary.com/v1_1/dxxdslebo/image/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        // Upload successful
        final imageUrl = response.data['secure_url'];
        return imageUrl;
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }
}
