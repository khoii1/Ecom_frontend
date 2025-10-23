import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/user.dart';

class UserService {
  final Dio _dio;

  UserService(this._dio);

  Future<User> getMyProfile() async {
    try {
      final response = await _dio.get('/users/profile/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi lấy thông tin người dùng',
      );
    }
  }
}
