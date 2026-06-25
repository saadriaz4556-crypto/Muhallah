import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'post_creation_screen.dart';
import 'my_posts_screen.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String activeFilter = 'all';
  final Set<String> likedPosts = {};
  final Set<String> savedPosts = {};
  final Set<String> upvotedPosts = {};

  // Colors matching the React Native version
  final colors = {
    'background': const Color(0xFF252A34),
    'cardBackground': const Color(0xFF2A303C),
    'surface': const Color(0xFF3A4250),
    'primary': const Color(0xFF08D9D6),
    'accent': const Color(0xFFFF2E63),
    'textPrimary': const Color(0xFFEAEAEA),
    'textSecondary': Colors.white70,
    'textTertiary': Colors.white38,
    'border': Colors.white10,
    'success': const Color(0xFF10B981),
    'warning': const Color(0xFFF59E0B),
    'error': const Color(0xFFFF2E63),
  };

  // Sample data
  final filters = [
    {'id': 'all', 'label': 'All', 'count': 42},
    {'id': 'announcements', 'label': 'Announcements', 'count': 12},
    {'id': 'complaints', 'label': 'Complaints', 'count': 8},
    {'id': 'marketplace', 'label': 'Marketplace', 'count': 15},
    {'id': 'jobs', 'label': 'Jobs', 'count': 5},
    {'id': 'lostfound', 'label': 'Lost & Found', 'count': 2},
    {'id': 'events', 'label': 'Events', 'count': 7},
    {'id': 'polls', 'label': 'Polls', 'count': 3},
  ];





  Future<void> handleLike(String postId) async {
    final postRef = FirebaseFirestore.instance.collection('announcements').doc(postId);
    if (likedPosts.contains(postId)) {
      likedPosts.remove(postId);
      await postRef.update({'likes': FieldValue.increment(-1)});
    } else {
      likedPosts.add(postId);
      await postRef.update({'likes': FieldValue.increment(1)});
    }
    setState(() {});
  }

  void handleSave(String postId) {
    setState(() {
      if (savedPosts.contains(postId)) {
        savedPosts.remove(postId);
      } else {
        savedPosts.add(postId);
      }
    });
  }

  void _showCommentSheet(BuildContext context, Map<String, dynamic> post) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A303C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comments',
              style: TextStyle(color: Color(0xFFEAEAEA),
              fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .doc(post['id'])
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No comments yet',
                      style: TextStyle(color: Colors.white54)),
                  );
                }
                return SizedBox(
                  height: 200,
                  child: ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(radius: 16,
                              backgroundColor: Color(0xFF3A4250)),
                            const SizedBox(width: 8),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['authorName'] ?? 'Resident',
                                  style: const TextStyle(
                                    color: Color(0xFF08D9D6),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                                Text(d['text'] ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFFEAEAEA), fontSize: 14)),
                              ],
                            )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  style: const TextStyle(color: Color(0xFFEAEAEA)),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF3A4250),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final text = commentController.text.trim();
                  if (text.isEmpty) return;
                  final postRef = FirebaseFirestore.instance
                      .collection('announcements').doc(post['id']);
                  await postRef.collection('comments').add({
                    'text': text,
                    'authorId': FirebaseAuth.instance.currentUser?.uid ?? '',
                    'authorName': FirebaseAuth.instance.currentUser
                        ?.displayName?.isNotEmpty == true
                        ? FirebaseAuth.instance.currentUser!.displayName!
                        : (FirebaseAuth.instance.currentUser?.email
                            ?.split('@').first ?? 'Resident'),
                    'createdAt': Timestamp.now(),
                  });
                  await postRef.update({'comments': FieldValue.increment(1)});
                  commentController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF08D9D6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else {
      return timestamp.toString();
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month-1]} ${dt.year}';
  }

  Widget _buildFilterChip(Map<String, dynamic> item) {
    final isActive = activeFilter == item['id'];
    return GestureDetector(
      onTap: () => setState(() => activeFilter = item['id']),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive ? colors['primary'] : Colors.transparent,
          border: Border.all(
            color: isActive ? colors['primary']! : colors['border']!,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${item['label']} (${item['count']})',
          style: TextStyle(
            color: isActive ? colors['textPrimary'] : colors['textSecondary'],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedItem(Map<String, dynamic> item) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: item['color'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['description'],
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'View',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementBar(Map<String, dynamic> post) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors['border']!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEngagementButton(
            icon: likedPosts.contains(post['id']) ? '❤️' : '🤍',
            count: post['likes'] ?? 0,
            color: likedPosts.contains(post['id'])
                ? colors['accent']
                : colors['textSecondary'],
            onTap: () => handleLike(post['id']),
          ),
          _buildEngagementButton(
            icon: '💬',
            count: post['comments'] ?? 0,
            color: colors['textSecondary'],
            onTap: () => _showCommentSheet(context, post),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton({
    required String icon,
    required int? count,
    required Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 18, color: color)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 14, color: colors['textSecondary']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> post) {
    return _buildCard(
      post: post,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(post),
          const SizedBox(height: 12),
          if (post['image'] != null && post['image'].toString().isNotEmpty) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post['image'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: colors['surface'],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: colors['primary'],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colors['surface'],
                      child: const Icon(
                        Icons.error,
                        color: Colors.grey,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            post['title'],
            style: TextStyle(
              color: colors['textPrimary'],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _stripHtml(post['content'] ?? ''),
            style: TextStyle(
              color: colors['textSecondary'],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Read more',
              style: TextStyle(
                color: colors['primary'],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildEngagementBar(post),
        ],
      ),
    );
  }

  Widget _buildMarketplaceCard(Map<String, dynamic> post) {
    return _buildCard(
      post: post,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(post, marketplace: true),
          const SizedBox(height: 12),
          // ACTUAL IMAGE LOADING - FIXED
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post['image'] ?? 'https://via.placeholder.com/400x200',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: colors['surface'],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colors['surface'],
                    child: const Icon(
                      Icons.error,
                      color: Colors.grey,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Men\'s Mountain Bicycle - 21 Gear',
            style: TextStyle(
              color: colors['textPrimary'],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            post['price'],
            style: TextStyle(
              color: colors['success'],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post['content'],
            style: TextStyle(
              color: colors['textSecondary'],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors['primary'],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Contact Seller',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildEngagementBar(post),
        ],
      ),
    );
  }

  Widget _buildPollCard(Map<String, dynamic> post) {
    return _buildCard(
      post: post,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(post),
          const SizedBox(height: 12),
          Text(
            post['title'],
            style: TextStyle(
              color: colors['textPrimary'],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _stripHtml(post['content'] ?? ''),
            style: TextStyle(
              color: colors['textSecondary'],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...post['options']
              .map<Widget>((option) => _buildPollOption(option))
              .toList(),
          const SizedBox(height: 8),
          Text(
            '${post['totalVotes']} total votes',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors['textTertiary'], fontSize: 12),
          ),
          const SizedBox(height: 12),
          _buildEngagementBar(post),
        ],
      ),
    );
  }

  Widget _buildPollOption(Map<String, dynamic> option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: option['color'],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Text(
                  option['label'],
                  style: TextStyle(
                    color: colors['textPrimary'],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${option['percentage']}%',
                style: TextStyle(
                  color: colors['textSecondary'],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: colors['border'],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: option['percentage'] / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: option['color'],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${option['votes']} votes',
            style: TextStyle(color: colors['textTertiary'], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(
    Map<String, dynamic> post, {
    bool marketplace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: colors['surface'],
                shape: BoxShape.circle,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post['author'],
                      style: TextStyle(
                        color: colors['textPrimary'],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (post['verified']) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors['primary'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  post['time'],
                  style: TextStyle(color: colors['textTertiary'], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        if (post['pinned'] ?? false)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors['accent'],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '📌 Pinned',
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else if (marketplace)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors['success'],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '🛒 For Sale',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard({required Map<String, dynamic> post, required Widget child}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors['cardBackground'],
          border: Border.all(color: colors['border']!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors['background'],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors['cardBackground'],
                border: Border(bottom: BorderSide(color: colors['border']!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Feed',
                    style: TextStyle(
                      color: colors['textPrimary'],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Location Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors['cardBackground'],
                          border: Border.all(color: colors['border']!),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📍 Gulshan Block A',
                              style: TextStyle(
                                color: colors['textPrimary'],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: colors['primary'],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Filter Chips
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: filters.map(_buildFilterChip).toList(),
                      ),
                    ),
                    // Composer Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors['cardBackground'],
                        border: Border.all(color: colors['border']!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const MyPostsScreen())),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: colors['surface'],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText:
                                        'Share something with Gulshan Block A...',
                                    hintStyle: TextStyle(
                                      color: colors['textTertiary'],
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(
                                    color: colors['textSecondary'],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PostCreationScreen()),
                                ),
                                icon: Icon(
                                  Icons.photo_camera,
                                  color: colors['textSecondary'],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Pinned Section
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('announcements')
                          .where('pinned', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink(); // hide section if no pinned items
                        }
                        final pinned = snapshot.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return <String, dynamic>{
                            'id': doc.id,
                            'title': d['headline'] ?? '',
                            'description': d['description'] ?? '',
                            'color': const Color(0xFFFF2E63),
                          };
                        }).toList();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Updates',
                                style: TextStyle(
                                  color: colors['textPrimary'],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 140,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: pinned.map(_buildPinnedItem).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Feed Posts
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('announcements')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colors['primary'],
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No posts yet',
                                style: TextStyle(
                                  color: colors['textSecondary'],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }
                        final posts = snapshot.data!.docs.map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          try {
                            return <String, dynamic>{
                              'id': doc.id,
                              'type': data['postType'] ?? 'announcement',
                              'author': data['authorName'] ?? '',
                              'time': _timeAgo(data['createdAt']),
                              'verified': data['verified'] ?? false,
                              'pinned': data['pinned'] ?? false,
                              'title': data['headline'] ?? '',
                              'content': data['description'] ?? '',
                              'image': data['imageUrl'],
                              'likes': (data['likes'] ?? 0) as int,
                              'comments': (data['comments'] ?? 0) as int,
                              'shares': (data['shares'] ?? 0) as int,
                            };
                          } catch (e) {
                            return <String, dynamic>{
                              'id': doc.id,
                              'type': 'announcement',
                              'author': 'User',
                              'time': 'Just now',
                              'verified': false,
                              'pinned': false,
                              'title': 'Loading...',
                              'content': '',
                              'image': null,
                              'likes': 0,
                              'comments': 0,
                              'shares': 0,
                            };
                          }
                        }).toList();
                        return Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: posts.map<Widget>((post) {
                              switch (post['type']) {
                                case 'announcement':
                                  return _buildAnnouncementCard(post);
                                case 'marketplace':
                                  return _buildMarketplaceCard(post);
                                case 'poll':
                                  return _buildPollCard(post);
                                default:
                                  return _buildAnnouncementCard(post);
                              }
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostCreationScreen()),
        ),
        backgroundColor: colors['primary'],
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
