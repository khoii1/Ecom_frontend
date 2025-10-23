import 'package:dio/dio.dart';
import 'package:ecom_frontend/providers/category_provider.dart'; // <-- THÊM MỚI
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/services/category_service.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/services/store_service.dart';
import 'package:ecom_frontend/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/app_wrapper.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/services/api_client.dart';
import 'package:ecom_frontend/services/auth_service.dart';
import 'package:ecom_frontend/services/cart_service.dart';
import 'package:ecom_frontend/services/storage_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Cấu hình các services ---
    final StorageService storageService = StorageService();
    final Dio dio = Dio();
    final ApiClient apiClient = ApiClient(dio, storageService);
    final AuthService authService = AuthService(dio);
    final CartService cartService = CartService(dio);
    final UserService userService = UserService(dio);
    final CategoryService categoryService = CategoryService(dio); // <-- Đã có
    final StoreService storeService = StoreService(dio);
    final ProductService productService = ProductService(dio);

    return MultiProvider(
      providers: [
        // --- Services ---
        Provider(create: (_) => storageService),
        Provider(create: (_) => apiClient),
        Provider(create: (_) => authService),
        Provider(create: (_) => cartService),
        Provider(create: (_) => userService),
        Provider(create: (_) => categoryService), // <-- Đã có
        Provider(create: (_) => storeService),
        Provider(create: (_) => productService),

        // --- Providers (State Management) ---
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storageService, userService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(cartService, null),
          update: (_, authProvider, previousCartProvider) =>
              CartProvider(cartService, authProvider),
        ),
        ChangeNotifierProvider(create: (_) => ProductProvider(productService)),
        // CategoryProvider cần CategoryService
        ChangeNotifierProvider(
          // <-- THÊM MỚI
          create: (_) => CategoryProvider(categoryService),
        ),
      ],
      child: MaterialApp(
        title: 'E-commerce App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: kBackgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: kBackgroundColor,
            foregroundColor: kTextColor,
            elevation: 0,
            iconTheme: IconThemeData(color: kTextColor),
            titleTextStyle: TextStyle(
              color: kTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
          useMaterial3: true,
        ),
        home: const AppWrapper(), // AppWrapper sẽ điều hướng ban đầu
        // Có thể thêm routes ở đây nếu muốn
      ),
    );
  }
}
