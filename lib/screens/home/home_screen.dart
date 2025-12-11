import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/providers/category_provider.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/screens/cart/cart_screen.dart';
import 'package:ecom_frontend/screens/product/product_detail_screen.dart';
import 'package:ecom_frontend/screens/search/search_screen.dart';
import 'package:ecom_frontend/screens/seller/add_product_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/screens/profile/profile_screen.dart';
import 'package:ecom_frontend/services/banner_service.dart';
import 'package:ecom_frontend/models/banner.dart' as ecom_banner;
import 'package:ecom_frontend/services/address_service.dart';
import 'package:ecom_frontend/models/address.dart';
import 'package:ecom_frontend/screens/address/address_list_screen.dart';
import 'package:ecom_frontend/screens/wishlist/wishlist_screen.dart';
import 'package:ecom_frontend/screens/category/category_products_screen.dart';
import 'package:ecom_frontend/services/wishlist_service.dart';
import 'package:ecom_frontend/widgets/chatbot_widget.dart';
import 'package:ecom_frontend/screens/shipper/shipper_orders_screen.dart';

class CountdownTicker extends StatefulWidget {
  final Duration initial;
  const CountdownTicker({super.key, required this.initial});

  @override
  State<CountdownTicker> createState() => _CountdownTickerState();
}

