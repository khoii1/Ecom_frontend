import 'package:ecom_frontend/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/models/order.dart';
import 'package:ecom_frontend/services/vnpay_service.dart';
import 'package:ecom_frontend/services/discount_service.dart';
import 'package:ecom_frontend/services/address_service.dart';
import 'package:ecom_frontend/services/wallet_service.dart';
import 'package:ecom_frontend/screens/payment/vnpay_webview_screen.dart';
import 'package:ecom_frontend/screens/discount/discount_vouchers_screen.dart';
import 'package:ecom_frontend/screens/address/address_list_screen.dart';
import 'package:ecom_frontend/l10n/app_localizations.dart';

class CartScreen extends StatefulWidget {
  CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  String? _selectedDiscountId;
  Map<String, dynamic>? _selectedDiscount;
  List<Map<String, dynamic>> _myDiscounts = [];
  bool _isLoadingDiscounts = false;
  bool _isExpandingDiscountForm = false;
  final TextEditingController _discountCodeController = TextEditingController();
  String _paymentMethod = 'cash'; // 'cash', 'vnpay', hoặc 'wallet'
  bool _isCheckingOut = false;
  double? _walletBalance;

  @override
  void initState() {
    super.initState();
    _loadMyDiscounts();
    _loadWalletBalance();
    // Refresh cart khi mở màn hình để đảm bảo dữ liệu mới nhất
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartProvider>().fetchCart();
      }
    });
  }

  Future<void> _loadWalletBalance() async {
    try {
      final walletService = context.read<WalletService>();
      final balanceData = await walletService.getBalance();
      if (mounted) {
        setState(() {
          _walletBalance = (balanceData['balance'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      // Silently fail - balance will remain null
    }
  }

  @override
  void dispose() {
    _discountCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadMyDiscounts() async {
    setState(() => _isLoadingDiscounts = true);
    try {
      final discountService = context.read<DiscountService>();
      final discounts = await discountService.getMyClaimedDiscounts();
      if (mounted) {
        setState(() {
          _myDiscounts = discounts
              .where((d) => d['is_active'] == true && d['is_expired'] == false)
              .toList();
          _isLoadingDiscounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDiscounts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: _buildAppBar(context, cartProvider),
          body: _buildBody(context, cartProvider),
          bottomNavigationBar: _buildBottomBar(context, cartProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CartProvider cartProvider,
  ) {
    return AppBar(
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
      title: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.cart,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          if (cartProvider.cart != null && cartProvider.cart!.items.isNotEmpty)
            Text(
              '${cartProvider.cart!.items.length} ${AppLocalizations.of(context)!.productsCount}',
              style: const TextStyle(
                fontSize: 12,
                color: kSecondaryTextColor,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (cartProvider.cart != null && cartProvider.cart!.items.isNotEmpty)
          GestureDetector(
            onTap: () => _confirmClearCart(context, cartProvider),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: kCardShadow,
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 20,
                color: kHeartColor,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmClearCart(
    BuildContext context,
    CartProvider cartProvider,
  ) async {
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kHeartColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline, color: kHeartColor),
              ),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.clearCart),
            ],
          ),
          content: Text(AppLocalizations.of(context)!.clearCartConfirm),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kHeartColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Xóa tất cả'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        await cartProvider.clearCart();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Đã xóa giỏ hàng'),
                ],
              ),
              backgroundColor: kSuccessColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: kErrorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildBody(BuildContext context, CartProvider cartProvider) {
    if (cartProvider.status == CartStatus.loading &&
        cartProvider.cart == null) {
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
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đang tải giỏ hàng...',
              style: TextStyle(color: kSecondaryTextColor),
            ),
          ],
        ),
      );
    }

    if (cartProvider.status == CartStatus.error && cartProvider.cart == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
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
                'Không thể tải giỏ hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cartProvider.errorMessage ?? 'Vui lòng thử lại',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kSecondaryTextColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
                onPressed: () => cartProvider.fetchCart(force: true),
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

    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor.withOpacity(0.1),
                    kAccentColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: kPrimaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.emptyCart,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.emptyCartDesc,
              style: TextStyle(fontSize: 14, color: kSecondaryTextColor),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: kButtonShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(AppLocalizations.of(context)!.exploreNow),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cart = cartProvider.cart!;

    return RefreshIndicator(
      onRefresh: () async {
        await cartProvider.fetchCart(force: true);
        await _loadMyDiscounts();
      },
      color: kPrimaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(kDefaultPadding),
        itemCount: cart.items.length,
        itemBuilder: (context, index) {
          final item = cart.items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCartItem(context, item, cartProvider),
          );
        },
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        try {
          await cartProvider.removeFromCart(item.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã xóa "${item.title}"'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e'), backgroundColor: kErrorColor),
            );
          }
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kHeartColor.withOpacity(0.8), kHeartColor],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Xóa', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(kMediumPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: kOffWhiteColor,
                borderRadius: BorderRadius.circular(kMediumBorderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kMediumBorderRadius),
                child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_not_supported_outlined,
                              color: kSecondaryTextColor,
                              size: 32,
                            ),
                      )
                    : const Icon(
                        Icons.image_not_supported_outlined,
                        size: 32,
                        color: kSecondaryTextColor,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: kTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        currencyFormatter.format(item.finalPrice ?? item.price),
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.discountPercentage != null &&
                          item.discountPercentage! > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kHeartColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${item.discountPercentage!.toInt()}%',
                            style: const TextStyle(
                              color: kHeartColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quantity Controls
                  _buildQuantityControls(context, item, cartProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    bool isUpdating = false;

    return StatefulBuilder(
      builder: (context, setQtyState) {
        return Container(
          decoration: BoxDecoration(
            color: kOffWhiteColor,
            borderRadius: BorderRadius.circular(kMediumBorderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQtyButton(
                icon: Icons.remove,
                enabled: item.qty > 1 && !isUpdating,
                onTap: () async {
                  setQtyState(() => isUpdating = true);
                  try {
                    await cartProvider.updateItemQuantity(
                      item.id,
                      item.qty - 1,
                    );
                  } finally {
                    if (context.mounted) setQtyState(() => isUpdating = false);
                  }
                },
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimaryColor,
                        ),
                      )
                    : Text(
                        '${item.qty}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kTextColor,
                        ),
                      ),
              ),
              _buildQtyButton(
                icon: Icons.add,
                enabled: !isUpdating,
                isPrimary: true,
                onTap: () async {
                  setQtyState(() => isUpdating = true);
                  try {
                    await cartProvider.updateItemQuantity(
                      item.id,
                      item.qty + 1,
                    );
                  } finally {
                    if (context.mounted) setQtyState(() => isUpdating = false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary && enabled ? kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(kSmallBorderRadius),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? (isPrimary ? Colors.white : kTextColor)
              : kSecondaryTextColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider) {
    final bool isEmpty =
        cartProvider.cart == null || cartProvider.cart!.items.isEmpty;
    final double subtotal = isEmpty ? 0.0 : cartProvider.cart!.subtotal;
    final double discountAmount =
        _selectedDiscount?['discount_amount']?.toDouble() ?? 0.0;
    final double total = subtotal - discountAmount;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -10),
            blurRadius: 30,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Discount Code Section
          if (!isEmpty) _buildDiscountSection(),

          // Payment Method Selection
          if (!isEmpty) ...[
            const SizedBox(height: 16),
            _buildPaymentMethodSection(),
            const SizedBox(height: 16),
          ],

          // Subtotal and Discount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.subtotal,
                          style: const TextStyle(
                            color: kSecondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormatter.format(subtotal),
                          style: const TextStyle(
                            fontSize: 14,
                            color: kSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    if (discountAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Giảm giá (${_selectedDiscount?['code'] ?? ''})',
                            style: const TextStyle(
                              color: kSuccessColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '-${currencyFormatter.format(discountAmount)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: kSuccessColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.total,
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            currencyFormatter.format(total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Checkout Button
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isEmpty ? null : kPrimaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isEmpty ? null : kButtonShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: (isEmpty || _isCheckingOut)
                        ? null
                        : () async {
                            // Kiểm tra địa chỉ trước khi checkout
                            try {
                              final addressService = context
                                  .read<AddressService>();
                              final addresses = await addressService
                                  .getMyAddresses();

                              if (addresses.isEmpty) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.addAddressFirst,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: kWarningColor,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'Thêm địa chỉ',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AddressListScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Lỗi kiểm tra địa chỉ: ${e.toString()}",
                                    ),
                                    backgroundColor: kErrorColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              return;
                            }

                            setState(() => _isCheckingOut = true);
                            Order? newOrder;

                            try {
                              final orderService = context.read<OrderService>();
                              newOrder = await orderService.createOrderFromCart(
                                discountId: _selectedDiscountId,
                                paymentMethod: _paymentMethod,
                              );

                              // Refresh cart ngay sau khi tạo order (cart items đã bị xóa ở backend)
                              if (context.mounted) {
                                await context.read<CartProvider>().fetchCart();
                              }

                              // Xử lý theo phương thức thanh toán
                              if (_paymentMethod == 'cash') {
                                // Thanh toán khi nhận hàng
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Đặt hàng thành công! Bạn sẽ thanh toán khi nhận hàng.',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                }
                              } else if (_paymentMethod == 'wallet') {
                                // Thanh toán bằng ví - đã được xử lý ở backend (order status = paid)
                                if (context.mounted) {
                                  await _loadWalletBalance(); // Refresh balance
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Đặt hàng và thanh toán thành công!',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                }
                              } else {
                                // Thanh toán VNPay
                                final vnpayService = context
                                    .read<VnpayService>();
                                final paymentUrl = await vnpayService
                                    .createPaymentUrl(
                                      orderId: newOrder.id,
                                      amount: newOrder.total,
                                    );

                                if (paymentUrl != null && context.mounted) {
                                  Navigator.of(context).pushNamed(
                                    VnpayWebViewScreen.routeName,
                                    arguments: {'paymentUrl': paymentUrl},
                                  );
                                } else {
                                  throw Exception(
                                    "Không lấy được URL thanh toán.",
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Lỗi: ${e.toString()}"),
                                    backgroundColor: kErrorColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isCheckingOut = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: kSecondaryTextColor.withOpacity(
                        0.3,
                      ),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isCheckingOut
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _paymentMethod == 'cash'
                                    ? AppLocalizations.of(context)!.placeOrder
                                    : AppLocalizations.of(context)!.payment,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _paymentMethod == 'cash'
                                    ? Icons.shopping_cart_outlined
                                    : Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedDiscount != null
              ? kPrimaryColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với nút toggle
          InkWell(
            onTap: () {
              setState(() {
                _isExpandingDiscountForm = !_isExpandingDiscountForm;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selectedDiscount != null
                              ? kPrimaryColor.withOpacity(0.1)
                              : kOffWhiteColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.local_offer_outlined,
                          size: 20,
                          color: _selectedDiscount != null
                              ? kPrimaryColor
                              : kSecondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.discountCode,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedDiscount != null
                                  ? kPrimaryColor
                                  : kTextColor,
                            ),
                          ),
                          if (_selectedDiscount != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _selectedDiscount!['discount_type'] ==
                                      'percentage'
                                  ? 'Giảm ${_selectedDiscount!['discount_value']}%'
                                  : 'Giảm ${currencyFormatter.format(_selectedDiscount!['discount_value'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: kPrimaryColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_selectedDiscount != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDiscountId = null;
                              _selectedDiscount = null;
                              _discountCodeController.clear();
                            });
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text(
                            'Bỏ',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: kSecondaryTextColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      Icon(
                        _isExpandingDiscountForm
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: kSecondaryTextColor,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable form
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isExpandingDiscountForm
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Input field để nhập mã
                        Container(
                          decoration: BoxDecoration(
                            color: kOffWhiteColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _discountCodeController,
                            decoration: InputDecoration(
                              hintText: 'Nhập mã giảm giá',
                              hintStyle: TextStyle(
                                color: kSecondaryTextColor.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.confirmation_number_outlined,
                                size: 20,
                                color: kSecondaryTextColor,
                              ),
                              suffixIcon:
                                  _discountCodeController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.check_circle),
                                      color: kPrimaryColor,
                                      onPressed: () {
                                        // TODO: Apply discount code
                                        _applyDiscountCode(
                                          _discountCodeController.text,
                                        );
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Dropdown cho mã đã nhận (nếu có)
                        if (_myDiscounts.isNotEmpty) ...[
                          Text(
                            'Hoặc chọn từ mã đã nhận:',
                            style: TextStyle(
                              fontSize: 13,
                              color: kSecondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedDiscountId,
                              decoration: InputDecoration(
                                hintText: 'Chọn mã giảm giá',
                                hintStyle: TextStyle(
                                  color: kSecondaryTextColor.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.wallet_outlined,
                                  size: 20,
                                  color: kSecondaryTextColor,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Không dùng mã'),
                                ),
                                ..._myDiscounts.map((discount) {
                                  final discountText =
                                      discount['discount_type'] == 'percentage'
                                      ? '${discount['code']} - Giảm ${discount['discount_value']}%'
                                      : '${discount['code']} - Giảm ${currencyFormatter.format(discount['discount_value'])}';
                                  return DropdownMenuItem<String>(
                                    value: discount['discount_id'],
                                    child: Text(
                                      discountText,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDiscountId = value;
                                  _selectedDiscount = value != null
                                      ? _myDiscounts.firstWhere(
                                          (d) => d['discount_id'] == value,
                                        )
                                      : null;
                                  _discountCodeController.clear();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Nút nhận mã mới
                        if (_isLoadingDiscounts)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DiscountVouchersScreen(),
                                ),
                              ).then((_) {
                                _loadMyDiscounts();
                              });
                            },
                            icon: const Icon(Icons.card_giftcard, size: 18),
                            label: const Text('Nhận mã giảm giá mới'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              side: BorderSide(
                                color: kPrimaryColor.withOpacity(0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _applyDiscountCode(String code) async {
    if (code.trim().isEmpty) return;

    final cartProvider = context.read<CartProvider>();
    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng trống'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    try {
      final discountService = context.read<DiscountService>();
      final subtotal = cartProvider.cart!.subtotal;

      // Lấy category_ids từ các sản phẩm trong cart
      // Note: CartItem chỉ có productId, không có product object
      // Có thể bỏ qua categoryIds hoặc lấy từ ProductService nếu cần
      // Tạm thời bỏ qua categoryIds để đơn giản
      final List<String>? categoryIds = null;

      // Validate discount code
      final result = await discountService.validateDiscount(
        code: code.trim().toUpperCase(),
        orderTotal: subtotal,
        categoryIds: categoryIds,
      );

      if (mounted) {
        setState(() {
          _selectedDiscountId = result['discount_id'];
          _selectedDiscount = {
            'discount_id': result['discount_id'],
            'code': result['code'],
            'discount_type': result['discount_type'],
            'discount_value': result['discount_value'],
            'discount_amount': result['discount_amount'],
          };
          _discountCodeController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Áp dụng mã giảm giá thành công',
            ),
            backgroundColor: kSuccessColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: kErrorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildPaymentMethodSection() {
    final cartProvider = context.watch<CartProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kOffWhiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_outlined,
                size: 20,
                color: kSecondaryTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.paymentMethod,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RadioListTile<String>(
            value: 'cash',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() => _paymentMethod = value!);
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Icon(Icons.money_outlined, size: 20, color: kTextColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.cashOnDelivery,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            activeColor: kPrimaryColor,
          ),
          RadioListTile<String>(
            value: 'wallet',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
                if (value == 'wallet') {
                  _loadWalletBalance(); // Refresh balance khi chọn ví
                }
              });
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 16,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.payByWallet,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_paymentMethod == 'wallet' &&
                          _walletBalance != null) ...[
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final cart = cartProvider.cart;
                            final cartSubtotal = cart?.subtotal ?? 0.0;
                            final discountAmount =
                                _selectedDiscount?['discount_amount']
                                    ?.toDouble() ??
                                0.0;
                            final cartTotal = cartSubtotal - discountAmount;
                            return Text(
                              'Số dư: ${currencyFormatter.format(_walletBalance)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _walletBalance! >= cartTotal
                                    ? kSuccessColor
                                    : kErrorColor,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            activeColor: kPrimaryColor,
          ),
          RadioListTile<String>(
            value: 'vnpay',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() => _paymentMethod = value!);
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.payment,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.payByVnpay,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            activeColor: kPrimaryColor,
          ),
          // Cảnh báo nếu không đủ tiền trong ví
          if (_paymentMethod == 'wallet' &&
              _walletBalance != null &&
              cartProvider.cart != null) ...[
            Builder(
              builder: (context) {
                final cartSubtotal = cartProvider.cart!.subtotal;
                final discountAmount =
                    _selectedDiscount?['discount_amount']?.toDouble() ?? 0.0;
                final cartTotal = cartSubtotal - discountAmount;
                if (_walletBalance! < cartTotal) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kErrorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: kErrorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: kErrorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.insufficientBalance,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kErrorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ],
      ),
    );
  }
}
