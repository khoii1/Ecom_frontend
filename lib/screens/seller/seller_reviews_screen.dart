import 'package:ecom_frontend/models/review.dart';
import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/models/store.dart';
import 'package:ecom_frontend/services/review_service.dart';
import 'package:ecom_frontend/services/store_service.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:ecom_frontend/widgets/review_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellerReviewsScreen extends StatefulWidget {
  const SellerReviewsScreen({super.key});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _filteredReviews = [];
  List<Store> _myStores = [];
  List<Product> _storeProducts = [];
  
  // Filters
  String? _selectedStoreId;
  String? _selectedProductId;
  int? _selectedRating;
  String _sortBy = 'newest'; // 'newest', 'oldest', 'rating_high', 'rating_low'
  
  // Stats
  Map<String, dynamic> _stats = {
    'total': 0,
    'average': 0.0,
    'five_star': 0,
    'four_star': 0,
    'three_star': 0,
    'two_star': 0,
    'one_star': 0,
  };

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Lấy stores của seller
      final storeService = context.read<StoreService>();
      _myStores = await storeService.getMyStores();
      
      if (_myStores.isEmpty) {
        setState(() {
          _error = 'Bạn chưa có cửa hàng nào';
          _isLoading = false;
        });
        return;
      }

      // Chọn store đầu tiên nếu chưa chọn
      if (_selectedStoreId == null) {
        _selectedStoreId = _myStores.first.id;
      }

      // 2. Lấy products của store
      await _loadStoreProducts();

      // 3. Lấy reviews
      await _loadReviews();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStoreProducts() async {
    if (_selectedStoreId == null) return;

    try {
      final productService = context.read<ProductService>();
      final allProducts = await productService.getProducts();
      _storeProducts = allProducts
          .where((p) => p.storeId == _selectedStoreId)
          .toList();
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _loadReviews() async {
    if (_selectedStoreId == null || _storeProducts.isEmpty) {
      setState(() {
        _allReviews = [];
        _filteredReviews = [];
        _isLoading = false;
        _updateStats();
      });
      return;
    }

    try {
      final reviewService = context.read<ReviewService>();
      final productIds = _storeProducts.map((p) => p.id).toList();
      _allReviews = await reviewService.getStoreReviews(productIds);
      
      _applyFilters();
      _updateStats();
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải đánh giá: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allReviews);

    // Lọc theo sản phẩm
    if (_selectedProductId != null && _selectedProductId!.isNotEmpty) {
      filtered = filtered.where((r) => 
        r['product_id']?.toString() == _selectedProductId
      ).toList();
    }

    // Lọc theo rating
    if (_selectedRating != null) {
      filtered = filtered.where((r) => 
        r['rating'] == _selectedRating
      ).toList();
    }

    // Sắp xếp
    filtered.sort((a, b) {
      final dateA = DateTime.parse(a['created_at'] ?? '');
      final dateB = DateTime.parse(b['created_at'] ?? '');
      
      switch (_sortBy) {
        case 'oldest':
          return dateA.compareTo(dateB);
        case 'rating_high':
          final ratingA = a['rating'] ?? 0;
          final ratingB = b['rating'] ?? 0;
          if (ratingA != ratingB) return ratingB.compareTo(ratingA);
          return dateB.compareTo(dateA);
        case 'rating_low':
          final ratingA = a['rating'] ?? 0;
          final ratingB = b['rating'] ?? 0;
          if (ratingA != ratingB) return ratingA.compareTo(ratingB);
          return dateB.compareTo(dateA);
        case 'newest':
        default:
          return dateB.compareTo(dateA);
      }
    });

    setState(() {
      _filteredReviews = filtered;
    });
  }

  void _updateStats() {
    final reviews = _filteredReviews.isEmpty ? _allReviews : _filteredReviews;
    
    if (reviews.isEmpty) {
      setState(() {
        _stats = {
          'total': 0,
          'average': 0.0,
          'five_star': 0,
          'four_star': 0,
          'three_star': 0,
          'two_star': 0,
          'one_star': 0,
        };
      });
      return;
    }

    int total = reviews.length;
    double sum = 0;
    Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (final review in reviews) {
      final rating = review['rating'] ?? 0;
      sum += rating;
      if (rating >= 1 && rating <= 5) {
        starCounts[rating] = (starCounts[rating] ?? 0) + 1;
      }
    }

    setState(() {
      _stats = {
        'total': total,
        'average': total > 0 ? (sum / total) : 0.0,
        'five_star': starCounts[5] ?? 0,
        'four_star': starCounts[4] ?? 0,
        'three_star': starCounts[3] ?? 0,
        'two_star': starCounts[2] ?? 0,
        'one_star': starCounts[1] ?? 0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá sản phẩm'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: kErrorColor),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: kErrorColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Stats card
                    _buildStatsCard(),
                    
                    // Filters
                    _buildFilters(),
                    
                    // Reviews list
                    Expanded(
                      child: _filteredReviews.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(kDefaultPadding),
                                itemCount: _filteredReviews.length,
                                itemBuilder: (context, index) {
                                  return _buildReviewCard(_filteredReviews[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(kDefaultPadding),
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê đánh giá',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Average rating
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _stats['average'].toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    RatingStars(
                      rating: _stats['average'],
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_stats['total']} đánh giá',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kSecondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Star distribution
              Expanded(
                child: Column(
                  children: [
                    _buildStarRow(5, _stats['five_star']),
                    _buildStarRow(4, _stats['four_star']),
                    _buildStarRow(3, _stats['three_star']),
                    _buildStarRow(2, _stats['two_star']),
                    _buildStarRow(1, _stats['one_star']),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(int stars, int count) {
    final percentage = _stats['total'] > 0 
        ? (count / _stats['total'] * 100).toStringAsFixed(0)
        : '0';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(fontSize: 12, color: kSecondaryTextColor),
            textAlign: TextAlign.right,
            textWidthBasis: TextWidthBasis.longestLine,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 14, color: kStarColor),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: _stats['total'] > 0 ? count / _stats['total'] : 0,
              backgroundColor: kOffWhiteColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                stars >= 4 ? kSuccessColor : stars >= 3 ? kWarningColor : kErrorColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ($percentage%)',
            style: const TextStyle(fontSize: 12, color: kSecondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          // Store filter
          if (_myStores.length > 1)
            Row(
              children: [
                const Text('Cửa hàng: ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStoreId,
                    isExpanded: true,
                    items: _myStores.map((store) {
                      return DropdownMenuItem(
                        value: store.id,
                        child: Text(store.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStoreId = value;
                        _selectedProductId = null;
                      });
                      _loadStoreProducts().then((_) => _loadReviews());
                    },
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              // Product filter
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedProductId,
                  hint: const Text('Tất cả sản phẩm', style: TextStyle(fontSize: 14)),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tất cả sản phẩm'),
                    ),
                    ..._storeProducts.map((product) {
                      return DropdownMenuItem(
                        value: product.id,
                        child: Text(
                          product.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProductId = value;
                    });
                    _applyFilters();
                    _updateStats();
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Rating filter
              DropdownButton<int>(
                value: _selectedRating,
                hint: const Text('Tất cả', style: TextStyle(fontSize: 14)),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Tất cả'),
                  ),
                  ...List.generate(5, (index) {
                    final rating = 5 - index;
                    return DropdownMenuItem(
                      value: rating,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$rating'),
                          const Icon(Icons.star, size: 16, color: kStarColor),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRating = value;
                  });
                  _applyFilters();
                  _updateStats();
                },
              ),
              
              const SizedBox(width: 8),
              
              // Sort
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                  _applyFilters();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'newest',
                    child: Text('Mới nhất'),
                  ),
                  const PopupMenuItem(
                    value: 'oldest',
                    child: Text('Cũ nhất'),
                  ),
                  const PopupMenuItem(
                    value: 'rating_high',
                    child: Text('Đánh giá cao'),
                  ),
                  const PopupMenuItem(
                    value: 'rating_low',
                    child: Text('Đánh giá thấp'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> reviewData) {
    final review = Review.fromJson(reviewData);
    final product = _storeProducts.firstWhere(
      (p) => p.id == review.productId,
      orElse: () => Product(
        id: review.productId,
        storeId: '',
        title: 'Sản phẩm đã xóa',
        price: 0,
        status: 'inactive',
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: kDefaultPadding),
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Product info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl ?? '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: kOffWhiteColor,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 4),
                    Text(
                      _dateFormatter.format(review.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: kSecondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // Review content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating
              RatingStars(rating: review.rating.toDouble(), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Comment
                    if (review.comment != null && review.comment!.isNotEmpty)
                      Text(
                        review.comment!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kTextColor,
                          height: 1.5,
                        ),
                      ),
                    // Images
                    if (review.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: review.imageUrls.take(3).map((url) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: kOffWhiteColor,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // Seller Response
          if (review.sellerResponse != null && review.sellerResponse!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kPrimaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        size: 16,
                        color: kPrimaryColor,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Phản hồi từ người bán',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (review.sellerResponseAt != null)
                        Text(
                          _dateFormatter.format(review.sellerResponseAt!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: kSecondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.sellerResponse!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kTextColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Button to respond
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showResponseDialog(review),
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Phản hồi đánh giá'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: const BorderSide(color: kPrimaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showResponseDialog(Review review) {
    final TextEditingController responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phản hồi đánh giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đánh giá từ ${review.userName}:',
              style: const TextStyle(
                fontSize: 12,
                color: kSecondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              review.comment ?? 'Không có bình luận',
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Phản hồi của bạn',
                hintText: 'Nhập phản hồi...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              maxLines: 5,
              maxLength: 1000,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập phản hồi'),
                    backgroundColor: kErrorColor,
                  ),
                );
                return;
              }

              try {
                final reviewService = context.read<ReviewService>();
                await reviewService.respondToReview(
                  reviewId: review.id,
                  response: responseController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phản hồi thành công'),
                      backgroundColor: kSuccessColor,
                    ),
                  );
                  // Reload reviews
                  await _loadReviews();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: kErrorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gửi phản hồi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: kSecondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(
              fontSize: 16,
              color: kSecondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

