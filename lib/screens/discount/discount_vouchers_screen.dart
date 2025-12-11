import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/services/discount_service.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:intl/intl.dart';

class DiscountVouchersScreen extends StatefulWidget {
  static const routeName = '/discount-vouchers';

  const DiscountVouchersScreen({super.key});

  @override
  State<DiscountVouchersScreen> createState() => _DiscountVouchersScreenState();
}

class _DiscountVouchersScreenState extends State<DiscountVouchersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableDiscounts = [];
  List<Map<String, dynamic>> _myDiscounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final discountService = context.read<DiscountService>();
      final available = await discountService.getAvailableDiscounts();
      final myDiscounts = await discountService.getMyClaimedDiscounts();
      
      if (mounted) {
        setState(() {
          _availableDiscounts = available;
          _myDiscounts = myDiscounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  Future<void> _claimDiscount(String discountId) async {
    try {
      final discountService = context.read<DiscountService>();
      await discountService.claimDiscount(discountId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nhận mã thành công!'),
            backgroundColor: kSuccessColor,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Mã khuyến mãi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Có thể nhận', icon: Icon(Icons.card_giftcard)),
            Tab(text: 'Mã của tôi', icon: Icon(Icons.wallet)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableTab(),
                _buildMyDiscountsTab(),
              ],
            ),
    );
  }

  Widget _buildAvailableTab() {
    if (_availableDiscounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: kSecondaryTextColor),
            const SizedBox(height: 16),
            Text(
              'Không có mã khuyến mãi nào',
              style: TextStyle(color: kSecondaryTextColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(kDefaultPadding),
        itemCount: _availableDiscounts.length,
        itemBuilder: (context, index) {
          final discount = _availableDiscounts[index];
          return _buildDiscountCard(
            discount,
            isClaimed: discount['is_claimed'] ?? false,
            canClaim: discount['can_claim'] ?? false,
            onClaim: () => _claimDiscount(discount['id']),
          );
        },
      ),
    );
  }

  Widget _buildMyDiscountsTab() {
    if (_myDiscounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wallet, size: 64, color: kSecondaryTextColor),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa nhận mã nào',
              style: TextStyle(color: kSecondaryTextColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(kDefaultPadding),
        itemCount: _myDiscounts.length,
        itemBuilder: (context, index) {
          final discount = _myDiscounts[index];
          return _buildMyDiscountCard(discount);
        },
      ),
    );
  }

  Widget _buildDiscountCard(
    Map<String, dynamic> discount, {
    required bool isClaimed,
    required bool canClaim,
    required VoidCallback onClaim,
  }) {
    final isExpired = discount['end_date'] != null &&
        DateTime.parse(discount['end_date']).isBefore(DateTime.now());
    final isActive = discount['is_active'] ?? false && !isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: kDefaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadius),
        gradient: isActive
            ? LinearGradient(
                colors: [kPrimaryColor, kPrimaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : kOffWhiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discount['code'] ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : kTextColor,
                        ),
                      ),
                      if (discount['description'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            discount['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isActive
                                  ? Colors.white70
                                  : kSecondaryTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Đã nhận',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  discount['discount_type'] == 'percentage'
                      ? Icons.percent
                      : Icons.attach_money,
                  color: isActive ? Colors.white : kPrimaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  discount['discount_type'] == 'percentage'
                      ? 'Giảm ${discount['discount_value']}%'
                      : 'Giảm ${NumberFormat.currency(symbol: '₫', decimalDigits: 0).format(discount['discount_value'])}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : kTextColor,
                  ),
                ),
              ],
            ),
            if (discount['min_order_value'] != null &&
                discount['min_order_value'] > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Đơn tối thiểu: ${NumberFormat.currency(symbol: '₫', decimalDigits: 0).format(discount['min_order_value'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.white70 : kSecondaryTextColor,
                  ),
                ),
              ),
            if (discount['end_date'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'HSD: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(discount['end_date']))}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.white70 : kSecondaryTextColor,
                  ),
                ),
              ),
            if (canClaim && !isClaimed)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isActive ? onClaim : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Nhận mã',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyDiscountCard(Map<String, dynamic> discount) {
    final isExpired = discount['is_expired'] ?? false;
    final isActive = discount['is_active'] ?? false && !isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: kDefaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadius),
        color: isActive ? kCardColor : kOffWhiteColor,
        border: Border.all(
          color: isActive ? kPrimaryColor : kSecondaryTextColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    discount['code'] ?? '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isActive ? kTextColor : kSecondaryTextColor,
                    ),
                  ),
                ),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kErrorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hết hạn',
                      style: TextStyle(
                        color: kErrorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kSuccessColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Có thể dùng',
                      style: TextStyle(
                        color: kSuccessColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (discount['description'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  discount['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: kSecondaryTextColor,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  discount['discount_type'] == 'percentage'
                      ? Icons.percent
                      : Icons.attach_money,
                  color: isActive ? kPrimaryColor : kSecondaryTextColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  discount['discount_type'] == 'percentage'
                      ? 'Giảm ${discount['discount_value']}%'
                      : 'Giảm ${NumberFormat.currency(symbol: '₫', decimalDigits: 0).format(discount['discount_value'])}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActive ? kPrimaryColor : kSecondaryTextColor,
                  ),
                ),
              ],
            ),
            if (discount['end_date'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'HSD: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(discount['end_date']))}',
                  style: TextStyle(
                    fontSize: 12,
                    color: kSecondaryTextColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

