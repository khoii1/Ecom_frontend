import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/screens/product/product_detail_screen.dart'; // Để điều hướng đến chi tiết
import 'package:ecom_frontend/utils/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = ""; // Lưu trữ query hiện tại

  @override
  void initState() {
    super.initState();
    // Lấy tất cả sản phẩm ban đầu hoặc để trống
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lấy toàn bộ sản phẩm từ ProductProvider để lọc ban đầu
      _performSearch(""); // Hiển thị tất cả ban đầu (hoặc không hiển thị gì)
    });

    // Lắng nghe thay đổi text input
    _searchController.addListener(() {
      // Dùng debounce để tránh search quá nhiều lần khi gõ nhanh
      // (Trong ví dụ này, search ngay lập tức để đơn giản)
      if (_searchController.text != _currentQuery) {
        _performSearch(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm thực hiện tìm kiếm (lọc từ danh sách đã có)
  void _performSearch(String query) {
    if (!mounted) return; // Kiểm tra widget còn tồn tại

    setState(() {
      _isLoading = true; // Bắt đầu loading
      _currentQuery = query.toLowerCase(); // Lưu query hiện tại (chữ thường)
    });

    // Lấy danh sách sản phẩm gốc từ Provider
    final allProducts = context.read<ProductProvider>().products;

    // Lọc sản phẩm
    if (_currentQuery.isEmpty) {
      // Nếu query rỗng, hiển thị tất cả (hoặc không hiển thị gì tùy ý)
      _searchResults = List.from(allProducts); // Sao chép danh sách gốc
    } else {
      _searchResults = allProducts.where((product) {
        final titleLower = product.title.toLowerCase();
        // Tìm kiếm đơn giản trong title
        return titleLower.contains(_currentQuery);
        // Có thể mở rộng tìm kiếm trong description, category,...
      }).toList();
    }

    // Kết thúc loading sau một khoảng trễ nhỏ để UI kịp cập nhật
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  // --- AppBar Tùy chỉnh với Search Bar ---
  AppBar _buildSearchBar(BuildContext context) {
    return AppBar(
      backgroundColor: kPrimaryColor,
      elevation: 1, // Shadow nhẹ
      shadowColor: Colors.black.withOpacity(0.1),
      automaticallyImplyLeading: false, // Ẩn nút back
      titleSpacing: kDefaultPadding,
      title: TextField(
        controller: _searchController,
        autofocus: true, // Tự động focus khi vào trang
        decoration: InputDecoration(
          hintText: "Search Outfit...", // Giống thiết kế
          hintStyle: TextStyle(
            color: kSecondaryTextColor.withOpacity(0.7),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: kSecondaryTextColor.withOpacity(0.9),
            size: 22,
          ),
          filled: true,
          fillColor: kOffWhiteColor, // Màu nền search bar
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
          ), // Padding dọc
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
          // Nút xóa text
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: kSecondaryTextColor.withOpacity(0.7),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    // _performSearch(""); // Gọi lại search khi xóa
                  },
                )
              : null,
        ),
      ),
      actions: [
        IconButton(
          // Icon filter (giống thiết kế)
          icon: Icon(Icons.filter_list_alt, color: kTextColor.withOpacity(0.8)),
          onPressed: () {
            // TODO: Implement Filter functionality
            print("Filter button pressed");
          },
        ),
        const SizedBox(width: kDefaultPadding / 2),
      ],
    );
  }

  // --- Hiển thị thông tin kết quả ---
  Widget _buildResultHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            // Sử dụng Flexible để tránh text overflow
            child: Text(
              _currentQuery.isEmpty
                  ? "Showing All Products"
                  : 'Showing "${_searchController.text}"', // Hiển thị query gốc
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: kTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_isLoading) // Chỉ hiển thị số lượng khi không loading
            Text(
              "${_searchResults.length} Results",
              style: const TextStyle(fontSize: 13, color: kSecondaryTextColor),
            ),
        ],
      ),
    );
  }

  // --- Lưới hiển thị kết quả tìm kiếm ---
  Widget _buildSearchResultsGrid(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      );
    }

    if (_searchResults.isEmpty && _currentQuery.isNotEmpty) {
      return const Center(child: Text("No products found for your search."));
    }
    if (_searchResults.isEmpty && _currentQuery.isEmpty) {
      return const Center(
        child: Text("Enter a keyword to search."),
      ); // Hoặc hiển thị gợi ý
    }

    // Sử dụng lại widget card từ HomeScreenContent (có thể tách ra thành widget riêng)
    return GridView.builder(
      // shrinkWrap: true, // Không cần shrinkWrap khi dùng Expanded
      // physics: const NeverScrollableScrollPhysics(), // Không cần physics khi dùng Expanded
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 1.5,
      ).copyWith(bottom: kDefaultPadding), // Padding cho Grid
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // Tỉ lệ giống trang Home
        crossAxisSpacing: kDefaultPadding / 1.5, // Khoảng cách ngang
        mainAxisSpacing: kDefaultPadding / 1.5, // Khoảng cách dọc
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        // Sử dụng widget card tương tự như trên HomeScreen
        return _buildPopularProductCard(context, product);
      },
    );
  }

  // --- Widget Card cho Sản phẩm (Giống HomeScreenContent) ---
  Widget _buildPopularProductCard(BuildContext context, Product product) {
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: kOffWhiteColor,
                    ),
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: kSecondaryTextColor,
                                    ),
                                  ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        print("Toggle favorite for ${product.title}");
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: Icon(
                          Icons.favorite_border,
                          color: kHeartColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: kTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "\$${product.finalPrice?.toStringAsFixed(2) ?? product.price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                                fontSize: 15,
                              ),
                            ),
                            if (product.discountPercentage != null &&
                                product.discountPercentage! > 0)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-${product.discountPercentage!.toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
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
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: kSecondaryTextColor,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildSearchBar(context),
      body: Column(
        children: [
          _buildResultHeader(), // Header thông tin kết quả
          // Sử dụng Expanded để GridView chiếm hết không gian còn lại
          Expanded(child: _buildSearchResultsGrid(context)),
        ],
      ),
    );
  }
}
