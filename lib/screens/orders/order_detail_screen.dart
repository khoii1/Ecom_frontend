import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/services/user_service.dart';
import 'package:ecom_frontend/models/order.dart';
import 'package:ecom_frontend/models/user.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/screens/product/product_detail_screen.dart';
import 'package:ecom_frontend/screens/returns/create_return_screen.dart';
import 'package:ecom_frontend/utils/constants.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderService = context.read<OrderService>();
      final order = await orderService.getOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ thanh toán';
      case 'paid':
        return 'Đã thanh toán';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.payment_outlined;
      case 'paid':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.settings_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.verified_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: kHeartColor),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: kSecondaryTextColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrderDetail,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : _order == null
          ? const Center(child: Text('Không tìm thấy đơn hàng'))
          : RefreshIndicator(
              onRefresh: _loadOrderDetail,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  if (_order!.tracking != null && _order!.tracking!.isNotEmpty)
                    _buildTrackingTimeline(),
                  if (_order!.tracking != null && _order!.tracking!.isNotEmpty)
                    const SizedBox(height: 16),
                  _buildOrderInfoCard(),
                  const SizedBox(height: 16),
                  _buildCustomerInfoCard(),
                  const SizedBox(height: 16),
                  if (_order!.items != null && _order!.items!.isNotEmpty)
                    _buildOrderItemsCard(),
                  if (_order!.items != null && _order!.items!.isNotEmpty)
                    const SizedBox(height: 16),
                  if (_order!.shippingAddress != null)
                    _buildShippingAddressCard(),
                  if (_order!.shippingAddress != null)
                    const SizedBox(height: 16),
                  _buildPriceSummaryCard(),
                  // Hiển thị hình ảnh xác nhận của shipper khi đã delivered (cho tất cả người dùng)
                  // Status cuối cùng sau khi shipper chụp ảnh xác nhận là "delivered"
                  if (_order!.status == 'delivered' &&
                      _order!.deliveryProofImage != null) ...[
                    const SizedBox(height: 16),
                    _buildDeliveryProofCard(),
                  ],
                  if (_order!.status == 'delivered' &&
                      !_order!.deliveryConfirmedByCustomer) ...[
                    const SizedBox(height: 16),
                    _buildDeliveryConfirmationCard(),
                  ],
                  // Return button - chỉ hiển thị cho customer khi đã delivered và confirmed
                  Builder(
                    builder: (context) {
                      final currentUser = context
                          .watch<AuthProvider>()
                          .currentUser;
                      if (_order!.status == 'delivered' &&
                          _order!.deliveryConfirmedByCustomer &&
                          currentUser?.role == 'USER') {
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildReturnButton(),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // Show actions for SELLER/ADMIN
                  Builder(
                    builder: (context) {
                      final currentUser = context
                          .watch<AuthProvider>()
                          .currentUser;
                      final isSellerOrAdmin =
                          currentUser?.role == 'SELLER' ||
                          currentUser?.role == 'ADMIN';

                      if (!isSellerOrAdmin) return const SizedBox.shrink();

                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          // Update status card - Ẩn khi đã delivered hoặc paid (không cần cập nhật nữa)
                          // Status cuối cùng sau khi shipper chụp ảnh xác nhận là "delivered"
                          if (_order!.status != 'paid' &&
                              _order!.status != 'delivered') ...[
                            _buildUpdateStatusCard(),
                            const SizedBox(height: 16),
                          ],
                          // Assign shipper card (if applicable)
                          if ((_order!.status == 'paid' ||
                                  _order!.status == 'processing') &&
                              _order!.shipperId == null) ...[
                            _buildAssignShipperCard(),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_order!.status);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(_order!.status),
                color: statusColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getStatusText(_order!.status),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã đơn: ${_order!.code}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (_order!.trackingNumber != null) ...[
              const SizedBox(height: 8),
              Text(
                'Mã vận đơn: ${_order!.trackingNumber}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final tracking = _order!.tracking!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Lịch sử vận chuyển',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...tracking.asMap().entries.map((entry) {
              final index = entry.key;
              final track = entry.value;
              final isLast = index == tracking.length - 1;
              final statusColor = _getStatusColor(track.status);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(
                          _getStatusIcon(track.status),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 60,
                          color: Colors.grey[300],
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(track.status),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                          if (track.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              track.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                          if (track.location != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  track.location!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _dateFormatter.format(track.trackedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đơn hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Mã đơn hàng', _order!.code),
            _buildInfoRow('Ngày đặt', _dateFormatter.format(_order!.createdAt)),
            if (_order!.shippingMethod != null)
              _buildInfoRow('Phương thức vận chuyển', _order!.shippingMethod!),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 12),
            ..._order!.items!.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailScreen(productId: item.productId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.productImageUrl ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productTitle,
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
                    'Số lượng: ${item.qty}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              _currencyFormatter.format(item.unitPrice * item.qty),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kBrownDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin khách hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 12),
            // Tên khách hàng
            Row(
              children: [
                Icon(Icons.person, color: kPrimaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _order!.buyerName ?? 'Chưa có thông tin',
                    style: const TextStyle(fontSize: 14, color: kTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Email
            Row(
              children: [
                Icon(Icons.email, color: kPrimaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _order!.buyerEmail ?? 'Chưa có thông tin',
                    style: const TextStyle(fontSize: 14, color: kTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Địa chỉ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: kPrimaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _order!.shippingAddress != null
                        ? _order!.shippingAddress!.fullAddress
                        : 'Chưa có địa chỉ',
                    style: TextStyle(
                      fontSize: 14,
                      color: _order!.shippingAddress != null
                          ? kTextColor
                          : Colors.grey[600],
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

  Widget _buildShippingAddressCard() {
    final address = _order!.shippingAddress!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Địa chỉ giao hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address.fullName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              address.phone,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              address.fullAddress,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildPriceRow('Tạm tính', _order!.subtotal),
            if (_order!.discountAmount != null && _order!.discountAmount! > 0)
              _buildPriceRow(
                'Giảm giá ${_order!.discountCode ?? ''}',
                -(_order!.discountAmount ?? 0),
                isDiscount: true,
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                Text(
                  _currencyFormatter.format(_order!.total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            isDiscount
                ? '-${_currencyFormatter.format(amount.abs())}'
                : _currencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.green : kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryConfirmationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: kPrimaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Đơn hàng đã được giao',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_order!.deliveryProofImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _order!.deliveryProofImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Bạn đã nhận được hàng chưa?',
              style: TextStyle(fontSize: 14, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConfirmDeliveryDialog(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Chưa nhận được'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmDeliveryDialog(true),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Đã nhận được'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildReturnButton() {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_return, color: kPrimaryColor, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Trả hàng / Đổi hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Bạn có thể yêu cầu trả hàng hoặc đổi hàng trong vòng 7 ngày kể từ ngày nhận hàng.',
            style: TextStyle(
              fontSize: 13,
              color: kSecondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateReturnScreen(order: _order!),
                ),
              );
              if (result == true && mounted) {
                await _loadOrderDetail();
              }
            },
            icon: const Icon(Icons.assignment_return),
            label: const Text('Yêu cầu trả hàng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmDeliveryDialog(bool confirmed) async {
    String? note;
    if (!confirmed) {
      note = await showDialog<String>(
        context: context,
        builder: (context) => _ConfirmDeliveryNoteDialog(),
      );
      if (note == null) return; // User cancelled
    }

    final orderService = context.read<OrderService>();
    try {
      await orderService.confirmDelivery(
        orderId: widget.orderId,
        confirmed: confirmed,
        note: note,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirmed
                  ? 'Cảm ơn bạn đã xác nhận! Bạn có thể để lại đánh giá cho sản phẩm.'
                  : 'Đã gửi thông báo đến shop. Shop sẽ liên hệ với bạn sớm nhất.',
            ),
            backgroundColor: confirmed ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        await _loadOrderDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUpdateStatusCard() {
    final statusColor = _getStatusColor(_order!.status);
    String? nextStatus;
    String? nextStatusText;
    IconData? nextStatusIcon;

    // Xác định trạng thái tiếp theo dựa trên trạng thái hiện tại
    switch (_order!.status) {
      case 'pending':
        // Kiểm tra payment method để xác định trạng thái tiếp theo
        if (_order!.paymentMethod == 'cash') {
          // Với cash: chuyển sang processing (xác nhận đơn hàng)
          // Vì chưa thu tiền, chỉ xác nhận đơn hàng để bắt đầu chuẩn bị
          nextStatus = 'processing';
          nextStatusText = 'Xác nhận đơn hàng';
          nextStatusIcon = Icons.inventory_2;
        } else {
          // Với VNPay: chuyển sang paid (xác nhận thanh toán)
          // VNPay thường tự động chuyển, nhưng seller có thể xác nhận thủ công nếu cần
          nextStatus = 'paid';
          nextStatusText = 'Xác nhận thanh toán';
          nextStatusIcon = Icons.check_circle;
        }
        break;
      case 'paid':
        nextStatus = 'processing';
        nextStatusText = 'Bắt đầu xử lý';
        nextStatusIcon = Icons.settings;
        break;
      case 'processing':
        // Nếu đã có shipper được assign, không cho seller cập nhật thủ công
        // Shipper sẽ tự động cập nhật khi pickup
        if (_order!.shipperId != null && _order!.shipperId!.isNotEmpty) {
          // Đã có shipper, không hiển thị nút cập nhật
          nextStatus = null;
          nextStatusText = null;
          nextStatusIcon = null;
        } else {
          // Chưa có shipper, seller có thể cập nhật thủ công
          nextStatus = 'shipped';
          nextStatusText = 'Đang giao hàng';
          nextStatusIcon = Icons.local_shipping;
        }
        break;
      case 'shipped':
        // Nếu đã có shipper, không cho seller cập nhật thủ công
        // Shipper sẽ tự động cập nhật khi deliver
        if (_order!.shipperId != null && _order!.shipperId!.isNotEmpty) {
          // Đã có shipper, không hiển thị nút cập nhật
          nextStatus = null;
          nextStatusText = null;
          nextStatusIcon = null;
        } else {
          // Chưa có shipper, seller có thể cập nhật thủ công
          nextStatus = 'delivered';
          nextStatusText = 'Hoàn thành giao hàng';
          nextStatusIcon = Icons.verified;
        }
        break;
      default:
        // Không có trạng thái tiếp theo
        break;
    }

    if (nextStatus == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.update_outlined, color: kPrimaryColor, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cập nhật trạng thái',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(_order!.status), color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trạng thái hiện tại:',
                          style: TextStyle(
                            fontSize: 12,
                            color: kSecondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStatusText(_order!.status),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  _showUpdateStatusDialog(nextStatus!, nextStatusText!),
              icon: Icon(nextStatusIcon),
              label: Text('Chuyển sang: $nextStatusText'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildDeliveryProofCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt_outlined, color: kPrimaryColor, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Hình ảnh xác nhận giao hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_order!.deliveryProofImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _order!.deliveryProofImage!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Không thể tải hình ảnh',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_order!.deliveryNote != null &&
                  _order!.deliveryNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _order!.deliveryNote!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignShipperCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: kPrimaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gán shipper',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAssignShipperDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Chọn shipper'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  Future<void> _showUpdateStatusDialog(
    String newStatus,
    String statusText,
  ) async {
    final orderService = context.read<OrderService>();

    String? trackingNumber;
    String? shippingMethod;
    String? description;
    String? location;

    // Nếu chuyển sang 'shipped', cần thông tin vận chuyển
    if (newStatus == 'shipped') {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (BuildContext context) =>
            _UpdateStatusDialog(statusText: statusText, requireTracking: true),
      );
      if (result == null) return; // User cancelled
      trackingNumber = result['trackingNumber'];
      shippingMethod = result['shippingMethod'];
      description = result['description'];
      location = result['location'];
    } else {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (BuildContext context) =>
            _UpdateStatusDialog(statusText: statusText, requireTracking: false),
      );
      if (result == null) return; // User cancelled
      description = result['description'];
    }

    try {
      await orderService.updateOrderStatus(
        orderId: widget.orderId,
        status: newStatus,
        description: description?.isEmpty == true ? null : description,
        location: location?.isEmpty == true ? null : location,
        trackingNumber: trackingNumber?.isEmpty == true ? null : trackingNumber,
        shippingMethod: shippingMethod?.isEmpty == true ? null : shippingMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái: $statusText'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadOrderDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAssignShipperDialog() async {
    final userService = context.read<UserService>();
    final orderService = context.read<OrderService>();

    try {
      final shippers = await userService.getUsersByRole('SHIPPER');

      if (!mounted) return;

      if (shippers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có shipper nào trong hệ thống'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final selectedShipper = await showDialog<User>(
        context: context,
        builder: (context) => _SelectShipperDialog(shippers: shippers),
      );

      if (selectedShipper != null && mounted) {
        try {
          await orderService.assignShipper(
            orderId: widget.orderId,
            shipperId: selectedShipper.id,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã gán shipper thành công'),
                backgroundColor: Colors.green,
              ),
            );
            await _loadOrderDetail();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Lỗi: ${e.toString().replaceFirst('Exception: ', '')}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SelectShipperDialog extends StatelessWidget {
  final List<User> shippers;

  const _SelectShipperDialog({required this.shippers});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn shipper'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: shippers.length,
          itemBuilder: (context, index) {
            final shipper = shippers[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(shipper.fullName),
              subtitle: Text(shipper.email),
              onTap: () => Navigator.pop(context, shipper),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}

class _UpdateStatusDialog extends StatefulWidget {
  final String statusText;
  final bool requireTracking;

  _UpdateStatusDialog({
    required this.statusText,
    required this.requireTracking,
  });

  @override
  State<_UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<_UpdateStatusDialog> {
  final _trackingNumberController = TextEditingController();
  final _shippingMethodController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _trackingNumberController.dispose();
    _shippingMethodController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cập nhật: ${widget.statusText}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.requireTracking) ...[
              TextField(
                controller: _trackingNumberController,
                decoration: const InputDecoration(
                  labelText: 'Mã vận đơn',
                  hintText: 'Nhập mã vận đơn (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _shippingMethodController,
                decoration: const InputDecoration(
                  labelText: 'Phương thức vận chuyển',
                  hintText: 'VD: Giao hàng nhanh, Vietnam Post...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Vị trí hiện tại',
                  hintText: 'VD: Hà Nội, TP.HCM...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Ghi chú về trạng thái (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'trackingNumber': _trackingNumberController.text.trim(),
              'shippingMethod': _shippingMethodController.text.trim(),
              'description': _descriptionController.text.trim(),
              'location': _locationController.text.trim(),
            });
          },
          child: const Text('Cập nhật'),
        ),
      ],
    );
  }
}

class _ConfirmDeliveryNoteDialog extends StatefulWidget {
  @override
  State<_ConfirmDeliveryNoteDialog> createState() =>
      _ConfirmDeliveryNoteDialogState();
}

class _ConfirmDeliveryNoteDialogState
    extends State<_ConfirmDeliveryNoteDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lý do chưa nhận được hàng'),
      content: TextField(
        controller: _noteController,
        decoration: const InputDecoration(
          hintText: 'Vui lòng mô tả lý do...',
          border: OutlineInputBorder(),
        ),
        maxLines: 4,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_noteController.text.trim().isNotEmpty) {
              Navigator.pop(context, _noteController.text.trim());
            }
          },
          child: const Text('Gửi'),
        ),
      ],
    );
  }
}
