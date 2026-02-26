import 'package:flutter/material.dart';

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
    'background': const Color(0xFF121212),
    'cardBackground': const Color(0xFF1E1E1E),
    'surface': const Color(0xFF252525),
    'primary': const Color(0xFF11988D),
    'accent': const Color(0xFFFFC107),
    'textPrimary': const Color(0xFFFFFFFF),
    'textSecondary': const Color(0xFFB0B0B0),
    'textTertiary': const Color(0xFF888888),
    'border': const Color(0xFF333333),
    'success': const Color(0xFF059669),
    'warning': const Color(0xFFF59E0B),
    'error': const Color(0xFFDC2626),
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

  final pinnedItems = [
    {
      'id': '1',
      'type': 'emergency',
      'title': 'Water outage tomorrow',
      'description': 'Main water line maintenance from 9 AM to 5 PM.',
      'color': const Color(0xFFDC2626),
    },
    {
      'id': '2',
      'type': 'announcement',
      'title': 'Community Clean-up Saturday',
      'description': 'Meet at the park - bags provided.',
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': '3',
      'type': 'poll',
      'title': 'Active Community Poll',
      'description': 'Vote on the new playground equipment.',
      'color': const Color(0xFF11988D),
    },
  ];

  final posts = [
    {
      'id': '1',
      'type': 'announcement',
      'author': 'Muhallah Admin',
      'time': '2 hours ago',
      'verified': true,
      'pinned': true,
      'title': 'Annual Neighborhood Festival',
      'content':
          "The annual neighborhood festival is scheduled for next month! We're looking for volunteers to help with planning and on-the-day activities. Please sign up using the link below.",
      'likes': 23,
      'comments': 8,
      'shares': 4,
    },
    {
      'id': '2',
      'type': 'marketplace',
      'author': 'Alsha Khan',
      'time': '5 hours ago',
      'verified': false,
      'title': 'For Sale',
      'content': 'Selling my barely used bicycle. Perfect for city rides.',
      'price': '₹8,500',
      'image':
          'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmljeWNsZXxlbnwwfHwwfHx8MA%3D%3D',
      'likes': 5,
      'comments': 3,
      'shares': 1,
    },
    {
      'id': '3',
      'type': 'poll',
      'author': 'Bilal Ahmed',
      'time': '1 day ago',
      'verified': false,
      'title': 'Community Center Colors',
      'content': 'What color should we paint the community center walls?',
      'options': [
        {
          'id': '1',
          'label': 'Light Blue',
          'votes': 79,
          'percentage': 62,
          'color': const Color(0xFF93C5FD),
        },
        {
          'id': '2',
          'label': 'Warm Beige',
          'votes': 32,
          'percentage': 25,
          'color': const Color(0xFFFDE68A),
        },
        {
          'id': '3',
          'label': 'Mint Green',
          'votes': 17,
          'percentage': 13,
          'color': const Color(0xFFA7F3D0),
        },
      ],
      'totalVotes': 128,
      'likes': 15,
      'comments': 24,
      'shares': 7,
    },
  ];

  void handleLike(String postId) {
    setState(() {
      if (likedPosts.contains(postId)) {
        likedPosts.remove(postId);
      } else {
        likedPosts.add(postId);
      }
    });
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
            count: post['likes'],
            color: likedPosts.contains(post['id'])
                ? colors['accent']
                : colors['textSecondary'],
            onTap: () => handleLike(post['id']),
          ),
          _buildEngagementButton(
            icon: '💬',
            count: post['comments'],
            color: colors['textSecondary'],
            onTap: () {},
          ),
          _buildEngagementButton(
            icon: '↗️',
            count: post['shares'],
            color: colors['textSecondary'],
            onTap: () {},
          ),
          _buildEngagementButton(
            icon: savedPosts.contains(post['id']) ? '📖' : '📚',
            count: null,
            color: savedPosts.contains(post['id'])
                ? colors['accent']
                : colors['textSecondary'],
            onTap: () => handleSave(post['id']),
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
            post['content'],
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
            post['content'],
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

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors['cardBackground'],
        border: Border.all(color: colors['border']!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: null, // () => context.go('/TabScreens/menu'),
                    icon: Icon(Icons.menu, color: colors['textPrimary']),
                  ),
                  Text(
                    'Feed',
                    style: TextStyle(
                      color: colors['textPrimary'],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.search, color: colors['textPrimary']),
                      ),
                      IconButton(
                        onPressed:
                            null, // () => context.go('/TabScreens/menu'),
                        icon: Icon(
                          Icons.settings,
                          color: colors['textPrimary'],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            null, // () => Navigator.pushNamed('/TabScreens/NewPost'),
                        icon: Icon(Icons.add, color: colors['primary']),
                      ),
                    ],
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
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: colors['surface'],
                                  shape: BoxShape.circle,
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
                                onPressed: () {},
                                icon: Icon(
                                  Icons.photo_camera,
                                  color: colors['textSecondary'],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.poll,
                                  color: colors['textSecondary'],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.attach_money,
                                  color: colors['textSecondary'],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.warning,
                                  color: colors['textSecondary'],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Pinned Section
                    Container(
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
                              children:
                                  pinnedItems.map(_buildPinnedItem).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Feed Posts
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            null, // () => Navigator.pushNamed(context, '/TabScreens/NewPost'),
        backgroundColor: colors['primary'],
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