class _CountdownTickerState extends State<CountdownTicker> {
  late Duration _left;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _left = widget.initial;
    _ticker = Ticker(_tick)..start();
  }

  void _tick(Duration _) {
    if (!mounted) return;
    if (_left.inSeconds <= 0) {
      _ticker.stop();
      return;
    }
    // chỉ rebuild mỗi 1 giây
    final next = _left - const Duration(seconds: 1);
    if (next.inSeconds != _left.inSeconds) {
      setState(() => _left = next);
    } else {
      _left = next;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<String> _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return [
      two(d.inHours),
      two(d.inMinutes.remainder(60)),
      two(d.inSeconds.remainder(60)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final parts = _format(_left);
    return Row(
      children: parts.asMap().entries.map((entry) {
        final value = entry.value;
        final isLast = entry.key == parts.length - 1;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  ":",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

// Ticker nhẹ không kéo theo SchedulerBinding (tránh thêm dependency)
class Ticker {
  Ticker(this.onTick);
  final void Function(Duration elapsed) onTick;
  bool _running = false;
  Duration _elapsed = Duration.zero;

  void start() {
    if (_running) return;
    _running = true;
    _schedule();
  }

  void _schedule() async {
    while (_running) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_running) break;
      _elapsed += const Duration(seconds: 1);
      onTick(_elapsed);
    }
  }

  void stop() => _running = false;
  void dispose() => stop();
}
// ================================================================================

// --- DEPRECATED: Widget chính giữ trạng thái các trang ---
// DEPRECATED: Widget này đã được thay thế bởi RoleBasedMainScreen
// Sử dụng RoleBasedMainScreen thay vì MainScreenWrapper
// MainScreenWrapper chỉ được giữ lại để tương thích ngược
@Deprecated('Use RoleBasedMainScreen instead. This widget is deprecated and will be removed in a future version.')
class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int _selectedIndex = 0; // Trang hiện tại được chọn (bắt đầu từ 0)
  bool _isShipper = false; // Lưu trạng thái shipper

  static List<Widget> _widgetOptions(
    BuildContext context, {
    required bool isShipper,
  }) {
    if (isShipper) {
      // Màn hình cho shipper
      return [
        const ShipperOrdersScreen(), // Đơn hàng (index 0)
        const ProfileScreen(), // Profile (index 1)
      ];
    } else {
      // Màn hình cho user thường
      return [
        const HomeScreenContent(), // Home (index 0)
        const SearchScreen(), // Search (index 1)
        const ProfileScreen(), // Profile (index 2)
      ];
    }
  }

  void _onItemTapped(int index) {
    final options = _widgetOptions(context, isShipper: _isShipper);
    if (index < options.length && index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.select(
      (AuthProvider provider) => provider.currentUser?.role,
    );
    final bool isShipper = userRole == 'SHIPPER';

    // Cập nhật state nếu role thay đổi
    if (_isShipper != isShipper) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isShipper = isShipper;
            _selectedIndex = 0; // Reset về màn hình đầu tiên khi role thay đổi
          });
        }
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions(context, isShipper: isShipper),
      ),
      floatingActionButton: isShipper ? null : const ChatbotFloatingButton(),
      bottomNavigationBar: _buildBottomNavBar(
        context,
        _selectedIndex,
        _onItemTapped,
        isShipper: isShipper,
      ),
    );
  }

  Widget _buildBottomNavBar(
    BuildContext context,
    int currentActualIndex,
    ValueChanged<int> onTap, {
    required bool isShipper,
  }) {
    if (isShipper) {
      // Bottom navigation cho shipper
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Đơn hàng
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.local_shipping_outlined,
                    activeIcon: Icons.local_shipping,
                    label: 'Đơn hàng',
                    isActive: currentActualIndex == 0,
                    onTap: () => onTap(0),
                  ),
                ),

                // Profile
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    isActive: currentActualIndex == 1,
                    onTap: () => onTap(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Bottom navigation cho user thường
    final userRole = context.select(
      (AuthProvider provider) => provider.currentUser?.role,
    );
    final bool canAddProduct = userRole == 'ADMIN' || userRole == 'SELLER';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home - Luôn chiếm 1/4 không gian
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isActive: currentActualIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),

              // Favorites
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite,
                  label: 'Favorites',
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    );
                  },
                ),
              ),

              // Add Product (chỉ hiển thị cho Seller/Admin)
              if (canAddProduct)
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.add_circle_outline,
                    activeIcon: Icons.add_circle,
                    label: 'Add',
                    isActive: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                    },
                  ),
                ),

              // Cart
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    final itemCount =
                        cartProvider.cart?.items.fold<int>(
                          0,
                          (sum, item) => sum + item.qty,
                        ) ??
                        0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildBottomNavItem(
                          icon: Icons.shopping_cart_outlined,
                          activeIcon: Icons.shopping_cart,
                          label: 'Cart',
                          isActive: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CartScreen()),
                            );
                          },
                        ),
                        if (itemCount > 0)
                          Positioned(
                            right: canAddProduct
                                ? MediaQuery.of(context).size.width / 5 - 30
                                : MediaQuery.of(context).size.width / 4 - 30,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: kHeartColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                itemCount > 99 ? '99+' : itemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Profile
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: currentActualIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive
                ? kPrimaryColor
                : kSecondaryTextColor.withOpacity(0.7),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive
                  ? kPrimaryColor
                  : kSecondaryTextColor.withOpacity(0.7),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Nội dung trang Home ---
class HomeScreenContent extends StatefulWidget {
  final Function(int)? onTabSwitch; // Callback để switch tab trong bottom nav
  
  const HomeScreenContent({super.key, this.onTabSwitch});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  int _bannerCurrentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  List<ecom_banner.Banner> _banners = [];
  bool _isLoadingBanners = false;

  Address? _defaultAddress;
  bool _isLoadingAddress = false;

  // Wishlist state - Map<productId, isInWishlist>
  final Map<String, bool> _wishlistStatus = {};
  final Map<String, bool> _checkingWishlist =
      {}; // Track which products are being checked/toggled
  String?
  _lastCheckedProductsHash; // Track last checked products to prevent duplicate checks
  bool _isCheckingWishlistForProducts =
      false; // Prevent concurrent wishlist checks

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  Future<void> _loadBanners() async {
    if (!mounted) return;
    setState(() => _isLoadingBanners = true);
    try {
      final bannerService = context.read<BannerService>();
      final banners = await bannerService.getHomeBanners();
      print("Loaded ${banners.length} banners for home screen");
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoadingBanners = false;
        });
      }
    } catch (e) {
      print("Error loading banners: $e");
      if (mounted) {
        setState(() {
          _banners = [];
          _isLoadingBanners = false;
        });
      }
    }
  }

  // ===== Helper hiển thị ảnh từ URL thường hoặc data URL base64 =====
  Widget _buildImageFromUrlOrBase64(
    String? url, {
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    double? width,
    double? height,
  }) {
    final Widget ph =
        placeholder ??
        Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported_outlined, size: 30),
        );

    if (url == null || url.isEmpty) return ph;

    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Part = commaIndex != -1
            ? url.substring(commaIndex + 1)
            : url;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (c, e, s) => ph,
        );
      } catch (_) {
        return ph;
      }
    }

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (c, e, s) => ph,
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return const SizedBox.shrink();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _loadDefaultAddress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().fetchProducts();
      context.read<CategoryProvider>().fetchCategories();
      context.read<CartProvider>().fetchCart();
    });
  }

  Future<void> _loadDefaultAddress() async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);
    try {
      final addressService = context.read<AddressService>();
      final address = await addressService.getDefaultAddress();
      if (mounted) {
        setState(() {
          _defaultAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      print("Error loading default address: $e");
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  // Check wishlist status for recommended products
  Future<void> _checkRecommendedProductsWishlist(List<Product> products) async {
    if (!mounted || products.isEmpty) return;

    // Prevent concurrent checks
    if (_isCheckingWishlistForProducts) return;

    // Create a hash of product IDs to track if we've already checked this list
    final productsHash = products.map((p) => p.id).join(',');
    if (_lastCheckedProductsHash == productsHash) {
      // Already checked this exact list, skip
      return;
    }

    // Mark that we're checking and this list as checked
    _isCheckingWishlistForProducts = true;
    _lastCheckedProductsHash = productsHash;

    try {
      final wishlistService = context.read<WishlistService>();
      for (var product in products) {
        // Skip if already checked and status is known, or if currently checking
        if (_checkingWishlist[product.id] == true) continue;
        if (_wishlistStatus.containsKey(product.id))
          continue; // Already have status

        try {
          final isInWishlist = await wishlistService.checkInWishlist(
            product.id,
          );
          if (mounted) {
            setState(() {
              _wishlistStatus[product.id] = isInWishlist;
            });
          }
        } catch (e) {
          // Silent fail - just don't set the status
          print("Error checking wishlist for ${product.id}: $e");
        }
      }
    } finally {
      _isCheckingWishlistForProducts = false;
    }
  }

  // Toggle wishlist for a specific product
  Future<void> _toggleWishlist(String productId) async {
    if (!mounted) return;

    // Prevent multiple simultaneous toggles for the same product
    if (_checkingWishlist[productId] == true) return;

    final currentStatus = _wishlistStatus[productId] ?? false;

    setState(() {
      _checkingWishlist[productId] = true;
    });

    try {
      final wishlistService = context.read<WishlistService>();
      if (currentStatus) {
        await wishlistService.removeFromWishlist(productId);
        if (mounted) {
          setState(() {
            _wishlistStatus[productId] = false;
          });
        }
      } else {
        await wishlistService.addToWishlist(productId);
        if (mounted) {
          setState(() {
            _wishlistStatus[productId] = true;
          });
        }
      }
    } catch (e) {
      print("Error toggling wishlist for $productId: $e");
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? 'Lỗi khi xóa khỏi yêu thích'
                  : 'Lỗi khi thêm vào yêu thích',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingWishlist[productId] = false;
        });
      }
    }
  }

  // --- Header mới với greeting, location, search, cart ---
  Widget _buildHeader(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cartProvider = context.watch<CartProvider>();
    final user = authProvider.currentUser;
    final userName = user?.fullName.isNotEmpty == true
        ? user!.fullName.split(' ').first
        : 'Bạn';

    return Container(
      decoration: const BoxDecoration(gradient: kPrimaryGradient),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: kDefaultPadding,
        right: kDefaultPadding,
        bottom: kDefaultPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Xin chào, $userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Location picker
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressListScreen()),
              );
              _loadDefaultAddress();
            },
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isLoadingAddress
                        ? 'Đang tải địa chỉ...'
                        : _defaultAddress != null
                        ? _defaultAddress!.fullAddress
                        : 'Chưa có địa chỉ. Nhấn để thêm',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 14,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Sử dụng callback nếu có (từ UserMainScreen), nếu không thì fallback về MainScreenWrapper (deprecated)
                    if (widget.onTabSwitch != null) {
                      widget.onTabSwitch!(1); // Switch to Search tab
                    } else {
                      final wrapperState = context
                          .findAncestorStateOfType<_MainScreenWrapperState>();
                      wrapperState?._onItemTapped(1); // sang tab Search
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: kSecondaryTextColor.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Tìm kiếm sản phẩm',
                          style: TextStyle(
                            color: kSecondaryTextColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.filter_list,
                          color: kSecondaryTextColor.withOpacity(0.7),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Cart icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CartScreen()),
                        );
                      },
                    ),
                  ),
                  if (cartProvider.cart != null &&
                      cartProvider.cart!.items.isNotEmpty)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: kHeartColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartProvider.cart!.items
                              .fold<int>(0, (sum, item) => sum + item.qty)
                              .toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Banner carousel (Special For You section) ---
  Widget _buildBannerCarousel(BuildContext context) {
    if (_isLoadingBanners) {
      return Container(
        height: 200.0,
        margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        decoration: BoxDecoration(
          color: kOffWhiteColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink(); // Không hiển thị gì nếu không có banner
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Special For You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all banners or promotions
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 200.0,
            autoPlay: _banners.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            viewportFraction: 0.92,
            enlargeCenterPage: false,
            enlargeFactor: 0.2,
            scrollDirection: Axis.horizontal,
            reverse: false, // Trượt từ phải sang trái (bình thường)
            onPageChanged: (index, reason) {
              setState(() => _bannerCurrentIndex = index);
            },
          ),
          items: _banners.map((banner) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () => _handleBannerTap(context, banner),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 6.0),
                    decoration: BoxDecoration(
                      color: kOffWhiteColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        kPrimaryColor,
                                      ),
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                "Lỗi tải ảnh banner: ${banner.imageUrl}, $error",
                              );
                              return Container(
                                color: kOffWhiteColor,
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: kSecondaryTextColor,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Overlay gradient for text readability
                          if (banner.title.isNotEmpty ||
                              banner.description != null)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          // Banner content overlay
                          if (banner.title.isNotEmpty ||
                              banner.description != null)
                            Positioned(
                              left: kDefaultPadding * 1.5,
                              bottom: kDefaultPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (banner.title.isNotEmpty)
                                    Text(
                                      banner.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (banner.title.isNotEmpty &&
                                      banner.description != null)
                                    const SizedBox(height: 6),
                                  if (banner.description != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        banner.description!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        if (_banners.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _banners.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 4.0,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryColor.withOpacity(
                    _bannerCurrentIndex == entry.key ? 0.9 : 0.3,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _handleBannerTap(BuildContext context, ecom_banner.Banner banner) async {
    // Track click
    try {
      final bannerService = context.read<BannerService>();
      await bannerService.trackBannerClick(banner.id);
    } catch (e) {
      print("Error tracking banner click: $e");
    }

    // Navigate based on link type
    if (banner.linkType == 'none' || banner.linkTargetId == null) {
      return;
    }

    switch (banner.linkType) {
      case 'product':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailScreen(productId: banner.linkTargetId!),
          ),
        );
        break;
      case 'category':
        // Navigate to category screen if you have one
        // Navigator.push(...);
        break;
      case 'store':
        // Navigate to store screen if you have one
        // Navigator.push(...);
        break;
    }
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Sử dụng callback nếu có (từ UserMainScreen), nếu không thì fallback về MainScreenWrapper (deprecated)
                  if (widget.onTabSwitch != null) {
                    widget.onTabSwitch!(1); // Switch to Search tab
                  } else {
                    final wrapperState = context
                        .findAncestorStateOfType<_MainScreenWrapperState>();
                    wrapperState?._onItemTapped(1);
                  }
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<CategoryProvider>(
          builder: (context, provider, child) {
            if (provider.status == CategoryStatus.loading ||
                provider.status == CategoryStatus.initial) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      kPrimaryColor,
                    ),
                  ),
                ),
              );
            }
            if (provider.status == CategoryStatus.error) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    "Lỗi tải danh mục: ${provider.errorMessage ?? 'Lỗi không xác định'}",
                    style: const TextStyle(color: kSecondaryTextColor),
                  ),
                ),
              );
            }
            if (provider.categories.isEmpty) {
              return const SizedBox(
                height: 120,
                child: Center(child: Text("Chưa có danh mục nào.")),
              );
            }

            final cats = provider.categories;
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                ),
                itemCount: cats.length > 8
                    ? 9
                    : cats.length, // Hiển thị tối đa 8 + 1 "More"
                itemBuilder: (context, index) {
                  if (index == 8 && cats.length > 8) {
                    // Nút "More"
                    return GestureDetector(
                      onTap: () {
                        // Sử dụng callback nếu có (từ UserMainScreen), nếu không thì fallback về MainScreenWrapper (deprecated)
                        if (widget.onTabSwitch != null) {
                          widget.onTabSwitch!(1); // Switch to Search tab
                        } else {
                          final wrapperState = context
                              .findAncestorStateOfType<_MainScreenWrapperState>();
                          wrapperState?._onItemTapped(1);
                        }
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: kOffWhiteColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                color: kSecondaryTextColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'More',
                              style: TextStyle(
                                color: kTextColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final cat = cats[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to category products screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategoryProductsScreen(category: cat),
                        ),
                      );
                      // Sử dụng callback nếu có (từ UserMainScreen), nếu không thì fallback về MainScreenWrapper (deprecated)
                      if (widget.onTabSwitch != null) {
                        widget.onTabSwitch!(1); // Switch to Search tab
                      } else {
                        final wrapperState = context
                            .findAncestorStateOfType<_MainScreenWrapperState>();
                        wrapperState?._onItemTapped(1);
                      }
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  cat.imageUrl != null &&
                                      cat.imageUrl!.isNotEmpty
                                  ? _buildImageFromUrlOrBase64(
                                      cat.imageUrl,
                                      fit: BoxFit.cover,
                                      width: 70,
                                      height: 70,
                                    )
                                  : Container(
                                      color: kOffWhiteColor,
                                      child: Icon(
                                        Icons.category_outlined,
                                        color: kSecondaryTextColor.withOpacity(
                                          0.5,
                                        ),
                                        size: 35,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedProductsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended For You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Sử dụng callback nếu có (từ UserMainScreen), nếu không thì fallback về MainScreenWrapper (deprecated)
                  if (widget.onTabSwitch != null) {
                    widget.onTabSwitch!(1); // Switch to Search tab
                  } else {
                    final wrapperState = context
                        .findAncestorStateOfType<_MainScreenWrapperState>();
                    wrapperState?._onItemTapped(1);
                  }
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            if (provider.status == ProductStatus.loading ||
                provider.status == ProductStatus.initial) {
              return SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      kPrimaryColor,
                    ),
                  ),
                ),
              );
            }
            if (provider.status == ProductStatus.error) {
              return SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    "Lỗi tải sản phẩm: ${provider.errorMessage ?? 'Lỗi không xác định'}",
                    style: const TextStyle(color: kSecondaryTextColor),
                  ),
                ),
              );
            }
            if (provider.products.isEmpty) {
              return const SizedBox(
                height: 250,
                child: Center(child: Text("Không có sản phẩm nào.")),
              );
            }

            final products = provider.products.take(10).toList();
            // Check wishlist status when products are loaded (only once per unique product list)
            final productsHash = products.map((p) => p.id).join(',');
            if (productsHash != _lastCheckedProductsHash &&
                !_isCheckingWishlistForProducts) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && productsHash != _lastCheckedProductsHash) {
                  _checkRecommendedProductsWishlist(products);
                }
              });
            }
            return SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildRecommendedProductCard(context, product);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedProductCard(BuildContext context, Product product) {
    final hasDiscount =
        product.discountPercentage != null && product.discountPercentage! > 0;
    final isOutOfStock = product.stockQuantity <= 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: kOffWhiteColor,
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? _buildImageFromUrlOrBase64(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 160,
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: kSecondaryTextColor,
                              size: 40,
                            ),
                          ),
                  ),
                ),
                // Wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: kCardShadow,
                      ),
                      child: _checkingWishlist[product.id] == true
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  kHeartColor,
                                ),
                              ),
                            )
                          : Icon(
                              (_wishlistStatus[product.id] ?? false)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: (_wishlistStatus[product.id] ?? false)
                                  ? kHeartColor
                                  : Colors.grey.shade600,
                              size: 18,
                            ),
                    ),
                  ),
                ),
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kHeartColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${product.discountPercentage!.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Out of stock overlay
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Hết hàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(kMediumPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currencyFormatter.format(
                                  product.finalPrice ?? product.price,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                              ),
                              if (hasDiscount)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    currencyFormatter.format(product.price),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: kSecondaryTextColor,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (product.rating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kStarColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: kStarColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  product.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<ProductProvider>().fetchProducts(),
            context.read<CategoryProvider>().fetchCategories(),
            context.read<CartProvider>().fetchCart(),
            _loadBanners(),
            _loadDefaultAddress(),
          ]);
        },
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(context)),

            // Banner section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: kDefaultPadding,
                  bottom: kDefaultPadding / 2,
                ),
                child: _buildBannerCarousel(context),
              ),
            ),

            // Categories section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: kDefaultPadding,
                  bottom: kDefaultPadding,
                ),
                child: _buildCategoriesSection(context),
              ),
            ),

            // Recommended Products section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: kDefaultPadding,
                  bottom: kDefaultPadding * 2,
                ),
                child: _buildRecommendedProductsSection(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
