import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchUserOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _firestoreService.getUserOrders(user.uid);
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(
    List<CartItem> cartItems, 
    String address, 
    double totalPrice
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Convert cart items to order items
      final orderItems = cartItems.map((item) => OrderItem(
        productId: item.product.id, 
        quantity: item.quantity
      )).toList();

      final order = OrderModel(
        id: '', // Will be assigned by Firestore
        userId: user.uid,
        address: address,
        products: orderItems,
        totalPrice: totalPrice,
        orderDate: DateTime.now(),
        status: 'Pending',
      );

      await _firestoreService.createOrder(order);
      
      // Refresh orders
      await fetchUserOrders();
      
      return true;
    } catch (e) {
      print('Error creating order: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 