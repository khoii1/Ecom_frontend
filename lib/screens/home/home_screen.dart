import 'package:carousel_slider/carousel_slider.dart';
import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/providers/category_provider.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/screens/cart/cart_screen.dart'; // Vẫn cần để điều hướng từ AppBar
import 'package:ecom_frontend/screens/search/search_screen.dart';
import 'package:ecom_frontend/screens/product/product_detail_screen.dart';
import 'package:ecom_frontend/screens/seller/add_product_screen.dart'; // Cần cho tab Add Product
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// --- Widget chính giữ trạng thái các trang ---
class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int _selectedIndex = 0; // Trang hiện tại được chọn (bắt đầu từ 0)

  // --- DANH SÁCH WIDGET KHÔNG ĐỔI ---
  static List<Widget> _widgetOptions(BuildContext context) {
    List<Widget> options = [
      const HomeScreenContent(), // Trang Home (index 0)
      const SearchScreen(), // Trang Search (index 1)
      Scaffold(
        // Trang Profile (index 2)
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text("Đăng xuất"),
          ),
        ),
      ),
    ];
    return options;
  }
  // --- HẾT DANH SÁCH WIDGET ---

  void _onItemTapped(int index) {
    final userRole = context.read<AuthProvider>().currentUser?.role;
    final bool canAddProduct = userRole == 'ADMIN' || userRole == 'SELLER';
    int actualIndex = index;

    // Logic xử lý khi nhấn tab
    if (canAddProduct) {
      // Dành cho Admin/Seller
      if (index == 2) {
        // Nhấn vào nút Add Product (+)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        );
        return; // Không đổi tab chính đang hiển thị
      } else if (index > 2) {
        // Nhấn vào Profile (index 3 trên UI)
        actualIndex =
            index - 1; // Index thực tế của Profile trong _widgetOptions là 2
      }
      // index 0 -> Home (actualIndex 0)
      // index 1 -> Search (actualIndex 1)
    } else {
      // Dành cho User thường (không có nút Add)
      // index 0 -> Home (actualIndex 0)
      // index 1 -> Search (actualIndex 1)
      // index 2 -> Profile (actualIndex 2)
      // actualIndex = index; // Không cần điều chỉnh
    }

    // Cập nhật trang hiển thị nếu index hợp lệ và khác trang hiện tại
    if (actualIndex < _widgetOptions(context).length &&
        actualIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = actualIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- XÓA FLOATING ACTION BUTTON ---
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions(context),
      ),
      bottomNavigationBar: _buildBottomNavBar(
        context,
        _selectedIndex,
        _onItemTapped,
      ),
      // floatingActionButton và floatingActionButtonLocation đã bị xóa
    );
  }

  // --- Thanh điều hướng dưới cùng ---
  Widget _buildBottomNavBar(
    BuildContext context,
    int currentActualIndex,
    ValueChanged<int> onTap,
  ) {
    final userRole = context.select(
      (AuthProvider provider) => provider.currentUser?.role,
    );
    final bool canAddProduct = userRole == 'ADMIN' || userRole == 'SELLER';

    // --- CẬP NHẬT DANH SÁCH ITEM (Thay Bag bằng Add) ---
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ), // index 0
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search),
        label: 'Search',
      ), // index 1
      // Nút Add Product (chỉ hiển thị cho Admin/Seller)
      if (canAddProduct)
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline, size: 28), // Icon dấu cộng
          activeIcon: Icon(Icons.add_circle, size: 28),
          label: 'Add',
        ), // index 2 (nếu có)
      // Bỏ tab Giỏ hàng (Bag) ở đây
      const BottomNavigationBarItem(
        // Index 2 (nếu user) hoặc 3 (nếu admin/seller)
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
    // --- HẾT CẬP NHẬT ITEM ---

    // Điều chỉnh currentIndex hiển thị trên BottomNavigationBar
    int displayIndex =
        currentActualIndex; // Index của trang đang hiển thị (0, 1, 2)
    if (canAddProduct && currentActualIndex >= 2) {
      // Nếu là admin/seller và đang ở trang Profile (index 2)
      displayIndex = currentActualIndex + 1; // Index trên NavBar phải là 3
    }

    // Bỏ BottomAppBar, trả về BottomNavigationBar đơn giản
    return BottomNavigationBar(
      items: items,
      currentIndex: displayIndex, // Index trên NavBar
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: kSecondaryTextColor.withOpacity(0.7),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed, // Quan trọng khi item thay đổi
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: onTap, // Hàm onTap đã bao gồm logic điều hướng cho Add Product
    );
  }
}

