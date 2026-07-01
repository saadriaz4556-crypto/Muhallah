import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class MarketplaceService {
  MarketplaceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> uploadImageToCloudinary(File image) async {
    const cloudName = 'drposqmf0';
    const uploadPreset = 'flutter_uploads';

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.headers['X-Requested-With'] = 'XMLHttpRequest';

    final bytes = await image.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: image.path.split('/').last.isNotEmpty
          ? image.path.split('/').last
          : 'upload.jpg',
    ));

    try {
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'];
        if (secureUrl is String && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }

      throw Exception(
        'Cloudinary upload failed: ${response.statusCode} - $responseString',
      );
    } catch (e) {
      throw Exception('Cloudinary upload error: $e');
    }
  }

  Future<void> submitListing({
    required Map<String, dynamic> fields,
    File? image,
  }) async {
    final user = _auth.currentUser;
    final userId = user?.uid ?? 'anonymous';
    final userName = user?.displayName ?? user?.email ?? 'Anonymous User';

    String imageUrl = '';
    if (image != null) {
      try {
        imageUrl = await uploadImageToCloudinary(image);
      } catch (_) {
        imageUrl = '';
      }
    }

    final listingData = {
      ...fields,
      'imageUrl': imageUrl,
      'userId': userId,
      'userName': fields['userName'] ?? userName,
      'timestamp': FieldValue.serverTimestamp(),
      'isFeatured': false,
      'isEndingSoon': false,
    };

    await _firestore.collection('marketplace').add(listingData);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listingStream() {
    return _firestore
        .collection('marketplace')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
