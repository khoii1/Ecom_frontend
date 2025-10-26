import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class VnpayService {
  final Dio _dio;

  VnpayService(this._dio);

  /// Gọi backend để tạo URL thanh toán VNPay
  Future<String?> createPaymentUrl({
    required String orderId,
    required double amount,
    String language = 'vn',
    String? bankCode, // Optional
  }) async {
    try {
      print(
        "Requesting VNPay URL from backend for Order ID: $orderId, Amount: $amount",
      );
      final response = await _dio.post(
        '/payment/vnpay/create_payment_url',
        data: {
          'orderId': orderId,
          'amount': amount,
          'language': language,
          if (bankCode != null && bankCode.isNotEmpty) 'bankCode': bankCode,
        },
      );

      if (response.data != null && response.data['paymentUrl'] != null) {
        print("Received VNPay URL: ${response.data['paymentUrl']}");
        return response.data['paymentUrl'];
      } else {
        throw Exception('Không nhận được URL thanh toán từ server');
      }
      // Sửa: Bỏ Future<dynamic>
    } on DioException catch (e) {
      // <<< SỬA
      print("DioException creating VNPay URL: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi tạo URL thanh toán VNPay',
      );
    } catch (e) {
      print("Unknown error creating VNPay URL: $e");
      throw Exception('Lỗi không xác định khi tạo URL thanh toán VNPay');
    }
  }

  /// Mở URL thanh toán VNPay
  /// Trả về true nếu mở thành công, false nếu thất bại
  Future<bool> launchVNPayUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      print("Could not launch $url");
      return false;
    }
    // Mở trong trình duyệt ngoài (an toàn và đơn giản nhất)
    final bool launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      print("Failed to launch $url externally");
      // Có thể thử lại với WebView nếu external không được
      // final bool launchedInApp = await launchUrl(url, mode: LaunchMode.inAppWebView);
      // return launchedInApp;
    }
    return launched;
  }

  // Optional: Nếu dùng WebView
  // Widget buildVnpayWebView(String url) {
  //   return WebView(
  //     initialUrl: url,
  //     javascriptMode: JavascriptMode.unrestricted,
  //     navigationDelegate: (NavigationRequest request) {
  //       if (request.url.startsWith(process.env.FRONTEND_PAYMENT_REDIRECT_URL)) { // <<< CẦN CHECK URL CHÍNH XÁC
  //         print('Intercepted redirect: ${request.url}');
  //         // TODO: Parse params from request.url, close webview, navigate to result screen
  //         return NavigationDecision.prevent; // Ngăn không cho WebView điều hướng
  //       }
  //       return NavigationDecision.navigate; // Cho phép điều hướng đến cổng VNPay
  //     },
  //   );
  // }
}
