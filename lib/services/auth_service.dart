import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// Helper để lấy message lỗi từ response một cách an toàn
  String _getErrorMessage(dynamic responseData, String defaultMessage) {
    if (responseData == null) return defaultMessage;
    if (responseData is Map<String, dynamic>) {
      // Trường hợp lỗi validation: { errors: [...] }
      if (responseData['errors'] != null && responseData['errors'] is List) {
        final errors = responseData['errors'] as List;
        if (errors.isNotEmpty && errors[0] is Map) {
          return errors[0]['msg']?.toString() ?? defaultMessage;
        }
      }
      // Trường hợp lỗi thông thường: { message: "..." }
      return responseData['message']?.toString() ?? defaultMessage;
    }
    return defaultMessage;
  }

  // ===== Đăng nhập =====
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, 'Lỗi đăng nhập'));
    }
  }

  // ===== Đăng ký tài khoản =====
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      if (response.data is Map<String, dynamic>) {
        // Trả về response data, bao gồm cả warning nếu email không gửi được
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, 'Lỗi đăng ký'));
    }
  }

  // ===== Xác thực email (OTP đăng ký) =====
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'email': email, 'code': code},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, 'Lỗi xác thực OTP'));
    }
  }

  // ===== Gửi lại email xác minh =====
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      final response = await _dio.post(
        '/auth/resend-verification-email',
        data: {'email': email},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, 'Lỗi gửi lại email xác minh'));
    }
  }

  // ===== Quên mật khẩu =====
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, 'Lỗi gửi email khôi phục'));
    }
  }

  // ===== Kiểm tra mã OTP khôi phục mật khẩu =====
  Future<Map<String, dynamic>> verifyResetCode(
    String email,
    String code,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/verify-reset-code',
        data: {'email': email, 'code': code},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, 'Mã xác thực không hợp lệ'));
    }
  }

  // ===== Đặt lại mật khẩu =====
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Phản hồi từ server không hợp lệ');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, 'Lỗi đặt lại mật khẩu'));
    }
  }

  // ===== Đăng xuất =====
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      // Không throw exception vì logout có thể thành công ngay cả khi server lỗi
      // (token đã được xóa ở client)
      print("DioException logout: ${e.response?.data}");
    } catch (e) {
      print("Exception logout: $e");
    }
  }
}
