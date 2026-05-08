import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class JobStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload CV (PDF)
  Future<String> uploadCV({
    required String jobId,
    required String applicantId,
    required File cvFile,
  }) async {
    try {
      // Validate file extension
      final extension = path.extension(cvFile.path).toLowerCase();
      if (extension != '.pdf') {
        throw Exception('Only PDF files are allowed');
      }

      // Check file size (5MB limit)
      final size = await cvFile.length();
      if (size > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit');
      }

      // Create storage reference
      final fileName = 'cv_$applicantId.pdf';
      final ref = _storage.ref().child('job_applications/$jobId/$applicantId/$fileName');

      // Upload file with metadata
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
      );

      final uploadTask = await ref.putFile(cvFile, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload CV: $e');
    }
  }

  // Get CV download URL (useful if we only store path)
  Future<String> getCVUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get CV URL: $e');
    }
  }
}
