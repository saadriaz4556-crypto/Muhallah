import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'announcements.dart';

class AnnouncementEntryScreen extends StatefulWidget {
  const AnnouncementEntryScreen({super.key});

  @override
  State<AnnouncementEntryScreen> createState() =>
      _AnnouncementEntryScreenState();
}

class _AnnouncementEntryScreenState extends State<AnnouncementEntryScreen> {
  final Set<String> likedAnnouncements = <String>{};
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final colors = const {
    'background': Color(0xFF252A34),
    'cardBackground': Color(0xFF2A303C),
    'surface': Color(0xFF3A4250),
    'primary': Color(0xFF08D9D6),
    'accent': Color(0xFFFF2E63),
    'textPrimary': Color(0xFFEAEAEA),
    'textSecondary': Colors.white70,
    'textTertiary': Colors.white38,
    'border': Colors.white10,
    'error': Color(0xFFFF2E63),
  };

  // Like logic matching complaint_screen.dart
  Future<void> handleLike(String docId, List<dynamic> likedByList) async {
    final docRef =
        FirebaseFirestore.instance.collection('announcements').doc(docId);

    final isLikedInList =
        currentUserId != null && likedByList.contains(currentUserId);
    final isLikedLocally = likedAnnouncements.contains(docId);

    if (isLikedInList || isLikedLocally) {
      likedAnnouncements.remove(docId);
      await docRef.update({
        'likes': FieldValue.increment(-1),
        if (currentUserId != null)
          'likedBy': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      likedAnnouncements.add(docId);
      await docRef.update({
        'likes': FieldValue.increment(1),
        if (currentUserId != null)
          'likedBy': FieldValue.arrayUnion([currentUserId]),
      });
    }
    if (mounted) setState(() {});
  }

  // Comment sheet matching complaint_screen.dart
  void _showCommentSheet(
      BuildContext context, Map<String, dynamic> announcement) {
    final commentController = TextEditingController();
    final docId = announcement['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors['cardBackground'],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments',
              style: TextStyle(
                color: colors['textPrimary'],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .doc(docId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No comments yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return SizedBox(
                  height: 220,
                  child: ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final text = d['text'] ?? d['commentText'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: colors['surface'],
                              child: const Icon(Icons.person,
                                  color: Colors.white70, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['authorName'] ?? 'Resident',
                                    style: TextStyle(
                                      color: colors['primary'],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: colors['textPrimary'],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    style: TextStyle(color: colors['textPrimary']),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(color: colors['textTertiary']),
                      filled: true,
                      fillColor: colors['surface'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final text = commentController.text.trim();
                    if (text.isEmpty) return;

                    final docRef = FirebaseFirestore.instance
                        .collection('announcements')
                        .doc(docId);

                    await docRef.collection('comments').add({
                      'text': text,
                      'authorId': FirebaseAuth.instance.currentUser?.uid ?? '',
                      'authorName': FirebaseAuth.instance.currentUser
                                  ?.displayName?.isNotEmpty ==
                              true
                          ? FirebaseAuth.instance.currentUser!.displayName!
                          : (FirebaseAuth.instance.currentUser?.email
                                  ?.split('@')
                                  .first ??
                              'Resident'),
                      'createdAt': Timestamp.now(),
                    });

                    await docRef.update({'comments': FieldValue.increment(1)});
                    commentController.clear();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors['primary'],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Delete logic matching local_vibes_screen.dart
  void _deletePost(String postId, String? imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors['background'],
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: Color(0xFFEAEAEA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFEAEAEA))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors['error']),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(postId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post deleted successfully'),
          backgroundColor: colors['error'],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $e'),
          backgroundColor: colors['error'],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors['background'],
      appBar: AppBar(
        title: const Text(
          'Community Announcements',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A6B6B),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colors['primary']),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined,
                      color: Colors.white38, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first announcement',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final allDocs = snapshot.data!.docs;
          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final postType = data['postType']?.toString().toLowerCase();
            final type = data['type']?.toString();
            const announcementTypes = {
              'General',
              'Pool',
              'Security',
              'Events'
            };

            if (postType == 'announcement') return true;
            if (type != null && announcementTypes.contains(type)) {
              return true;
            }
            return false;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined,
                      color: Colors.white38, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first announcement',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final docId = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = docId;

              final headline = data['headline'] ?? '';
              final description = data['description'] ?? '';
              final imageUrl = data['imageUrl'] ?? '';
              final type = data['type'] ?? 'General';
              final createdAt = data['createdAt'];

              final authorId = data['authorId'] ?? data['postedBy'] ?? '';
              final isOwner =
                  currentUserId != null && currentUserId == authorId;

              final likedBy = List<dynamic>.from(data['likedBy'] ?? []);
              final isLiked =
                  (currentUserId != null && likedBy.contains(currentUserId)) ||
                      likedAnnouncements.contains(docId);
              final rawLikes = data['likes'] ?? 0;
              final likesCount = (rawLikes is num) ? rawLikes.toInt() : 0;

              final rawComments = data['comments'] ?? 0;
              final commentsCount =
                  (rawComments is num) ? rawComments.toInt() : 0;

              String timeStr = '';
              if (createdAt != null) {
                final dt = (createdAt as Timestamp).toDate();
                final diff = DateTime.now().difference(dt);
                if (diff.inMinutes < 60) {
                  timeStr = '${diff.inMinutes}m ago';
                } else if (diff.inHours < 24) {
                  timeStr = '${diff.inHours}h ago';
                } else {
                  timeStr = '${diff.inDays}d ago';
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors['cardBackground'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors['primary']!
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: colors['primary'],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'By ${data['authorName'] ?? 'Resident'} • $timeStr',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 12),
                              ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _deletePost(docId, imageUrl),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: colors['error'],
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            headline,
                            style: const TextStyle(
                              color: Color(0xFFEAEAEA),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => handleLike(docId, likedBy),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isLiked
                                            ? colors['accent']
                                            : Colors.white38,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${likesCount < 0 ? 0 : likesCount}',
                                        style: TextStyle(
                                          color: isLiked
                                              ? colors['accent']
                                              : Colors.white38,
                                          fontSize: 13,
                                          fontWeight: isLiked
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              GestureDetector(
                                onTap: () => _showCommentSheet(context, data),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.comment_outlined,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${commentsCount < 0 ? 0 : commentsCount}',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors['primary'],
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementTypeScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
