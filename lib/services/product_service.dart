import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/product.dart';

class ProductService {
  final Dio _dio;
  ProductService(this._dio);

  // Lấy danh sách sản phẩm
  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi lấy sản phẩm');
    }
  }

  // Lấy chi tiết 1 sản phẩm theo ID
  Future<Product> getProductDetail(String productId) async {
    try {
      final response = await _dio.get('/products/$productId');
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy sản phẩm');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi lấy chi tiết sản phẩm',
      );
    } catch (e) {
      print("Lỗi không xác định khi lấy chi tiết sản phẩm: $e");
      throw Exception('Lỗi không xác định khi lấy chi tiết sản phẩm');
    }
  }

  // Upload ảnh sản phẩm -> trả về URL ảnh
  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });
      final response = await _dio.post(
        '/products/upload-image',
        data: formData,
      );
      // Tùy backend: có thể trả về 'image_url' hoặc 'imageUrl'
      return response.data['image_url'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi upload ảnh');
    } catch (e) {
      print("Lỗi không xác định khi upload ảnh: $e");
      throw Exception('Lỗi không xác định khi upload ảnh');
    }
  }

  // Tạo sản phẩm mới
  Future<Product> addProduct({
    required String storeId,
    required String title,
    required double price,
    String? description,
    double? discountPercentage,
    String? categoryId,
    String? imageUrl,
  }) async {
    try {
      final Map<String, dynamic> productData = {
        'store_id': storeId,
        'title': title,
        'price': price,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (discountPercentage != null)
          'discount_percentage': discountPercentage,
        if (categoryId != null && categoryId.isNotEmpty)
          'category_id': categoryId,
        if (imageUrl != null) 'image_url': imageUrl,
        'status': 'active',
      };

      final response = await _dio.post('/products', data: productData);
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException khi tạo sản phẩm: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tạo sản phẩm');
    } catch (e) {
      print("Lỗi không xác định khi tạo sản phẩm: $e");
      throw Exception('Lỗi không xác định khi tạo sản phẩm');
    }
  }
}
