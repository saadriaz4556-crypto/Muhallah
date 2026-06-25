import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String applicantPhone;
  final String cvDownloadUrl;
  final String cvFileName;
  final String coverLetter;
  final String status;
  final DateTime appliedAt;
  final String jobPosterId;

  JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantPhone,
    required this.cvDownloadUrl,
    required this.cvFileName,
    this.coverLetter = '',
    this.status = 'Pending',
    required this.appliedAt,
    required this.jobPosterId,
  });

  factory JobApplicationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JobApplicationModel(
      id: documentId,
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      company: map['company'] ?? '',
      applicantId: map['applicantId'] ?? '',
      applicantName: map['applicantName'] ?? '',
      applicantEmail: map['applicantEmail'] ?? '',
      applicantPhone: map['applicantPhone'] ?? '',
      cvDownloadUrl: map['cvDownloadUrl'] ?? '',
      cvFileName: map['cvFileName'] ?? '',
      coverLetter: map['coverLetter'] ?? '',
      status: map['status'] ?? 'Pending',
      appliedAt: (map['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      jobPosterId: map['jobPosterId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'company': company,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'applicantPhone': applicantPhone,
      'cvDownloadUrl': cvDownloadUrl,
      'cvFileName': cvFileName,
      'coverLetter': coverLetter,
      'status': status,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'jobPosterId': jobPosterId,
    };
  }
}
