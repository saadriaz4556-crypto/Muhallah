import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:muhallah/screens/features_screen/lost_item_detail_screen.dart';
import 'package:muhallah/services/lost_found_service.dart';

class LostItemsListScreen extends StatelessWidget {
  const LostItemsListScreen({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wallet':
        return Icons.wallet;
      case 'keys':
        return Icons.key;
      case 'phone':
        return Icons.phone_iphone;
      case 'bag':
        return Icons.backpack;
      case 'documents':
        return Icons.description;
      case 'electronics':
        return Icons.devices;
      default:
        return Icons.help_outline;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wallet':
        return Colors.brown;
      case 'keys':
        return Colors.amber;
      case 'phone':
        return Colors.grey;
      case 'bag':
        return Colors.red;
      case 'documents':
        return Colors.blue;
      case 'electronics':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lostFoundService = LostFoundService();

    return Scaffold(
      backgroundColor: const Color(0xFF252A34),
      appBar: AppBar(
        title: const Text(
          'Lost Items',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF252A34),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: lostFoundService.getLostItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF08D9D6),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No lost items reported yet',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // ensure we have reference to id

              final category = data['category'] ?? 'Other';
              final itemName = data['itemName'] ?? 'Unnamed Item';
              final description = data['description'] ?? '';

              return Card(
                color: const Color(0xFF2A303C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LostItemDetailScreen(itemData: data),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(category),
                    child:
                        Icon(_getCategoryIcon(category), color: Colors.black),
                  ),
                  title: Text(
                    itemName,
                    style: const TextStyle(
                      color: Color(0xFFEAEAEA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
