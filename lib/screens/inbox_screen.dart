import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  static const Color backgroundColor = Color(0xFF0D1B2A);
  static const Color accentColor = Color(0xFF00BCD4);

  InboxScreen({super.key});

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final dateTime = timestamp.toDate();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: accentColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet. Start a conversation!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>? ?? {};
              final chatId = chats[index].id;
              final participants =
                  List<String>.from(chat['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != _currentUserId,
                orElse: () => '',
              );
              final lastMessage = chat['lastMessage'] as String? ?? '';
              final lastMessageTime = chat['lastMessageTime'] as Timestamp?;
              final unreadCount = chat['unreadCount'] as int? ?? 0;
              final lastMessageSenderId =
                  chat['lastMessageSenderId'] as String? ?? '';
              final hasUnread =
                  unreadCount > 0 && lastMessageSenderId != _currentUserId;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  String otherUserName = 'Unknown User';

                  if (userSnapshot.hasData && userSnapshot.data != null) {
                    final userData = userSnapshot.data!;
                    otherUserName = userData['name'] as String? ??
                        userData['displayName'] as String? ??
                        userData['fullName'] as String? ??
                        'Unknown User';
                  }

                  return _buildConversationTile(
                    context: context,
                    chatId: chatId,
                    otherUserName: otherUserName,
                    lastMessage: lastMessage,
                    lastMessageTime: lastMessageTime,
                    hasUnread: hasUnread,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile({
    required BuildContext context,
    required String chatId,
    required String otherUserName,
    required String lastMessage,
    Timestamp? lastMessageTime,
    required bool hasUnread,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: Colors.white70,
              size: 28,
            ),
          ),
          if (hasUnread)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        otherUserName,
        style: TextStyle(
          color: Colors.white,
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
          fontFamily: 'Roboto',
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          lastMessage.isNotEmpty ? lastMessage : 'No messages',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: hasUnread
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.5),
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            fontSize: 14,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      trailing: Text(
        _formatTimestamp(lastMessageTime),
        style: TextStyle(
          color: hasUnread ? accentColor : Colors.white.withOpacity(0.4),
          fontSize: 12,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          fontFamily: 'Roboto',
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserName: otherUserName,
            ),
          ),
        );
      },
    );
  }
}
