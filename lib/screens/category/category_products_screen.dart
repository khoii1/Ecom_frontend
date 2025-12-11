import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/models/category.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/services/wishlist_service.dart';
import 'package:ecom_frontend/screens/product/product_detail_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Category category;

  const CategoryProductsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  
  // Wishlist state - Map<productId, isInWishlist>
  final Map<String, bool> _wishlistStatus = {};
  final Map<String, bool> _checkingWishlist = {}; // Track which products are being checked/toggled

  @override
  void initState() {
    super.initState();
    _loadCategoryProducts();
  }

  Future<void> _loadCategoryProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productService = context.read<ProductService>();
      // Backend API nhận category_id dạng string (MongoDB ObjectId)
      final categoryIdStr = widget.category.id;
      
      // Gọi API với category_id là string
      final products = await productService.getProducts(
        categoryIdString: categoryIdStr,
      );
      
      // Filter thêm ở client để đảm bảo (nếu backend không filter đúng)
      final filteredProducts = products.where((p) {
        return p.categoryId == categoryIdStr;
      }).toList();

      if (mounted) {
        setState(() {
          _products = filteredProducts;
          _isLoading = false;
        });
        // Check wishlist status for all products
        _checkAllWishlistStatus();
      }
    } catch (e) {
      print("Error loading category products: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khi tải sản phẩm: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Check wishlist status for all products
  Future<void> _checkAllWishlistStatus() async {
    if (!mounted || _products.isEmpty) return;
    
    final wishlistService = context.read<WishlistService>();
    for (var product in _products) {
      // Skip if already checking or if we already have the status
      if (_checkingWishlist[product.id] == true) continue;
      if (_wishlistStatus.containsKey(product.id)) continue; // Already have status
      
      try {
        final isInWishlist = await wishlistService.checkInWishlist(product.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategoryProducts,
        color: kPrimaryColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: kSecondaryTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: kSecondaryTextColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCategoryProducts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Thử lại',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: kSecondaryTextColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có sản phẩm nào trong danh mục này',
                              style: TextStyle(
                                color: kSecondaryTextColor,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _buildProductsGrid(),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(kDefaultPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final isOutOfStock = product.stockQuantity <= 0;
    final finalPrice = product.finalPrice;
    final hasDiscount = product.discountPercentage != null &&
        product.discountPercentage! > 0;

    return GestureDetector(
      onTap: isOutOfStock
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    productId: product.id,
                  ),
                ),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: kOffWhiteColor,
                      child: (product.imageUrls != null &&
                              product.imageUrls!.isNotEmpty)
                          ? Image.network(
                              product.imageUrls!.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: kSecondaryTextColor.withOpacity(0.3),
                                    size: 40,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      kPrimaryColor,
                                    ),
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : product.imageUrl != null
                              ? Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color:
                                            kSecondaryTextColor.withOpacity(0.3),
                                        size: 40,
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: kSecondaryTextColor.withOpacity(0.3),
                                    size: 40,
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
                  // Wishlist icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleWishlist(product.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                                    : kSecondaryTextColor.withOpacity(0.7),
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                  // Out of stock overlay
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Hết hàng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price
                    Row(
                      children: [
                        Text(
                          _currency.format(finalPrice),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? kSecondaryTextColor.withOpacity(0.5)
                                : kPrimaryColor,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            _currency.format(product.price),
                            style: TextStyle(
                              fontSize: 12,
                              color: kSecondaryTextColor.withOpacity(0.6),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isOutOfStock)
                      Text(
                        'Số lượng: ${product.stockQuantity}',
                        style: TextStyle(
                          fontSize: 11,
                          color: kSecondaryTextColor.withOpacity(0.7),
                        ),
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
}

