import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/product.dart';

class WishlistService {
  final Dio _dio;
  WishlistService(this._dio);

  // Lấy danh sách yêu thích
  Future<List<Product>> getMyWishlist() async {
    try {
      final response = await _dio.get('/wishlist');
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      print("DioException getMyWishlist: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy danh sách yêu thích');
    } catch (e) {
      print("Exception getMyWishlist: $e");
      throw Exception('Lỗi không xác định khi lấy danh sách yêu thích');
    }
  }

  // Kiểm tra sản phẩm có trong wishlist không
  Future<bool> checkInWishlist(String productId) async {
    try {
      final response = await _dio.get('/wishlist/check/$productId');
      return response.data['isInWishlist'] ?? false;
    } on DioException catch (e) {
      print("DioException checkInWishlist: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Exception checkInWishlist: $e");
      return false;
    }
  }

  // Thêm vào wishlist
  Future<void> addToWishlist(String productId) async {
    try {
      await _dio.post('/wishlist', data: {'product_id': productId});
    } on DioException catch (e) {
      print("DioException addToWishlist: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi thêm vào danh sách yêu thích',
      );
    } catch (e) {
      print("Exception addToWishlist: $e");
      throw Exception('Lỗi không xác định khi thêm vào danh sách yêu thích');
    }
  }

  // Xóa khỏi wishlist
  Future<void> removeFromWishlist(String productId) async {
    try {
      await _dio.delete('/wishlist/$productId');
    } on DioException catch (e) {
      print("DioException removeFromWishlist: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi xóa khỏi danh sách yêu thích',
      );
    } catch (e) {
      print("Exception removeFromWishlist: $e");
      throw Exception('Lỗi không xác định khi xóa khỏi danh sách yêu thích');
    }
  }

  // Xóa tất cả khỏi wishlist
  Future<void> clearWishlist() async {
    try {
      await _dio.delete('/wishlist');
    } on DioException catch (e) {
      print("DioException clearWishlist: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi xóa tất cả khỏi danh sách yêu thích',
      );
    } catch (e) {
      print("Exception clearWishlist: $e");
      throw Exception('Lỗi không xác định khi xóa tất cả khỏi danh sách yêu thích');
    }
  }
}

