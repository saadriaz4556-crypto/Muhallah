import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_application_model.dart';

class JobApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'job_applications';

  // Apply for a job
  Future<void> applyForJob(JobApplicationModel application) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(application.id)
          .set(application.toMap());
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // Get applications for a specific job (For Job Poster)
  Stream<List<JobApplicationModel>> getApplicationsForJob(String jobId) {
    return _firestore
        .collection(_collectionName)
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
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
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobApplicationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update application status
  Future<void> updateApplicationStatus(String applicationId, String status) async {
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
