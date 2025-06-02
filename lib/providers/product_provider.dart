import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _selectedCategory = '';
  List<String> _categories = [];

  List<Product> get products => _filteredProducts.isEmpty && _selectedCategory.isEmpty 
      ? _products 
      : _filteredProducts;
      
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _firestoreService.getProducts();
      _extractCategories();
    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _extractCategories() {
    final categoriesSet = _products.map((product) => product.category).toSet();
    _categories = categoriesSet.toList();
  }

  Future<void> filterByCategory(String category) async {
    if (category.isEmpty) {
      _selectedCategory = '';
      _filteredProducts = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _selectedCategory = category;
    notifyListeners();

    try {
      _filteredProducts = await _firestoreService.getProductsByCategory(category);
    } catch (e) {
      print('Error filtering products: $e');
      _filteredProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _filteredProducts = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _filteredProducts = await _firestoreService.searchProducts(query);
    } catch (e) {
      print('Error searching products: $e');
      _filteredProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFilters() {
    _selectedCategory = '';
    _filteredProducts = [];
    notifyListeners();
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
} 