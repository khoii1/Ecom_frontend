import 'package:ecom_frontend/models/order.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/services/cart_service.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/screens/orders/order_detail_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/l10n/app_localizations.dart';

class MyOrdersScreen extends StatefulWidget {
  static const String routeName = '/my-orders';

  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late Future<List<Order>> _ordersFuture;
  late TabController _tabController;
  
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  final List<String?> _tabFilters = [null, 'pending', 'paid', 'shipped', 'delivered'];
  
  List<String> _getTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.allOrders,
      l10n.pending,
      l10n.paid,
      l10n.delivering,
      l10n.delivered,
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabFilters.length, vsync: this);
    _ordersFuture = _fetchMyOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Order>> _fetchMyOrders() async {
    final orderService = context.read<OrderService>();
    try {
      return await orderService.getMyOrders();
    } catch (e) {
      throw Exception('Lỗi tải đơn hàng: ${e.toString()}');
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _fetchMyOrders();
    });
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
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.myOrders,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: kCardShadow,
            ),
            child: Builder(
              builder: (context) => TabBar(
                controller: _tabController,
                isScrollable: true,
              labelColor: kPrimaryColor,
              unselectedLabelColor: kSecondaryTextColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              indicator: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: _getTabs(context).map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
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
                      child: const CircularProgressIndicator(color: kPrimaryColor),
                    ),
                    const SizedBox(height: 16),
                    const Text('Đang tải đơn hàng...', style: TextStyle(color: kSecondaryTextColor)),
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
                        child: const Icon(Icons.error_outline, color: kErrorColor, size: 48),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Không thể tải đơn hàng',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kSecondaryTextColor),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Thử lại"),
                        onPressed: _refreshOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              'Đơn hàng của bạn sẽ xuất hiện ở đây',
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
      margin: const EdgeInsets.only(bottom: kDefaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
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
                top: Radius.circular(kBorderRadius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(kMediumBorderRadius),
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getOrderStatusText(context, order.status),
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
                    borderRadius: BorderRadius.circular(kMediumBorderRadius),
                  ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kMediumBorderRadius),
                    child: (order.firstItemImageUrl != null && order.firstItemImageUrl!.isNotEmpty)
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
                          builder: (context) => OrderDetailScreen(orderId: order.id),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: kPrimaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kMediumBorderRadius),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
                if (order.status == 'delivered') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _reorder(context, order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kMediumBorderRadius),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Mua lại'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOrderStatusText(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'paid':
        return l10n.paid;
      case 'payment_failed':
        return l10n.paymentFailed;
      case 'processing':
        return l10n.pending;
      case 'shipped':
        return l10n.shipped;
      case 'delivered':
        return l10n.delivered;
      case 'cancelled':
        return l10n.cancelled;
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
      default:
        return Icons.receipt_outlined;
    }
  }

  Future<void> _reorder(BuildContext context, Order order) async {
    // Lấy order detail để có items
    try {
      final orderService = context.read<OrderService>();
      final orderDetail = await orderService.getOrderDetail(order.id);
      
      if (orderDetail.items == null || orderDetail.items!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đơn hàng không có sản phẩm'),
              backgroundColor: kErrorColor,
            ),
          );
        }
        return;
      }

      // Thêm từng item vào cart
      final cartService = context.read<CartService>();
      int successCount = 0;
      int failCount = 0;

      for (final item in orderDetail.items!) {
        try {
          await cartService.addItemToCart(item.productId, item.qty);
          successCount++;
        } catch (e) {
          failCount++;
          // Log error nhưng tiếp tục với các item khác
          print('Lỗi thêm sản phẩm ${item.productTitle}: $e');
        }
      }

      // Refresh cart
      if (context.mounted) {
        await context.read<CartProvider>().fetchCart();
        
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failCount > 0
                    ? 'Đã thêm $successCount sản phẩm vào giỏ hàng. $failCount sản phẩm không thể thêm.'
                    : 'Đã thêm $successCount sản phẩm vào giỏ hàng',
              ),
              backgroundColor: successCount > 0 ? kSuccessColor : kWarningColor,
              action: SnackBarAction(
                label: 'Xem giỏ hàng',
                textColor: Colors.white,
                onPressed: () {
                  // Pop orders screen để user có thể navigate đến cart từ bottom nav
                  Navigator.pop(context);
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể thêm sản phẩm vào giỏ hàng'),
              backgroundColor: kErrorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }
}
