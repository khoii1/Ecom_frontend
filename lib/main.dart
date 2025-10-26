import 'package:dio/dio.dart';
import 'package:ecom_frontend/providers/category_provider.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/services/category_service.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/services/store_service.dart';
import 'package:ecom_frontend/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/app_wrapper.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
// import 'package:ecom_frontend/services/api_client.dart'; // Bỏ
import 'package:ecom_frontend/services/auth_service.dart';
import 'package:ecom_frontend/services/cart_service.dart';
import 'package:ecom_frontend/services/storage_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/screens/cart/cart_screen.dart';
import 'package:ecom_frontend/services/vnpay_service.dart';
import 'package:ecom_frontend/screens/payment/vnpay_webview_screen.dart';
// --- THÊM IMPORT OrderService ---
import 'package:ecom_frontend/services/order_service.dart';
// --- KẾT THÚC THÊM ---
// <<< THÊM IMPORT PaymentResultScreen >>>
import 'package:ecom_frontend/screens/payment/payment_result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Chuyển sang StatefulWidget để khởi tạo service 1 lần
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Khai báo các service và Dio làm biến instance
  late final StorageService _storageService;
  late final Dio _dio;
  late final AuthService _authService;
  late final CartService _cartService;
  late final UserService _userService;
  late final CategoryService _categoryService;
  late final StoreService _storeService;
  late final ProductService _productService;
  late final OrderService _orderService;
  late final VnpayService _vnpayService;

  @override
  void initState() {
    super.initState();
    // Khởi tạo tất cả service và Dio MỘT LẦN trong initState
    // Khởi tạo Dio trước
    _dio = Dio(
      // SỬA: Lấy baseUrl từ AppConfig để dễ thay đổi
      // BaseOptions(baseUrl: AppConfig.baseUrl),
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8080',
      ), // Tạm giữ cho Android Emulator
    );

    _storageService = StorageService();

    // Cấu hình Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await _storageService.readToken('access_token');
          if (token != null && token.isNotEmpty) {
            print("Attaching token to request...");
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print("No auth token found for request to ${options.path}");
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          print("Dio Error on ${e.requestOptions.path}: ${e.message}");
          if (e.response != null) {
            print(
              "Dio Error Response: ${e.response?.statusCode} ${e.response?.data}",
            );
          }
          if (e.response?.statusCode == 401) {
            print("Unauthorized request - need to handle logout");
            // TODO: Cần cơ chế global để gọi logout từ AuthProvider
            // Ví dụ: Dùng GlobalKey<NavigatorState> hoặc EventBus/Stream
          }
          return handler.next(e);
        },
      ),
    );

    // Khởi tạo các service với Dio đã cấu hình
    _authService = AuthService(_dio);
    _cartService = CartService(_dio);
    _userService = UserService(_dio);
    _categoryService = CategoryService(_dio);
    _storeService = StoreService(_dio);
    _productService = ProductService(_dio);
    _orderService = OrderService(_dio); // Đã có OrderService
    _vnpayService = VnpayService(_dio); // Đã có VnpayService
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Cung cấp Services đã khởi tạo trong initState
        Provider(create: (_) => _storageService),
        Provider(create: (_) => _authService),
        Provider(create: (_) => _cartService),
        Provider(create: (_) => _userService),
        Provider(create: (_) => _categoryService),
        Provider(create: (_) => _storeService),
        Provider(create: (_) => _productService),
        Provider(
          create: (_) => _orderService,
        ), // Đảm bảo OrderService được cung cấp
        Provider(
          create: (_) => _vnpayService,
        ), // Đảm bảo VnpayService được cung cấp
        // --- Providers (State Management) ---
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            _authService,
            _storageService,
            _userService,
          ), // Tự gọi _checkAuthStatus
        ),
        // CartProvider phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) =>
              CartProvider(_cartService, null), // Ban đầu auth có thể null
          update: (_, authProvider, previousCartProvider) => CartProvider(
            _cartService,
            authProvider,
          ), // Cập nhật khi auth thay đổi
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(_productService)..fetchProducts(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(_categoryService)..fetchCategories(),
        ),
      ],
      child: MaterialApp(
        title: 'E-commerce App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: kPrimaryColor,
          scaffoldBackgroundColor: kBackgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 1,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryColor,
              side: const BorderSide(color: kPrimaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kOffWhiteColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
            primary: kPrimaryColor,
            secondary: kAccentColor,
            error: kHeartColor,
          ).copyWith(background: kBackgroundColor),
          useMaterial3: true,
        ),
        routes: {
          '/cart': (context) => CartScreen(),
          PaymentResultScreen.routeName: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return PaymentResultScreen(
              orderId: args?['orderId'] ?? 'N/A',
              initialStatus: args?['initialStatus'] ?? 'unknown',
              message: args?['message'],
              vnpResponseCode: args?['vnpResponseCode'],
            );
          },
          // <<< THÊM ROUTE CHO WEBVIEW >>>
          VnpayWebViewScreen.routeName: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return VnpayWebViewScreen(
              paymentUrl:
                  args?['paymentUrl'] ?? 'about:blank', // Cung cấp URL mặc định
              // orderId: args?['orderId'] ?? 'N/A', // Truyền orderId nếu cần
            );
          },
        },
        // Màn hình khởi đầu
        home: const AppWrapper(),
        // <<< CẬP NHẬT routes >>>
      ),
    );
  }
}
