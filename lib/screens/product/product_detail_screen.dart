import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Thêm thư viện intl để format tiền tệ

// --- Giả định các file/class này đã tồn tại ---
import 'package:ecom_frontend/models/product.dart'; // Model Product của bạn
import 'package:ecom_frontend/services/product_service.dart'; // Service Product của bạn
import 'package:ecom_frontend/widgets/primary_button.dart'; // Widget Button của bạn
import 'package:ecom_frontend/providers/cart_provider.dart'; // Provider giỏ hàng
import 'package:ecom_frontend/providers/product_provider.dart'; // Provider sản phẩm
// SỬA: Thêm import cho CartScreen
import 'package:ecom_frontend/screens/cart/cart_screen.dart'; // <<< THÊM DÒNG NÀY
// --- KẾT THÚC SỬA ---
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/scheduler.dart'; // Import SchedulerBinding

class ProductDetailScreen extends StatefulWidget {
  final String productId; // ID sản phẩm được truyền vào

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0; // Để theo dõi ảnh đang hiển thị

  List<Product> _similarProducts = [];
  bool _isLoadingSimilar = true;

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0, // Bỏ phần thập phân
  );

  // --- THÊM MỚI: Biến kiểm tra mounted ---
  // bool _mounted = true; // Không cần thiết trong StatefulWidget

  @override
  void initState() {
    super.initState();
    // _mounted = true; // Không cần thiết
    _fetchProductDetails();
  }

  // @override
  // void dispose() {
  //   _mounted = false; // Không cần thiết
  //   super.dispose();
  // }

  Future<void> _fetchProductDetails() async {
    if (!mounted) return; // Kiểm tra mounted có sẵn trong State
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productService = context.read<ProductService>();
      final productData = await productService.getProductDetail(
        widget.productId,
      );
      // Kiểm tra mounted lần nữa trước khi gọi setState
      if (mounted) {
        setState(() {
          _product = productData;
          _isLoading = false;
          _errorMessage = null;
        });
        _fetchSimilarProducts();
      }
    } catch (e) {
      print("Lỗi lấy chi tiết sản phẩm: $e");
      if (mounted) {
        // Kiểm tra mounted
        setState(() {
          _errorMessage = 'Không thể tải chi tiết sản phẩm: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _fetchSimilarProducts() {
    // Kiểm tra mounted ở đầu hàm
    if (!mounted) return;

    if (_product == null || _product!.categoryId == null) {
      setState(() => _isLoadingSimilar = false);
      return;
    }

    setState(() => _isLoadingSimilar = true);

    ProductProvider? productProvider = context.read<ProductProvider>();
    if (productProvider == null || productProvider.products.isEmpty) {
      print("ProductProvider chưa sẵn sàng hoặc chưa có sản phẩm.");
      if (mounted)
        setState(() => _isLoadingSimilar = false); // Kiểm tra mounted
      return;
    }

    try {
      final similar = productProvider.products
          .where(
            (p) => p.categoryId == _product!.categoryId && p.id != _product!.id,
          )
          .toList();

      final limitedSimilar = similar.take(4).toList();

      if (mounted) {
        // Kiểm tra mounted
        setState(() {
          _similarProducts = limitedSimilar;
          _isLoadingSimilar = false;
        });
      }
    } catch (e) {
      print("Lỗi khi lọc sản phẩm tương tự: $e");
      if (mounted) {
        // Kiểm tra mounted
        setState(() {
          _isLoadingSimilar = false;
        });
      }
    }
  }

  void _addToCart() {
    // Kiểm tra mounted trước khi truy cập context
    if (!mounted) return;
    if (_product != null) {
      final cartProvider = context.read<CartProvider>();
      try {
        // Không cần await nếu chỉ hiển thị SnackBar ngay lập tức
        cartProvider.addToCart(_product!.id);
        // Kiểm tra mounted trước khi hiển thị SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm "${_product!.title}" vào giỏ hàng'),
              duration: const Duration(seconds: 2),
              backgroundColor: kPrimaryColor,
            ),
          );
        }
        print('Thêm vào giỏ hàng: ${_product!.id}');
      } catch (e) {
        if (mounted) {
          // Kiểm tra mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi thêm vào giỏ: ${e.toString()}'),
              backgroundColor: kHeartColor,
            ),
          );
        }
      }
    }
  }

  void _buyNow() {
    // Kiểm tra mounted trước khi truy cập context
    if (!mounted) return;
    if (_product != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mua ngay: "${_product!.title}"')));
      print('Mua ngay: ${_product!.id}');
      // Điều hướng đến trang thanh toán
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              // TODO: Xử lý thêm vào yêu thích
            },
          ),
          // SỬA: Thêm hành động điều hướng cho IconButton giỏ hàng
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              // Điều hướng đến CartScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(),
                ), // Bỏ const nếu CartScreen không const
              );
            },
          ),
          // --- KẾT THÚC SỬA ---
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _product != null ? _buildBottomButtons() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: kHeartColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kDefaultPadding),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
                onPressed: _fetchProductDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return const Center(child: Text('Không tìm thấy thông tin sản phẩm.'));
    }

    final List<String> images =
        (_product!.imageUrl != null && _product!.imageUrl!.isNotEmpty)
        ? [_product!.imageUrl!]
        : [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSlider(images),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: _buildProductInfo(),
          ),
          const Divider(height: 1, thickness: 6, color: kOffWhiteColor),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: _buildSimilarProductsSection(),
          ),
          const SizedBox(height: 80), // Khoảng trống cho bottom buttons
        ],
      ),
    );
  }

  Widget _buildImageSlider(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 300,
        color: kOffWhiteColor,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: kSecondaryTextColor,
          ),
        ),
      );
    }

    return Container(
      height: 300,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              // Kiểm tra mounted trước khi gọi setState
              if (mounted) setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        kPrimaryColor,
                      ),
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 50,
                      color: kSecondaryTextColor,
                    ),
                  );
                },
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 10.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentImageIndex == index ? 12.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentImageIndex == index
                          ? kPrimaryColor
                          : kPrimaryColor.withOpacity(0.3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    bool hasDiscount =
        _product!.discountPercentage != null &&
        _product!.discountPercentage! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Căn trên cùng
          children: [
            // Cột Tên + Rating + Sold
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                  Row(
                    children: [
                      const Icon(Icons.star, color: kStarColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _product!.rating?.toStringAsFixed(1) ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(width: kDefaultPadding / 2),
                      const Text(
                        '|',
                        style: TextStyle(color: kSecondaryTextColor),
                      ),
                      const SizedBox(width: kDefaultPadding / 2),
                      const Text(
                        '8,374 sold',
                        style: TextStyle(color: kSecondaryTextColor),
                      ), // Dữ liệu giả định
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: kDefaultPadding),
            // Cột Giá + Discount Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Căn phải
              children: [
                Text(
                  currencyFormatter.format(
                    _product!.finalPrice ?? _product!.price,
                  ),
                  style: const TextStyle(
                    fontSize: 24, // To hơn chút
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
                if (hasDiscount) ...[
                  // Dùng spread operator để thêm nhiều widget
                  const SizedBox(height: 2), // Khoảng cách nhỏ
                  Text(
                    currencyFormatter.format(_product!.price),
                    style: const TextStyle(
                      fontSize: 14,
                      color: kSecondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: kHeartColor,
                      decorationThickness: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kHeartColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: kHeartColor.withOpacity(0.5),
                        width: 1,
                      ), // Viền nhạt hơn
                    ),
                    child: Text(
                      '-${_product!.discountPercentage!.toInt()}%',
                      style: const TextStyle(
                        color: kHeartColor,
                        fontSize: 12, // Nhỏ hơn
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: kDefaultPadding),

        // --- Mô tả sản phẩm ---
        const Text(
          "Mô tả sản phẩm",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          _product!.description ?? 'Không có mô tả cho sản phẩm này.',
          style: const TextStyle(
            fontSize: 14,
            color: kSecondaryTextColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sản phẩm tương tự',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            TextButton(
              onPressed: () {
                /* TODO: Navigate */
              },
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: kDefaultPadding / 2),
        if (_isLoadingSimilar)
          const SizedBox(
            height: 230,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
          )
        else if (_similarProducts.isEmpty)
          const SizedBox(
            height: 230,
            child: Center(child: Text("Không tìm thấy sản phẩm tương tự.")),
          )
        else
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _similarProducts.length,
              itemBuilder: (context, index) {
                final similarProd = _similarProducts[index];
                return _buildSimilarProductCard(similarProd);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSimilarProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ), // Thêm context
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: kDefaultPadding * 0.75),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                    ? Container(
                        color: kOffWhiteColor,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: kSecondaryTextColor,
                          ),
                        ),
                      )
                    : Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (c, e, s) => Container(
                          color: kOffWhiteColor,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: kSecondaryTextColor,
                            ),
                          ),
                        ),
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(kPrimaryColor),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: kTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      currencyFormatter.format(
                        product.finalPrice ?? product.price,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kBrownDark,
                        fontSize: 14,
                      ),
                      maxLines: 1,
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

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 1.5,
        vertical: kDefaultPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
              label: const Text('Thêm vào giỏ'),
              onPressed: _addToCart,
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                side: const BorderSide(color: kPrimaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: kDefaultPadding),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              label: const Text('Mua ngay'),
              onPressed: _buyNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
