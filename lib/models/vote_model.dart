import 'package:cloud_firestore/cloud_firestore.dart';

class VoteModel {
  final String voteId;
  final String pollId;
  final String? userId; // Null if isAnonymous is true
  final List<String> selectedOptions;
  final DateTime votedAt;

  VoteModel({
    required this.voteId,
    required this.pollId,
    this.userId,
    required this.selectedOptions,
    required this.votedAt,
  });

  factory VoteModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VoteModel(
      voteId: doc.id,
      pollId: data['pollId'] ?? '',
      userId: data['userId'],
      selectedOptions: List<String>.from(data['selectedOptions'] ?? []),
      votedAt: (data['votedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pollId': pollId,
      'userId': userId,
      'selectedOptions': selectedOptions,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }
}
