import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/conversation.dart';
import 'package:ecom_frontend/models/message.dart';

class ChatService {
  final Dio _dio;

  ChatService(this._dio);

  // Lấy danh sách conversations
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _dio.get('/conversations');
      return (response.data as List)
          .map((json) => Conversation.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải danh sách cuộc trò chuyện',
      );
    }
  }

  // Tạo conversation mới
  Future<Conversation> createConversation({
    required String storeId,
    String? productId,
    String? orderId,
  }) async {
    try {
      final response = await _dio.post(
        '/conversations',
        data: {
          'store_id': storeId,
          if (productId != null) 'product_id': productId,
          if (orderId != null) 'order_id': orderId,
        },
      );
      return Conversation.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tạo cuộc trò chuyện',
      );
    }
  }

  // Lấy chi tiết conversation
  Future<Conversation> getConversation(String conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId');
      return Conversation.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải cuộc trò chuyện',
      );
    }
  }

  // Lấy messages của conversation
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/conversations/$conversationId/messages',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi tải tin nhắn',
      );
    }
  }

  // Upload ảnh cho chat
  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/conversations/upload-image',
        data: formData,
      );
      return response.data['image_url'] as String;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi upload ảnh',
      );
    }
  }

  // Gửi message
  Future<Message> sendMessage({
    required String conversationId,
    String message = '',
    String messageType = 'text',
    String? imageUrl,
    String? productId,
  }) async {
    try {
      final data = <String, dynamic>{
        'message_type': messageType,
      };
      
      // Chỉ thêm message nếu có
      if (message.isNotEmpty) {
        data['message'] = message;
      }
      
      // Thêm image_url nếu có
      if (imageUrl != null) {
        data['image_url'] = imageUrl;
      }
      
      // Thêm product_id nếu có
      if (productId != null) {
        data['product_id'] = productId;
      }
      
      final response = await _dio.post(
        '/conversations/$conversationId/messages',
        data: data,
      );
      return Message.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi gửi tin nhắn',
      );
    }
  }

  // Xóa cuộc hội thoại
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dio.delete('/conversations/$conversationId');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi xóa cuộc trò chuyện',
      );
    }
  }
}

