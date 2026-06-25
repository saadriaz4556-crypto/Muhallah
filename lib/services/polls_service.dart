import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poll_model.dart';
import '../models/vote_model.dart';

class PollsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new poll
  Future<void> createPoll(PollModel poll) async {
    await _firestore.collection('polls').add(poll.toMap());
  }

  // Get active polls
  Stream<List<PollModel>> getActivePolls() {
    return _firestore
        .collection('polls')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PollModel.fromFirestore(doc)).toList());
  }

  // Get completed polls
  Stream<List<PollModel>> getCompletedPolls() {
    return _firestore
        .collection('polls')
        .where('status', isEqualTo: 'completed')
        .orderBy('endDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PollModel.fromFirestore(doc)).toList());
  }

  // Cast a vote
  Future<void> castVote(String pollId, List<String> selectedOptionIds, bool isAnonymous) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Check if user already voted
    final alreadyVoted = await hasUserVoted(pollId);
    if (alreadyVoted) throw Exception("Already voted");

    // 2. Save vote to poll_votes
    final vote = VoteModel(
      voteId: '',
      pollId: pollId,
      userId: isAnonymous ? null : user.uid,
      selectedOptions: selectedOptionIds,
      votedAt: DateTime.now(),
    );

    await _firestore.collection('poll_votes').add(vote.toMap());

    // 3. Update vote counts in poll document
    // Note: In a real production app, this should be a transaction or a cloud function to prevent race conditions.
    final pollDoc = await _firestore.collection('polls').doc(pollId).get();
    if (pollDoc.exists) {
      final poll = PollModel.fromFirestore(pollDoc);
      final updatedOptions = poll.options.map((option) {
        if (selectedOptionIds.contains(option.optionId)) {
          return PollOption(
            optionId: option.optionId,
            text: option.text,
            voteCount: option.voteCount + 1,
          );
        }
        return option;
      }).toList();

      await _firestore.collection('polls').doc(pollId).update({
        'options': updatedOptions.map((o) => o.toMap()).toList(),
      });
    }
  }

  // Check if user has voted on a poll
  Future<bool> hasUserVoted(String pollId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore
        .collection('poll_votes')
        .where('pollId', isEqualTo: pollId)
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Get user's vote for a specific poll
  Future<VoteModel?> getUserVote(String pollId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('poll_votes')
        .where('pollId', isEqualTo: pollId)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return VoteModel.fromFirestore(snapshot.docs.first);
  }

  // Get all polls user has voted on
  Stream<List<Map<String, dynamic>>> getMyVotes() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('poll_votes')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> results = [];
      for (var doc in snapshot.docs) {
        final vote = VoteModel.fromFirestore(doc);
        final pollDoc = await _firestore.collection('polls').doc(vote.pollId).get();
        if (pollDoc.exists) {
          final poll = PollModel.fromFirestore(pollDoc);
          results.add({
            'poll': poll,
            'vote': vote,
          });
        }
      }
      return results;
    });
  }
  
  // Get user role
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data()?['isAdmin'] ?? false;
    }
    return false;
  }
}
