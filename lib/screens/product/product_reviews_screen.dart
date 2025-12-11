import 'package:ecom_frontend/models/review.dart';
import 'package:ecom_frontend/services/review_service.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/widgets/review_widget.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductReviewsScreen extends StatefulWidget {
  final String productId;
  final String productTitle;
  final ReviewStats? initialStats;

  const ProductReviewsScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    this.initialStats,
  });

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Review> _allReviews = []; // Tất cả reviews từ API
  List<Review> _filteredReviews = []; // Reviews sau khi filter
  ReviewStats? _reviewStats;
  
  // Filter options
  int? _selectedRating; // null = all, 1-5 = specific rating
  String _sortBy = 'newest'; // 'newest', 'oldest', 'rating_high', 'rating_low'

  @override
  void initState() {
    super.initState();
    _reviewStats = widget.initialStats;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviewService = context.read<ReviewService>();
      final data = await reviewService.getProductReviews(widget.productId);

      if (mounted) {
        final reviewsList = (data['reviews'] as List)
            .map((r) => Review.fromJson(r))
            .toList();
        final stats = ReviewStats.fromJson(data['stats']);

        setState(() {
          _allReviews = reviewsList;
          _reviewStats = stats;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    // Filter và sort reviews từ _allReviews
    List<Review> filtered = List.from(_allReviews);

    // Filter by rating
    if (_selectedRating != null) {
      filtered = filtered.where((r) => r.rating == _selectedRating).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'rating_high':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'rating_low':
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {
      _filteredReviews = filtered;
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
            onPressed: _loadReviews,
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
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: kErrorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: kErrorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReviews,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Stats và Filters
                    Container(
                      padding: const EdgeInsets.all(kDefaultPadding),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product title
                          Text(
                            widget.productTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          
                          // Review stats
                          if (_reviewStats != null)
                            ReviewStatsWidget(stats: _reviewStats!),
                          
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          
                          // Filter by rating
                          const Text(
                            'Lọc theo đánh giá:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildRatingFilterChip(null, 'Tất cả'),
                              _buildRatingFilterChip(5, '5 sao'),
                              _buildRatingFilterChip(4, '4 sao'),
                              _buildRatingFilterChip(3, '3 sao'),
                              _buildRatingFilterChip(2, '2 sao'),
                              _buildRatingFilterChip(1, '1 sao'),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Sort options
                          const Text(
                            'Sắp xếp:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _sortBy,
                            decoration: kInputDecoration('Sắp xếp'),
                            items: const [
                              DropdownMenuItem(
                                value: 'newest',
                                child: Text('Mới nhất'),
                              ),
                              DropdownMenuItem(
                                value: 'oldest',
                                child: Text('Cũ nhất'),
                              ),
                              DropdownMenuItem(
                                value: 'rating_high',
                                child: Text('Đánh giá cao → thấp'),
                              ),
                              DropdownMenuItem(
                                value: 'rating_low',
                                child: Text('Đánh giá thấp → cao'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortBy = value;
                                });
                                _applyFilters();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Reviews list
                    Expanded(
                      child: _filteredReviews.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.rate_review_outlined,
                                    size: 64,
                                    color: kSecondaryTextColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedRating != null
                                        ? 'Không có đánh giá ${_selectedRating} sao'
                                        : 'Chưa có đánh giá nào',
                                    style: const TextStyle(
                                      color: kSecondaryTextColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadReviews,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(kDefaultPadding),
                                itemCount: _filteredReviews.length,
                                itemBuilder: (context, index) {
                                  final review = _filteredReviews[index];
                                  final authProvider = context.read<AuthProvider>();
                                  final isOwner = authProvider.currentUser?.id.toString() == review.userId;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: kDefaultPadding),
                                    child: ReviewCard(
                                      review: review,
                                      isOwner: isOwner,
                                      onEdit: isOwner ? () => _editReview(review) : null,
                                      onDelete: isOwner ? () => _deleteReview(review) : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRatingFilterChip(int? rating, String label) {
    final isSelected = _selectedRating == rating;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRating = selected ? rating : null;
        });
        _applyFilters();
      },
      selectedColor: kPrimaryColor.withOpacity(0.2),
      checkmarkColor: kPrimaryColor,
      labelStyle: TextStyle(
        color: isSelected ? kPrimaryColor : kTextColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Future<void> _editReview(Review review) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => WriteReviewDialog(
        productId: widget.productId,
        productName: widget.productTitle,
        initialRating: review.rating,
        initialComment: review.comment,
        initialImageUrls: review.imageUrls,
        onSubmit: (orderId, rating, comment, imageUrls) async {
          final reviewService = context.read<ReviewService>();
          await reviewService.updateReview(
            reviewId: review.id,
            rating: rating,
            comment: comment,
            imageUrls: imageUrls,
          );
        },
      ),
    );

    if (result == true && mounted) {
      await _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật đánh giá thành công'),
            backgroundColor: kSuccessColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteReview(Review review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: kErrorColor),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        setState(() => _isLoading = true);
        final reviewService = context.read<ReviewService>();
        await reviewService.deleteReview(review.id);
        
        if (mounted) {
          _loadReviews();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa đánh giá thành công'),
              backgroundColor: kSuccessColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: kErrorColor,
            ),
          );
        }
      }
    }
  }
}

