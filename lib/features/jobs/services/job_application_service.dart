import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/job_application_model.dart';
import '../../../config/cloudinary_config.dart';

class JobApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'job_applications';

  // Cloudinary Upload for CV
  Future<String?> uploadCVToCloudinary(PlatformFile file) async {
    try {
      final extension = file.extension?.toLowerCase();
      final isPdf = extension == 'pdf';
      final resourceType = isPdf ? 'raw' : 'image';

      const cloudName = CloudinaryConfig.cloudName;
      const uploadPreset = CloudinaryConfig.uploadPreset;

      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'job_applications/cvs';
      request.headers['X-Requested-With'] = 'XMLHttpRequest';

      final bytes = file.bytes;
      if (bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ));
      } else {
        // Fallback for mobile if bytes are null
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        print(
            'Cloudinary Upload Failed: ${response.statusCode} - $responseString');
        return null;
      }
    } catch (e) {
      print('CV upload error: $e');
      return null;
    }
  }

  // Apply for a job
  Future<void> applyForJob(JobApplicationModel application) async {
    try {
      if (application.id.isEmpty) {
        await _firestore.collection(_collectionName).add(application.toMap());
      } else {
        await _firestore
            .collection(_collectionName)
            .doc(application.id)
            .set(application.toMap());
      }
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // Get applications for a specific job (For Job Poster)
  Stream<List<JobApplicationModel>> getApplicationsForJob(
      String jobId, String posterId) {
    return _firestore
        .collection(_collectionName)
        .where('jobId', isEqualTo: jobId)
        .where('jobPosterId', isEqualTo: posterId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobApplicationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get applications by applicant (For Job Seeker)
  Stream<List<JobApplicationModel>> getMyApplications(String applicantId) {
    return _firestore
        .collection(_collectionName)
        .where('applicantId', isEqualTo: applicantId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobApplicationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update application status
  Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(applicationId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  // Check if user has already applied
  Future<bool> hasAlreadyApplied(String jobId, String applicantId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('jobId', isEqualTo: jobId)
          .where('applicantId', isEqualTo: applicantId)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check application status: $e');
    }
  }
}
