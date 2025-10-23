import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/store.dart';

class StoreService {
  final Dio _dio;

  StoreService(this._dio);

  // GET /stores/my/stores - Lấy các cửa hàng của user hiện tại
  Future<List<Store>> getMyStores() async {
    try {
      final response = await _dio.get('/stores/my/stores');
      final List<dynamic> data = response.data;
      return data.map((json) => Store.fromJson(json)).toList();
    } on DioException catch (e) {
      // Có thể user chưa có store nào -> trả về list rỗng thay vì ném lỗi
      if (e.response?.statusCode == 404) {
        return []; // Hoặc xử lý theo cách khác nếu backend trả 404
      }
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy cửa hàng');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy cửa hàng');
    }
  }

  // Thêm các hàm khác nếu cần (createStore, updateStore, etc.)
}
