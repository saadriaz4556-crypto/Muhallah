import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for chats
  CollectionReference get _chatsCollection => _firestore.collection('chats');

  /// Generate chat document ID from two user IDs (sorted alphabetically, joined with underscore)
  String generateChatId(String uid1, String uid2) {
    final sortedUids = [uid1, uid2]..sort();
    return sortedUids.join('_');
  }

  /// Send a message in a chat
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text,
  ) async {
    if (text.trim().isEmpty) return;

    final messageData = {
      'senderId': senderId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    };

    final chatRef = _chatsCollection.doc(chatId);

    await _firestore.runTransaction((transaction) async {
      final chatDoc = await transaction.get(chatRef);

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      // Add message to messages subcollection
      final messageRef = chatRef.collection('messages').doc();
      transaction.set(messageRef, messageData);

      // Update chat with last message info
      transaction.update(chatRef, {
        'lastMessage': text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'unreadCount': FieldValue.increment(1),
      });
    });
  }

  /// Get messages stream for a specific chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get user's chats stream
  Stream<QuerySnapshot> getUserChats(String currentUserId) {
    return _chatsCollection
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Mark all messages in a chat as read by current user
  Future<void> markMessagesAsRead(
    String chatId,
    String currentUserId,
  ) async {
    final messagesRef = _chatsCollection.doc(chatId).collection('messages');

    // Get messages not yet read by current user
    final unreadMessages =
        await messagesRef.where('readBy', arrayContains: currentUserId).get();

    final batch = _firestore.batch();

    for (final doc in unreadMessages.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      if (!readBy.contains(currentUserId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }

    await batch.commit();

    // Reset unread count for this user in the chat document
    final chatRef = _chatsCollection.doc(chatId);
    await chatRef.update({
      'unreadCount': 0,
    });
  }

  /// Create a new chat document if it doesn't exist
  Future<void> createChatIfNotExists(
    String chatId,
    String userId1,
    String userId2,
  ) async {
    final chatRef = _chatsCollection.doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCount': 0,
      });
    }
  }
}
