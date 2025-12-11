import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/user.dart';

class UserService {
  final Dio _dio;

  UserService(this._dio);

  /// Helper để lấy message lỗi từ response một cách an toàn
  String _getErrorMessage(dynamic responseData, String defaultMessage) {
    if (responseData == null) return defaultMessage;
    if (responseData is Map<String, dynamic>) {
      return responseData['message']?.toString() ?? defaultMessage;
    }
    return defaultMessage;
  }

  // Lấy thông tin hồ sơ người dùng hiện tại (GET /users/profile/me)
  Future<User> getMyProfile() async {
    try {
      final response = await _dio.get('/users/profile/me');
      if (response.data is Map<String, dynamic>) {
        return User.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e.response?.data, 'Lỗi khi lấy thông tin người dùng'),
      );
    }
  }

  // Lấy danh sách users theo role (GET /users?role=SHIPPER)
  Future<List<User>> getUsersByRole(String role) async {
    try {
      final response = await _dio.get(
        '/users',
        queryParameters: {'role': role},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e.response?.data, 'Lỗi khi lấy danh sách người dùng'),
      );
    }
  }

  // Cập nhật thông tin hồ sơ người dùng hiện tại
  Future<User> updateProfile({
    String? fullName,
    String? email,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) {
        data['full_name'] = fullName;
      }
      if (email != null && email.isNotEmpty) {
        data['email'] = email;
      }

      final response = await _dio.put('/users/profile/me', data: data);
      if (response.data is Map<String, dynamic>) {
        return User.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e.response?.data, 'Lỗi khi cập nhật hồ sơ'),
      );
    }
  }
}