// --- Nội dung trang Home (HomeScreenContent) ---
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  int _bannerCurrentIndex = 0;
  // --- SỬA LỖI KHAI BÁO CONTROLLER ---
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  // --- KẾT THÚC SỬA LỖI ---
  late Timer _timer;
  Duration _countdownDuration = const Duration(
    hours: 2,
    minutes: 9,
    seconds: 24,
  );

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().fetchProducts();
        context.read<CategoryProvider>().fetchCategories();
        context.read<CartProvider>().fetchCart(); // Fetch giỏ hàng khi vào home
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_countdownDuration.inSeconds > 0) {
            _countdownDuration -= const Duration(seconds: 1);
          } else {
            _timer.cancel();
          }
        });
      } else {
        _timer.cancel();
      }
    });
  }

  List<String> _formatCountdown(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [hours, minutes, seconds];
  }

  // --- AppBar Mới (Thêm Icon Giỏ hàng, bỏ Icon Trái tim) ---
  AppBar _buildAppBar(BuildContext context) {
    final cartProvider = context.watch<CartProvider>(); // Lấy cart provider
    return AppBar(
      backgroundColor: kBackgroundColor,
      elevation: 0,
      leadingWidth: 0,
      titleSpacing: kDefaultPadding,
      title: TextField(
        onTap: () {
          final wrapperState = context
              .findAncestorStateOfType<_MainScreenWrapperState>();
          wrapperState?._onItemTapped(1); // Index 1 là trang Search
        },
        readOnly: true,
        decoration: InputDecoration(
          hintText: "Search Outfit",
          hintStyle: TextStyle(
            color: kSecondaryTextColor.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: kSecondaryTextColor.withOpacity(0.7),
            size: 20,
          ),
          filled: true,
          fillColor: kOffWhiteColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: kPrimaryColor.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
      ),
      actions: [
        // --- CẬP NHẬT: Icon Giỏ hàng (Thay thế Trái tim) ---
        Stack(
          alignment: Alignment.center, // Canh giữa badge và icon
          children: [
            IconButton(
              icon: Icon(
                Icons.shopping_bag_outlined,
                color: kTextColor.withOpacity(0.7),
              ),
              onPressed: () {
                // Điều hướng đến trang giỏ hàng
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
            // Badge Count
            if (cartProvider.cart != null &&
                cartProvider.cart!.items.isNotEmpty)
              Positioned(
                // Đặt badge ở góc trên bên phải icon
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: kHeartColor, // Màu đỏ cho badge
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  child: Text(
                    // Hiển thị tổng số lượng sản phẩm trong giỏ
                    cartProvider.cart!.items
                        .fold<int>(0, (sum, item) => sum + item.qty)
                        .toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        // --- HẾT CẬP NHẬT GIỎ HÀNG ---

        // --- Icon Thông báo (Giữ nguyên) ---
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: kTextColor.withOpacity(0.7),
              ),
              onPressed: () {
                /* TODO: Navigate to Notifications */
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: kHeartColor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                child: const Text(
                  '3', // Số thông báo ví dụ
                  style: TextStyle(color: Colors.white, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: kDefaultPadding / 2),
      ],
    );
  }

  // --- Các hàm build khác (_buildBannerCarousel, _buildSectionHeader, etc.) giữ nguyên ---
  Widget _buildBannerCarousel(BuildContext context) {
    final List<String> bannerImages = [
      'lib/assets/images/banner_1.jpg',
      'lib/assets/images/banner_2.png',
    ];
    List<String> timeParts = _formatCountdown(_countdownDuration);

    return Column(
      children: [
        CarouselSlider(
          // --- SỬA LỖI TYPE CONTROLLER ---
          carouselController: _carouselController,
          // --- KẾT THÚC SỬA LỖI ---
          options: CarouselOptions(
            height: 180.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            viewportFraction: 0.92,
            enlargeCenterPage: false,
            enlargeFactor: 0.2,
            onPageChanged: (index, reason) {
              setState(() {
                _bannerCurrentIndex = index;
              });
            },
          ),
          items: bannerImages.map((imgPath) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                  decoration: BoxDecoration(
                    color: kOffWhiteColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        Image.asset(
                          imgPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            print("Lỗi tải ảnh banner: $imgPath, $error");
                            return const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: kSecondaryTextColor,
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding * 1.5,
                            vertical: kDefaultPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "New Year Sale",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "40% off",
                                style: TextStyle(
                                  fontSize: 26,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: timeParts
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              entry.value,
                                              style: const TextStyle(
                                                color: kTextColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (entry.key < timeParts.length - 1)
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 4.0,
                                              ),
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
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bannerImages.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _carouselController.animateToPage(entry.key),
              child: Container(
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
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerRight,
            ),
            child: const Text(
              "View all",
              style: TextStyle(
                fontSize: 13,
                color: kAccentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    List<Map<String, dynamic>> displayCategories = [
      {'name': 'Man Style', 'image': 'lib/assets/images/category_man.png'},
      {'name': 'Woman Style', 'image': 'lib/assets/images/category_woman.png'},
      {'name': 'Kids Style', 'image': 'lib/assets/images/category_kids.jpg'},
    ];

    return Column(
      children: [
        _buildSectionHeader("Categories", () {
          final wrapperState = context
              .findAncestorStateOfType<_MainScreenWrapperState>();
          wrapperState?._onItemTapped(1);
          print("View all categories -> Navigate to Search Tab");
        }),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding * 0.75,
            ),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              return GestureDetector(
                onTap: () {
                  print("Tapped category: ${category['name']}");
                  /* TODO: Navigate to Search with filter */
                },
                child: Container(
                  width: 85,
                  margin: const EdgeInsets.only(right: kDefaultPadding * 0.75),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: kOffWhiteColor,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 55,
                        width: 55,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            category['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.error_outline,
                                    size: 30,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
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
        ),
      ],
    );
  }

  Widget _buildPopularProductsSection(BuildContext context) {
    return Column(
      children: [
        _buildSectionHeader("Popular Product", () {
          print("View all popular products"); /* TODO: Navigate */
        }),
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            if (provider.status == ProductStatus.loading ||
                provider.status == ProductStatus.initial) {
              return const Center(
                heightFactor: 5,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
              );
            }
            if (provider.status == ProductStatus.error) {
              return Center(
                heightFactor: 5,
                child: Text(
                  "Lỗi tải sản phẩm: ${provider.errorMessage ?? 'Unknown error'}",
                ),
              );
            }
            if (provider.products.isEmpty) {
              return const Center(
                heightFactor: 5,
                child: Text("Không có sản phẩm nào."),
              );
            }
            final popularProducts = provider.products.take(6).toList();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding * 0.75,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: kDefaultPadding * 0.75,
                mainAxisSpacing: kDefaultPadding * 0.75,
              ),
              itemCount: popularProducts.length,
              itemBuilder: (context, index) {
                final product = popularProducts[index];
                return _buildPopularProductCard(context, product);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPopularProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: kOffWhiteColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: kDefaultPadding,
                        left: kDefaultPadding,
                        right: kDefaultPadding,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: product.imageUrl != null
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: kSecondaryTextColor,
                                  ),
                                ),
                                loadingBuilder: (c, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        kPrimaryColor,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: kSecondaryTextColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(kDefaultPadding * 0.75),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: kTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      "\$${product.discountedPrice?.toStringAsFixed(2) ?? product.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: kTextColor,
                                    fontSize: 16,
                                  ),
                                ),
                                if (product.discountedPrice != null)
                                  TextSpan(
                                    text:
                                        " \$${product.price.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: kSecondaryTextColor.withOpacity(
                                        0.8,
                                      ),
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: kSecondaryTextColor
                                          .withOpacity(0.8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (product.rating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  print("Toggle favorite for ${product.title}");
                  /* TODO: Implement favorite logic */
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: Icon(
                    Icons.favorite_border,
                    color: kSecondaryTextColor.withOpacity(0.6),
                    size: 18,
                  ),
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
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<ProductProvider>().fetchProducts(),
            context.read<CategoryProvider>().fetchCategories(),
            if (mounted)
              context
                  .read<CartProvider>()
                  .fetchCart(), // Fetch lại cart khi refresh
          ]);
        },
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        child: ListView(
          children: [
            _buildBannerCarousel(context),
            const SizedBox(height: kDefaultPadding / 2),
            _buildCategoriesSection(context),
            const SizedBox(height: kDefaultPadding / 2),
            _buildPopularProductsSection(context),
            const SizedBox(height: kDefaultPadding * 1.5),
          ],
        ),
      ),
    );
  }
}
