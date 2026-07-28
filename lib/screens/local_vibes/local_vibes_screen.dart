import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muhallah/services/local_vibes_service.dart';
import 'package:muhallah/screens/local_vibes/new_post_screen.dart';
import 'package:muhallah/screens/local_vibes/comments_bottom_sheet.dart';
import 'package:muhallah/widgets/fullscreen_image_viewer.dart';

// --- THEME COLORS ---
const Color bgDeepNavy = Color(0xFF252A34);
const Color accentTeal = Color(0xFF08D9D6);
const Color lightText = Color(0xFFEAEAEA);
const Color cardBg = Color(0xFF1A1F2E);
const Color statusGreen = Color(0xFF10B981);
const Color statusRed = Color(0xFFFF2E63);

class LocalVibesScreen extends StatefulWidget {
  const LocalVibesScreen({super.key});

  @override
  State<LocalVibesScreen> createState() => _LocalVibesScreenState();
}

class _LocalVibesScreenState extends State<LocalVibesScreen> {
  final _service = LocalVibesService();

  Color _getTimerColor(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    if (diff.inHours >= 12) return const Color(0xFF00C853); // Green
    if (diff.inHours >= 6) return const Color(0xFFFFD600); // Yellow
    return const Color(0xFFFF1744); // Red
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: CommentsBottomSheet(postId: postId),
      ),
    );
  }

  void _reportPost(String postId) async {
    await _service.reportPost(postId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post reported to admin.')),
      );
    }
  }

  void _deletePost(String postId, String? imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgDeepNavy,
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this post?',
            style: TextStyle(color: lightText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: lightText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: statusRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deletePost(postId, imageUrl: imageUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: statusRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $e'),
          backgroundColor: statusRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeepNavy,
      floatingActionButton: SizedBox(
        width: 62,
        height: 62,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewPostScreen()),
            );
          },
          backgroundColor: accentTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 100,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF252A34),
                  const Color(0xFF08D9D6).withValues(alpha: 0.2),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            child: IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A303C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFFEAEAEA)),
              ),
            ),
          ),
          titleSpacing: 0,
          title: const SizedBox(
            height: 100,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Vibes 🔥',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Posts 24 ghante mein gayab ho jate hain',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: accentTeal));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📭', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text('Abhi koi vibe nahi!\nPehli vibe aap dalo 🔥',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final post = posts[index];
              final postId = post['id'];
              final expiresAt =
                  (post['expires_at'] as dynamic)?.toDate() ?? DateTime.now();
              final diff = expiresAt.difference(DateTime.now());
              final timerColor = _getTimerColor(expiresAt);

              return Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white12,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Resident',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  '${diff.inHours} hours left!',
                                  style: TextStyle(
                                      color: timerColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white54),
                            color: bgDeepNavy,
                            onSelected: (val) {
                              if (val == 'report') {
                                _reportPost(postId);
                              } else if (val == 'delete') {
                                _deletePost(postId, post['media_url']);
                              }
                            },
                            itemBuilder: (context) => [
                              if (post['user_id'] == _service.currentUserId)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete',
                                      style:
                                          TextStyle(color: Colors.redAccent)),
                                )
                              else
                                const PopupMenuItem(
                                  value: 'report',
                                  child: Text('Report',
                                      style:
                                          TextStyle(color: Colors.redAccent)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Content
                    if (post['content_text'] != null &&
                        post['content_text'].toString().trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          post['content_text'] ?? '',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    if (post['post_type'] == 'photo' &&
                        post['media_url'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullscreenImageViewer(
                                  imageUrl: post['media_url'],
                                ),
                              ),
                            );
                          },
                          child: Image.network(
                            post['media_url'],
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: 250,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: accentTeal)),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                              height: 100,
                              child: Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                    // Footer Actions
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('local_vibes_reactions')
                          .doc('${postId}_${_service.currentUserId}')
                          .snapshots(),
                      builder: (context, rxSnapshot) {
                        final hasReacted =
                            rxSnapshot.hasData && rxSnapshot.data!.exists;
                        final rxType = hasReacted
                            ? rxSnapshot.data!['reaction_type']
                            : null;
                        final hasLiked = rxType == 'like';
                        final hasHaha = rxType == 'haha';

                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildAction(
                                icon: hasLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                count: post['likes_count'] ?? 0,
                                color: const Color(0xFFFF4081),
                                onTap: () =>
                                    _service.toggleReaction(postId, 'like'),
                              ),
                              const SizedBox(width: 16),
                              _buildAction(
                                icon: hasHaha
                                    ? Icons.sentiment_very_satisfied
                                    : Icons.sentiment_satisfied_alt,
                                count: post['haha_count'] ?? 0,
                                color: Colors.amber,
                                onTap: () =>
                                    _service.toggleReaction(postId, 'haha'),
                              ),
                              const Spacer(),
                              if (post['user_id'] == _service.currentUserId)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _deletePost(postId, post['media_url']),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ),
                              _buildAction(
                                icon: Icons.chat_bubble_outline,
                                count: post['comments_count'] ?? 0,
                                color: Colors.white54,
                                onTap: () => _showComments(postId),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAction(
      {required IconData icon,
      required int count,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 4),
          Text('$count',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
