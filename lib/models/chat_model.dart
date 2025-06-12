class ChatModel {
  final String id;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final double productPrice;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCount;
  final bool isActive;

  ChatModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.productPrice,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.unreadCount = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'productPrice': productPrice,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isActive': isActive,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(map['lastMessageTime']),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      unreadCount: map['unreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime sentAt;
  final bool isRead;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.sentAt,
    this.isRead = false,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      sentAt: DateTime.parse(map['sentAt']),
      isRead: map['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
}

enum MessageType {
  text,
  image,
  system
}