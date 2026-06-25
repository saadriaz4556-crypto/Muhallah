import 'package:cloud_firestore/cloud_firestore.dart';

class PollModel {
  final String pollId;
  final String title;
  final String description;
  final List<PollOption> options;
  final String pollType; // "single" or "multiple"
  final DateTime startDate;
  final DateTime endDate;
  final String targetAudience;
  final bool isAnonymous;
  final String createdBy;
  final DateTime createdAt;
  final String status; // "active" or "completed"

  PollModel({
    required this.pollId,
    required this.title,
    required this.description,
    required this.options,
    required this.pollType,
    required this.startDate,
    required this.endDate,
    required this.targetAudience,
    required this.isAnonymous,
    required this.createdBy,
    required this.createdAt,
    required this.status,
  });

  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PollModel(
      pollId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      options: (data['options'] as List? ?? [])
          .map((o) => PollOption.fromMap(o))
          .toList(),
      pollType: data['pollType'] ?? 'single',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      targetAudience: data['targetAudience'] ?? 'All Residents',
      isAnonymous: data['isAnonymous'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'options': options.map((o) => o.toMap()).toList(),
      'pollType': pollType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetAudience': targetAudience,
      'isAnonymous': isAnonymous,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}

class PollOption {
  final String optionId;
  final String text;
  final int voteCount;

  PollOption({
    required this.optionId,
    required this.text,
    required this.voteCount,
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      optionId: map['optionId'] ?? '',
      text: map['text'] ?? '',
      voteCount: map['voteCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'optionId': optionId,
      'text': text,
      'voteCount': voteCount,
    };
  }
}
