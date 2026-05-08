import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String posterId;
  final String title;
  final String description;
  final String companyName;
  final String location;
  final String salaryRange;
  final String jobType; // Full-time, Part-time, Freelance
  final String category;
  final DateTime deadline;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.posterId,
    required this.title,
    required this.description,
    required this.companyName,
    required this.location,
    required this.salaryRange,
    required this.jobType,
    required this.category,
    required this.deadline,
    required this.createdAt,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JobModel(
      id: documentId,
      posterId: map['posterId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      companyName: map['companyName'] ?? '',
      location: map['location'] ?? '',
      salaryRange: map['salaryRange'] ?? '',
      jobType: map['jobType'] ?? '',
      category: map['category'] ?? '',
      deadline: (map['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'posterId': posterId,
      'title': title,
      'description': description,
      'companyName': companyName,
      'location': location,
      'salaryRange': salaryRange,
      'jobType': jobType,
      'category': category,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
