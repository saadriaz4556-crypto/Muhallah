import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ComplaintService {
  ComplaintService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> uploadImageToCloudinary(XFile image) async {
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
      filename: image.name.isNotEmpty ? image.name : 'upload.jpg',
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

  Future<void> submitComplaint({
    required Map<String, dynamic> fields,
    XFile? image,
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

    final complaintData = {
      ...fields,
      'imageUrl': imageUrl,
      'status': fields['status'] ?? 'pending',
      'upvotes': fields['upvotes'] ?? 0,
      'comments': fields['comments'] ?? 0,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': userId,
      'userName': fields['userName'] ?? userName,
    };

    await _firestore.collection('complaints').add(complaintData);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> complaintStream({
    String? status,
    String? userId,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('complaints')
        .orderBy('timestamp', descending: true);

    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots();
  }

  Stream<int> complaintsCount() {
    return complaintStream().map((snapshot) => snapshot.size);
  }
}
