class Conversation {
  final String id;
  final String buyerId;
  final String sellerId;
  final String storeId;
  final String storeName;
  final ConversationUser otherUser;
  final ConversationProduct? product;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.storeId,
    required this.storeName,
    required this.otherUser,
    this.product,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'].toString(),
      buyerId: json['buyer_id'].toString(),
      sellerId: json['seller_id'].toString(),
      storeId: json['store_id'].toString(),
      storeName: json['store_name'] ?? '',
      otherUser: ConversationUser.fromJson(json['other_user']),
      product: json['product'] != null
          ? ConversationProduct.fromJson(json['product'])
          : null,
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class ConversationUser {
  final String id;
  final String name;
  final String email;

  ConversationUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class ConversationProduct {
  final String id;
  final String title;
  final String? imageUrl;

  ConversationProduct({
    required this.id,
    required this.title,
    this.imageUrl,
  });

  factory ConversationProduct.fromJson(Map<String, dynamic> json) {
    return ConversationProduct(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}

