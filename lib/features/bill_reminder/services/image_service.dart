import 'dart:io';
import 'package:image_picker/image_picker.dart';
import './cloudinary_service.dart';

class ImageService {
  final CloudinaryService _cloudinaryService = CloudinaryService();

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
      final url = await _cloudinaryService.uploadBillImage(imageFile);
      return url;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  /// Delete from Cloudinary
  Future<bool> deleteImageFromCloudinary(String? imageUrl) async {
    if (imageUrl == null) return true;
    return await _cloudinaryService.deleteBillImage(imageUrl);
  }

  /// Get thumbnail URL from Cloudinary
  String? getThumbnailUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    return _cloudinaryService.getThumbnailUrl(imageUrl);
  }
}
