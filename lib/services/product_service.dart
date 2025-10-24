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

  // --- SỬA: BẮT ĐẦU THÊM MỚI ---
  // GET /products/:productId - Lấy chi tiết sản phẩm theo ID
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
      // Bắt các lỗi khác (ví dụ: lỗi parsing JSON nếu backend trả về sai định dạng)
      print("Lỗi không xác định khi lấy chi tiết sản phẩm: $e");
      throw Exception('Lỗi không xác định khi lấy chi tiết sản phẩm');
    }
  }
  // --- SỬA: KẾT THÚC THÊM MỚI ---

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
      // Kiểm tra kỹ key trả về từ backend (có thể là 'image_url' hoặc 'imageUrl')
      return response.data['image_url'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi upload ảnh');
    } catch (e) {
      // Bắt các lỗi khác
      print("Lỗi không xác định khi upload ảnh: $e");
      throw Exception('Lỗi không xác định khi upload ảnh');
    }
  }

  // POST /products
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
        'status': 'active', // Đảm bảo status được gửi đi
      };

      final response = await _dio.post('/products', data: productData);
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      // In ra lỗi chi tiết hơn từ Dio
      print("DioException khi tạo sản phẩm: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tạo sản phẩm');
    } catch (e) {
      // Bắt các lỗi khác (ví dụ: lỗi parsing JSON)
      print("Lỗi không xác định khi tạo sản phẩm: $e");
      throw Exception('Lỗi không xác định khi tạo sản phẩm');
    }
  }
}
