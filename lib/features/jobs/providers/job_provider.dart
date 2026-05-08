import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/job_model.dart';
import '../models/job_application_model.dart';
import '../services/job_service.dart';
import '../services/job_application_service.dart';
import '../services/job_storage_service.dart';

class JobProvider with ChangeNotifier {
  final JobService _jobService = JobService();
  final JobApplicationService _applicationService = JobApplicationService();
  final JobStorageService _storageService = JobStorageService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // --- JOB METHODS ---

  Future<bool> createJob({
    required String posterId,
    required String title,
    required String description,
    required String companyName,
    required String location,
    required String salaryRange,
    required String jobType,
    required String category,
    required DateTime deadline,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final String id = const Uuid().v4();
      final job = JobModel(
        id: id,
        posterId: posterId,
        title: title,
        description: description,
        companyName: companyName,
        location: location,
        salaryRange: salaryRange,
        jobType: jobType,
        category: category,
        deadline: deadline,
        createdAt: DateTime.now(),
      );
      await _jobService.createJob(job);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Stream<List<JobModel>> getAllJobs() {
    return _jobService.getJobs();
  }

  Stream<List<JobModel>> getMyPostedJobs(String posterId) {
    return _jobService.getJobsByPoster(posterId);
  }

  // --- APPLICATION METHODS ---

  Future<bool> applyForJob({
    required String jobId,
    required String applicantId,
    required String applicantName,
    required String applicantEmail,
    required String applicantPhone,
    required File cvFile,
    String? coverLetter,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      // 1. Check if already applied
      final hasApplied = await _applicationService.hasAlreadyApplied(jobId, applicantId);
      if (hasApplied) {
        throw Exception('You have already applied for this job.');
      }

      // 2. Upload CV
      final cvUrl = await _storageService.uploadCV(
        jobId: jobId,
        applicantId: applicantId,
        cvFile: cvFile,
      );

      // 3. Save application
      final applicationId = const Uuid().v4();
      final application = JobApplicationModel(
        id: applicationId,
        jobId: jobId,
        applicantId: applicantId,
        applicantName: applicantName,
        applicantEmail: applicantEmail,
        applicantPhone: applicantPhone,
        cvUrl: cvUrl,
        coverLetter: coverLetter,
        appliedAt: DateTime.now(),
      );

      await _applicationService.applyForJob(application);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Stream<List<JobApplicationModel>> getApplicationsForJob(String jobId) {
    return _applicationService.getApplicationsForJob(jobId);
  }

  Stream<List<JobApplicationModel>> getMyApplications(String applicantId) {
    return _applicationService.getMyApplications(applicantId);
  }

  Future<bool> updateApplicationStatus(String applicationId, String status) async {
    _setLoading(true);
    _setError(null);
    try {
      await _applicationService.updateApplicationStatus(applicationId, status);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
