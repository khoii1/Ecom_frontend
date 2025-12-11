import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/store.dart';

class StoreService {
  final Dio _dio;

  StoreService(this._dio);

  // Lấy danh sách cửa hàng thuộc người dùng hiện tại (GET /stores/my/stores)
  Future<List<Store>> getMyStores() async {
    try {
      final response = await _dio.get('/stores/my/stores');
      final List<dynamic> data = response.data;
      return data.map((json) => Store.fromJson(json)).toList();
    } on DioException catch (e) {
      // Nếu user chưa có cửa hàng nào -> trả về danh sách rỗng
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy cửa hàng');
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy cửa hàng');
    }
  }

  // Lấy danh sách tất cả cửa hàng (Public)
  Future<List<Store>> getAllStores() async {
    try {
      final response = await _dio.get('/stores');
      final List<dynamic> data = response.data;
      return data.map((json) => Store.fromJson(json)).toList();
    } on DioException catch (e) {
      print("DioException getAllStores: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy danh sách cửa hàng');
    } catch (e) {
      print("Exception getAllStores: $e");
      throw Exception('Lỗi không xác định khi lấy danh sách cửa hàng');
    }
  }

  // Lấy chi tiết một cửa hàng
  Future<Store> getStoreDetail(String storeId) async {
    try {
      final response = await _dio.get('/stores/$storeId');
      return Store.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy cửa hàng');
      }
      print("DioException getStoreDetail: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy chi tiết cửa hàng');
    } catch (e) {
      print("Exception getStoreDetail: $e");
      throw Exception('Lỗi không xác định khi lấy chi tiết cửa hàng');
    }
  }

  // Tạo cửa hàng mới (Seller/Admin)
  Future<Store> createStore({
    required String name,
    String? description,
    String? address,
    String? phone,
    String? email,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        if (address != null && address.isNotEmpty) 'address': address,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      final response = await _dio.post('/stores', data: data);
      return Store.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException createStore: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tạo cửa hàng');
    } catch (e) {
      print("Exception createStore: $e");
      throw Exception('Lỗi không xác định khi tạo cửa hàng');
    }
  }

  // Cập nhật cửa hàng
  Future<Store> updateStore(
    String storeId, {
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null && name.isNotEmpty) data['name'] = name;
      if (description != null) data['description'] = description;
      if (address != null) data['address'] = address;
      if (phone != null) data['phone'] = phone;
      if (email != null) data['email'] = email;
      if (status != null) data['status'] = status;

      final response = await _dio.put('/stores/$storeId', data: data);
      return Store.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException updateStore: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi cập nhật cửa hàng');
    } catch (e) {
      print("Exception updateStore: $e");
      throw Exception('Lỗi không xác định khi cập nhật cửa hàng');
    }
  }

  // Xóa cửa hàng
  Future<void> deleteStore(String storeId) async {
    try {
      await _dio.delete('/stores/$storeId');
    } on DioException catch (e) {
      print("DioException deleteStore: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa cửa hàng');
    } catch (e) {
      print("Exception deleteStore: $e");
      throw Exception('Lỗi không xác định khi xóa cửa hàng');
    }
  }
}
