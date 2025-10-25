import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/cart.dart';
// Bỏ import CartItem vì hàm add/update không cần trả về nữa
// import 'package:ecom_frontend/models/cart_item.dart';

class CartService {
  final Dio _dio;
  CartService(this._dio);

  // GET /cart - Lấy giỏ hàng của user hiện tại
  Future<Cart> getMyCart() async {
    try {
      final response = await _dio.get('/cart');
      // Backend đã trả về đúng cấu trúc Cart rồi
      return Cart.fromJson(response.data);
    // SỬA: Bỏ Future<dynamic> khỏi mệnh đề on
    } on DioException catch (e) { // <<< SỬA Ở ĐÂY
    // --- KẾT THÚC SỬA ---
      if (e.response?.statusCode == 404) {
        // Trả về Cart rỗng với subtotal = 0
        return Cart(cartId: '', items: [], subtotal: 0.0);
      }
      print("DioException getMyCart: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy giỏ hàng');
    } catch (e) {
      print("Exception getMyCart: $e");
      throw Exception('Lỗi không xác định khi lấy giỏ hàng');
    }
  }

  // POST /cart/items - Thêm sản phẩm vào giỏ
  Future<void> addItemToCart(String productId, int quantity) async {
    try {
      await _dio.post(
        '/cart/items',
        data: {
          'product_id': productId,
          'qty': quantity,
        },
      );
    // SỬA: Bỏ Future<dynamic> khỏi mệnh đề on
    } on DioException catch (e) { // <<< SỬA Ở ĐÂY
    // --- KẾT THÚC SỬA ---
      print("DioException addItemToCart: ${e.response?.data}");
      throw Exception(
          e.response?.data['message'] ?? 'Lỗi khi thêm vào giỏ hàng');
    } catch (e) {
      print("Exception addItemToCart: $e");
      throw Exception('Lỗi không xác định khi thêm vào giỏ hàng');
    }
  }

  // PUT /cart/items/:itemId - Cập nhật số lượng item
  Future<void> updateCartItem(String itemId, int quantity) async {
    try {
      await _dio.put(
        '/cart/items/$itemId',
        data: {'qty': quantity},
      );
    // SỬA: Bỏ Future<dynamic> khỏi mệnh đề on
    } on DioException catch (e) { // <<< SỬA Ở ĐÂY
    // --- KẾT THÚC SỬA ---
       print("DioException updateCartItem: ${e.response?.data}");
      throw Exception(
          e.response?.data['message'] ?? 'Lỗi khi cập nhật giỏ hàng');
    } catch (e) {
       print("Exception updateCartItem: $e");
      throw Exception('Lỗi không xác định khi cập nhật giỏ hàng');
    }
  }

  // DELETE /cart/items/:itemId - Xóa item khỏi giỏ
  Future<void> removeCartItem(String itemId) async {
    try {
      await _dio.delete('/cart/items/$itemId');
    // SỬA: Bỏ Future<dynamic> khỏi mệnh đề on
    } on DioException catch (e) { // <<< SỬA Ở ĐÂY
    // --- KẾT THÚC SỬA ---
       print("DioException removeCartItem: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa khỏi giỏ hàng');
    } catch (e) {
       print("Exception removeCartItem: $e");
       throw Exception('Lỗi không xác định khi xóa khỏi giỏ hàng');
    }
  }

  // DELETE /cart - Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    try {
      await _dio.delete('/cart');
    // SỬA: Bỏ Future<dynamic> khỏi mệnh đề on
    } on DioException catch (e) { // <<< SỬA Ở ĐÂY
    // --- KẾT THÚC SỬA ---
       print("DioException clearCart: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa giỏ hàng');
    } catch (e) {
       print("Exception clearCart: $e");
       throw Exception('Lỗi không xác định khi xóa giỏ hàng');
    }
  }
}
