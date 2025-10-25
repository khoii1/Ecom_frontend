import 'package:ecom_frontend/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:ecom_frontend/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecom_frontend/services/stripe_service.dart';
// <<< THÊM IMPORT OrderService và Order >>>
import 'package:ecom_frontend/services/order_service.dart';
import 'package:ecom_frontend/models/order.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    // Dùng Consumer để chỉ rebuild khi CartProvider thay đổi
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Scaffold(
          appBar: AppBar(
            // backgroundColor: kPrimaryColor, // AppBar đã có màu nâu từ theme
            // foregroundColor: Colors.white,
            leading: const BackButton(
              /*color: Colors.white*/
            ), // Màu icon lấy từ theme
            title: const Text("Giỏ hàng của tôi"),
            actions: [
              if (cartProvider.cart != null &&
                  cartProvider.cart!.items.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_outlined /*, color: Colors.white*/,
                  ),
                  tooltip: "Xóa tất cả",
                  onPressed: () => _confirmClearCart(context, cartProvider),
                ),
            ],
          ),
          body: _buildBody(context, cartProvider),
          bottomNavigationBar: _buildBottomBar(context, cartProvider),
        );
      },
    );
  }

  // Hàm hiển thị dialog xác nhận xóa tất cả
  Future<void> _confirmClearCart(
    BuildContext context,
    CartProvider cartProvider,
  ) async {
    // Sử dụng context.mounted để kiểm tra an toàn hơn
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Dùng dialogContext riêng
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
            'Bạn có chắc muốn xóa tất cả sản phẩm khỏi giỏ hàng?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: kHeartColor),
              child: const Text('Xóa'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    // Kiểm tra mounted sau await
    if (confirmed == true && context.mounted) {
      try {
        await cartProvider.clearCart();
        // Kiểm tra mounted lần nữa trước khi dùng context
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa toàn bộ giỏ hàng'),
              backgroundColor: kPrimaryColor,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi xóa giỏ hàng: $e'),
              backgroundColor: kHeartColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildBody(BuildContext context, CartProvider cartProvider) {
    // Kiểm tra trạng thái từ CartProvider
    if (cartProvider.status == CartStatus.loading &&
        cartProvider.cart == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
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
              const Icon(Icons.error_outline, color: kHeartColor, size: 60),
              const SizedBox(height: kDefaultPadding),
              Text(
                "Lỗi tải giỏ hàng:\n${cartProvider.errorMessage ?? 'Unknown error'}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: kHeartColor),
              ),
              const SizedBox(height: kDefaultPadding),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
                onPressed: () => cartProvider.fetchCart(force: true),
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

    // Nếu không loading, không lỗi, nhưng giỏ hàng trống
    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: kDefaultPadding),
            const Text(
              "Giỏ hàng của bạn đang trống.",
              style: TextStyle(fontSize: 16, color: kSecondaryTextColor),
            ),
            const SizedBox(height: kDefaultPadding * 2),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text("Tiếp tục mua sắm"),
            ),
          ],
        ),
      );
    }

    // Nếu có giỏ hàng
    final cart = cartProvider.cart!;

    return RefreshIndicator(
      onRefresh: () => cartProvider.fetchCart(force: true),
      color: kPrimaryColor,
      child: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          // Hiển thị danh sách sản phẩm
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return _buildCartItem(context, item, cartProvider);
            },
            separatorBuilder: (context, index) => const Divider(
              height: kDefaultPadding * 1.5,
              thickness: 1,
              color: kOffWhiteColor,
            ), // Màu divider nhạt hơn
          ),
          const SizedBox(height: kDefaultPadding * 1.5),

          // Phần Promo Code
          const Text(
            "Mã giảm giá",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: "Nhập mã giảm giá"),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  /* TODO: Apply promo code */
                },
                child: const Text("Áp dụng"),
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding * 2), // Khoảng trống cuối
        ],
      ),
    );
  }

  // Widget hiển thị một item trong giỏ hàng
  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    return Dismissible(
      key: ValueKey(item.id), // Key quan trọng cho Dismissible
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        // Thêm async
        try {
          await cartProvider.removeFromCart(item.id);
          // Kiểm tra mounted trước khi dùng context
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã xóa "${item.title}"'),
                // action: SnackBarAction( // Tạm bỏ Hoàn tác cho đơn giản
                //    label: "Hoàn tác",
                //    onPressed: () => cartProvider.fetchCart(force: true),
                // ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi xóa sản phẩm: $e'),
                backgroundColor: kHeartColor,
              ),
            );
          }
        }
      },
      background: Container(
        color: kHeartColor.withOpacity(0.8),
        padding: const EdgeInsets.only(right: 20.0),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Ảnh Sản Phẩm ---
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: kOffWhiteColor,
                child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.error_outline,
                              color: kSecondaryTextColor,
                            ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(kPrimaryColor),
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.image_not_supported_outlined,
                        size: 40,
                        color: kSecondaryTextColor,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // --- Thông tin Sản Phẩm ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Hiển thị giá cuối (finalPrice) nếu có, kèm giá gốc gạch ngang
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencyFormatter.format(
                          item.finalPrice ?? item.price,
                        ), // Ưu tiên giá cuối
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.discountPercentage != null &&
                          item.discountPercentage! > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            currencyFormatter.format(item.price),
                            style: const TextStyle(
                              fontSize: 13,
                              color: kSecondaryTextColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // --- Nút tăng giảm số lượng ---
            _buildQuantityButtons(context, item, cartProvider),
          ],
        ),
      ),
    );
  }

  // Widget nút tăng giảm số lượng
  Widget _buildQuantityButtons(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    bool isUpdating = false; // State tạm để disable nút khi đang gọi API

    return StatefulBuilder(
      // Dùng StatefulBuilder để quản lý isUpdating
      builder: (context, setQtyState) {
        return Container(
          decoration: BoxDecoration(
            color: kOffWhiteColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút giảm
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.remove,
                    color: item.qty > 1 && !isUpdating
                        ? kTextColor
                        : kSecondaryTextColor.withOpacity(0.5),
                    size: 18,
                  ),
                  // Disable nút khi đang loading hoặc qty <= 0
                  onPressed: (isUpdating || item.qty <= 0)
                      ? null
                      : () async {
                          setQtyState(
                            () => isUpdating = true,
                          ); // Bắt đầu loading
                          try {
                            // Gọi API cập nhật (Backend tự xử lý xóa nếu qty-1 <= 0)
                            await cartProvider.updateItemQuantity(
                              item.id,
                              item.qty - 1,
                            );
                            // Fetch lại cart sẽ tự cập nhật UI
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: $e'),
                                  backgroundColor: kHeartColor,
                                ),
                              );
                            }
                          } finally {
                            // Đảm bảo dừng loading
                            if (context.mounted)
                              setQtyState(() => isUpdating = false);
                          }
                        },
                ),
              ),
              // Số lượng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        item.qty.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kTextColor,
                        ),
                      ),
              ),
              // Nút tăng
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.add,
                    color: !isUpdating
                        ? kTextColor
                        : kSecondaryTextColor.withOpacity(0.5),
                    size: 18,
                  ),
                  onPressed: isUpdating
                      ? null
                      : () async {
                          setQtyState(
                            () => isUpdating = true,
                          ); // Bắt đầu loading
                          try {
                            await cartProvider.updateItemQuantity(
                              item.id,
                              item.qty + 1,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: $e'),
                                  backgroundColor: kHeartColor,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted)
                              setQtyState(() => isUpdating = false);
                          }
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget thanh bottom bar tính tổng và nút checkout
  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider) {
    final bool isEmpty =
        cartProvider.cart == null || cartProvider.cart!.items.isEmpty;
    // Lấy subtotal đã tính từ backend
    final double subtotal = isEmpty ? 0.0 : cartProvider.cart!.subtotal;
    // --- QUAN TRỌNG: Logic lấy/tạo Order ID ---
    String? orderIdForPayment; // Sẽ lấy ID sau khi tạo Order thành công
    // -----------------------------------------

    // State tạm để quản lý loading cho nút checkout
    bool _isCheckingOut = false;

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding).copyWith(
        top: kDefaultPadding * 0.75,
        bottom: kDefaultPadding + MediaQuery.of(context).padding.bottom / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -4),
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tạm tính (${cartProvider.cart?.items.length ?? 0} sản phẩm)",
                style: const TextStyle(
                  fontSize: 16,
                  color: kSecondaryTextColor,
                ),
              ),
              Text(
                currencyFormatter.format(subtotal),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding),
          // Sử dụng StatefulBuilder để quản lý trạng thái loading của nút
          StatefulBuilder(
            builder: (context, setCheckoutState) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (isEmpty ||
                          _isCheckingOut) // Disable nếu rỗng hoặc đang checkout
                      ? null
                      : () async {
                          // --- Logic gọi thanh toán Stripe ---
                          setCheckoutState(
                            () => _isCheckingOut = true,
                          ); // Bắt đầu loading nút

                          final stripeService = context.read<StripeService>();
                          final cartProv = context
                              .read<CartProvider>(); // Không listen
                          final orderService = context
                              .read<OrderService>(); // Lấy OrderService

                          // 1. (QUAN TRỌNG) Tạo Order trên Backend trước khi thanh toán
                          print("--- Start Payment Process ---");
                          print("Step 1: Creating Order from Cart...");
                          Order? newOrder;
                          try {
                            // Gọi API backend (POST /orders)
                            newOrder = await orderService.createOrderFromCart();
                            orderIdForPayment = newOrder!.id; // Lấy ID thật
                            print(
                              "Order created successfully: ID = $orderIdForPayment, Total = ${newOrder!.total}",
                            );
                          } catch (e) {
                            print("Error creating order: $e");
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Lỗi tạo đơn hàng: ${e.toString()}",
                                  ),
                                  backgroundColor: kHeartColor,
                                ),
                              );
                            }
                            setCheckoutState(
                              () => _isCheckingOut = false,
                            ); // Dừng loading
                            return; // Dừng nếu không tạo được order
                          }
                          // --- KẾT THÚC Tạo Order ---

                          // 2. Kiểm tra lại orderIdForPayment
                          if (orderIdForPayment == null || newOrder == null) {
                            print(
                              "Error: Order ID or Order object is null after creation.",
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Không thể tạo mã đơn hàng."),
                                  backgroundColor: kHeartColor,
                                ),
                              );
                            }
                            setCheckoutState(() => _isCheckingOut = false);
                            return;
                          }

                          // 3. Gọi Stripe Payment Sheet
                          try {
                            print(
                              "Step 2: Presenting Stripe Payment Sheet for amount ${newOrder!.total}...",
                            );
                            await stripeService.presentPaymentSheet(
                              context,
                              amount:
                                  newOrder!.total, // Lấy total từ Order mới tạo
                              currency: 'vnd',
                              orderId: orderIdForPayment, // Truyền ID đơn hàng
                              merchantDisplayName: 'Khoi Ecom App',
                            );

                            // 4. Sheet đã đóng -> Kiểm tra trạng thái từ backend
                            print(
                              "Step 3: Payment sheet closed. Checking final order status from backend...",
                            );
                            // Sửa lỗi bằng cách tạo biến non-nullable cục bộ
                            final String finalOrderId = orderIdForPayment!;
                            String? finalStatus = await orderService
                                .checkOrderStatus(
                                  finalOrderId,
                                ); // Dùng OrderService

                            // 5. Xử lý kết quả cuối cùng
                            if (finalStatus == 'paid') {
                              print(
                                "Step 4: Backend confirmed payment success for order $finalOrderId.",
                              );
                              // Giỏ hàng đã được xóa ở backend khi tạo order, chỉ cần fetch lại
                              await cartProv.fetchCart(force: true);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Thanh toán thành công!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                ); // Quay về Home
                              }
                            } else {
                              print(
                                "Step 4: Backend check FAILED or payment not completed (status: ${finalStatus ?? 'lỗi'}).",
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Thanh toán chưa hoàn tất (trạng thái: ${finalStatus ?? 'lỗi'}). Đơn hàng ${newOrder!.code} đã được tạo.",
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            // Lỗi xảy ra trong quá trình presentPaymentSheet hoặc checkOrderStatus
                            print("Step 4: Payment process error: $e");
                            // TODO: Gọi API backend để hủy Order vừa tạo (newOrder.id) nếu thanh toán thất bại?
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Lỗi thanh toán: ${e.toString()}",
                                  ),
                                  backgroundColor: kHeartColor,
                                ),
                              );
                            }
                          } finally {
                            // Luôn dừng loading nút
                            if (context.mounted)
                              setCheckoutState(() => _isCheckingOut = false);
                            print("--- End Payment Process ---");
                          }
                          // --- Kết thúc logic Stripe ---
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isCheckingOut
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Tiến hành đặt hàng",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.lock_outline, size: 20),
                          ],
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
