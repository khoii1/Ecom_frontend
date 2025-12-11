import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/notification.dart' as model;

class NotificationService {
  final Dio _dio;
  NotificationService(this._dio);

  // Lấy danh sách thông báo
  Future<List<model.Notification>> getMyNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (unreadOnly) 'unread_only': 'true',
        },
      );
      final List<dynamic> data = response.data;
      return data.map((json) => model.Notification.fromJson(json)).toList();
    } on DioException catch (e) {
      print("DioException getMyNotifications: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy thông báo');
    } catch (e) {
      print("Exception getMyNotifications: $e");
      throw Exception('Lỗi không xác định khi lấy thông báo');
    }
  }

  // Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      print("DioException getUnreadCount: ${e.response?.data}");
      return 0;
    } catch (e) {
      print("Exception getUnreadCount: $e");
      return 0;
    }
  }

  // Đánh dấu đã đọc
  Future<model.Notification> markAsRead(String notificationId) async {
    try {
      final response = await _dio.patch('/notifications/$notificationId/read');
      return model.Notification.fromJson(response.data);
    } on DioException catch (e) {
      print("DioException markAsRead: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi đánh dấu đã đọc');
    } catch (e) {
      print("Exception markAsRead: $e");
      throw Exception('Lỗi không xác định khi đánh dấu đã đọc');
    }
  }

  // Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      print("DioException markAllAsRead: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi đánh dấu tất cả đã đọc');
    } catch (e) {
      print("Exception markAllAsRead: $e");
      throw Exception('Lỗi không xác định khi đánh dấu tất cả đã đọc');
    }
  }

  // Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dio.delete('/notifications/$notificationId');
    } on DioException catch (e) {
      print("DioException deleteNotification: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa thông báo');
    } catch (e) {
      print("Exception deleteNotification: $e");
      throw Exception('Lỗi không xác định khi xóa thông báo');
    }
  }
}

