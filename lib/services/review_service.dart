import 'package:dio/dio.dart';
import 'dart:io';

class ReviewService {
  final Dio _dio;

  ReviewService(this._dio);

  // Lấy reviews của sản phẩm
  Future<Map<String, dynamic>> getProductReviews(String productId) async {
    try {
      final response = await _dio.get('/reviews/product/$productId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tải đánh giá');
    }
  }

  // Upload ảnh cho review
  Future<List<String>> uploadReviewImages(List<File> imageFiles) async {
    try {
      final formData = FormData();
      for (var file in imageFiles) {
        final fileName = file.path.split('/').last;
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      final response = await _dio.post(
        '/reviews/upload-images',
        data: formData,
      );
      return List<String>.from(response.data['image_urls'] ?? []);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi upload ảnh');
    }
  }

  // Tạo review mới
  Future<Map<String, dynamic>> createReview({
    required String productId,
    required String orderId,
    required int rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await _dio.post(
        '/reviews/product/$productId',
        data: {
          'rating': rating,
          'order_id': orderId,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (imageUrls != null && imageUrls.isNotEmpty)
            'image_urls': imageUrls,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi gửi đánh giá');
    }
  }

  // Cập nhật review
  Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await _dio.put(
        '/reviews/$reviewId',
        data: {
          'rating': rating,
          if (comment != null) 'comment': comment,
          if (imageUrls != null && imageUrls.isNotEmpty)
            'image_urls': imageUrls,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi cập nhật đánh giá',
      );
    }
  }

  // Xóa review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _dio.delete('/reviews/$reviewId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi xóa đánh giá');
    }
  }

  // Lấy reviews của user
  Future<List<Map<String, dynamic>>> getMyReviews() async {
    try {
      final response = await _dio.get('/reviews/my');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tải đánh giá');
    }
  }

  // Lấy reviews của store (bằng cách lấy reviews của tất cả products trong store)
  // Note: Backend chưa có endpoint riêng, nên sẽ lấy từng product
  Future<List<Map<String, dynamic>>> getStoreReviews(List<String> productIds) async {
    try {
      List<Map<String, dynamic>> allReviews = [];
      
      // Lấy reviews của từng product
      for (final productId in productIds) {
        try {
          final data = await getProductReviews(productId);
          final reviews = (data['reviews'] as List)
              .map((r) => {
                    ...r as Map<String, dynamic>,
                    'product_id': productId,
                  })
              .toList();
          allReviews.addAll(reviews);
        } catch (e) {
          // Bỏ qua nếu product không có reviews
          continue;
        }
      }
      
      // Sắp xếp theo thời gian mới nhất
      allReviews.sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] ?? '');
        final dateB = DateTime.parse(b['created_at'] ?? '');
        return dateB.compareTo(dateA);
      });
      
      return allReviews;
    } catch (e) {
      throw Exception('Lỗi khi tải đánh giá cửa hàng: ${e.toString()}');
    }
  }

  // Phản hồi review (chỉ seller)
  Future<Map<String, dynamic>> respondToReview({
    required String reviewId,
    required String response,
  }) async {
    try {
      final response_data = await _dio.put(
        '/reviews/$reviewId/response',
        data: {
          'response': response,
        },
      );
      return response_data.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi phản hồi đánh giá',
      );
    }
  }
}
