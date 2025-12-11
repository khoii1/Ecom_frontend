class ReturnItem {
  final String orderItemId;
  final String productId;
  final int qty;
  final double unitPrice;
  final String? reason;

  ReturnItem({
    required this.orderItemId,
    required this.productId,
    required this.qty,
    required this.unitPrice,
    this.reason,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      orderItemId: json['order_item_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      qty: json['qty'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_item_id': orderItemId,
      'product_id': productId,
      'qty': qty,
      'unit_price': unitPrice,
      if (reason != null) 'reason': reason,
    };
  }
}

class Return {
  final String id;
  final String orderId;
  final String userId;
  final String storeId;
  final String returnType; // 'refund', 'exchange', 'both'
  final String reason;
  final String? description;
  final List<ReturnItem> items;
  final String status; // 'pending', 'approved', 'rejected', 'processing', 'completed', 'cancelled'
  final double refundAmount;
  final String refundMethod; // 'original', 'wallet', 'bank_transfer'
  final String refundStatus; // 'pending', 'processing', 'completed', 'failed'
  final List<String> images;
  final String? adminNote;
  final String? customerNote;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated fields
  final Map<String, dynamic>? order;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? store;

  Return({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.storeId,
    required this.returnType,
    required this.reason,
    this.description,
    required this.items,
    required this.status,
    required this.refundAmount,
    required this.refundMethod,
    required this.refundStatus,
    required this.images,
    this.adminNote,
    this.customerNote,
    this.processedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.order,
    this.user,
    this.store,
  });

  factory Return.fromJson(Map<String, dynamic> json) {
    return Return(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      returnType: json['return_type'] ?? 'refund',
      reason: json['reason'] ?? '',
      description: json['description'],
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ReturnItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] ?? 'pending',
      refundAmount: (json['refund_amount'] ?? 0).toDouble(),
      refundMethod: json['refund_method'] ?? 'original',
      refundStatus: json['refund_status'] ?? 'pending',
      images: (json['images'] as List<dynamic>?)
              ?.map((img) => img.toString())
              .toList() ??
          [],
      adminNote: json['admin_note'],
      customerNote: json['customer_note'],
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      order: json['order_id'] is Map ? json['order_id'] : null,
      user: json['user_id'] is Map ? json['user_id'] : null,
      store: json['store_id'] is Map ? json['store_id'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'store_id': storeId,
      'return_type': returnType,
      'reason': reason,
      if (description != null) 'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'refund_amount': refundAmount,
      'refund_method': refundMethod,
      'refund_status': refundStatus,
      'images': images,
      if (adminNote != null) 'admin_note': adminNote,
      if (customerNote != null) 'customer_note': customerNote,
      if (processedAt != null) 'processed_at': processedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Đã từ chối';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn tất';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

