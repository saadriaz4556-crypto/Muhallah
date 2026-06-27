import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LostFoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Reports a lost item to Firestore and returns the document reference ID
  Future<String> reportLostItem({
    required String itemName,
    required String category,
    required String description,
    required String lastSeenLocation,
    required String imageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to report an item');
    }

    final reporterName = currentUser.displayName?.isNotEmpty == true
        ? currentUser.displayName!
        : (currentUser.email?.split('@').first ?? 'Resident');

    final docRef = await _firestore.collection('lost_found_reports').add({
      'itemName': itemName,
      'category': category,
      'description': description,
      'lastSeenLocation': lastSeenLocation,
      'imageUrl': imageUrl,
      'type': 'lost',
      'reportedBy': currentUser.uid,
      'reporterName': reporterName,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
    });
    
    return docRef.id;
  }

  /// Stream of all lost items sorted by timestamp descending
  Stream<QuerySnapshot> getLostItemsStream() {
    return _firestore
        .collection('lost_found_reports')
        .where('type', isEqualTo: 'lost')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Stream of active lost items sorted by timestamp descending
  Stream<QuerySnapshot> getActiveLostItemsStream() {
    return _firestore
        .collection('lost_found_reports')
        .where('type', isEqualTo: 'lost')
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
