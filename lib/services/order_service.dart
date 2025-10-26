import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/order.dart';

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  // Tạo đơn từ giỏ hàng hiện tại (POST /orders) -> trả về Order
  Future<Order> createOrderFromCart() async {
    try {
      print("Calling backend API (POST /orders) to create order from cart...");
      final response = await _dio.post('/orders');

      if (response.statusCode == 201 && response.data != null) {
        print(
          "Order created successfully on backend. ID: ${response.data['id']}",
        );
        return Order.fromJson(response.data);
      } else {
        final message =
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

  // Kiểm tra trạng thái đơn (GET /orders/:orderId/status) -> 'paid' | 'pending' | 'payment_failed' | 'not_found' | 'forbidden'
  Future<String> checkOrderStatus(String orderId) async {
    try {
      print("OrderService: Calling backend API GET /orders/$orderId/status");
      final response = await _dio.get('/orders/$orderId/status');

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['status'] != null) {
        final status = response.data['status'] as String;
        print("OrderService: Received status for order $orderId: $status");
        return status;
      } else {
        print(
          "OrderService: Invalid response format from status check for order $orderId",
        );
        throw Exception('Phản hồi trạng thái không hợp lệ từ server');
      }
    } on DioException catch (e) {
      print(
        "OrderService: DioException checking order status $orderId: ${e.response?.statusCode} - ${e.response?.data}",
      );
      if (e.response?.statusCode == 404) return 'not_found';
      if (e.response?.statusCode == 403) return 'forbidden';
      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi mạng khi kiểm tra trạng thái',
      );
    } catch (e) {
      print("OrderService: Unknown error checking order status $orderId: $e");
      throw Exception(
        'Lỗi không xác định khi kiểm tra trạng thái: ${e.toString()}',
      );
    }
  }
}
