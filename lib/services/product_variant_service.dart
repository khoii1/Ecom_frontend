import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/product_variant.dart';

class ProductVariantService {
  final Dio _dio;
  ProductVariantService(this._dio);

  // Lấy tất cả variants của một sản phẩm
  Future<List<ProductVariant>> getProductVariants(String productId) async {
    try {
      final response = await _dio.get('/products/$productId/variants');
      final List<dynamic> data = response.data;
      return data.map((json) => ProductVariant.fromJson(json)).toList();
    } on DioException catch (e) {
      print("DioException getProductVariants: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy biến thể sản phẩm');
    } catch (e) {
      print("Exception getProductVariants: $e");
      throw Exception('Lỗi không xác định khi lấy biến thể sản phẩm');
    }
  }

  // Lấy chi tiết một variant theo ID
  Future<ProductVariant> getVariantById(String variantId) async {
    try {
      final response = await _dio.get('/variants/$variantId');
      return ProductVariant.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy biến thể sản phẩm');
      }
      print("DioException getVariantById: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy chi tiết biến thể');
    } catch (e) {
      print("Exception getVariantById: $e");
      throw Exception('Lỗi không xác định khi lấy chi tiết biến thể');
    }
  }

  // Tạo variant mới cho sản phẩm (Seller/Admin)
  Future<ProductVariant> createVariant({
    required String productId,
    required String name,
    required String value,
  }) async {
    try {
      final response = await _dio.post(
        '/products/$productId/variants',
        data: {
          'name': name,
          'value': value,
        },
      );
      return ProductVariant.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException createVariant: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tạo biến thể sản phẩm');
    } catch (e) {
      print("Exception createVariant: $e");
      throw Exception('Lỗi không xác định khi tạo biến thể sản phẩm');
    }
  }

  // Cập nhật variant
  Future<ProductVariant> updateVariant({
    required String variantId,
    String? name,
    String? value,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null && name.isNotEmpty) data['name'] = name;
      if (value != null && value.isNotEmpty) data['value'] = value;

      final response = await _dio.put('/variants/$variantId', data: data);
      return ProductVariant.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException updateVariant: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi cập nhật biến thể');
    } catch (e) {
      print("Exception updateVariant: $e");
      throw Exception('Lỗi không xác định khi cập nhật biến thể');
    }
  }

  // Xóa variant
  Future<void> deleteVariant(String variantId) async {
    try {
      await _dio.delete('/variants/$variantId');
    } on DioException catch (e) {
      print("DioException deleteVariant: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa biến thể');
    } catch (e) {
      print("Exception deleteVariant: $e");
      throw Exception('Lỗi không xác định khi xóa biến thể');
    }
  }
}

