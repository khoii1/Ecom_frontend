import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/category.dart';

class CategoryService {
  final Dio _dio;
  CategoryService(this._dio);

  // Lấy danh sách danh mục sản phẩm
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/categories'); // API public
      final List<dynamic> data = response.data;
      return data.map((json) => Category.fromJson(json)).toList();
    } on DioException catch (e) {
      print("DioException khi lấy danh mục: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi lấy danh sách danh mục',
      );
    } catch (e) {
      print("Lỗi không xác định khi lấy danh mục: $e");
      throw Exception('Lỗi không xác định khi tải danh mục.');
    }
  }

  // Lấy danh sách danh mục kèm thống kê (số lượng sản phẩm)
  Future<List<Map<String, dynamic>>> getCategoryStats() async {
    try {
      final response = await _dio.get('/categories/stats');
      final List<dynamic> data = response.data;
      return data.map((json) => json as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      print("DioException getCategoryStats: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi lấy thống kê danh mục',
      );
    } catch (e) {
      print("Exception getCategoryStats: $e");
      throw Exception('Lỗi không xác định khi lấy thống kê danh mục');
    }
  }

  // Lấy danh sách danh mục dạng cây (tree structure)
  Future<List<Map<String, dynamic>>> getCategoryTree() async {
    try {
      final response = await _dio.get('/categories/tree');
      final List<dynamic> data = response.data;
      return data.map((json) => json as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      print("DioException getCategoryTree: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi lấy cây danh mục',
      );
    } catch (e) {
      print("Exception getCategoryTree: $e");
      throw Exception('Lỗi không xác định khi lấy cây danh mục');
    }
  }

  // Lấy chi tiết một danh mục
  Future<Category> getCategoryDetail(String categoryId) async {
    try {
      final response = await _dio.get('/categories/$categoryId');
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy danh mục');
      }
      print("DioException getCategoryDetail: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi lấy chi tiết danh mục',
      );
    } catch (e) {
      print("Exception getCategoryDetail: $e");
      throw Exception('Lỗi không xác định khi lấy chi tiết danh mục');
    }
  }
}
