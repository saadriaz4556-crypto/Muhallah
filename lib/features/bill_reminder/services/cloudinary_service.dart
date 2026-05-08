import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../config/cloudinary_config.dart';

class CloudinaryService {
  
  /// Upload bill image to Cloudinary (EXACT SAME METHOD AS registration_screen.dart)
  static Future<String?> uploadBillImage(XFile file) async {
    final url = Uri.parse(CloudinaryConfig.uploadUrl);

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    request.headers['X-Requested-With'] = 'XMLHttpRequest';

    // Universally use bytes for upload (Works on Web & Mobile)
    try {
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ));

      debugPrint('📤 Starting Cloudinary upload for ${file.name}...');
      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'];
        debugPrint('✅ Cloudinary Upload Success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('❌ Cloudinary Upload Failed: ${response.statusCode} - $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Cloudinary Upload Error: $e');
      return null;
    }
  }
}
