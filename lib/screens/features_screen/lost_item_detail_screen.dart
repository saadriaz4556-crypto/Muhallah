import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LostItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const LostItemDetailScreen({super.key, required this.itemData});

  @override
  State<LostItemDetailScreen> createState() => _LostItemDetailScreenState();
}

class _LostItemDetailScreenState extends State<LostItemDetailScreen> {
  Future<void> _deletePost() async {
    final itemId = (widget.itemData['id'] ??
            widget.itemData['docId'] ??
            widget.itemData['lostItemId'] ??
            widget.itemData['itemId'] ??
            '')
        .toString();

    if (itemId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to find this post to delete'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Delete this post?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF08D9D6)),
            ),
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
          .doc(itemId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted'),
            backgroundColor: Color(0xFF08D9D6),
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return 'Recent';
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final String itemName = widget.itemData['itemName'] ?? 'Unnamed Item';
    final String category = widget.itemData['category'] ?? 'Other';
    final String description =
        widget.itemData['description'] ?? 'No description provided.';
    final String lastSeenLocation =
        widget.itemData['lastSeenLocation'] ?? 'Unknown location';
    final String imageUrl = widget.itemData['imageUrl'] ?? '';
    final dynamic rawTimestamp = widget.itemData['timestamp'];
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String posterUid =
        widget.itemData['reportedBy'] ?? widget.itemData['postedBy'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF252A34),
      appBar: AppBar(
        title: const Text(
          'Item Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF252A34),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            if (imageUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 250,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A303C),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF08D9D6),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white24,
                        size: 60,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 180,
                color: const Color(0xFF2A303C),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white24,
                    size: 60,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge & Lost Item Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF08D9D6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF08D9D6).withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          '🔍 Lost Item',
                          style: TextStyle(
                            color: Color(0xFF08D9D6),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white24,
                          ),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Item Name
                  Text(
                    itemName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Timestamp
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimestamp(rawTimestamp),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Color(0xFF08D9D6),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFEAEAEA),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Last Seen Location
                  const Text(
                    'Last Seen Location',
                    style: TextStyle(
                      color: Color(0xFF08D9D6),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFFFF2E63), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lastSeenLocation,
                          style: const TextStyle(
                            color: Color(0xFFEAEAEA),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Contact Reporter Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final contactNumber =
                            (widget.itemData['contactNumber'] ?? '')
                                .toString()
                                .trim();
                        if (contactNumber.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No contact number provided'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final Uri launchUri =
                            Uri(scheme: 'tel', path: contactNumber);
                        if (!await launchUrl(launchUri)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to open the dialer'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Color(0xFF08D9D6)),
                      label: const Text(
                        'Contact Reporter',
                        style: TextStyle(
                          color: Color(0xFF08D9D6),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF08D9D6), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  if (currentUid.isNotEmpty && currentUid == posterUid) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _deletePost,
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          'Delete My Post',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
