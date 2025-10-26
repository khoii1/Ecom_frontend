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
      // Backend POST /orders không cần request body
      final response = await _dio.post('/orders');

      if (response.statusCode == 201 && response.data != null) {
        print(
          "Order created successfully on backend. ID: ${response.data['id']}",
        );
        return Order.fromJson(response.data);
      } else {
        String message =
            response.data?['message'] ??
            response.statusMessage ??
            'Lỗi khi tạo đơn hàng';
        print("Error creating order (non-201): $message");
        throw Exception(message);
      }
      // Sửa: Bỏ Future<dynamic>
    } on DioException catch (e) {
      // <<< SỬA
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
  /// Trả về chuỗi trạng thái ('paid', 'pending', 'payment_failed', 'not_found', 'forbidden')
  /// hoặc ném Exception nếu có lỗi mạng hoặc lỗi không xác định khác.
  Future<String> checkOrderStatus(String orderId) async {
    // <<< HÀM ĐÃ ĐƯỢC CẬP NHẬT >>>
    try {
      print("OrderService: Calling backend API GET /orders/$orderId/status");
      // Endpoint này cần tồn tại ở backend
      final response = await _dio.get('/orders/$orderId/status');

      // Kiểm tra thành công và dữ liệu hợp lệ
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['status'] != null) {
        final status = response.data['status'] as String;
        print("OrderService: Received status for order $orderId: $status");
        return status; // Trả về trạng thái ('paid', 'pending', 'payment_failed', ...)
      } else {
        // Nếu backend trả về 200 nhưng không có 'status'
        print(
          "OrderService: Invalid response format from status check for order $orderId",
        );
        throw Exception(
          'Phản hồi trạng thái không hợp lệ từ server',
        ); // Ném lỗi
      }
      // Sửa: Bỏ Future<dynamic>
    } on DioException catch (e) {
      // <<< SỬA
      print(
        "OrderService: DioException checking order status $orderId: ${e.response?.statusCode} - ${e.response?.data}",
      );
      // Xử lý các lỗi HTTP cụ thể và trả về chuỗi đặc biệt
      if (e.response?.statusCode == 404) {
        return 'not_found'; // Đơn hàng không tồn tại
      }
      if (e.response?.statusCode == 403) {
        return 'forbidden'; // Không có quyền xem đơn hàng này
      }
      // Ném lỗi cho các DioException khác (lỗi mạng, timeout, 500, ...)
      // Màn hình PaymentResultScreen sẽ bắt lỗi này và hiển thị thông báo lỗi
      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi mạng khi kiểm tra trạng thái',
      );
    } catch (e) {
      // Bắt các lỗi không mong muốn khác
      print("OrderService: Unknown error checking order status $orderId: $e");
      // Ném lỗi để màn hình PaymentResultScreen xử lý
      throw Exception(
        'Lỗi không xác định khi kiểm tra trạng thái: ${e.toString()}',
      );
    }
  }

  // <<< KẾT THÚC CẬP NHẬT >>>
}
