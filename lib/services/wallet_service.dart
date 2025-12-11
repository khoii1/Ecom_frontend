import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/wallet.dart';

class WalletService {
  final Dio _dio;

  WalletService(this._dio);

  /// Lấy số dư ví
  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await _dio.get('/wallet/balance');
      if (response.statusCode == 200 && response.data != null) {
        return {
          'balance': (response.data['balance'] as num?)?.toDouble() ?? 0.0,
          'wallet_id': response.data['wallet_id']?.toString() ?? '',
          'status': response.data['status'] as String? ?? 'active',
        };
      } else {
        throw Exception('Lỗi khi lấy số dư ví');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi mạng khi lấy số dư ví');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy số dư ví: ${e.toString()}');
    }
  }

  /// Tạo yêu cầu nạp tiền
  Future<WalletTransaction> createTopupRequest({
    required double amount,
    String? description,
  }) async {
    try {
      final data = {
        'amount': amount,
        if (description != null && description.isNotEmpty) 'description': description,
      };
      final response = await _dio.post('/wallet/topup', data: data);
      if (response.statusCode == 201 && response.data != null) {
        return WalletTransaction.fromJson(response.data);
      } else {
        throw Exception(response.data?['message'] ?? 'Lỗi khi tạo yêu cầu nạp tiền');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi mạng khi tạo yêu cầu nạp tiền');
    } catch (e) {
      throw Exception('Lỗi không xác định khi tạo yêu cầu nạp tiền: ${e.toString()}');
    }
  }

  /// Tạo VNPay URL cho nạp tiền
  Future<String> createTopupPaymentUrl({
    required String transactionId,
    required double amount,
    String language = 'vn',
    String? bankCode,
  }) async {
    try {
      final data = {
        'transactionId': transactionId,
        'amount': amount,
        'language': language,
        if (bankCode != null && bankCode.isNotEmpty) 'bankCode': bankCode,
      };
      final response = await _dio.post('/payment/vnpay/create_topup_url', data: data);
      if (response.statusCode == 200 && response.data != null) {
        return response.data['paymentUrl'] as String;
      } else {
        throw Exception(response.data?['message'] ?? 'Lỗi khi tạo URL thanh toán');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi mạng khi tạo URL thanh toán');
    } catch (e) {
      throw Exception('Lỗi không xác định khi tạo URL thanh toán: ${e.toString()}');
    }
  }

  /// Lấy lịch sử giao dịch
  Future<WalletTransactionsResponse> getTransactions({
    String? type,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get('/wallet/transactions', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        return WalletTransactionsResponse.fromJson(response.data);
      } else {
        return WalletTransactionsResponse(
          transactions: [],
          total: 0,
          limit: limit,
          offset: offset,
        );
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi mạng khi lấy lịch sử giao dịch');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy lịch sử giao dịch: ${e.toString()}');
    }
  }

  /// Lấy chi tiết giao dịch
  Future<WalletTransaction> getTransactionDetail(String transactionId) async {
    try {
      final response = await _dio.get('/wallet/transactions/$transactionId');
      if (response.statusCode == 200 && response.data != null) {
        return WalletTransaction.fromJson(response.data);
      } else {
        throw Exception(response.data?['message'] ?? 'Không tìm thấy giao dịch');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi mạng khi lấy chi tiết giao dịch');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy chi tiết giao dịch: ${e.toString()}');
    }
  }
}

