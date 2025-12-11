import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/models/review.dart';
import 'package:ecom_frontend/models/order.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/services/review_service.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/widgets/review_widget.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/providers/product_provider.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/cart/cart_screen.dart';
import 'package:ecom_frontend/services/wishlist_service.dart';
import 'package:ecom_frontend/screens/product/image_gallery_dialog.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/models/product_variant.dart';
import 'package:ecom_frontend/services/product_variant_service.dart';
import 'package:ecom_frontend/services/chat_service.dart';
import 'package:ecom_frontend/screens/chat/chat_screen.dart';
import 'package:ecom_frontend/screens/product/product_reviews_screen.dart';
import 'package:ecom_frontend/models/store.dart';
import 'package:ecom_frontend/services/store_service.dart';
import 'package:ecom_frontend/screens/store/store_products_screen.dart';
import 'package:ecom_frontend/l10n/app_localizations.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // State
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;

  List<Product> _similarProducts = [];
  bool _isLoadingSimilar = true;

  late PageController _imageSliderController;

  // Reviews state
  List<Review> _reviews = [];
  ReviewStats? _reviewStats;
  bool _isLoadingReviews = true;

  // Wishlist state
  bool _isInWishlist = false;
  bool _isCheckingWishlist = false;

  // Purchase state - kiểm tra user đã mua sản phẩm chưa
  bool _hasPurchasedProduct = false;
  bool _isCheckingPurchase = false;

  // Variants state
  List<ProductVariant> _variants = [];
  Map<String, String?> _selectedVariants = {}; // {name: value}

  // Chat state
  bool _isCreatingConversation = false;

  // Store state
  Store? _store;

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _imageSliderController = PageController();
    _fetchProductDetails();
    _fetchReviews();
    _checkWishlistStatus();
    _loadVariants();
    _checkIfUserPurchasedProduct();
  }

  Future<void> _loadVariants() async {
    try {
      final variantService = context.read<ProductVariantService>();
      final variants = await variantService.getProductVariants(
        widget.productId,
      );
      if (mounted) {
        setState(() {
          _variants = variants;
          // Group variants by name
          final variantGroups = <String, List<ProductVariant>>{};
          for (var variant in variants) {
            if (!variantGroups.containsKey(variant.name)) {
              variantGroups[variant.name] = [];
            }
            variantGroups[variant.name]!.add(variant);
          }
          // Auto-select first variant of each group
          for (var entry in variantGroups.entries) {
            if (_selectedVariants[entry.key] == null &&
                entry.value.isNotEmpty) {
              _selectedVariants[entry.key] = entry.value.first.value;
            }
          }
        });
      }
    } catch (e) {
      // Silent fail - variants are optional
    }
  }

  @override
  void dispose() {
    _imageSliderController.dispose();
    super.dispose();
  }

  void _showImageGallery(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) =>
          ImageGalleryDialog(images: images, initialIndex: initialIndex),
    );
  }

  // Kiểm tra trạng thái wishlist
  Future<void> _checkWishlistStatus() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.authStatus != AuthStatus.authenticated) {
      return;
    }

    setState(() => _isCheckingWishlist = true);
    try {
      final wishlistService = context.read<WishlistService>();
      final isInWishlist = await wishlistService.checkInWishlist(
        widget.productId,
      );
      if (mounted) {
        setState(() {
          _isInWishlist = isInWishlist;
          _isCheckingWishlist = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingWishlist = false);
      }
    }
  }

  // Kiểm tra user đã mua sản phẩm chưa
  Future<void> _checkIfUserPurchasedProduct() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.authStatus != AuthStatus.authenticated) {
      return;
    }

    setState(() => _isCheckingPurchase = true);
    try {
      final orderService = context.read<OrderService>();
      final allOrders = await orderService.getMyOrders();

      // Lọc orders đã thanh toán
      final paidOrders = allOrders.where((order) {
        return order.status == 'paid' ||
            order.status == 'processing' ||
            order.status == 'shipped' ||
            order.status == 'delivered';
      }).toList();

      // Kiểm tra từng order xem có chứa sản phẩm này không
      for (final order in paidOrders) {
        try {
          final orderDetail = await orderService.getOrderDetail(order.id);
          if (orderDetail.items != null) {
            final hasProduct = orderDetail.items!.any(
              (item) => item.productId == widget.productId,
            );
            if (hasProduct) {
              if (mounted) {
                setState(() {
                  _hasPurchasedProduct = true;
                  _isCheckingPurchase = false;
                });
              }
              return;
            }
          }
        } catch (e) {
          // Bỏ qua lỗi khi lấy chi tiết order
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _hasPurchasedProduct = false;
          _isCheckingPurchase = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPurchasedProduct = false;
          _isCheckingPurchase = false;
        });
      }
    }
  }

  // Open chat with seller
  Future<void> _openChat() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.authStatus != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để chat với người bán'),
        ),
      );
      return;
    }

    if (_product == null) return;

    setState(() {
      _isCreatingConversation = true;
    });

    try {
      final chatService = context.read<ChatService>();
      // Tạo conversation chung giữa buyer và seller (không theo từng sản phẩm)
      final conversation = await chatService.createConversation(
        storeId: _product!.storeId,
        // Bỏ productId để tạo conversation chung
      );

      if (mounted) {
        setState(() {
          _isCreatingConversation = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversationId: conversation.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingConversation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  // Toggle wishlist
  Future<void> _toggleWishlist() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.authStatus != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để sử dụng tính năng yêu thích'),
        ),
      );
      return;
    }

    setState(() => _isCheckingWishlist = true);
    try {
      final wishlistService = context.read<WishlistService>();
      if (_isInWishlist) {
        await wishlistService.removeFromWishlist(widget.productId);
        if (mounted) {
          setState(() {
            _isInWishlist = false;
            _isCheckingWishlist = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa khỏi danh sách yêu thích')),
          );
        }
      } else {
        await wishlistService.addToWishlist(widget.productId);
        if (mounted) {
          setState(() {
            _isInWishlist = true;
            _isCheckingWishlist = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm vào danh sách yêu thích')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingWishlist = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  // Tải chi tiết sản phẩm
  Future<void> _fetchProductDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productService = context.read<ProductService>();
      final productData = await productService.getProductDetail(
        widget.productId,
      );
      if (!mounted) return;
      setState(() {
        _product = productData;
        _isLoading = false;
      });
      _fetchSimilarProducts();
      // Load store detail sau khi có product
      if (productData.storeId.isNotEmpty) {
        _fetchStoreDetails(productData.storeId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải chi tiết sản phẩm: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Tải store details
  Future<void> _fetchStoreDetails(String storeId) async {
    if (!mounted) return;

    try {
      final storeService = context.read<StoreService>();
      final storeData = await storeService.getStoreDetail(storeId);
      if (!mounted) return;
      setState(() {
        _store = storeData;
      });
    } catch (e) {
      // Silent fail - store info is optional
    }
  }

  // Tải reviews
  Future<void> _fetchReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);

    try {
      final reviewService = context.read<ReviewService>();
      final data = await reviewService.getProductReviews(widget.productId);

      if (!mounted) return;

      final reviewsList = (data['reviews'] as List)
          .map((r) => Review.fromJson(r))
          .toList();
      final stats = ReviewStats.fromJson(data['stats']);

      setState(() {
        _reviews = reviewsList;
        _reviewStats = stats;
        _isLoadingReviews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingReviews = false);
    }
  }

  // Hiển thị dialog viết review
  void _showWriteReviewDialog() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.authStatus != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
      );
      return;
    }

    // Kiểm tra user đã mua sản phẩm chưa
    if (!_hasPurchasedProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng mua sản phẩm để có thể đánh giá'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Lấy danh sách orders đã mua sản phẩm này
    List<Order>? availableOrders;
    try {
      final orderService = context.read<OrderService>();
      final allOrders = await orderService.getMyOrders();
      // Lọc orders đã thanh toán và có chứa sản phẩm này
      availableOrders = allOrders.where((order) {
        if (order.status != 'paid' &&
            order.status != 'processing' &&
            order.status != 'shipped' &&
            order.status != 'delivered') {
          return false;
        }
        // Kiểm tra xem order có chứa sản phẩm này không (cần lấy chi tiết order)
        // Tạm thời lấy tất cả orders đã thanh toán, backend sẽ validate
        return true;
      }).toList();
    } catch (e) {
      // Nếu không lấy được orders, vẫn cho phép user thử
      availableOrders = [];
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => WriteReviewDialog(
        productName: _product?.title ?? '',
        productId: widget.productId,
        availableOrders: availableOrders,
        onSubmit: (orderId, rating, comment, imageUrls) async {
          final reviewService = context.read<ReviewService>();
          await reviewService.createReview(
            productId: widget.productId,
            orderId: orderId,
            rating: rating,
            comment: comment,
            imageUrls: imageUrls,
          );
        },
      ),
    );

    if (result == true) {
      // Refresh reviews sau khi tạo thành công
      // Thử fetch lại nhiều lần để đảm bảo lấy được review mới
      int previousReviewCount = _reviews.length;
      bool reviewFound = false;

      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) break;

        await _fetchReviews();

        // Kiểm tra xem review mới đã có trong danh sách chưa
        // (so sánh số lượng reviews trước và sau)
        if (mounted && _reviews.length > previousReviewCount) {
          reviewFound = true;
          break;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reviewFound
                  ? 'Đã gửi đánh giá thành công!'
                  : 'Đã gửi đánh giá. Vui lòng kéo xuống để làm mới.',
            ),
            backgroundColor: reviewFound ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );

        // Force rebuild để đảm bảo UI được cập nhật
        setState(() {});
      }
    }
  }

  // Lọc sản phẩm tương tự từ ProductProvider
  void _fetchSimilarProducts() {
    if (!mounted) return;

    if (_product == null || _product!.categoryId == null) {
      setState(() => _isLoadingSimilar = false);
      return;
    }

    setState(() => _isLoadingSimilar = true);

    final productProvider = context.read<ProductProvider>();
    if (productProvider.products.isEmpty) {
      setState(() => _isLoadingSimilar = false);
      return;
    }

    try {
      final similar = productProvider.products
          .where(
            (p) => p.categoryId == _product!.categoryId && p.id != _product!.id,
          )
          .toList()
          .take(4)
          .toList();

      if (!mounted) return;
      setState(() {
        _similarProducts = similar;
        _isLoadingSimilar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSimilar = false);
    }
  }

  // Thêm vào giỏ
  void _addToCart() {
    if (!mounted || _product == null) return;
    final cartProvider = context.read<CartProvider>();
    try {
      cartProvider.addToCart(_product!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm "${_product!.title}" vào giỏ hàng'),
          duration: const Duration(seconds: 2),
          backgroundColor: kPrimaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thêm vào giỏ: ${e.toString()}'),
          backgroundColor: kHeartColor,
        ),
      );
    }
  }

  // Mua ngay (thêm vào giỏ rồi điều hướng sang giỏ)
  void _buyNow() async {
    if (!mounted || _product == null) return;
    final cartProvider = context.read<CartProvider>();
    try {
      await cartProvider.addToCart(_product!.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm vào giỏ: ${e.toString()}'),
          backgroundColor: kHeartColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // AppBar
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.productDetail),
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
            icon: _isCreatingConversation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: _isCreatingConversation ? null : _openChat,
            tooltip: 'Chat với người bán',
          ),
          IconButton(
            icon: _isCheckingWishlist
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: _isInWishlist ? kHeartColor : Colors.white,
                  ),
            onPressed: _isCheckingWishlist ? null : _toggleWishlist,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _product != null ? _buildBottomButtons() : null,
    );
  }

  // Body (loading / error / content)
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

    // Sử dụng imageUrls nếu có, fallback về imageUrl
    List<String> images = [];
    if (_product!.imageUrls != null && _product!.imageUrls!.isNotEmpty) {
      images = _product!.imageUrls!;
    } else if (_product!.imageUrl != null && _product!.imageUrl!.isNotEmpty) {
      images = [_product!.imageUrl!];
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _fetchProductDetails(),
          _fetchReviews(),
          _checkWishlistStatus(),
          _loadVariants(),
          _checkIfUserPurchasedProduct(),
        ]);
      },
      color: kPrimaryColor,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSlider(images),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: _buildProductInfo(),
            ),
            const Divider(height: 1, thickness: 6, color: kOffWhiteColor),
            // Store profile section
            if (_store != null)
              Padding(
                padding: const EdgeInsets.all(kDefaultPadding),
                child: _buildStoreProfile(),
              ),
            if (_store != null)
              const Divider(height: 1, thickness: 6, color: kOffWhiteColor),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: _buildReviewsSection(),
            ),
            const Divider(height: 1, thickness: 6, color: kOffWhiteColor),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: _buildSimilarProductsSection(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Khu vực đánh giá
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'Đánh giá sản phẩm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Chỉ hiển thị nút "Viết đánh giá" nếu user đã mua sản phẩm
            if (_hasPurchasedProduct)
              TextButton.icon(
                onPressed: _showWriteReviewDialog,
                icon: const Icon(Icons.rate_review, size: 18),
                label: const Text('Viết đánh giá'),
                style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
              )
            else if (!_isCheckingPurchase)
              Flexible(
                child: TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text(
                    'Mua để đánh giá',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    disabledForegroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: kDefaultPadding / 2),

        if (_isLoadingReviews)
          const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
          )
        else if (_reviewStats != null && _reviewStats!.totalReviews > 0) ...[
          // Thống kê đánh giá
          ReviewStatsWidget(stats: _reviewStats!),
          const SizedBox(height: kDefaultPadding),

          // Danh sách reviews (hiển thị tối đa 3)
          ..._reviews.take(3).map((review) {
            final authProvider = context.read<AuthProvider>();
            final isOwner =
                authProvider.currentUser?.id.toString() == review.userId;

            return ReviewCard(
              review: review,
              isOwner: isOwner,
              onEdit: isOwner
                  ? () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => WriteReviewDialog(
                          productName: _product?.title ?? '',
                          productId: widget.productId,
                          initialRating: review.rating,
                          initialComment: review.comment,
                          initialImageUrls: review.imageUrls,
                          onSubmit:
                              (orderId, rating, comment, imageUrls) async {
                                final reviewService = context
                                    .read<ReviewService>();
                                // Upload ảnh mới nếu có
                                List<String> finalImageUrls = review.imageUrls;
                                if (imageUrls != null && imageUrls.isNotEmpty) {
                                  finalImageUrls = imageUrls;
                                }
                                await reviewService.updateReview(
                                  reviewId: review.id,
                                  rating: rating,
                                  comment: comment,
                                  imageUrls: finalImageUrls,
                                );
                              },
                        ),
                      );
                      if (result == true) _fetchReviews();
                    }
                  : null,
              onDelete: isOwner
                  ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận'),
                          content: const Text(
                            'Bạn có chắc muốn xóa đánh giá này?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          final reviewService = context.read<ReviewService>();
                          await reviewService.deleteReview(review.id);
                          _fetchReviews();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xóa đánh giá')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        }
                      }
                    }
                  : null,
            );
          }),

          // Nút xem thêm nếu có nhiều reviews
          if (_reviews.length > 3)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductReviewsScreen(
                      productId: widget.productId,
                      productTitle: _product?.title ?? '',
                      initialStats: _reviewStats,
                    ),
                  ),
                );
              },
              child: Text(
                'Xem tất cả ${_reviews.length} đánh giá',
                style: const TextStyle(color: kPrimaryColor),
              ),
            ),
        ] else
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có đánh giá nào',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Hiển thị nút hoặc thông báo tùy theo user đã mua sản phẩm chưa
                  if (_hasPurchasedProduct)
                    ElevatedButton(
                      onPressed: _showWriteReviewDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Viết đánh giá đầu tiên'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hãy mua sản phẩm để có thể đánh giá',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Store profile widget (giống Shopee)
  Widget _buildStoreProfile() {
    if (_store == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        // Navigate to store products screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreProductsScreen(store: _store!),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Store avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
              ),
              child: Icon(Icons.store, color: kPrimaryColor, size: 30),
            ),
            const SizedBox(width: 12),
            // Store info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _store!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '4.5', // TODO: Get from store stats if available
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 12,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Online', // TODO: Get from store status
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat button
                SizedBox(
                  width: 70,
                  child: ElevatedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: const Text('Chat', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 28),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // View shop button
                SizedBox(
                  width: 70,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to store products screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StoreProductsScreen(store: _store!),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: BorderSide(color: kPrimaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      'Xem shop',
                      style: TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Slider ảnh
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
            controller: _imageSliderController,
            itemCount: images.length,
            onPageChanged: (index) {
              if (mounted) setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageGallery(images, index),
                child: Hero(
                  tag: 'product_image_$index',
                  child: Image.network(
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
                  ),
                ),
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

  // Khối thông tin sản phẩm
  Widget _buildProductInfo() {
    final hasDiscount =
        _product!.discountPercentage != null &&
        _product!.discountPercentage! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên + đánh giá + đã bán
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
                        (_product!.rating ?? 0).toStringAsFixed(1),
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
                        'Đã bán 8.374',
                        style: TextStyle(color: kSecondaryTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: kDefaultPadding),
            // Giá + badge giảm
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(
                    _product!.finalPrice ?? _product!.price,
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(height: 2),
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
                      ),
                    ),
                    child: Text(
                      '-${_product!.discountPercentage!.toInt()}%',
                      style: const TextStyle(
                        color: kHeartColor,
                        fontSize: 12,
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

        // Stock status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _product!.stockQuantity > 0
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _product!.stockQuantity > 0
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _product!.stockQuantity > 0
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                size: 18,
                color: _product!.stockQuantity > 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _product!.stockQuantity > 0
                    ? '${AppLocalizations.of(context)!.inStock} (${_product!.stockQuantity} ${AppLocalizations.of(context)!.productsCount})'
                    : AppLocalizations.of(context)!.outOfStock,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _product!.stockQuantity > 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: kDefaultPadding),

        // Variants selector
        if (_variants.isNotEmpty) _buildVariantsSelector(),

        if (_variants.isNotEmpty) const SizedBox(height: kDefaultPadding),

        // Mô tả
        Text(
          AppLocalizations.of(context)!.description,
          style: const TextStyle(
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

  // Variants selector widget
  Widget _buildVariantsSelector() {
    // Group variants by name
    final variantGroups = <String, List<ProductVariant>>{};
    for (var variant in _variants) {
      if (!variantGroups.containsKey(variant.name)) {
        variantGroups[variant.name] = [];
      }
      variantGroups[variant.name]!.add(variant);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: variantGroups.entries.map((entry) {
        final variantName = entry.key;
        final variants = entry.value;
        final selectedValue = _selectedVariants[variantName];

        return Padding(
          padding: const EdgeInsets.only(bottom: kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                variantName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: kDefaultPadding / 2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: variants.map((variant) {
                  final isSelected = selectedValue == variant.value;
                  final isOutOfStock = variant.stockQuantity <= 0;

                  return GestureDetector(
                    onTap: isOutOfStock
                        ? null
                        : () {
                            setState(() {
                              _selectedVariants[variantName] = variant.value;
                            });
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kPrimaryColor.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? kPrimaryColor
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            variant.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isOutOfStock
                                  ? Colors.grey
                                  : isSelected
                                  ? kPrimaryColor
                                  : kTextColor,
                            ),
                          ),
                          if (variant.priceModifier != 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              variant.priceModifier > 0
                                  ? '+${currencyFormatter.format(variant.priceModifier)}'
                                  : currencyFormatter.format(
                                      variant.priceModifier,
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                color: variant.priceModifier > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                          if (isOutOfStock) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '(Hết hàng)',
                              style: TextStyle(fontSize: 11, color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Khu vực sản phẩm tương tự
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
                /* TODO: Điều hướng xem tất cả */
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

  // Card sản phẩm tương tự
  Widget _buildSimilarProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
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

  // Nút đáy (thêm giỏ / mua ngay)
  Widget _buildBottomButtons() {
    final isOutOfStock = _product!.stockQuantity <= 0;

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
              label: Text(
                isOutOfStock
                    ? AppLocalizations.of(context)!.outOfStock
                    : AppLocalizations.of(context)!.addToCart,
              ),
              onPressed: isOutOfStock ? null : _addToCart,
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
              onPressed: isOutOfStock ? null : _buyNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutOfStock ? Colors.grey : kPrimaryColor,
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
