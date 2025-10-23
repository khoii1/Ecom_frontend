import 'package:ecom_frontend/models/user.dart';
import 'package:ecom_frontend/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/services/auth_service.dart';
import 'package:ecom_frontend/services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;
  final UserService _userService;

  AuthStatus _authStatus = AuthStatus.unknown;
  AuthStatus get authStatus => _authStatus;

  String? _accessToken;
  String? get accessToken => _accessToken;

  User? _currentUser;
  User? get currentUser => _currentUser;

  AuthProvider(this._authService, this._storageService, this._userService) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Chỉ cần kiểm tra access_token
    final token = await _storageService.readToken('access_token');
    if (token != null) {
      _accessToken = token;
      try {
        _currentUser = await _userService.getMyProfile();
        _authStatus = AuthStatus.authenticated;
      } catch (e) {
        await logout(); // Xóa token cũ nếu không hợp lệ
        _authStatus = AuthStatus.unauthenticated;
      }
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      // API response chỉ chứa access_token
      final responseData = await _authService.login(email, password);

      final accessToken = responseData['access_token'];

      // Chỉ kiểm tra access_token
      if (accessToken is String) {
        _accessToken = accessToken;

        // Chỉ lưu access_token
        await _storageService.saveToken('access_token', accessToken);
        // Không lưu refresh_token nữa
        // await _storageService.saveToken('refresh_token', refreshToken);

        _currentUser = await _userService.getMyProfile();
        _authStatus = AuthStatus.authenticated;
        notifyListeners();
        return null; // Đăng nhập thành công
      } else {
        // Nếu API không trả về access_token như mong đợi
        throw Exception("API không trả về access_token hợp lệ.");
      }
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _currentUser = null;
      await _storageService.deleteAllTokens(); // Xóa hết token khi có lỗi
      notifyListeners();
      if (e is Exception && e.toString().contains('Sai thông tin đăng nhập')) {
        return 'Sai thông tin đăng nhập hoặc tài khoản chưa kích hoạt.';
      }
      return e.toString();
    }
  }

  Future<void> logout() async {
    // Chỉ cần xóa access_token (hoặc xóa hết cho chắc)
    await _storageService.deleteAllTokens();
    _accessToken = null;
    _currentUser = null;
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // --- Các hàm khác giữ nguyên ---
  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> verifyEmail(String email, String code) async {
    try {
      await _authService.verifyEmail(email, code);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await _authService.forgotPassword(email);
      return null;
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
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
