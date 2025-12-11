import 'package:dio/dio.dart';
import 'package:ecom_frontend/models/banner.dart';

class BannerService {
  final Dio _dio;
  BannerService(this._dio);

  // Lấy danh sách banners với bộ lọc
  Future<List<Banner>> getBanners({
    String? position,
    bool? activeOnly,
    bool? validOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (position != null) queryParams['position'] = position;
      if (activeOnly != null) queryParams['active_only'] = activeOnly.toString();
      if (validOnly != null) queryParams['valid_only'] = validOnly.toString();

      final response = await _dio.get('/banners', queryParameters: queryParams);
      final List<dynamic> data = response.data;
      return data.map((json) => Banner.fromJson(json)).toList();
    } on DioException catch (e) {
      print("DioException getBanners: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi lấy banners');
    } catch (e) {
      print("Exception getBanners: $e");
      throw Exception('Lỗi không xác định khi lấy banners');
    }
  }

  // Lấy banners cho trang chủ (home_top, home_middle, home_bottom)
  Future<List<Banner>> getHomeBanners() async {
    try {
      // Lấy tất cả banners active và valid, không filter position
      final banners = await getBanners(
        position: null, // Lấy tất cả
        activeOnly: true,
        validOnly: true,
      );
      
      print("Tổng số banners từ API: ${banners.length}");
      
      // Lọc các banner có position phù hợp với home (home_top, home_middle, home_bottom)
      final homeBanners = banners
          .where((b) {
            final isValidPosition = b.position.startsWith('home_');
            final isValid = b.isValid;
            print("Banner: ${b.title}, position: ${b.position}, isValid: $isValid, isValidPosition: $isValidPosition");
            return isValidPosition && isValid;
          })
          .toList();
      
      print("Số banners phù hợp với home: ${homeBanners.length}");
      
      // Sắp xếp theo display_order
      homeBanners.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      
      return homeBanners;
    } catch (e) {
      print("Exception getHomeBanners: $e");
      return []; // Trả về list rỗng nếu có lỗi
    }
  }

  // Ghi nhận click vào banner
  Future<void> trackBannerClick(String bannerId) async {
    try {
      await _dio.post('/banners/$bannerId/click');
    } catch (e) {
      // Silent fail - không cần xử lý lỗi
      print("Error tracking banner click: $e");
    }
  }
}

