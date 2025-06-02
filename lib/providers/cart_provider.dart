import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void addItem(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      // Increment quantity if product already in cart
      _items[existingIndex].quantity += 1;
    } else {
      // Add new product to cart
      _items.add(CartItem(product: product));
    }
    
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void decrementItem(String productId) {
    final existingIndex = _items.indexWhere((item) => item.product.id == productId);
    
    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity -= 1;
      } else {
        _items.removeAt(existingIndex);
      }
      
      notifyListeners();
    }
  }

  void clear() {
    _items = [];
    notifyListeners();
  }
} 