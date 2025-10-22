import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/product.dart';

class ProductService {
  final Dio _dio;
  ProductService(this._dio);

  Future<List<Product>> getProducts() async {
    try {
      // Endpoint này là public
      final response = await _dio.get('/products');
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi lấy sản phẩm');
    }
  }

  // TODO: Thêm hàm getProductDetail(String id)
}
