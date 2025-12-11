import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/return.dart';

class ReturnService {
  final Dio _dio;

  ReturnService(this._dio);

  // Tạo return request
  Future<Return> createReturn({
    required String orderId,
    required String returnType,
    required String reason,
    String? description,
    required List<Map<String, dynamic>> items,
    List<String>? images,
  }) async {
    try {
      final response = await _dio.post('/returns', data: {
        'order_id': orderId,
        'return_type': returnType,
        'reason': reason,
        if (description != null) 'description': description,
        'items': items,
        if (images != null && images.isNotEmpty) 'images': images,
      });

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return Return.fromJson(data);
      } else {
        throw Exception('Lỗi khi tạo yêu cầu trả hàng');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi mạng khi tạo yêu cầu trả hàng',
      );
    }
  }

  // Lấy danh sách returns của mình (customer)
  Future<List<Return>> getMyReturns() async {
    try {
      final response = await _dio.get('/returns/my');
      return (response.data as List<dynamic>)
          .map((json) => Return.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải danh sách trả hàng',
      );
    }
  }

  // Lấy danh sách returns của store (seller)
  Future<List<Return>> getStoreReturns(String storeId) async {
    try {
      final response = await _dio.get('/returns/store/$storeId');
      return (response.data as List<dynamic>)
          .map((json) => Return.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải danh sách trả hàng của cửa hàng',
      );
    }
  }

  // Chi tiết return
  Future<Return> getReturnDetail(String returnId) async {
    try {
      final response = await _dio.get('/returns/$returnId');
      return Return.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải chi tiết yêu cầu trả hàng',
      );
    }
  }

  // Duyệt return (seller/admin)
  Future<Return> approveReturn(String returnId, {String? adminNote}) async {
    try {
      final response = await _dio.patch(
        '/returns/$returnId/status',
        data: {
          'status': 'approved',
          if (adminNote != null) 'admin_note': adminNote,
        },
      );
      final data = response.data['data'] ?? response.data;
      return Return.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi duyệt yêu cầu trả hàng',
      );
    }
  }

  // Từ chối return (seller/admin)
  Future<Return> rejectReturn(String returnId, {required String adminNote}) async {
    try {
      final response = await _dio.patch(
        '/returns/$returnId/status',
        data: {
          'status': 'rejected',
          'admin_note': adminNote,
        },
      );
      final data = response.data['data'] ?? response.data;
      return Return.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi từ chối yêu cầu trả hàng',
      );
    }
  }

  // Xử lý return (seller/admin) - chuyển sang processing
  Future<Return> processReturn(String returnId) async {
    try {
      final response = await _dio.patch(
        '/returns/$returnId/status',
        data: {
          'status': 'processing',
        },
      );
      final data = response.data['data'] ?? response.data;
      return Return.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi xử lý yêu cầu trả hàng',
      );
    }
  }

  // Hoàn tất return (seller/admin)
  Future<Return> completeReturn(String returnId) async {
    try {
      final response = await _dio.patch(
        '/returns/$returnId/status',
        data: {
          'status': 'completed',
        },
      );
      final data = response.data['data'] ?? response.data;
      return Return.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi hoàn tất yêu cầu trả hàng',
      );
    }
  }

  // Hủy return (customer)
  Future<Return> cancelReturn(String returnId) async {
    try {
      final response = await _dio.patch('/returns/$returnId/cancel');
      final data = response.data['data'] ?? response.data;
      return Return.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi hủy yêu cầu trả hàng',
      );
    }
  }
}

