import 'package:ecom_frontend/models/order.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/services/store_service.dart';
import 'package:ecom_frontend/screens/orders/order_detail_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StoreOrdersScreen extends StatefulWidget {
  static const String routeName = '/store-orders';

  const StoreOrdersScreen({super.key});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Order>> _ordersFuture;
  late TabController _tabController;
  String? _selectedStoreId;
  List<String> _storeIds = [];
  bool _isLoadingStores = true;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  final List<String> _tabs = [
    'Tất cả',
    'Chờ TT',
    'Đã TT',
    'Đang giao',
    'Hoàn thành',
  ];
  final List<String?> _tabFilters = [
    null,
    'pending',
    'paid',
    'shipped',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadStores();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoadingStores = true);
    try {
      final storeService = context.read<StoreService>();
      final stores = await storeService.getMyStores();
      if (mounted) {
        setState(() {
          _storeIds = stores.map((s) => s.id).toList();
          if (_storeIds.isNotEmpty && _selectedStoreId == null) {
            _selectedStoreId = _storeIds.first;
            _ordersFuture = _fetchStoreOrders(_selectedStoreId!);
          }
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStores = false;
        });
      }
    }
  }

  Future<List<Order>> _fetchStoreOrders(String storeId) async {
    final orderService = context.read<OrderService>();
    try {
      return await orderService.getOrdersByStore(storeId);
    } catch (e) {
      throw Exception('Lỗi tải đơn hàng: ${e.toString()}');
    }
  }

  Future<void> _refreshOrders() async {
    if (_selectedStoreId != null) {
      setState(() {
        _ordersFuture = _fetchStoreOrders(_selectedStoreId!);
      });
    }
  }

  List<Order> _filterOrders(List<Order> orders, String? status) {
    if (status == null) return orders;
    return orders.where((o) => o.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: kTextColor,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: kCardShadow,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.black87,
            ),
          ),
        ),
        title: const Text(
          'Đơn hàng cửa hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Store selector
              if (_storeIds.length > 1)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: kCardShadow,
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStoreId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _storeIds.map((id) {
                      return DropdownMenuItem(
                        value: id,
                        child: Text('Cửa hàng: ${id.substring(0, 8)}...'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStoreId = value;
                          _ordersFuture = _fetchStoreOrders(value);
                        });
                      }
                    },
                  ),
                ),
              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: kCardShadow,
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: kPrimaryColor,
                  unselectedLabelColor: kSecondaryTextColor,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                  ),
                  indicator: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoadingStores
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _storeIds.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store_outlined,
                        size: 64,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Chưa có cửa hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bạn cần tạo cửa hàng trước khi xem đơn hàng',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kSecondaryTextColor),
                    ),
                  ],
                ),
              ),
            )
          : _selectedStoreId == null
          ? const Center(child: Text('Vui lòng chọn cửa hàng'))
          : RefreshIndicator(
              onRefresh: _refreshOrders,
              color: kPrimaryColor,
              child: FutureBuilder<List<Order>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(
                              color: kPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Đang tải đơn hàng...',
                            style: TextStyle(color: kSecondaryTextColor),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: kErrorColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: kErrorColor,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Không thể tải đơn hàng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: kSecondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text("Thử lại"),
                              onPressed: _refreshOrders,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasData) {
                    final allOrders = snapshot.data!;

                    return TabBarView(
                      controller: _tabController,
                      children: _tabFilters.map((filter) {
                        final orders = _filterOrders(allOrders, filter);
                        return _buildOrderList(orders);
                      }).toList(),
                    );
                  }

                  return const Center(child: Text('Không có dữ liệu'));
                },
              ),
            ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: kPrimaryColor.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đơn hàng của cửa hàng sẽ xuất hiện ở đây',
              style: TextStyle(color: kSecondaryTextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kOffWhiteColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getOrderStatusIcon(order.status),
                    color: _getOrderStatusColor(order.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateFormatter.format(order.createdAt.toLocal()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: kSecondaryTextColor,
                        ),
                      ),
                      if (order.buyerName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Khách hàng: ${order.buyerName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: kSecondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getOrderStatusText(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: kOffWhiteColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child:
                        (order.firstItemImageUrl != null &&
                            order.firstItemImageUrl!.isNotEmpty)
                        ? Image.network(
                            order.firstItemImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: kSecondaryTextColor,
                            ),
                          )
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            color: kSecondaryTextColor,
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng thanh toán',
                            style: TextStyle(
                              color: kSecondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _currencyFormatter.format(order.total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: kOffWhiteColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderDetailScreen(orderId: order.id),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: kPrimaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOrderStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ thanh toán';
      case 'paid':
        return 'Đã thanh toán';
      case 'payment_failed':
        return 'Thanh toán lỗi';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      case 'delivery_confirmed':
        return 'Đã xác nhận';
      default:
        return status;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'pending':
        return kWarningColor;
      case 'paid':
        return kSuccessColor;
      case 'payment_failed':
        return kErrorColor;
      case 'processing':
        return kInfoColor;
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return kPrimaryColor;
      case 'cancelled':
        return kSecondaryTextColor;
      case 'delivery_confirmed':
        return kSuccessColor;
      default:
        return kSecondaryTextColor;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'paid':
        return Icons.check_circle_outline;
      case 'payment_failed':
        return Icons.error_outline;
      case 'processing':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'delivery_confirmed':
        return Icons.check_circle;
      default:
        return Icons.receipt_outlined;
    }
  }
}
