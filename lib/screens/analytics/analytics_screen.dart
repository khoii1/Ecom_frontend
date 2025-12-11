import 'package:ecom_frontend/models/store.dart';
import 'package:ecom_frontend/services/analytics_service.dart';
import 'package:ecom_frontend/services/store_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Store> _myStores = [];
  String? _selectedStoreId;
  Map<String, dynamic>? _analytics;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storeService = context.read<StoreService>();
      _myStores = await storeService.getMyStores();
      
      if (_myStores.isNotEmpty) {
        _selectedStoreId = _myStores.first.id;
        await _loadAnalytics();
      } else {
        setState(() {
          _error = 'Bạn chưa có cửa hàng nào';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải dữ liệu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnalytics() async {
    if (_selectedStoreId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analyticsService = context.read<AnalyticsService>();
      final analytics = await analyticsService.getStoreAnalytics(_selectedStoreId!);
      
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải thống kê: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích cửa hàng'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
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
                        onPressed: _loadInitialData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(kDefaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Selector
                        if (_myStores.length > 1) ...[
                          _buildStoreSelector(),
                          const SizedBox(height: kDefaultPadding),
                        ],

                        // Revenue Card
                        _buildRevenueCard(),
                        const SizedBox(height: kDefaultPadding),

                        // Stats Cards
                        _buildStatsCards(),
                        const SizedBox(height: kDefaultPadding),

                        // Top Products
                        _buildTopProducts(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStoreSelector() {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn cửa hàng:',
            style: kSubheadingStyle,
          ),
          const SizedBox(height: kSmallPadding),
          DropdownButtonFormField<String>(
            value: _selectedStoreId,
            decoration: kInputDecoration('Cửa hàng'),
            items: _myStores.map((store) {
              return DropdownMenuItem(
                value: store.id,
                child: Text(store.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStoreId = value;
              });
              _loadAnalytics();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    final revenue = _analytics?['revenue'] ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      decoration: BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Tổng doanh thu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currencyFormatter.format(revenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalOrders = _analytics?['total_orders'] ?? 0;
    final totalProducts = _analytics?['total_products'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.shopping_bag,
            title: 'Đơn hàng',
            value: totalOrders.toString(),
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(width: kDefaultPadding),
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2,
            title: 'Sản phẩm',
            value: totalProducts.toString(),
            color: kInfoColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: kSecondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final topProducts = _analytics?['topProducts'] ?? [];
    final reviews = _analytics?['reviews'] ?? {};
    final totalReviews = reviews['total'] ?? 0;
    final avgRating = reviews['average_rating'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews Stats
        Container(
          padding: const EdgeInsets.all(kDefaultPadding),
          decoration: kCardDecoration,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đánh giá trung bình',
                      style: TextStyle(
                        fontSize: 12,
                        color: kSecondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: kStarColor,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: kOffWhiteColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng đánh giá',
                      style: TextStyle(
                        fontSize: 12,
                        color: kSecondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalReviews.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kDefaultPadding),

        // Top Products
        const Text(
          'Top sản phẩm bán chạy',
          style: kSubheadingStyle,
        ),
        const SizedBox(height: kSmallPadding),
        if (topProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: kCardDecoration,
            child: const Center(
              child: Text(
                'Chưa có sản phẩm nào được bán',
                style: kBodyStyle,
              ),
            ),
          )
        else
          ...topProducts.map<Widget>((product) {
            return Container(
              margin: const EdgeInsets.only(bottom: kDefaultPadding),
              padding: const EdgeInsets.all(kDefaultPadding),
              decoration: kCardDecoration,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['image_url'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: kOffWhiteColor,
                          child: const Icon(Icons.image),
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
                          product['title'] ?? '',
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
                          _currencyFormatter.format(product['price'] ?? 0),
                          style: const TextStyle(
                            fontSize: 12,
                            color: kSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product['total_sold'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const Text(
                        'đã bán',
                        style: TextStyle(
                          fontSize: 12,
                          color: kSecondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}

