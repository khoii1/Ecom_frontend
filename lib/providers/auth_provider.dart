import 'package:flutter/material.dart';
import 'package:ecom_frontend/services/auth_service.dart';
import 'package:ecom_frontend/services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  AuthStatus _authStatus = AuthStatus.unknown;
  AuthStatus get authStatus => _authStatus;

  String? _accessToken;
  String? get accessToken => _accessToken;

  AuthProvider(this._authService, this._storageService) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _storageService.readToken('access_token');
    if (token != null) {
      _accessToken = token;
      _authStatus = AuthStatus.authenticated;
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      final tokens = await _authService.login(email, password);

      _accessToken = tokens['access_token'];
      await _storageService.saveToken('access_token', tokens['access_token']);
      await _storageService.saveToken('refresh_token', tokens['refresh_token']);

      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return null; // Thành công
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return e.toString(); // Trả về lỗi
    }
  }

  // <-- CẬP NHẬT/THÊM HÀM MỚI -->

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      // Backend sẽ gửi email OTP tại đây
      await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      return null; // Đăng ký thành công
    } catch (e) {
      return e.toString(); // Trả về lỗi
    }
  }

  Future<String?> verifyEmail(String email, String code) async {
    try {
      await _authService.verifyEmail(email, code);
      return null; // Xác thực thành công
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      // Backend sẽ gửi email OTP tại đây
      await _authService.forgotPassword(email);
      return null; // Gửi yêu cầu thành công
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _authService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return null; // Reset thành công
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _storageService.deleteAllTokens();
    _accessToken = null;
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
