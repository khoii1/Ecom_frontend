import 'package:flutter/material.dart';
import 'package:ecom_frontend/models/cart.dart';
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService;
  final AuthProvider? _authProvider;

  Cart? _cart;
  Cart? get cart => _cart;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CartProvider(this._cartService, this._authProvider) {
    // Khi AuthProvider thay đổi (ví dụ: đăng nhập), hãy fetch giỏ hàng
    if (_authProvider?.authStatus == AuthStatus.authenticated) {
      fetchCart();
    }
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      _cart = await _cartService.getMyCart();
    } catch (e) {
      // Có thể _cart = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addToCart(String productId, {int qty = 1}) async {
    try {
      await _cartService.addItem(productId, qty);
      // Sau khi thêm thành công, fetch lại toàn bộ giỏ hàng để đồng bộ
      await fetchCart();
    } catch (e) {
      // TODO: Hiển thị lỗi cho người dùng
    }
  }

  Future<void> updateItemQuantity(String cartItemId, int qty) async {
    try {
      await _cartService.updateItem(cartItemId, qty);
      await fetchCart(); // Fetch lại để cập nhật tổng tiền
    } catch (e) {
      // Error updating item quantity
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _cartService.removeItem(cartItemId);
      await fetchCart(); // Fetch lại
    } catch (e) {
      // Error adding item to cart
    }
  }

  Future<void> clearCart() async {
    try {
      await _cartService.clearCart();
      _cart = null; // Xóa giỏ hàng ở local
      notifyListeners();
    } catch (e) {
      // Error clearing cart
    }
  }
}
