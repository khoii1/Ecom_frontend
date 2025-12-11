import 'package:dio/dio.dart';

class DiscountService {
  final Dio _dio;

  DiscountService(this._dio);

  // Lấy danh sách mã giảm giá còn hiệu lực
  Future<List<Map<String, dynamic>>> getActiveDiscounts() async {
    try {
      final response = await _dio.get('/discounts/active');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tải mã giảm giá');
    }
  }

  // Kiểm tra mã giảm giá
  Future<Map<String, dynamic>> validateDiscount({
    required String code,
    required double orderTotal,
    List<String>? categoryIds,
  }) async {
    try {
      final response = await _dio.post(
        '/discounts/validate',
        data: {
          'code': code,
          'order_total': orderTotal,
          if (categoryIds != null && categoryIds.isNotEmpty) 'category_ids': categoryIds,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Mã giảm giá không hợp lệ');
    }
  }

  // Lấy danh sách mã có thể nhận
  Future<List<Map<String, dynamic>>> getAvailableDiscounts() async {
    try {
      final response = await _dio.get('/discounts/available');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tải mã khuyến mãi');
    }
  }

  // Nhận mã giảm giá
  Future<Map<String, dynamic>> claimDiscount(String discountId) async {
    try {
      final response = await _dio.post('/discounts/$discountId/claim');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi nhận mã');
    }
  }

  // Lấy danh sách mã đã nhận của user
  Future<List<Map<String, dynamic>>> getMyClaimedDiscounts() async {
    try {
      final response = await _dio.get('/discounts/my');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tải mã đã nhận');
    }
  }
}

class DiscountResult {
  final bool valid;
  final String? discountId;
  final String? code;
  final String? discountType;
  final double? discountValue;
  final double? discountAmount;
  final String? message;

  DiscountResult({
    required this.valid,
    this.discountId,
    this.code,
    this.discountType,
    this.discountValue,
    this.discountAmount,
    this.message,
  });

  factory DiscountResult.fromJson(Map<String, dynamic> json) {
    return DiscountResult(
      valid: json['valid'] ?? false,
      discountId: json['discount_id'],
      code: json['code'],
      discountType: json['discount_type'],
      discountValue: json['discount_value']?.toDouble(),
      discountAmount: json['discount_amount']?.toDouble(),
      message: json['message'],
    );
  }
}

