import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đăng nhập');
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'USER',
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register', //
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đăng ký');
    }
  }

  // <-- THÊM CÁC HÀM MỚI -->

  // POST /auth/verify-email
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email', //
        data: {'email': email, 'code': code},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi xác thực OTP');
    }
  }

  // POST /auth/forgot-password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password', //
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi gửi email');
    }
  }

  // POST /auth/reset-password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password', //
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đặt lại mật khẩu');
    }
  }
}
