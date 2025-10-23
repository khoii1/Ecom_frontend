import 'package:ecom_frontend/models/category.dart';
import 'package:ecom_frontend/services/category_service.dart';
import 'package:flutter/material.dart';

// Enum for loading states
enum CategoryStatus { initial, loading, loaded, error }

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  CategoryStatus _status = CategoryStatus.initial;
  CategoryStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CategoryProvider(this._categoryService) {
    // Fetch categories on initialization
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    _status = CategoryStatus.loading;
    _errorMessage = null; // Reset previous error
    notifyListeners(); // Notify UI about loading state

    try {
      _categories = await _categoryService.getCategories();
      _status = CategoryStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = CategoryStatus.error;
    } finally {
      notifyListeners(); // Notify UI about loaded state or error
    }
  }

  // Optional: Add refresh method if needed later
  Future<void> refreshCategories() async {
    await fetchCategories();
  }
}
