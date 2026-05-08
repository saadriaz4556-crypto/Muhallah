import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplicationModel {
  final String id;
  final String jobId;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String applicantPhone;
  final String cvUrl; // Firebase Storage URL or Path
  final String? coverLetter;
  final String status; // Pending, Shortlisted, Rejected
  final DateTime appliedAt;

  JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantPhone,
    required this.cvUrl,
    this.coverLetter,
    this.status = 'Pending',
    required this.appliedAt,
  });

  factory JobApplicationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JobApplicationModel(
      id: documentId,
      jobId: map['jobId'] ?? '',
      applicantId: map['applicantId'] ?? '',
      applicantName: map['applicantName'] ?? '',
      applicantEmail: map['applicantEmail'] ?? '',
      applicantPhone: map['applicantPhone'] ?? '',
      cvUrl: map['cvUrl'] ?? '',
      coverLetter: map['coverLetter'],
      status: map['status'] ?? 'Pending',
      appliedAt: (map['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'applicantPhone': applicantPhone,
      'cvUrl': cvUrl,
      'coverLetter': coverLetter,
      'status': status,
      'appliedAt': Timestamp.fromDate(appliedAt),
    };
  }
}
