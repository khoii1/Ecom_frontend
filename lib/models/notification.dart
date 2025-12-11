class Notification {
  final String id;
  final String userId;
  final String type; // order, payment, promotion, system, message
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'])
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  String get typeIcon {
    switch (type) {
      case 'order':
        return '📦';
      case 'payment':
        return '💳';
      case 'promotion':
        return '🎉';
      case 'message':
        return '💬';
      default:
        return '🔔';
    }
  }
}

