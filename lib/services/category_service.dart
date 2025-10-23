import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/category.dart';

class CategoryService {
  final Dio _dio;

  CategoryService(this._dio);

  // GET /categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      final List<dynamic> data = response.data;
      return data.map((json) => Category.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy danh mục');
    }
  }
}
