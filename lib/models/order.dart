import 'parsers.dart';
import 'address.dart';

class OrderTracking {
  final String id;
  final String status;
  final String? description;
  final String? location;
  final String? note;
  final DateTime trackedAt;

  OrderTracking({
    required this.id,
    required this.status,
    this.description,
    this.location,
    this.note,
    required this.trackedAt,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      note: json['note'] as String?,
      trackedAt: json['tracked_at'] != null
          ? DateTime.parse(json['tracked_at'])
          : DateTime.now(),
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productTitle;
  final String? productImageUrl;
  final double unitPrice;
  final int qty;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productTitle,
    this.productImageUrl,
    required this.unitPrice,
    required this.qty,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productTitle: json['product_title'] ?? '',
      productImageUrl: json['product_image_url'] as String?,
      unitPrice: parseDouble(json['unit_price']) ?? 0.0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
    );
  }
}

class Order {
  final String id;
  final String code;
  final String buyerId;
  final String storeId;
  final double subtotal;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firstItemImageUrl;
  final String? discountCode;
  final double? discountAmount;
  final String? trackingNumber;
  final String? shippingMethod;
  final Address? shippingAddress;
  final List<OrderItem>? items;
  final List<OrderTracking>? tracking;
  final String? shipperId;
  final String? shipperName;
  final String? deliveryProofImage;
  final bool deliveryConfirmedByCustomer;
  final DateTime? deliveryConfirmedAt;
  final String? deliveryNote;
  final String? buyerName;
  final String? buyerEmail;
  final String? paymentMethod; // 'cash', 'vnpay', hoặc 'wallet'

  Order({
    required this.id,
    required this.code,
    required this.buyerId,
    required this.storeId,
    required this.subtotal,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.firstItemImageUrl,
    this.discountCode,
    this.discountAmount,
    this.trackingNumber,
    this.shippingMethod,
    this.shippingAddress,
    this.items,
    this.tracking,
    this.shipperId,
    this.shipperName,
    this.deliveryProofImage,
    this.deliveryConfirmedByCustomer = false,
    this.deliveryConfirmedAt,
    this.deliveryNote,
    this.buyerName,
    this.buyerEmail,
    this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Backend service đã format ID thành String
    return Order(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? 'N/A',
      buyerId: json['buyer_id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      subtotal: parseDouble(json['subtotal']) ?? 0.0,
      total: parseDouble(json['total']) ?? 0.0,
      status: json['status'] as String? ?? 'unknown',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now()),
      firstItemImageUrl: json['first_item_image_url'] as String?,
      discountCode: json['discount_code'] as String?,
      discountAmount: parseDouble(json['discount_amount']),
      trackingNumber: json['tracking_number'] as String?,
      shippingMethod: json['shipping_method'] as String?,
      shippingAddress: json['shipping_address'] != null
          ? Address.fromJson(json['shipping_address'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item))
                .toList()
          : null,
      tracking: json['tracking'] != null
          ? (json['tracking'] as List)
                .map((t) => OrderTracking.fromJson(t))
                .toList()
          : null,
      shipperId: json['shipper_id']?.toString(),
      shipperName: json['shipper_name'] as String?,
      deliveryProofImage: json['delivery_proof_image'] as String?,
      deliveryConfirmedByCustomer:
          json['delivery_confirmed_by_customer'] ?? false,
      deliveryConfirmedAt: json['delivery_confirmed_at'] != null
          ? DateTime.parse(json['delivery_confirmed_at'])
          : null,
      deliveryNote: json['delivery_note'] as String?,
      buyerName: json['buyer_name'] as String?,
      buyerEmail: json['buyer_email'] as String?,
      paymentMethod: json['payment_method'] as String?,
    );
  }
}
