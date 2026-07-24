import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muhallah/widgets/fullscreen_image_viewer.dart';

class FoundItemDetailScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> data;

  const FoundItemDetailScreen({
    super.key,
    required this.itemId,
    required this.data,
  });

  @override
  State<FoundItemDetailScreen> createState() => _FoundItemDetailScreenState();
}

class _FoundItemDetailScreenState extends State<FoundItemDetailScreen> {
  int _currentImageIndex = 0;

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF00D4C8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('lost_found_reports')
          .doc(widget.itemId)
          .delete();

      final feedSnapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .where('foundItemId', isEqualTo: widget.itemId)
          .get();

      for (final doc in feedSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(doc.id)
            .delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Color(0xFF00D4C8),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImageViewer(List<String> imageUrls) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullscreenImageViewer(imageUrl: imageUrls[index]),
                      ),
                    );
                  },
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFF2A2A3E),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00D4C8),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2A2A3E),
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.grey, size: 50),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(imageUrls.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentImageIndex == index ? 10 : 8,
              height: _currentImageIndex == index ? 10 : 8,
              decoration: BoxDecoration(
                color:
                    _currentImageIndex == index ? Colors.white : Colors.white38,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    List<String> imageUrls = [];
    try {
      final raw = data['imageUrls'];
      if (raw is List && raw.isNotEmpty) {
        imageUrls = List<String>.from(
          raw.where((e) => e != null && e.toString().trim().isNotEmpty),
        );
      } else if (raw is String && raw.trim().isNotEmpty) {
        imageUrls = [raw.trim()];
      }
    } catch (_) {}
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final posterUid = data['reportedBy'] ?? data['postedBy'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        title: const Text(
          'Found Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrls.isNotEmpty)
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.black,
                    insetPadding: EdgeInsets.zero,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.network(
                            imageUrls[0],
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.of(context, rootNavigator: true)
                                    .pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF08D9D6),
                                    width: 1.5),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF08D9D6),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrls[0],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 240,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF00D4C8),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.grey, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            if (imageUrls.isEmpty) SizedBox.shrink(),
            if (imageUrls.isNotEmpty) const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4C8).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✓ Found Item',
                style: TextStyle(
                  color: Color(0xFF00D4C8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              () {
                final raw = data['title'] ?? data['itemName'] ?? '';
                final rawString = raw.toString();
                if (rawString.startsWith('Found: '))
                  return rawString.substring(7);
                return rawString.isNotEmpty ? rawString : 'Unknown Item';
              }(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00D4C8)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data['category'] ?? 'Other',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(
                  color: Color(0xFF00D4C8), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              data['body'] ?? data['description'] ?? '',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Found Location',
              style: TextStyle(
                  color: Color(0xFF00D4C8), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFFFF2E63), size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data['location'] ??
                        data['foundLocation'] ??
                        'Unknown location',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () async {
                final contactNumber =
                    (data['contactNumber'] ?? '').toString().trim();
                if (contactNumber.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No contact number provided'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                final Uri launchUri = Uri(scheme: 'tel', path: contactNumber);
                if (!await launchUrl(launchUri)) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open the dialer'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(const Color(0xFF00D4C8)),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                overlayColor: MaterialStateProperty.all(
                  const Color(0xFF00D4C8).withOpacity(0.8),
                ),
                minimumSize: MaterialStateProperty.all(
                  const Size.fromHeight(48),
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text('Contact Reporter'),
            ),
            if (currentUid.isNotEmpty && currentUid == posterUid) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _deletePost,
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(Colors.red),
                  overlayColor:
                      MaterialStateProperty.all(Colors.red.withOpacity(0.08)),
                  side: MaterialStateProperty.all(
                    const BorderSide(color: Colors.red),
                  ),
                  minimumSize: MaterialStateProperty.all(
                    const Size.fromHeight(48),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: const Text('Delete My Post'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
