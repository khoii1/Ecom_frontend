import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/product.dart';

class ProductService {
  final Dio _dio;
  ProductService(this._dio);

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi lấy sản phẩm');
    }
  }

  // POST /products/upload-image
  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });
      final response = await _dio.post(
        '/products/upload-image',
        data: formData,
      );
      return response.data['image_url']; // Trả về URL ảnh đã upload
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi upload ảnh');
    }
  }

  // POST /products
  Future<Product> addProduct({
    required String storeId,
    required String title,
    required double price,
    String? description, // <-- THÊM MỚI
    double? discountedPrice, // <-- THÊM MỚI
    String? categoryId, // <-- THÊM MỚI
    String? imageUrl,
  }) async {
    try {
      final Map<String, dynamic> productData = {
        'store_id': storeId,
        'title': title,
        'price': price,
        if (description != null && description.isNotEmpty)
          'description': description, // <-- THÊM MỚI
        if (discountedPrice != null)
          'discounted_price': discountedPrice, // <-- THÊM MỚI
        if (categoryId != null && categoryId.isNotEmpty)
          'category_id': categoryId, // <-- THÊM MỚI
        if (imageUrl != null) 'image_url': imageUrl,
        'status': 'active', // Mặc định là active
      };

      final response = await _dio.post('/products', data: productData);
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tạo sản phẩm');
    }
  }
}
