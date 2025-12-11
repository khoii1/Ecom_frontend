class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String message;
  final String messageType; // 'text', 'image', 'system', 'product'
  final String? imageUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? productId;
  final MessageProduct? product;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.messageType,
    this.imageUrl,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.productId,
    this.product,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      conversationId: json['conversation_id'].toString(),
      senderId: json['sender_id'].toString(),
      senderName: json['sender_name'] ?? 'Ẩn danh',
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      imageUrl: json['image_url'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      productId: json['product_id']?.toString(),
      product: json['product'] != null ? MessageProduct.fromJson(json['product']) : null,
    );
  }

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isSystem => messageType == 'system';
  bool get isProduct => messageType == 'product';
}

class MessageProduct {
  final String id;
  final String title;
  final String? imageUrl;
  final double? price;

  MessageProduct({
    required this.id,
    required this.title,
    this.imageUrl,
    this.price,
  });

  factory MessageProduct.fromJson(Map<String, dynamic> json) {
    return MessageProduct(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      imageUrl: json['image_url'],
      price: json['price'] != null ? (json['price'] is int ? json['price'].toDouble() : json['price']) : null,
    );
  }
}

