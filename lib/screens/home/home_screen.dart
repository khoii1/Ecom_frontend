import 'package:flutter/material.dart';
import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/providers/cart_provider.dart'; // <-- THÊM MỚI
import 'package:ecom_frontend/screens/cart/cart_screen.dart'; // <-- THÊM MỚI
import 'package:ecom_frontend/services/api_client.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _productsFuture;
  late final ProductService _productService;

  @override
  void initState() {
    super.initState();
    final dio = context.read<ApiClient>().dio;
    _productService = ProductService(dio);
    _productsFuture = _productService.getProducts();

    // Tải giỏ hàng khi vào trang chủ (nếu chưa tải)
    // context.read<CartProvider>().fetchCart(); // Đã tự động gọi khi đăng nhập
  }

  @override
  Widget build(BuildContext context) {
    // Lấy cart provider để hiển thị số lượng
    final cartProvider = context.watch<CartProvider>(); // <-- THÊM MỚI

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang chủ"),
        actions: [
          // Icon giỏ hàng
          Stack(
            // <-- THÊM MỚI (Stack để hiển thị badge)
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cartProvider.cart != null &&
                  cartProvider.cart!.items.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.cart!.items.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error.toString()}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không có sản phẩm nào."));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: Icon(Icons.error),
                              ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                        ),
                  title: Text(product.title),
                  subtitle: Text("${product.price} VND"),
                  trailing: IconButton(
                    // <-- THÊM MỚI
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      context.read<CartProvider>().addToCart(product.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đã thêm ${product.title} vào giỏ"),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
