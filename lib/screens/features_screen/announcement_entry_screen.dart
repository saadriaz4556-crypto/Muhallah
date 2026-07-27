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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252A34),
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
            .where('authorId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF08D9D6)),
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
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final headline = data['headline'] ?? '';
              final description = data['description'] ?? '';
              final imageUrl = data['imageUrl'] ?? '';
              final type = data['type'] ?? 'General';
              final createdAt = data['createdAt'];
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
                  color: const Color(0xFF2A303C),
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
                                  color: const Color(0xFF08D9D6)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(type,
                                    style: const TextStyle(
                                      color: Color(0xFF08D9D6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                              const Spacer(),
                              Text(timeStr,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(headline,
                              style: const TextStyle(
                                color: Color(0xFFEAEAEA),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 4),
                          Text(description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.favorite_border,
                                  color: Colors.white38, size: 16),
                              const SizedBox(width: 4),
                              Text('${data['likes'] ?? 0}',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12)),
                              const SizedBox(width: 16),
                              const Icon(Icons.comment_outlined,
                                  color: Colors.white38, size: 16),
                              const SizedBox(width: 4),
                              Text('${data['comments'] ?? 0}',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12)),
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
        backgroundColor: const Color(0xFF08D9D6),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementTypeScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
