import 'package:ecom_frontend/models/cart_item.dart';

class Cart {
  final String cartId;
  final List<CartItem> items;

  Cart({required this.cartId, required this.items});

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<CartItem> items = itemsList.map((i) => CartItem.fromJson(i)).toList();

    return Cart(cartId: json['cart_id'], items: items);
  }

  // Tính tổng tiền
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.qty));
  }
}
