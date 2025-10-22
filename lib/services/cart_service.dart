import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/cart.dart';
import 'package:ecom_frontend/models/cart_item.dart';

class CartService {
  final Dio _dio;
  CartService(this._dio);

  // GET /cart
  Future<Cart> getMyCart() async {
    try {
      final response = await _dio.get('/cart');
      return Cart.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy giỏ hàng');
    }
  }

  // POST /cart/items
  Future<CartItem> addItem(String productId, int qty) async {
    try {
      final response = await _dio.post(
        '/cart/items',
        data: {
          'product_id': productId,
          'qty': qty,
        },
      );
      // API backend của bạn trả về cart_item đã tạo/cập nhật
      // Chúng ta cần giả lập lại đối tượng CartItem đầy đủ vì API /cart/items
      // không trả về tên và giá sản phẩm.
      // Tạm thời trả về dữ liệu thô, CartProvider sẽ fetch lại giỏ hàng.
      // return CartItem.fromJson(response.data); 
      // -> Đây là cách tốt hơn:
      return response.data; // Trả về dữ liệu thô, provider sẽ fetch lại
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi thêm sản phẩm');
    }
  }

  // PUT /cart/items/:itemId
  Future<void> updateItem(String cartItemId, int qty) async {
    try {
      await _dio.put(
        '/cart/items/$cartItemId',
        data: {'qty': qty},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi cập nhật số lượng');
    }
  }

  // DELETE /cart/items/:itemId
  Future<void> removeItem(String cartItemId) async {
    try {
      await _dio.delete('/cart/items/$cartItemId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa sản phẩm');
    }
  }

  // DELETE /cart
  Future<void> clearCart() async {
    try {
      await _dio.delete('/cart');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa giỏ hàng');
    }
  }
}
