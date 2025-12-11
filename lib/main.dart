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
import 'package:ecom_frontend/services/auth_service.dart';
import 'package:ecom_frontend/services/cart_service.dart';
import 'package:ecom_frontend/services/storage_service.dart';
import 'package:ecom_frontend/utils/app_config.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/screens/cart/cart_screen.dart';
import 'package:ecom_frontend/services/vnpay_service.dart';
import 'package:ecom_frontend/screens/payment/vnpay_webview_screen.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/screens/payment/payment_result_screen.dart';
import 'package:ecom_frontend/screens/wallet/wallet_screen.dart';
import 'package:ecom_frontend/screens/wallet/topup_screen.dart';
import 'package:ecom_frontend/services/review_service.dart';
import 'package:ecom_frontend/services/discount_service.dart';
import 'package:ecom_frontend/services/wishlist_service.dart';
import 'package:ecom_frontend/services/address_service.dart';
import 'package:ecom_frontend/services/notification_service.dart';
import 'package:ecom_frontend/services/product_variant_service.dart';
import 'package:ecom_frontend/services/banner_service.dart';
import 'package:ecom_frontend/services/shipper_service.dart';
import 'package:ecom_frontend/services/chat_service.dart';
import 'package:ecom_frontend/services/analytics_service.dart';
import 'package:ecom_frontend/services/return_service.dart';
import 'package:ecom_frontend/services/wallet_service.dart';
import 'package:ecom_frontend/providers/locale_provider.dart';
import 'package:ecom_frontend/l10n/app_localizations.dart';

// Global navigator key để access context từ bất kỳ đâu (dùng cho 401 handling)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// App thành Stateful để khởi tạo service một lần
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Khai báo service + Dio
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
  late final ReviewService _reviewService;
  late final DiscountService _discountService;
  late final WishlistService _wishlistService;
  late final AddressService _addressService;
  late final NotificationService _notificationService;
  late final ProductVariantService _productVariantService;
  late final BannerService _bannerService;
  late final ShipperService _shipperService;
  late final ChatService _chatService;
  late final AnalyticsService _analyticsService;
  late final ReturnService _returnService;
  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();

    // Sử dụng baseUrl từ AppConfig thay vì hardcode
    _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

    _storageService = StorageService();

    // Interceptor: gắn token & log lỗi
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.readToken('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            // Không log lỗi cho các endpoint auth vì chúng không cần token
            if (!options.path.contains('/auth/')) {
              print("No auth token found for request to ${options.path}");
            }
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
            print("Unauthorized request - Token hết hạn, đăng xuất...");
            // Xóa token khỏi storage
            await _storageService.deleteAllTokens();
            
            // Gọi logout từ AuthProvider nếu có context và Navigator đã sẵn sàng
            final navigator = navigatorKey.currentState;
            final context = navigatorKey.currentContext;
            if (context != null && navigator != null) {
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                print("Đã đăng xuất thành công do token hết hạn");
              } catch (e) {
                print("Lỗi khi gọi logout: $e");
              }
            }
          }
          return handler.next(e);
        },
      ),
    );

    // Khởi tạo service với Dio đã cấu hình
    _authService = AuthService(_dio);
    _cartService = CartService(_dio);
    _userService = UserService(_dio);
    _categoryService = CategoryService(_dio);
    _storeService = StoreService(_dio);
    _productService = ProductService(_dio);
    _orderService = OrderService(_dio);
    _vnpayService = VnpayService(_dio);
    _reviewService = ReviewService(_dio);
    _discountService = DiscountService(_dio);
    _wishlistService = WishlistService(_dio);
    _addressService = AddressService(_dio);
    _notificationService = NotificationService(_dio);
    _productVariantService = ProductVariantService(_dio);
    _bannerService = BannerService(_dio);
    _shipperService = ShipperService(_dio);
    _chatService = ChatService(_dio);
    _analyticsService = AnalyticsService(_dio);
    _returnService = ReturnService(_dio);
    _walletService = WalletService(_dio);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Cấp phát services và providers
      providers: [
        Provider(create: (_) => _storageService),
        Provider(create: (_) => _authService),
        Provider(create: (_) => _cartService),
        Provider(create: (_) => _userService),
        Provider(create: (_) => _categoryService),
        Provider(create: (_) => _storeService),
        Provider(create: (_) => _productService),
        Provider(create: (_) => _orderService),
        Provider(create: (_) => _vnpayService),
        Provider(create: (_) => _reviewService),
        Provider(create: (_) => _discountService),
        Provider(create: (_) => _wishlistService),
        Provider(create: (_) => _addressService),
        Provider(create: (_) => _notificationService),
        Provider(create: (_) => _productVariantService),
        Provider(create: (_) => _bannerService),
        Provider(create: (_) => _shipperService),
        Provider(create: (_) => _chatService),
        Provider(create: (_) => _analyticsService),
        Provider(create: (_) => _returnService),
        Provider(create: (_) => _walletService),

        // State management
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(_authService, _storageService, _userService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(_cartService, null),
          update: (_, authProvider, __) =>
              CartProvider(_cartService, authProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(_productService)..fetchProducts(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(_categoryService)..fetchCategories(),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey, // Thêm navigator key để access context từ interceptor
            title: 'E-commerce App',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
            ],
            locale: Locale(
              localeProvider.locale == AppLocale.vi ? 'vi' : 'en',
              localeProvider.locale == AppLocale.vi ? 'VN' : 'US',
            ),
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
        // Định nghĩa routes chính
        routes: {
          '/': (context) => const AppWrapper(), // Route mặc định
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
          VnpayWebViewScreen.routeName: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return VnpayWebViewScreen(
              paymentUrl: args?['paymentUrl'] ?? 'about:blank',
            );
          },
          WalletScreen.routeName: (context) => const WalletScreen(),
          TopupScreen.routeName: (context) => const TopupScreen(),
        },
        initialRoute: '/', // Sử dụng initialRoute thay vì home
        onGenerateRoute: (settings) {
          // Fallback route nếu không tìm thấy route nào
          return MaterialPageRoute(
            builder: (context) => const AppWrapper(),
          );
        },
          );
        },
      ),
    );
  }
}
