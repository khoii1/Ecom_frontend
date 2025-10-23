import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ecom_frontend/services/storage_service.dart';
import 'package:ecom_frontend/utils/app_config.dart';

class ApiClient {
  final Dio dio;
  final StorageService _storageService;

  ApiClient(this.dio, this._storageService) {
    dio.options.baseUrl = AppConfig.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Lấy token từ storage
          final accessToken = await _storageService.readToken('access_token');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Xử lý lỗi 401 (Token hết hạn)
          if (e.response?.statusCode == 401) {
            debugPrint("Token hết hạn, yêu cầu đăng nhập lại");
            // Xóa token và chuyển về màn hình đăng nhập
            await _storageService.deleteAllTokens();
          }
          return handler.next(e);
        },
      ),
    );
  }
}
