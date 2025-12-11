import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Base URL cho các API calls thông thường (KHÔNG dùng ngrok)
  // Chỉ dùng ngrok cho VNPay return URL trong backend .env (VNP_RETURNURL)
  //
  // HƯỚNG DẪN CẤU HÌNH:
  // 1. Thay đổi IP dưới đây theo IP LAN của máy chạy backend
  // 2. Để lấy IP: Windows (ipconfig) hoặc Mac/Linux (ifconfig)
  // 3. Đảm bảo backend đang chạy trên port 8080
  // 4. Đảm bảo điện thoại/emulator và máy tính cùng mạng WiFi

  static String get baseUrl {
    if (kDebugMode) {
      // Trong chế độ debug
      if (Platform.isAndroid) {
        return "http://192.168.1.3:8080";
      } else if (Platform.isIOS) {
        // iOS Simulator: dùng localhost
        return "http://localhost:8080";
      }
    }
    // Production - thay đổi theo domain thực tế của bạn
    return "http://192.168.1.3:8080"; // Hoặc domain production
  }

  static String get ngrokUrl {
    return "https://natalee-vixenish-nonevilly.ngrok-free.dev";
  }
}
