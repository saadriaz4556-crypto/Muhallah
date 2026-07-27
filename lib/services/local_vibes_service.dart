import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:muhallah/features/bill_reminder/services/cloudinary_service.dart';

class LocalVibesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? 'guest';

  // --- POSTS ---

  Stream<List<Map<String, dynamic>>> getPostsStream() {
    return _firestore
        .collection('local_vibes_posts')
        .orderBy('expires_at', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((post) {
        final isDeleted = post['is_deleted'] == true;
        final expiresAt = (post['expires_at'] as Timestamp?)?.toDate();
        if (isDeleted) return false;
        if (expiresAt == null) return false;
        return expiresAt.isAfter(now);
      }).toList();
    });
  }

  Future<Map<String, dynamic>> checkDailyLimits() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection('local_vibes_posts')
        .where('user_id', isEqualTo: currentUserId)
        .get();

    int jokes = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = (data['created_at'] as Timestamp?)?.toDate();
      if (createdAt != null && createdAt.isAfter(startOfDay)) {
        final type = data['post_type'] as String?;
        if (type == 'joke') jokes++;
      }
    }

    return {
      'jokesLeft': (5 - jokes).clamp(0, 5),
    };
  }

  Future<String?> uploadToCloudinary(File file) async {
    // Use the same CloudinaryService as registration_screen.dart
    final xFile = XFile(file.path);
    return await CloudinaryService.uploadBillImage(xFile);
  }

  Future<bool> createPost({
    required String postType,
    String? contentText,
    File? mediaFile,
  }) async {
    try {
      final docRef = _firestore.collection('local_vibes_posts').doc();

      String? mediaUrl;
      if (mediaFile != null) {
        mediaUrl = await uploadToCloudinary(mediaFile);
        if (mediaUrl == null) {
          throw Exception(
              'Image upload to Cloudinary failed. Check your internet connection.');
        }
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      await docRef.set({
        'user_id': currentUserId,
        'post_type': postType,
        'content_text': contentText,
        'media_url': mediaUrl,
        'likes_count': 0,
        'haha_count': 0,
        'comments_count': 0,
        'created_at': Timestamp.fromDate(now),
        'expires_at': Timestamp.fromDate(expiresAt),
        'is_deleted': false,
      });

      await _createAnnouncementMirror(
        localPostId: docRef.id,
        postType: postType,
        contentText: contentText,
        mediaUrl: mediaUrl,
      );

      return true;
    } catch (e) {
      debugPrint('Create Post Error: $e');
      rethrow; // Re-throw so UI catch block shows the real error
    }
  }

  Future<void> _createAnnouncementMirror({
    required String localPostId,
    required String postType,
    String? contentText,
    String? mediaUrl,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final authorName = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : 'Resident';

    await _firestore.collection('announcements').add({
      'postType': 'local_vibe',
      'headline':
          postType == 'photo' ? 'Shared a photo 📸' : 'Shared a funny vibe 😄',
      'description': contentText ?? '',
      'imageUrl': mediaUrl ?? '',
      'authorName': authorName,
      'authorId': currentUserId,
      'createdAt': Timestamp.now(),
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'pinned': false,
      'verified': false,
      'sourceCollection': 'local_vibes_posts',
      'sourcePostId': localPostId,
    });
  }

  Future<void> _deleteAnnouncementMirror(String localPostId) async {
    final snapshot = await _firestore
        .collection('announcements')
        .where('sourceCollection', isEqualTo: 'local_vibes_posts')
        .where('sourcePostId', isEqualTo: localPostId)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var announcementDoc in snapshot.docs) {
      batch.delete(announcementDoc.reference);
    }
    await batch.commit();
  }

  Future<void> deletePost(String postId, {String? imageUrl}) async {
    // Soft-delete: mark as deleted in Firestore
    // Cloudinary deletion requires server-side Admin API key (not done from client)
    await _firestore.collection('local_vibes_posts').doc(postId).update({
      'is_deleted': true,
    });

    await _deleteAnnouncementMirror(postId);
  }

  // --- REACTIONS ---

  Future<void> toggleReaction(String postId, String reactionType) async {
    final reactionRef = _firestore
        .collection('local_vibes_reactions')
        .doc('${postId}_$currentUserId');

    final postRef = _firestore.collection('local_vibes_posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final reactionDoc = await transaction.get(reactionRef);
      final postDoc = await transaction.get(postRef);

      if (!postDoc.exists) return;

      int likes = postDoc.data()?['likes_count'] ?? 0;
      int hahas = postDoc.data()?['haha_count'] ?? 0;

      if (reactionDoc.exists) {
        final currentReaction = reactionDoc.data()?['reaction_type'];

        // Remove old reaction
        if (currentReaction == 'like') likes--;
        if (currentReaction == 'haha') hahas--;

        if (currentReaction == reactionType) {
          // Un-react completely
          transaction.delete(reactionRef);
        } else {
          // Change reaction
          if (reactionType == 'like') likes++;
          if (reactionType == 'haha') hahas++;
          transaction.update(reactionRef, {'reaction_type': reactionType});
        }
      } else {
        // New reaction
        if (reactionType == 'like') likes++;
        if (reactionType == 'haha') hahas++;
        transaction.set(reactionRef, {
          'post_id': postId,
          'user_id': currentUserId,
          'reaction_type': reactionType,
          'created_at': Timestamp.now(),
        });
      }

      transaction.update(postRef, {
        'likes_count': likes,
        'haha_count': hahas,
      });
    });
  }

  // --- COMMENTS ---

  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) {
    return _firestore
        .collection('local_vibes_comments')
        .where('post_id', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      comments.sort((a, b) {
        final aDate = (a['created_at'] as Timestamp?)?.toDate();
        final bDate = (b['created_at'] as Timestamp?)?.toDate();
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      return comments;
    });
  }

  Future<void> addComment(String postId, String text) async {
    if (text.isEmpty || text.length > 150) return;

    final batch = _firestore.batch();

    final commentRef = _firestore.collection('local_vibes_comments').doc();
    batch.set(commentRef, {
      'post_id': postId,
      'user_id': currentUserId,
      'comment_text': text,
      'created_at': Timestamp.now(),
    });

    final postRef = _firestore.collection('local_vibes_posts').doc(postId);
    batch.update(postRef, {'comments_count': FieldValue.increment(1)});

    await batch.commit();
  }

  // --- REPORT ---
  Future<void> reportPost(String postId) async {
    await _firestore.collection('local_vibes_reports').add({
      'post_id': postId,
      'reporter_id': currentUserId,
      'created_at': Timestamp.now(),
    });
  }
}
