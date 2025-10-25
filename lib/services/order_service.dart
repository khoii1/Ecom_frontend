import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/order.dart'; // Import model Order

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  /// Gọi API backend (POST /orders) để tạo đơn hàng mới từ giỏ hàng hiện tại.
  /// Backend sẽ tự lấy cart items của user đang đăng nhập (dựa trên token).
  /// Trả về đối tượng Order mới được tạo (chứa ID thật).
  Future<Order> createOrderFromCart() async {
    try {
      print("Calling backend API (POST /orders) to create order from cart...");
      // Backend POST /orders không cần request body, nó lấy thông tin từ session user và DB
      final response = await _dio.post('/orders');

      if (response.statusCode == 201 && response.data != null) {
        print(
          "Order created successfully on backend. ID: ${response.data['id']}",
        );
        // Parse dữ liệu Order trả về từ backend
        return Order.fromJson(response.data);
      } else {
        // Xử lý các trường hợp lỗi khác từ backend
        String message =
            response.data?['message'] ??
            response.statusMessage ??
            'Lỗi khi tạo đơn hàng';
        print("Error creating order (non-201): $message");
        throw Exception(message);
      }
    } on DioException catch (e) {
      print("DioException creating order: ${e.response?.data ?? e.message}");
      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi mạng khi tạo đơn hàng',
      );
    } catch (e) {
      print("Unknown error creating order: $e");
      throw Exception('Lỗi không xác định khi tạo đơn hàng: ${e.toString()}');
    }
  }

  /// Gọi API backend (GET /orders/:orderId/status) để kiểm tra trạng thái đơn hàng.
  Future<String?> checkOrderStatus(String orderId) async {
    try {
      print("Calling backend API to check status for order $orderId...");
      // Endpoint này đã được thêm vào order.routes.js
      final response = await _dio.get('/orders/$orderId/status');
      if (response.data != null && response.data['status'] != null) {
        print("Backend status for order $orderId: ${response.data['status']}");
        return response.data['status']; // Ví dụ: 'paid', 'pending', 'failed'
      } else {
        print("Could not get valid status from backend for order $orderId");
        return 'pending'; // Trả về pending nếu không lấy được
      }
    } on DioException catch (e) {
      print(
        "Error checking order status (Dio): ${e.response?.data ?? e.message}",
      );
      if (e.response?.statusCode == 404) return 'not_found';
      if (e.response?.statusCode == 403) return 'forbidden';
      return null; // Lỗi mạng khác
    } catch (e) {
      print("Error checking order status: $e");
      return null;
    }
  }
}
