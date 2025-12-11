import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      // Common
      'app_name': 'E-Commerce',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      'cancel': 'Hủy',
      'confirm': 'Xác nhận',
      'close': 'Đóng',
      'save': 'Lưu',
      'edit': 'Chỉnh sửa',
      'delete': 'Xóa',
      'search': 'Tìm kiếm',
      'filter': 'Lọc',
      'sort': 'Sắp xếp',
      'back': 'Quay lại',
      'next': 'Tiếp theo',
      'done': 'Hoàn thành',
      'retry': 'Thử lại',
      'refresh': 'Làm mới',
      'no_data': 'Không có dữ liệu',
      'feature_developing': 'Tính năng đang phát triển',

      // Auth
      'welcome_back': 'Chào mừng trở lại! 👋',
      'login_subtitle': 'Đăng nhập để tiếp tục mua sắm',
      'email': 'Email',
      'password': 'Mật khẩu',
      'forgot_password': 'Quên mật khẩu?',
      'login': 'Đăng nhập',
      'register': 'Đăng ký',
      'register_now': 'Đăng ký ngay',
      'dont_have_account': 'Chưa có tài khoản?',
      'have_account': 'Đã có tài khoản?',
      'create_account': 'Tạo tài khoản',
      'full_name': 'Họ và tên',
      'phone': 'Số điện thoại',
      'confirm_password': 'Xác nhận mật khẩu',
      'verification_code': 'Mã xác thực',
      'enter_verification_code': 'Nhập mã xác thực',
      'verify': 'Xác thực',
      'resend_code': 'Gửi lại mã',
      'create_new_password': 'Tạo mật khẩu mới',
      'new_password': 'Mật khẩu mới',
      'confirm_new_password': 'Xác nhận mật khẩu mới',
      'password_changed': 'Đổi mật khẩu thành công',

      // Profile
      'profile': 'Hồ sơ',
      'customer': 'Khách hàng',
      'seller': 'Người bán',
      'shipper': 'Shipper',
      'admin': 'Quản trị viên',
      'orders': 'Đơn hàng',
      'favorites': 'Yêu thích',
      'my_orders': 'Đơn hàng của tôi',
      'all_orders': 'Tất cả đơn hàng',
      'view_order_history': 'Xem lịch sử đơn hàng',
      'return_request': 'Yêu cầu trả hàng',
      'view_manage_returns': 'Xem và quản lý yêu cầu trả hàng',
      'services': 'Dịch vụ',
      'wallet': 'Ví điện tử',
      'wallet_desc': 'Nạp tiền và quản lý ví',
      'promo_code': 'Mã khuyến mãi',
      'promo_code_desc': 'Nhận và quản lý mã giảm giá',
      'settings': 'Cài đặt',
      'notifications_desc': 'Xem và quản lý thông báo',
      'delivery_address': 'Địa chỉ giao hàng',
      'delivery_address_desc': 'Quản lý địa chỉ nhận hàng',
      'personal_info': 'Thông tin cá nhân',
      'personal_info_desc': 'Cập nhật hồ sơ của bạn',
      'security': 'Bảo mật',
      'security_desc': 'Đổi mật khẩu',
      'language': 'Ngôn ngữ',
      'language_desc': 'Thay đổi ngôn ngữ',
      'language_currency': 'Ngôn ngữ & Tiền tệ',
      'language_currency_desc': 'Thay đổi ngôn ngữ và đơn vị tiền tệ',
      'logout': 'Đăng xuất',
      'logout_confirm': 'Bạn có chắc muốn đăng xuất khỏi tài khoản này?',
      'logout_title': 'Đăng xuất?',
      'app_version': 'Phiên bản 1.0.0',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',

      // Home
      'home': 'Trang chủ',
      'categories': 'Danh mục',
      'products': 'Sản phẩm',
      'view_all': 'Xem tất cả',
      'featured_products': 'Sản phẩm nổi bật',
      'new_products': 'Sản phẩm mới',
      'best_sellers': 'Bán chạy nhất',
      'discount_products': 'Sản phẩm giảm giá',

      // Cart
      'cart': 'Giỏ hàng',
      'empty_cart': 'Giỏ hàng trống',
      'empty_cart_desc': 'Hãy thêm sản phẩm vào giỏ hàng để tiếp tục mua sắm',
      'explore_now': 'Khám phá ngay',
      'add_to_cart': 'Thêm vào giỏ',
      'checkout': 'Thanh toán',
      'subtotal': 'Tạm tính',
      'total': 'Tổng cộng',
      'place_order': 'Đặt hàng',
      'payment': 'Thanh toán',
      'payment_method': 'Phương thức thanh toán',
      'cash_on_delivery': 'Thanh toán khi nhận hàng',
      'pay_by_wallet': 'Thanh toán bằng ví',
      'pay_by_vnpay': 'Thanh toán VNPay',
      'discount_code': 'Mã giảm giá',
      'enter_discount_code': 'Nhập mã giảm giá',
      'apply': 'Áp dụng',
      'remove': 'Xóa',
      'quantity': 'Số lượng',
      'product': 'Sản phẩm',
      'products_count': 'sản phẩm',
      'clear_cart': 'Xóa giỏ hàng',
      'clear_cart_confirm':
          'Bạn có chắc muốn xóa tất cả sản phẩm trong giỏ hàng?',
      'add_address_first': 'Vui lòng thêm địa chỉ giao hàng trước khi mua hàng',
      'insufficient_balance': 'Số dư ví không đủ. Vui lòng nạp thêm tiền.',

      // Product
      'product_detail': 'Chi tiết sản phẩm',
      'add_to_wishlist': 'Thêm vào yêu thích',
      'remove_from_wishlist': 'Xóa khỏi yêu thích',
      'reviews': 'Đánh giá',
      'description': 'Mô tả',
      'specifications': 'Thông số kỹ thuật',
      'related_products': 'Sản phẩm liên quan',
      'out_of_stock': 'Hết hàng',
      'in_stock': 'Còn hàng',
      'select_variant': 'Chọn biến thể',
      'add_to_cart_success': 'Đã thêm vào giỏ hàng',
      'view_cart': 'Xem giỏ hàng',
      'chat_with_seller': 'Chat với người bán',
      'view_shop': 'Xem shop',
      'store_profile': 'Thông tin cửa hàng',

      // Order
      'order_status': 'Trạng thái đơn hàng',
      'pending': 'Chờ xử lý',
      'paid': 'Đã thanh toán',
      'shipped': 'Đang giao hàng',
      'delivering': 'Đang giao',
      'delivered': 'Đã giao',
      'cancelled': 'Đã hủy',
      'payment_failed': 'Thanh toán thất bại',
      'order_detail': 'Chi tiết đơn hàng',
      'order_id': 'Mã đơn hàng',
      'order_date': 'Ngày đặt hàng',
      'order_total': 'Tổng tiền',
      'order_items': 'Sản phẩm',
      'shipping_address': 'Địa chỉ giao hàng',
      'cancel_order': 'Hủy đơn hàng',
      'cancel_order_confirm': 'Bạn có chắc muốn hủy đơn hàng này?',
      'track_order': 'Theo dõi đơn hàng',
      'reorder': 'Đặt lại',
      'rate_product': 'Đánh giá sản phẩm',

      // Chat
      'chat': 'Chat',
      'conversations': 'Cuộc trò chuyện',
      'messages_from_customers': 'Tin nhắn từ khách hàng',
      'no_conversations': 'Chưa có cuộc trò chuyện nào',
      'type_message': 'Nhập tin nhắn...',
      'send': 'Gửi',
      'send_product': 'Gửi sản phẩm',
      'pick_image': 'Chọn hình ảnh',
      'no_messages': 'Chưa có tin nhắn',
      'typing': 'Đang nhập...',

      // Address
      'address': 'Địa chỉ',
      'delivery_addresses': 'Địa chỉ giao hàng',
      'edit_address': 'Chỉnh sửa địa chỉ',
      'delete_address': 'Xóa địa chỉ',
      'delete_address_confirm': 'Bạn có chắc muốn xóa địa chỉ này?',
      'set_default': 'Đặt làm mặc định',
      'default_address': 'Địa chỉ mặc định',
      'receiver_name': 'Tên người nhận',
      'phone_number': 'Số điện thoại',
      'province': 'Tỉnh/Thành phố',
      'district': 'Quận/Huyện',
      'ward': 'Phường/Xã',
      'street': 'Đường/Số nhà',
      'save_address': 'Lưu địa chỉ',

      // Wishlist
      'wishlist': 'Yêu thích',
      'my_wishlist': 'Sản phẩm yêu thích',
      'empty_wishlist': 'Chưa có sản phẩm yêu thích',
      'empty_wishlist_desc':
          'Hãy thêm sản phẩm vào yêu thích để dễ dàng tìm lại sau',

      // Search
      'search_placeholder': 'Tìm kiếm sản phẩm...',
      'search_history': 'Lịch sử tìm kiếm',
      'clear_history': 'Xóa lịch sử',
      'no_results': 'Không tìm thấy kết quả',
      'no_results_desc': 'Thử tìm kiếm với từ khóa khác',

      // Seller
      'seller_dashboard': 'Bảng điều khiển',
      'my_products': 'Sản phẩm của tôi',
      'store_orders': 'Đơn hàng cửa hàng',
      'add_product': 'Thêm sản phẩm',
      'edit_product': 'Chỉnh sửa sản phẩm',
      'product_name': 'Tên sản phẩm',
      'product_price': 'Giá sản phẩm',
      'product_description': 'Mô tả sản phẩm',
      'product_category': 'Danh mục',
      'product_images': 'Hình ảnh sản phẩm',
      'save_product': 'Lưu sản phẩm',
      'delete_product': 'Xóa sản phẩm',
      'delete_product_confirm': 'Bạn có chắc muốn xóa sản phẩm này?',
      'product_status': 'Trạng thái',
      'active': 'Đang bán',
      'inactive': 'Ngừng bán',

      // Shipper
      'shipper_orders': 'Đơn hàng giao',
      'available_orders': 'Đơn hàng có sẵn',
      'my_deliveries': 'Đơn hàng của tôi',
      'accept_order': 'Nhận đơn',
      'accept_order_confirm': 'Bạn có chắc muốn nhận đơn hàng này?',
      'complete_delivery': 'Hoàn thành giao hàng',
      'complete_delivery_confirm': 'Bạn có chắc đã giao hàng thành công?',

      // Wallet
      'wallet_balance': 'Số dư ví',
      'top_up': 'Nạp tiền',
      'transaction_history': 'Lịch sử giao dịch',
      'top_up_amount': 'Số tiền nạp',
      'min_amount': 'Số tiền tối thiểu: 10,000đ',
      'top_up_success': 'Nạp tiền thành công',

      // Returns
      'returns': 'Trả hàng',
      'create_return': 'Tạo yêu cầu trả hàng',
      'return_reason': 'Lý do trả hàng',
      'return_description': 'Mô tả',
      'return_status': 'Trạng thái',
      'return_pending': 'Chờ xử lý',
      'approved': 'Đã duyệt',
      'rejected': 'Từ chối',
      'completed': 'Hoàn thành',

      // Notifications
      'notifications': 'Thông báo',
      'no_notifications': 'Chưa có thông báo',
      'mark_all_read': 'Đánh dấu đã đọc tất cả',

      // Discount
      'discount_vouchers': 'Mã khuyến mãi',
      'available_vouchers': 'Mã có sẵn',
      'my_vouchers': 'Mã của tôi',
      'claim': 'Nhận mã',
      'use': 'Sử dụng',
      'expired': 'Đã hết hạn',
      'min_purchase': 'Đơn tối thiểu',
      'discount': 'Giảm',

      // Common actions
      'view_detail': 'Xem chi tiết',
      'buy_now': 'Mua ngay',
      'continue_shopping': 'Tiếp tục mua sắm',
      'checkout_now': 'Thanh toán ngay',
    },
    'en': {
      // Common
      'app_name': 'E-Commerce',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'close': 'Close',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'filter': 'Filter',
      'sort': 'Sort',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'retry': 'Retry',
      'refresh': 'Refresh',
      'no_data': 'No data',
      'feature_developing': 'Feature is under development',

      // Auth
      'welcome_back': 'Welcome back! 👋',
      'login_subtitle': 'Login to continue shopping',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot password?',
      'login': 'Login',
      'register': 'Register',
      'register_now': 'Register Now',
      'dont_have_account': "Don't have an account?",
      'have_account': 'Already have an account?',
      'create_account': 'Create account',
      'full_name': 'Full name',
      'phone': 'Phone number',
      'confirm_password': 'Confirm password',
      'verification_code': 'Verification code',
      'enter_verification_code': 'Enter verification code',
      'verify': 'Verify',
      'resend_code': 'Resend code',
      'create_new_password': 'Create new password',
      'new_password': 'New password',
      'confirm_new_password': 'Confirm new password',
      'password_changed': 'Password changed successfully',

      // Profile
      'profile': 'Profile',
      'customer': 'Customer',
      'seller': 'Seller',
      'shipper': 'Shipper',
      'admin': 'Administrator',
      'orders': 'Orders',
      'favorites': 'Favorites',
      'my_orders': 'My Orders',
      'all_orders': 'All Orders',
      'view_order_history': 'View order history',
      'return_request': 'Return Request',
      'view_manage_returns': 'View and manage return requests',
      'services': 'Services',
      'wallet': 'Wallet',
      'wallet_desc': 'Top up and manage wallet',
      'promo_code': 'Promo Code',
      'promo_code_desc': 'Receive and manage discount codes',
      'settings': 'Settings',
      'notifications_desc': 'View and manage notifications',
      'delivery_address': 'Delivery Address',
      'delivery_address_desc': 'Manage delivery addresses',
      'personal_info': 'Personal Information',
      'personal_info_desc': 'Update your profile',
      'security': 'Security',
      'security_desc': 'Change password',
      'language': 'Language',
      'language_desc': 'Change language',
      'language_currency': 'Language & Currency',
      'language_currency_desc': 'Change language and currency',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'logout_title': 'Logout?',
      'app_version': 'Version 1.0.0',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',

      // Home
      'home': 'Home',
      'categories': 'Categories',
      'products': 'Products',
      'view_all': 'View All',
      'featured_products': 'Featured Products',
      'new_products': 'New Products',
      'best_sellers': 'Best Sellers',
      'discount_products': 'Discount Products',

      // Cart
      'cart': 'Cart',
      'empty_cart': 'Cart is empty',
      'empty_cart_desc': 'Add products to your cart to continue shopping',
      'explore_now': 'Explore Now',
      'add_to_cart': 'Add to Cart',
      'checkout': 'Checkout',
      'subtotal': 'Subtotal',
      'total': 'Total',
      'place_order': 'Place Order',
      'payment': 'Payment',
      'payment_method': 'Payment Method',
      'cash_on_delivery': 'Cash on Delivery',
      'pay_by_wallet': 'Pay by Wallet',
      'pay_by_vnpay': 'Pay by VNPay',
      'discount_code': 'Discount Code',
      'enter_discount_code': 'Enter discount code',
      'apply': 'Apply',
      'remove': 'Remove',
      'quantity': 'Quantity',
      'product': 'Product',
      'products_count': 'products',
      'clear_cart': 'Clear Cart',
      'clear_cart_confirm': 'Are you sure you want to clear all items in cart?',
      'add_address_first': 'Please add delivery address before checkout',
      'insufficient_balance': 'Insufficient wallet balance. Please top up.',

      // Product
      'product_detail': 'Product Detail',
      'add_to_wishlist': 'Add to Wishlist',
      'remove_from_wishlist': 'Remove from Wishlist',
      'reviews': 'Reviews',
      'description': 'Description',
      'specifications': 'Specifications',
      'related_products': 'Related Products',
      'out_of_stock': 'Out of Stock',
      'in_stock': 'In Stock',
      'select_variant': 'Select Variant',
      'add_to_cart_success': 'Added to cart',
      'view_cart': 'View Cart',
      'chat_with_seller': 'Chat with Seller',
      'view_shop': 'View Shop',
      'store_profile': 'Store Profile',

      // Order
      'order_status': 'Order Status',
      'pending': 'Pending',
      'paid': 'Paid',
      'shipped': 'Shipped',
      'delivering': 'Delivering',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'payment_failed': 'Payment Failed',
      'order_detail': 'Order Detail',
      'order_id': 'Order ID',
      'order_date': 'Order Date',
      'order_total': 'Total',
      'order_items': 'Items',
      'shipping_address': 'Shipping Address',
      'cancel_order': 'Cancel Order',
      'cancel_order_confirm': 'Are you sure you want to cancel this order?',
      'track_order': 'Track Order',
      'reorder': 'Reorder',
      'rate_product': 'Rate Product',

      // Chat
      'chat': 'Chat',
      'conversations': 'Conversations',
      'messages_from_customers': 'Messages from Customers',
      'no_conversations': 'No conversations yet',
      'type_message': 'Type a message...',
      'send': 'Send',
      'send_product': 'Send Product',
      'pick_image': 'Pick Image',
      'no_messages': 'No messages yet',
      'typing': 'Typing...',
      'online': 'Online',
      'offline': 'Offline',

      // Address
      'address': 'Address',
      'delivery_addresses': 'Delivery Addresses',
      'edit_address': 'Edit Address',
      'delete_address': 'Delete Address',
      'delete_address_confirm': 'Are you sure you want to delete this address?',
      'set_default': 'Set as Default',
      'default_address': 'Default Address',
      'receiver_name': 'Receiver Name',
      'phone_number': 'Phone Number',
      'province': 'Province/City',
      'district': 'District',
      'ward': 'Ward',
      'street': 'Street/House Number',
      'save_address': 'Save Address',

      // Wishlist
      'wishlist': 'Wishlist',
      'my_wishlist': 'My Wishlist',
      'empty_wishlist': 'No favorite products yet',
      'empty_wishlist_desc':
          'Add products to wishlist to find them easily later',

      // Search
      'search': 'Search',
      'search_placeholder': 'Search products...',
      'search_history': 'Search History',
      'clear_history': 'Clear History',
      'no_results': 'No results found',
      'no_results_desc': 'Try searching with different keywords',

      // Seller
      'seller_dashboard': 'Dashboard',
      'my_products': 'My Products',
      'store_orders': 'Store Orders',
      'add_product': 'Add Product',
      'edit_product': 'Edit Product',
      'product_name': 'Product Name',
      'product_price': 'Product Price',
      'product_description': 'Product Description',
      'product_category': 'Category',
      'product_images': 'Product Images',
      'save_product': 'Save Product',
      'delete_product': 'Delete Product',
      'delete_product_confirm': 'Are you sure you want to delete this product?',
      'product_status': 'Status',
      'active': 'Active',
      'inactive': 'Inactive',

      // Shipper
      'shipper_orders': 'Delivery Orders',
      'available_orders': 'Available Orders',
      'my_deliveries': 'My Deliveries',
      'accept_order': 'Accept Order',
      'accept_order_confirm': 'Are you sure you want to accept this order?',
      'complete_delivery': 'Complete Delivery',
      'complete_delivery_confirm': 'Are you sure delivery is completed?',

      // Wallet
      'wallet_balance': 'Wallet Balance',
      'top_up': 'Top Up',
      'transaction_history': 'Transaction History',
      'top_up_amount': 'Top Up Amount',
      'min_amount': 'Minimum amount: \$10',
      'top_up_success': 'Top up successful',

      // Returns
      'returns': 'Returns',
      'create_return': 'Create Return Request',
      'return_reason': 'Return Reason',
      'return_description': 'Description',
      'return_status': 'Status',
      'return_pending': 'Pending',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'completed': 'Completed',

      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No notifications yet',
      'mark_all_read': 'Mark all as read',

      // Discount
      'discount_vouchers': 'Discount Vouchers',
      'available_vouchers': 'Available Vouchers',
      'my_vouchers': 'My Vouchers',
      'claim': 'Claim',
      'use': 'Use',
      'expired': 'Expired',
      'min_purchase': 'Min Purchase',
      'discount': 'Discount',

      // Common actions
      'view_detail': 'View Detail',
      'buy_now': 'Buy Now',
      'continue_shopping': 'Continue Shopping',
      'checkout_now': 'Checkout Now',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for common translations
  String get appName => translate('app_name');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get close => translate('close');
  String get save => translate('save');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get search => translate('search');
  String get filter => translate('filter');
  String get sort => translate('sort');
  String get back => translate('back');
  String get next => translate('next');
  String get done => translate('done');
  String get retry => translate('retry');
  String get refresh => translate('refresh');
  String get noData => translate('no_data');
  String get featureDeveloping => translate('feature_developing');

  // Auth getters
  String get welcomeBack => translate('welcome_back');
  String get loginSubtitle => translate('login_subtitle');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get login => translate('login');
  String get register => translate('register');
  String get registerNow => translate('register_now');
  String get dontHaveAccount => translate('dont_have_account');
  String get haveAccount => translate('have_account');
  String get createAccount => translate('create_account');

  // Chat getters
  String get chat => translate('chat');
  String get conversations => translate('conversations');
  String get messagesFromCustomers => translate('messages_from_customers');
  String get noConversations => translate('no_conversations');
  String get typeMessage => translate('type_message');
  String get send => translate('send');
  String get sendProduct => translate('send_product');
  String get pickImage => translate('pick_image');
  String get noMessages => translate('no_messages');
  String get typing => translate('typing');

  // Product getters
  String get productDetail => translate('product_detail');
  String get description => translate('description');
  String get addToCart => translate('add_to_cart');
  String get outOfStock => translate('out_of_stock');
  String get inStock => translate('in_stock');
  String get productsCount => translate('products_count');
  String get chatWithSeller => translate('chat_with_seller');
  String get removeFromWishlist => translate('remove_from_wishlist');

  // Profile getters
  String get profile => translate('profile');
  String get customer => translate('customer');
  String get seller => translate('seller');
  String get admin => translate('admin');
  String get shipper => translate('shipper');
  String get orders => translate('orders');
  String get favorites => translate('favorites');
  String get myOrders => translate('my_orders');
  String get allOrders => translate('all_orders');
  String get viewOrderHistory => translate('view_order_history');
  String get returnRequest => translate('return_request');
  String get viewManageReturns => translate('view_manage_returns');
  String get services => translate('services');
  String get wallet => translate('wallet');
  String get walletDesc => translate('wallet_desc');
  String get promoCode => translate('promo_code');
  String get promoCodeDesc => translate('promo_code_desc');
  String get settings => translate('settings');
  String get notifications => translate('notifications');
  String get notificationsDesc => translate('notifications_desc');
  String get deliveryAddress => translate('delivery_address');
  String get deliveryAddressDesc => translate('delivery_address_desc');
  String get personalInfo => translate('personal_info');
  String get personalInfoDesc => translate('personal_info_desc');
  String get security => translate('security');
  String get securityDesc => translate('security_desc');
  String get language => translate('language');
  String get languageDesc => translate('language_desc');
  String get logout => translate('logout');
  String get logoutTitle => translate('logout_title');
  String get logoutConfirm => translate('logout_confirm');
  String get appVersion => translate('app_version');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');

  // Home getters
  String get home => translate('home');
  String get products => translate('products');

  // Cart getters
  String get cart => translate('cart');

  // Order getters
  String get delivered => translate('delivered');
  String get cancelled => translate('cancelled');
  String get delivering => translate('delivering');
  String get trackOrder => translate('track_order');

  // Search getters
  String get searchPlaceholder => translate('search_placeholder');
  String get noResults => translate('no_results');

  // Seller getters
  String get sellerDashboard => translate('seller_dashboard');

  // Wishlist getters
  String get myWishlist => translate('my_wishlist');
  String get emptyWishlist => translate('empty_wishlist');
  String get emptyWishlistDesc => translate('empty_wishlist_desc');

  // Address getters
  String get deleteAddress => translate('delete_address');
  String get deleteAddressConfirm => translate('delete_address_confirm');
  String get deliveryAddresses => translate('delivery_addresses');
  String get addAddressFirst => translate('add_address_first');
  String get addAddress =>
      translate('save_address'); // Using save_address as add address

  // Cart getters
  String get clearCart => translate('clear_cart');
  String get clearCartConfirm => translate('clear_cart_confirm');
  String get emptyCart => translate('empty_cart');
  String get emptyCartDesc => translate('empty_cart_desc');
  String get exploreNow => translate('explore_now');
  String get subtotal => translate('subtotal');
  String get total => translate('total');
  String get placeOrder => translate('place_order');
  String get payment => translate('payment');
  String get discountCode => translate('discount_code');
  String get paymentMethod => translate('payment_method');
  String get cashOnDelivery => translate('cash_on_delivery');
  String get payByWallet => translate('pay_by_wallet');
  String get payByVnpay => translate('pay_by_vnpay');
  String get insufficientBalance => translate('insufficient_balance');

  // Order getters
  String get pending => translate('pending');
  String get paid => translate('paid');
  String get shipped => translate('shipped');
  String get paymentFailed => translate('payment_failed');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
