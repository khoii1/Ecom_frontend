import 'package:flutter/material.dart';
// SỬA: Thêm import scheduler
import 'package:flutter/scheduler.dart';
import 'package:ecom_frontend/models/cart.dart';
import 'package:ecom_frontend/models/cart_item.dart'; // Import CartItem
import 'package:ecom_frontend/providers/auth_provider.dart';
import 'package:ecom_frontend/services/cart_service.dart';

// Enum để quản lý trạng thái tải dữ liệu rõ ràng hơn
enum CartStatus { initial, loading, loaded, error }

class CartProvider extends ChangeNotifier {
  final CartService _cartService;
  final AuthProvider? _authProvider; // Vẫn giữ để lắng nghe thay đổi auth

  Cart? _cart;
  Cart? get cart => _cart;

  CartStatus _status = CartStatus.initial;
  CartStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Constructor nhận CartService và AuthProvider (tùy chọn)
  CartProvider(this._cartService, this._authProvider) {
    // Lắng nghe sự thay đổi trạng thái đăng nhập từ AuthProvider
    _authProvider?.addListener(_onAuthChanged);
    // Fetch giỏ hàng ngay nếu đã đăng nhập
    _onAuthChanged();
  }

  // Hàm được gọi khi trạng thái đăng nhập thay đổi
  void _onAuthChanged() {
    if (_authProvider?.authStatus == AuthStatus.authenticated) {
      // Chỉ fetch nếu đang ở trạng thái initial hoặc sau khi đăng xuất/đăng nhập lại
      if (_status == CartStatus.initial || _cart == null) {
        print("User authenticated, fetching cart...");
        fetchCart();
      }
    } else {
      // Nếu đăng xuất, xóa giỏ hàng local
      print("User logged out, clearing local cart.");
      _cart = null;
      _status = CartStatus.initial;
      _errorMessage = null;
      notifyListeners(); // Thông báo UI để xóa giỏ hàng
    }
  }

  // Hàm fetch giỏ hàng chính
  Future<void> fetchCart({bool force = false}) async {
    // Chỉ fetch nếu chưa load, hoặc bắt buộc (force=true), hoặc đang lỗi
    if (!force &&
        (_status == CartStatus.loading || _status == CartStatus.loaded)) {
      print("Skipping fetchCart (status: $_status, force: $force)");
      return;
    }

    _status = CartStatus.loading;
    _errorMessage = null; // Xóa lỗi cũ
    // Gọi notifyListeners ngay lập tức để UI biết đang loading
    // Không cần addPostFrameCallback ở đây vì nó ở đầu hàm async
    notifyListeners();

    try {
      // Kiểm tra lại đăng nhập trước khi gọi API
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Người dùng chưa đăng nhập.");
      }
      _cart = await _cartService.getMyCart();
      _status = CartStatus.loaded;
      print("Cart fetched successfully: ${_cart?.items.length ?? 0} items");
    } catch (e) {
      print("Error fetching cart: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      _cart = null; // Xóa cart cũ nếu có lỗi
    } finally {
      // Luôn dùng addPostFrameCallback để gọi notifyListeners an toàn
      // Đảm bảo gọi sau khi frame đã build xong, tránh lỗi
      if (mounted) {
        // Kiểm tra mounted trước khi gọi addPostFrameCallback
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Kiểm tra mounted lần nữa bên trong callback
            notifyListeners();
          }
        });
      }
    }
  }

  // Thêm sản phẩm vào giỏ
  Future<void> addToCart(String productId, {int qty = 1}) async {
    print("Attempting to add product $productId to cart...");
    try {
      // Kiểm tra đăng nhập
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Vui lòng đăng nhập để thêm vào giỏ hàng.");
      }
      await _cartService.addItemToCart(productId, qty);
      print("Add to cart successful, refreshing cart...");
      await fetchCart(force: true); // Bắt buộc fetch lại
    } catch (e) {
      print("Error adding to cart: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
      throw e;
    }
  }

  // Cập nhật số lượng
  Future<void> updateItemQuantity(String cartItemId, int qty) async {
    print("Attempting to update item $cartItemId quantity to $qty...");
    try {
      // Kiểm tra đăng nhập
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Vui lòng đăng nhập để cập nhật giỏ hàng.");
      }
      if (qty <= 0) {
        print("Quantity is <= 0, removing item instead.");
        await removeFromCart(cartItemId);
        return;
      }
      await _cartService.updateCartItem(cartItemId, qty);
      print("Update quantity successful, refreshing cart...");
      await fetchCart(force: true);
    } catch (e) {
      print("Error updating item quantity: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
      throw e;
    }
  }

  // Xóa item khỏi giỏ
  Future<void> removeFromCart(String cartItemId) async {
    print("Attempting to remove item $cartItemId from cart...");
    try {
      // Kiểm tra đăng nhập
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Vui lòng đăng nhập để xóa sản phẩm khỏi giỏ hàng.");
      }
      await _cartService.removeCartItem(cartItemId);
      print("Remove item successful, refreshing cart...");
      await fetchCart(force: true);
    } catch (e) {
      print("Error removing item from cart: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
      throw e;
    }
  }

  // Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    print("Attempting to clear cart...");
    try {
      // Kiểm tra đăng nhập
      if (_authProvider?.authStatus != AuthStatus.authenticated) {
        throw Exception("Vui lòng đăng nhập để xóa giỏ hàng.");
      }
      await _cartService.clearCart();
      // SỬA: Thêm subtotal: 0.0 vào constructor Cart
      _cart = Cart(
        cartId: _cart?.cartId ?? '',
        items: [],
        subtotal: 0.0,
      ); // Tạo cart rỗng
      // --- KẾT THÚC SỬA ---
      _status = CartStatus.loaded; // Trạng thái đã load (nhưng rỗng)
      _errorMessage = null;
      print("Cart cleared successfully.");
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
    } catch (e) {
      print("Error clearing cart: $e");
      _errorMessage = e.toString();
      _status = CartStatus.error;
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) notifyListeners();
        });
      }
      throw e;
    }
  }

  // --- THÊM MỚI: Biến kiểm tra mounted ---
  bool _mounted = true;
  bool get mounted => _mounted;
  // --- KẾT THÚC THÊM MỚI ---

  // Dọn dẹp listener và cập nhật mounted khi Provider bị dispose
  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    _mounted = false; // <<< THÊM DÒNG NÀY
    super.dispose();
  }
}
