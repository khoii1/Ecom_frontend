import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/app_wrapper.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/services/api_client.dart';
import 'package:ecom_frontend/services/auth_service.dart';
import 'package:ecom_frontend/services/cart_service.dart';
import 'package:ecom_frontend/services/storage_service.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cấu hình các services
    final StorageService storageService = StorageService();
    final Dio dio = Dio();
    final ApiClient apiClient = ApiClient(dio, storageService);
    final AuthService authService = AuthService(dio);
    final CartService cartService = CartService(dio); // <-- THÊM MỚI

    return MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => storageService),
        Provider(create: (_) => apiClient),
        Provider(create: (_) => authService),
        Provider(create: (_) => cartService), // <-- THÊM MỚI
        // Providers (State Management)
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storageService),
        ),
        // CartProvider cần AuthProvider (để biết khi nào load giỏ hàng)
        // và CartService (để gọi API)
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          // <-- THÊM MỚI
          create: (_) => CartProvider(cartService, null),
          update: (_, authProvider, previousCartProvider) =>
              CartProvider(cartService, authProvider),
        ),
      ],
      child: MaterialApp(
        title: 'E-commerce App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AppWrapper(),
      ),
    );
  }
}
