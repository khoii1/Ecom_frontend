import 'package:ecom_frontend/models/product.dart';
import 'package:ecom_frontend/services/product_service.dart';
import 'package:flutter/material.dart';

// Enum for loading states
enum ProductStatus { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  final ProductService _productService;

  List<Product> _products = [];
  List<Product> get products => _products;

  ProductStatus _status = ProductStatus.initial;
  ProductStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProductProvider(this._productService) {
    // Tự động fetch sản phẩm lần đầu
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    _status = ProductStatus.loading;
    _errorMessage = null; // Reset lỗi cũ
    notifyListeners(); // Thông báo đang tải

    try {
      _products = await _productService.getProducts();
      _status = ProductStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ProductStatus.error;
    } finally {
      notifyListeners(); // Thông báo đã tải xong hoặc có lỗi
    }
  }

  // Hàm này sẽ được gọi từ AddProductScreen sau khi đăng thành công
  Future<void> refreshProducts() async {
    await fetchProducts();
  }
}
