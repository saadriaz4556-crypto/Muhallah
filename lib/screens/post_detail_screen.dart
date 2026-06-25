import 'package:flutter/material.dart';
import 'fullscreen_image_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

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
    'success': Color(0xFF10B981),
    'warning': Color(0xFFF59E0B),
    'error': Color(0xFFFF2E63),
  };

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors['background'],
      appBar: AppBar(
        backgroundColor: colors['cardBackground'],
        title: Text('Post Detail', style: TextStyle(color: colors['textPrimary'])),
        iconTheme: IconThemeData(color: colors['textPrimary']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar and username + Timestamp
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
                          post['author'] ?? 'Unknown',
                          style: TextStyle(
                            color: colors['textPrimary'],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (post['verified'] == true) ...[
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
                      post['time'] ?? '',
                      style: TextStyle(color: colors['textTertiary'], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Full post image (if any)
            if (post['image'] != null && post['image'].toString().isNotEmpty) ...[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullscreenImageScreen(
                        imageUrl: post['image'],
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: colors['surface'],
                      child: const Icon(Icons.error, color: Colors.grey, size: 50),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Full post title
            if (post['title'] != null) ...[
              Text(
                post['title'],
                style: TextStyle(
                  color: colors['textPrimary'],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Full post content/description
            Text(
              post['content'] != null ? _stripHtml(post['content']) : '',
              style: TextStyle(
                color: colors['textSecondary'],
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
