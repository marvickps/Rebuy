import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String? _currentChatId;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String? get currentChatId => _currentChatId;

  Future<void> loadChats(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('chats')
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
          .get();

      _chats = querySnapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data()))
          .where((chat) => chat.buyerId == userId || chat.sellerId == userId)
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load chats: ${e.toString()}');
      _setLoading(false);
    }
  }

  Stream<List<ChatModel>> getChatStream(String userId) {
    return _firestore
        .collection('chats')
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .where(
                (chat) => chat.buyerId == userId || chat.sellerId == userId,
              )
              .toList();
        });
  }

  Future<String?> createOrGetChat({
    required ProductModel product,
    required UserModel buyer,
    required UserModel seller,
  }) async {
    try {
      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('productId', isEqualTo: product.id)
          .where('buyerId', isEqualTo: buyer.uid)
          .where('sellerId', isEqualTo: seller.uid)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat
      final chatId = _uuid.v4();
      final chat = ChatModel(
        id: chatId,
        productId: product.id,
        productTitle: product.title,
        productImageUrl: product.imageUrls.isNotEmpty
            ? product.imageUrls.first
            : '',
        productPrice: product.price,
        buyerId: buyer.uid,
        buyerName: buyer.name,
        sellerId: seller.uid,
        sellerName: seller.name,
        lastMessage: 'Chat started',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: buyer.uid,
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toMap());

      // Send initial system message
      await sendMessage(
        chatId: chatId,
        senderId: buyer.uid,
        senderName: buyer.name,
        message: 'Hi, I\'m interested in "${product.title}"',
        type: MessageType.system,
      );

      return chatId;
    } catch (e) {
      _setError('Failed to create chat: ${e.toString()}');
      return null;
    }
  }

  Future<void> loadMessages(String chatId) async {
    try {
      _currentChatId = chatId;
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('sentAt', descending: false)
          .get();

      _messages = querySnapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load messages: ${e.toString()}');
      _setLoading(false);
    }
  }

  Stream<List<MessageModel>> getMessageStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList();
        });
  }

  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    try {
      final messageId = _uuid.v4();
      final messageModel = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        sentAt: DateTime.now(),
        type: type,
      );

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageModel.toMap());

      // Update chat with last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessageSenderId': senderId,
      });

      return true;
    } catch (e) {
      _setError('Failed to send message: ${e.toString()}');
      return false;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      // Silently handle read receipt errors
    }
  }

  Future<ChatModel?> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _setError('Failed to get chat: ${e.toString()}');
      return null;
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      // Mark chat as inactive instead of deleting
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
      });

      _chats.removeWhere((chat) => chat.id == chatId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete chat: ${e.toString()}');
    }
  }

  int getUnreadCount(String chatId, String userId) {
    try {
      // This would typically be calculated from the messages
      // For now, returning 0 as a placeholder
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void clearCurrentChat() {
    _currentChatId = null;
    _messages.clear();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
