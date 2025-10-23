import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/category.dart';

class CategoryService {
  final Dio _dio;
  CategoryService(this._dio);

  // GET /categories
  Future<List<Category>> getCategories() async {
    try {
      // API này là public, không cần token
      final response = await _dio.get('/categories');
      final List<dynamic> data = response.data;
      // .fromJson sẽ tự động xử lý trường imageUrl mới
      return data.map((json) => Category.fromJson(json)).toList();
    } on DioException catch (e) {
      print(
        "DioException khi lấy categories: ${e.response?.data}",
      ); // Log lỗi chi tiết
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi lấy danh sách danh mục',
      );
    } catch (e) {
      print("Lỗi không xác định khi lấy categories: $e");
      throw Exception('Lỗi không xác định khi tải danh mục.');
    }
  }
}
