import 'package:flutter/material.dart';
import 'package:ecom_frontend/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Giỏ hàng"),
        actions: [
          if (cartProvider.cart != null && cartProvider.cart!.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                // TODO: Thêm xác nhận trước khi xóa
                context.read<CartProvider>().clearCart();
              },
            ),
        ],
      ),
      body: _buildBody(context, cartProvider),
      bottomNavigationBar: _buildBottomBar(context, cartProvider),
    );
  }

  Widget _buildBody(BuildContext context, CartProvider cartProvider) {
    if (cartProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      return const Center(child: Text("Giỏ hàng của bạn đang trống."));
    }

    final cart = cartProvider.cart!;

    return ListView.builder(
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return ListTile(
          leading: const Icon(Icons.shopping_bag_outlined), // Tạm thời
          title: Text(item.title),
          subtitle: Text("${item.price} VND x ${item.qty}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: item.qty > 1
                    ? () {
                        context.read<CartProvider>().updateItemQuantity(
                          item.id,
                          item.qty - 1,
                        );
                      }
                    : null, // Vô hiệu hóa nếu số lượng là 1
              ),
              Text(item.qty.toString()),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.read<CartProvider>().updateItemQuantity(
                    item.id,
                    item.qty + 1,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  context.read<CartProvider>().removeFromCart(item.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider) {
    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      return const SizedBox.shrink(); // Không hiển thị gì nếu giỏ hàng trống
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tổng cộng:", style: TextStyle(fontSize: 16)),
              Text(
                "${cartProvider.cart!.subtotal} VND",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Chuyển sang màn hình Thanh toán
              // Đây sẽ là nơi gọi API /orders (Phần 3)
              print("Chuyển đến thanh toán");
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text("Thanh toán", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
