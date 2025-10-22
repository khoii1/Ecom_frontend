class CartItem {
  final String id; // cart_item_id
  final String productId;
  final int qty;
  final String title;
  final double price;

  CartItem({
    required this.id,
    required this.productId,
    required this.qty,
    required this.title,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      qty: json['qty'],
      title: json['title'], // Lấy từ JOIN trong cart.service.js
      price: double.tryParse(json['price'].toString()) ?? 0.0, // Lấy từ JOIN
    );
  }
}
