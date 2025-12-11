import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/address.dart';

class AddressService {
  final Dio _dio;
  AddressService(this._dio);

  // Lấy tất cả địa chỉ
  Future<List<Address>> getMyAddresses() async {
    try {
      final response = await _dio.get('/addresses');
      final List<dynamic> data = response.data;
      return data.map((json) => Address.fromJson(json)).toList();
    } on DioException catch (e) {
      print("DioException getMyAddresses: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy danh sách địa chỉ');
    } catch (e) {
      print("Exception getMyAddresses: $e");
      throw Exception('Lỗi không xác định khi lấy danh sách địa chỉ');
    }
  }

  // Lấy địa chỉ mặc định
  Future<Address?> getDefaultAddress() async {
    try {
      final response = await _dio.get('/addresses/default');
      return Address.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      print("DioException getDefaultAddress: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy địa chỉ mặc định');
    } catch (e) {
      print("Exception getDefaultAddress: $e");
      throw Exception('Lỗi không xác định khi lấy địa chỉ mặc định');
    }
  }

  // Tạo địa chỉ mới
  Future<Address> createAddress(Address address) async {
    try {
      final response = await _dio.post('/addresses', data: address.toJson());
      return Address.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException createAddress: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tạo địa chỉ');
    } catch (e) {
      print("Exception createAddress: $e");
      throw Exception('Lỗi không xác định khi tạo địa chỉ');
    }
  }

  // Cập nhật địa chỉ
  Future<Address> updateAddress(String addressId, Address address) async {
    try {
      final response = await _dio.put('/addresses/$addressId', data: address.toJson());
      return Address.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException updateAddress: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi cập nhật địa chỉ');
    } catch (e) {
      print("Exception updateAddress: $e");
      throw Exception('Lỗi không xác định khi cập nhật địa chỉ');
    }
  }

  // Xóa địa chỉ
  Future<void> deleteAddress(String addressId) async {
    try {
      await _dio.delete('/addresses/$addressId');
    } on DioException catch (e) {
      print("DioException deleteAddress: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa địa chỉ');
    } catch (e) {
      print("Exception deleteAddress: $e");
      throw Exception('Lỗi không xác định khi xóa địa chỉ');
    }
  }

  // Set địa chỉ làm mặc định
  Future<Address> setDefaultAddress(String addressId) async {
    try {
      final response = await _dio.patch('/addresses/$addressId/set-default');
      return Address.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException setDefaultAddress: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi đặt địa chỉ mặc định');
    } catch (e) {
      print("Exception setDefaultAddress: $e");
      throw Exception('Lỗi không xác định khi đặt địa chỉ mặc định');
    }
  }
}

