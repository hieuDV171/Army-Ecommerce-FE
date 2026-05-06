import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
    _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  // Upload image file to Cloudinary and return secure URL
  Future<String> uploadImageFile({
    required File file,
    String folder = 'users',
  }) async {
    try {
      final res = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return res.secureUrl;
    } on CloudinaryException catch (e) {
      // e.message, e.request
      throw Exception('Cloudinary upload error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error uploading to Cloudinary: $e');
    }
  }
}