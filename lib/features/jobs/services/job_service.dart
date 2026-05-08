import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'jobs';

  // Create a new job
  Future<void> createJob(JobModel job) async {
    try {
      await _firestore.collection(_collectionName).doc(job.id).set(job.toMap());
    } catch (e) {
      throw Exception('Failed to create job: $e');
    }
  }

  // Get all jobs (for listing)
  Stream<List<JobModel>> getJobs() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get jobs posted by specific user
  Stream<List<JobModel>> getJobsByPoster(String posterId) {
    return _firestore
        .collection(_collectionName)
        .where('posterId', isEqualTo: posterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get single job details
  Future<JobModel?> getJobById(String jobId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(jobId).get();
      if (doc.exists && doc.data() != null) {
        return JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get job: $e');
    }
  }

  // Update a job
  Future<void> updateJob(JobModel job) async {
    try {
      await _firestore.collection(_collectionName).doc(job.id).update(job.toMap());
    } catch (e) {
      throw Exception('Failed to update job: $e');
    }
  }

  // Delete a job
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection(_collectionName).doc(jobId).delete();
    } catch (e) {
      throw Exception('Failed to delete job: $e');
    }
  }
}
