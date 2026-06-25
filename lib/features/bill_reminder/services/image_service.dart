import 'dart:io';
import 'package:image_picker/image_picker.dart';
import './cloudinary_service.dart';

class ImageService {
  Future<File?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) return File(image.path);
    } catch (e) {
      print('Camera error: $e');
    }
    return null;
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) return File(image.path);
    } catch (e) {
      print('Gallery error: $e');
    }
    return null;
  }

  /// Upload to Cloudinary and return URL
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    try {
      print('📤 Uploading image to Cloudinary...');
      // Convert File to XFile for CloudinaryService static method
      final xFile = XFile(imageFile.path);
      final url = await CloudinaryService.uploadBillImage(xFile);
      return url;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  /// Delete from Cloudinary — not supported by CloudinaryService; returns true to avoid blocking UI
  Future<bool> deleteImageFromCloudinary(String? imageUrl) async {
    if (imageUrl == null) return true;
    // CloudinaryService does not expose a delete method; deletion must be done server-side
    return true;
  }

  /// Get a thumbnail variant URL by appending Cloudinary transformation parameters
  String? getThumbnailUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    // Insert w_200,h_200,c_thumb transformation into the Cloudinary URL
    return imageUrl.replaceFirst('/upload/', '/upload/w_200,h_200,c_thumb/');
  }
}
