import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/order.dart';

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  Future<Order> createOrderFromCart({
    String? discountId,
    String paymentMethod = 'cash',
  }) async {
    try {
      print("Gọi API backend (POST /orders) để tạo đơn hàng từ giỏ hàng...");
      final data = <String, dynamic>{'payment_method': paymentMethod};
      if (discountId != null) {
        data['discount_id'] = discountId;
      }
      final response = await _dio.post('/orders', data: data);

      if (response.statusCode == 201 && response.data != null) {
        print(
          "Đơn hàng đã được tạo thành công trên backend. ID: ${response.data['id']}",
        );
        return Order.fromJson(response.data);
      } else {
        final message =
            response.data?['message'] ??
            response.statusMessage ??
            'Lỗi khi tạo đơn hàng';

        print("Lỗi tạo đơn hàng (không phải 201): $message");
        throw Exception(message);
      }
    } on DioException catch (e) {
      print("DioException khi tạo đơn hàng: ${e.response?.data ?? e.message}");
      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi mạng khi tạo đơn hàng',
      );
    } catch (e) {
      print("Lỗi không xác định khi tạo đơn hàng: $e");
      throw Exception('Lỗi không xác định khi tạo đơn hàng: ${e.toString()}');
    }
  }

  Future<String> checkOrderStatus(String orderId) async {
    try {
      print("OrderService: Gọi API backend GET /orders/$orderId/status");
      final response = await _dio.get('/orders/$orderId/status');

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['status'] != null) {
        final status = response.data['status'] as String;

        print(
          "OrderService: Đã nhận trạng thái cho đơn hàng $orderId: $status",
        );
        return status;
      } else {
        print(
          "OrderService: Định dạng phản hồi không hợp lệ từ kiểm tra trạng thái cho đơn hàng $orderId",
        );
        throw Exception('Phản hồi trạng thái không hợp lệ từ server');
      }
    } on DioException catch (e) {
      print(
        "OrderService: DioException khi kiểm tra trạng thái đơn hàng $orderId: ${e.response?.statusCode} - ${e.response?.data}",
      );
      if (e.response?.statusCode == 404) return 'not_found';
      if (e.response?.statusCode == 403) return 'forbidden';
      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi mạng khi kiểm tra trạng thái',
      );
    } catch (e) {
      print(
        "OrderService: Lỗi không xác định khi kiểm tra trạng thái đơn hàng $orderId: $e",
      );
      throw Exception(
        'Lỗi không xác định khi kiểm tra trạng thái: ${e.toString()}',
      );
    }
  }

  Future<List<Order>> getMyOrders() async {
    try {
      print("OrderService: Gọi API backend GET /orders/my");

      final response = await _dio.get('/orders/my');

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;

        print("OrderService: Đã nhận ${data.length} đơn hàng.");

        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        print("OrderService: Định dạng phản hồi không hợp lệ từ getMyOrders.");

        return [];
      }
    } on DioException catch (e) {
      print(
        "OrderService: DioException khi lấy đơn hàng của tôi: ${e.response?.data ?? e.message}",
      );

      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi mạng khi lấy đơn hàng',
      );
    } catch (e) {
      print("OrderService: Lỗi không xác định khi lấy đơn hàng của tôi: $e");
      throw Exception('Lỗi không xác định khi lấy đơn hàng: ${e.toString()}');
    }
  }

  Future<Order> getOrderDetail(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException getOrderDetail: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi lấy chi tiết đơn hàng',
      );
    } catch (e) {
      print("Exception getOrderDetail: $e");
      throw Exception('Lỗi không xác định khi lấy chi tiết đơn hàng');
    }
  }

  // Xác nhận đã nhận hàng (customer)
  Future<void> confirmDelivery({
    required String orderId,
    required bool confirmed,
    String? note,
  }) async {
    try {
      await _dio.post(
        '/orders/$orderId/confirm-delivery',
        data: {
          'confirmed': confirmed,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi xác nhận giao hàng',
      );
    }
  }

  // Gán shipper cho đơn hàng (seller/admin)
  Future<void> assignShipper({
    required String orderId,
    required String shipperId,
  }) async {
    try {
      await _dio.post(
        '/orders/$orderId/assign-shipper',
        data: {'shipper_id': shipperId},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi gán shipper');
    }
  }

  // Cập nhật trạng thái đơn hàng (seller/admin)
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? description,
    String? location,
    String? note,
    String? trackingNumber,
    String? shippingMethod,
  }) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (description != null && description.isNotEmpty) {
        data['description'] = description;
      }
      if (location != null && location.isNotEmpty) {
        data['location'] = location;
      }
      if (note != null && note.isNotEmpty) {
        data['note'] = note;
      }
      if (trackingNumber != null && trackingNumber.isNotEmpty) {
        data['tracking_number'] = trackingNumber;
      }
      if (shippingMethod != null && shippingMethod.isNotEmpty) {
        data['shipping_method'] = shippingMethod;
      }

      await _dio.patch('/orders/$orderId/status', data: data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi cập nhật trạng thái đơn hàng',
      );
    }
  }

  // Lấy đơn hàng theo store (seller/admin)
  Future<List<Order>> getOrdersByStore(String storeId) async {
    try {
      print("OrderService: Gọi API backend GET /orders/store/$storeId");
      final response = await _dio.get('/orders/store/$storeId');

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        print("OrderService: Đã nhận ${data.length} đơn hàng từ store.");
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        print(
          "OrderService: Định dạng phản hồi không hợp lệ từ getOrdersByStore.",
        );
        return [];
      }
    } on DioException catch (e) {
      print(
        "OrderService: DioException khi lấy đơn hàng của store: ${e.response?.data ?? e.message}",
      );
      throw Exception(
        e.response?.data?['message'] ??
            'Lỗi mạng khi lấy đơn hàng của cửa hàng',
      );
    } catch (e) {
      print("OrderService: Lỗi không xác định khi lấy đơn hàng của store: $e");
      throw Exception(
        'Lỗi không xác định khi lấy đơn hàng của cửa hàng: ${e.toString()}',
      );
    }
  }
}
