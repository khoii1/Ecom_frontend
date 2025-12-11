import 'package:dio/dio.dart';

class AnalyticsService {
  final Dio _dio;

  AnalyticsService(this._dio);

  // Lấy thống kê cho cửa hàng (Seller)
  Future<Map<String, dynamic>> getStoreAnalytics(String storeId) async {
    try {
      final response = await _dio.get('/analytics/store/$storeId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải thống kê cửa hàng',
      );
    }
  }

  // Lấy thống kê doanh thu theo thời gian (Admin)
  Future<List<Map<String, dynamic>>> getRevenueAnalytics({
    String period = 'daily',
    int days = 30,
  }) async {
    try {
      final response = await _dio.get(
        '/analytics/revenue',
        queryParameters: {
          'period': period,
          'days': days,
        },
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải thống kê doanh thu',
      );
    }
  }

  // Lấy thống kê tổng quan (Admin)
  Future<Map<String, dynamic>> getOverviewAnalytics() async {
    try {
      final response = await _dio.get('/analytics/overview');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải thống kê tổng quan',
      );
    }
  }
}

