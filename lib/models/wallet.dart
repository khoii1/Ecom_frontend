import 'package:ecom_frontend/models/parsers.dart';

class Wallet {
  final String id;
  final String userId;
  final double balance;
  final String status; // 'active', 'frozen', 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      balance: parseDouble(json['balance']) ?? 0.0,
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class WalletTransaction {
  final String id;
  final String walletId;
  final String userId;
  final String type; // 'topup', 'payment', 'refund', 'withdrawal'
  final double amount;
  final String status; // 'pending', 'completed', 'failed', 'cancelled'
  final String? referenceId; // order_id, return_id, hoặc topup_id
  final String? referenceType; // 'order', 'topup', 'return', 'withdrawal'
  final String? description;
  final String? vnpTransactionRef;
  final String? vnpResponseCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    this.referenceId,
    this.referenceType,
    this.description,
    this.vnpTransactionRef,
    this.vnpResponseCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      walletId: json['wallet_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      amount: parseDouble(json['amount']) ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      referenceId: json['reference_id']?.toString(),
      referenceType: json['reference_type'] as String?,
      description: json['description'] as String?,
      vnpTransactionRef: json['vnp_transaction_ref'] as String?,
      vnpResponseCode: json['vnp_response_code'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  String get typeText {
    switch (type) {
      case 'topup':
        return 'Nạp tiền';
      case 'payment':
        return 'Thanh toán';
      case 'refund':
        return 'Hoàn tiền';
      case 'withdrawal':
        return 'Rút tiền';
      default:
        return type;
    }
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'completed':
        return 'Thành công';
      case 'failed':
        return 'Thất bại';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

class WalletTransactionsResponse {
  final List<WalletTransaction> transactions;
  final int total;
  final int limit;
  final int offset;

  WalletTransactionsResponse({
    required this.transactions,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory WalletTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return WalletTransactionsResponse(
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }
}

