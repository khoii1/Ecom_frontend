import 'package:dio/dio.dart';
import 'dart:io';

class ShipperService {
  final Dio _dio;

  ShipperService(this._dio);

  // Lấy danh sách đơn hàng chờ giao (available)
  Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    try {
      final response = await _dio.get('/shipper/orders/available');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải danh sách đơn hàng',
      );
    }
  }

  // Lấy danh sách đơn hàng của shipper
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      final response = await _dio.get('/shipper/orders/my');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải đơn hàng của tôi',
      );
    }
  }

  // Chi tiết đơn hàng
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final response = await _dio.get('/shipper/orders/$orderId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải chi tiết đơn hàng',
      );
    }
  }

  // Nhận đơn hàng
  Future<void> acceptOrder(String orderId) async {
    try {
      await _dio.post('/shipper/orders/$orderId/accept');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi nhận đơn hàng',
      );
    }
  }

  // Xác nhận đã nhận hàng từ store
  Future<void> pickupOrder(String orderId) async {
    try {
      await _dio.post('/shipper/orders/$orderId/pickup');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi xác nhận nhận hàng',
      );
    }
  }

  // Xác nhận đã giao hàng (với ảnh)
  Future<void> deliverOrder({
    required String orderId,
    required File deliveryProofImage,
    String? note,
  }) async {
    try {
      final formData = FormData.fromMap({
        'delivery_proof_image': await MultipartFile.fromFile(
          deliveryProofImage.path,
          filename: deliveryProofImage.path.split('/').last,
        ),
        if (note != null && note.isNotEmpty) 'delivery_note': note,
      });

      await _dio.post(
        '/shipper/orders/$orderId/deliver',
        data: formData,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi xác nhận giao hàng',
      );
    }
  }
}

