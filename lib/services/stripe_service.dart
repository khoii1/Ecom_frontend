import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart'; // Import để dùng BuildContext

class StripeService {
  final Dio _dio; // Dio instance đã cấu hình (với base URL và interceptor)

  StripeService(this._dio);

  /// Gọi backend tạo PaymentIntent và lấy clientSecret.
  ///
  /// Cần truyền `amount` (số tiền cuối cùng cần thanh toán) và `orderId` (ID đơn hàng đã tạo).
  Future<String?> _createPaymentIntent({
    required double amount,
    String currency = 'vnd',
    String? orderId,
  }) async {
    try {
      // Stripe yêu cầu amount là số nguyên (đơn vị nhỏ nhất). Với VND, không cần nhân 100.
      final int amountInt = amount.round();
      print(
        "Requesting Payment Intent from backend for amount: $amountInt $currency (Order: ${orderId ?? 'N/A'})",
      );

      final response = await _dio.post(
        '/payment/stripe/create-payment-intent', // Endpoint backend
        data: {
          'amount': amountInt,
          'currency': currency,
          'orderId': orderId, // Gửi orderId để backend lưu vào metadata
        },
      );
      if (response.data != null && response.data['clientSecret'] != null) {
        print("Received client secret.");
        return response.data['clientSecret'];
      } else {
        String serverMessage =
            response.data?['message'] ??
            'Không nhận được client secret từ server';
        throw Exception(serverMessage);
      }
    } on DioException catch (e) {
      print(
        "Error creating Payment Intent on backend: ${e.response?.statusCode} ${e.response?.data}",
      );
      throw Exception(
        e.response?.data?['message'] ?? 'Lỗi tạo phiên thanh toán Stripe',
      );
    } catch (e) {
      print("Unknown error creating Payment Intent: $e");
      throw Exception('Lỗi không xác định khi tạo phiên thanh toán Stripe');
    }
  }

  /// Khởi tạo và hiển thị Stripe Payment Sheet.
  ///
  /// Cần truyền `context`, `amount`, `orderId`, và `merchantDisplayName`.
  Future<void> presentPaymentSheet(
    BuildContext context, {
    required double amount,
    String currency = 'vnd',
    String? orderId,
    String merchantDisplayName = 'Ecom App',
  }) async {
    String? clientSecret;
    try {
      // 1. Lấy client secret từ backend
      clientSecret = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        orderId: orderId,
      );
      // _createPaymentIntent sẽ throw Exception nếu thất bại

      // 2. Khởi tạo Payment Sheet
      print("Initializing Payment Sheet...");
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret!, // Đảm bảo không null
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.system, // Hoặc .light / .dark
          // Bật Google Pay/Apple Pay nếu cần và đã cấu hình native
          // googlePay: PaymentSheetGooglePay( merchantCountryCode: 'VN', testEnv: true, currencyCode: currency.toUpperCase()),
          // applePay: PaymentSheetApplePay( merchantCountryCode: 'VN'),
          allowsDelayedPaymentMethods:
              false, // Tắt nếu không muốn phương thức chờ
        ),
      );

      // 3. Hiển thị Payment Sheet
      print("Presenting Payment Sheet...");
      // await Future.delayed(Duration(seconds: 1)); // Delay nhỏ nếu cần để sheet init xong
      await Stripe.instance.presentPaymentSheet();

      print("Payment Sheet closed successfully.");
      // Sheet đóng KHÔNG đảm bảo thanh toán thành công, cần kiểm tra lại từ backend
    } on StripeException catch (e) {
      // Lỗi từ Stripe SDK (ví dụ: thẻ không hợp lệ, user hủy)
      print(
        "StripeException during payment sheet: ${e.error.code} - ${e.error.message}",
      );
      // Ném lại lỗi để UI xử lý
      if (e.error.code == FailureCode.Canceled) {
        throw Exception('Bạn đã hủy thanh toán.');
      } else {
        throw Exception(
          'Lỗi thanh toán: ${e.error.localizedMessage ?? e.error.message ?? 'Unknown Stripe Error'}',
        );
      }
    } catch (e) {
      // Các lỗi khác (ví dụ: lỗi mạng khi gọi backend, lỗi khởi tạo sheet từ _createPaymentIntent)
      print("Error presenting payment sheet: $e");
      // Ném lại lỗi gốc để UI hiển thị
      throw e;
    }
  }

  /// Hàm gọi backend để kiểm tra trạng thái đơn hàng sau thanh toán.
  ///
  /// **QUAN TRỌNG:** Bạn cần triển khai endpoint backend tương ứng (ví dụ: `GET /orders/:orderId/status`).
  Future<String?> checkOrderStatus(String orderId) async {
    try {
      print("Checking order status for $orderId...");
      // --- TODO: Triển khai Endpoint Backend ---
      // Ví dụ: Tạo endpoint GET /orders/:orderId/status trả về { "status": "paid" } hoặc { "status": "pending" }
      // final response = await _dio.get('/orders/$orderId/status');
      // if (response.data != null && response.data['status'] != null) {
      //    print("Backend status for order $orderId: ${response.data['status']}");
      //    return response.data['status']; // Ví dụ: 'paid', 'pending', 'payment_failed'
      // } else {
      //    print("Could not get valid status from backend for order $orderId");
      //    return 'pending'; // Trả về pending nếu không lấy được
      // }
      // --- Kết thúc TODO ---

      // Giả lập chờ đợi backend xử lý webhook và trả về kết quả
      await Future.delayed(const Duration(seconds: 4));
      print("Simulating backend status check: returning 'paid'");
      return 'paid'; // <<<--- GIẢ LẬP KẾT QUẢ THÀNH CÔNG
    } on DioException catch (e) {
      print(
        "Error checking order status (Dio): ${e.response?.data ?? e.message}",
      );
      return null; // Trả về null nếu có lỗi mạng
    } catch (e) {
      print("Error checking order status: $e");
      return null; // Trả về null nếu có lỗi khác
    }
  }
}
