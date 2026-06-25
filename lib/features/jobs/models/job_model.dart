import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String jobTitle;
  final String company;
  final String description;
  final String location;
  final String salary;
  final String jobType;
  final String category;
  final DateTime lastDate;
  final String postedBy;
  final String postedByName;
  final DateTime createdAt;
  final bool isActive;

  JobModel({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.description,
    required this.location,
    required this.salary,
    required this.jobType,
    required this.category,
    required this.lastDate,
    required this.postedBy,
    required this.postedByName,
    required this.createdAt,
    required this.isActive,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JobModel(
      id: documentId,
      jobTitle: map['jobTitle'] ?? map['title'] ?? '',
      company: map['company'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      salary: map['salary'] ?? '',
      jobType: map['jobType'] ?? '',
      category: map['category'] ?? '',
      lastDate: (map['lastDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      postedBy: map['postedBy'] ?? '',
      postedByName: map['postedByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobTitle': jobTitle,
      'company': company,
      'description': description,
      'location': location,
      'salary': salary,
      'jobType': jobType,
      'category': category,
      'lastDate': Timestamp.fromDate(lastDate),
      'postedBy': postedBy,
      'postedByName': postedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}
