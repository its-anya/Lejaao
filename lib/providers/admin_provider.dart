import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isAdmin = false;
  bool _isLoading = false;
  List<OrderModel> _allOrders = [];
  List<UserModel> _allUsers = [];

  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  List<OrderModel> get allOrders => _allOrders;
  List<UserModel> get allUsers => _allUsers;

  Future<void> checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isAdmin = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _isAdmin = await _firestoreService.checkIfAdmin(user.uid);
    } catch (e) {
      print('Error checking admin status: $e');
      _isAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllOrders() async {
    if (!_isAdmin) return;

    _isLoading = true;
    notifyListeners();

    try {
      _allOrders = await _firestoreService.getAllOrders();
    } catch (e) {
      print('Error fetching all orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllUsers() async {
    if (!_isAdmin) return;

    _isLoading = true;
    notifyListeners();

    try {
      _allUsers = await _firestoreService.getAllUsers();
    } catch (e) {
      print('Error fetching all users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    if (!_isAdmin) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _firestoreService.updateOrderStatus(orderId, newStatus);
      if (result) {
        await fetchAllOrders(); // Refresh orders list
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNewOrder(
    String userId,
    String address,
    List<OrderItem> products,
    double totalPrice
  ) async {
    if (!_isAdmin) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final order = OrderModel(
        id: '',
        userId: userId,
        address: address,
        products: products,
        totalPrice: totalPrice,
        orderDate: DateTime.now(),
        status: 'Processing',
      );

      await _firestoreService.createOrder(order);
      await fetchAllOrders(); // Refresh orders list
      return true;
    } catch (e) {
      print('Error creating new order: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNewProduct(
    String name,
    String description,
    double price,
    String imageUrl,
    String category,
    double rating
  ) async {
    if (!_isAdmin) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final product = Product(
        id: '',
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        category: category,
        rating: rating,
      );

      return await _firestoreService.createProduct(product);
    } catch (e) {
      print('Error creating product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(
    String productId,
    String name,
    String description,
    double price,
    String imageUrl,
    String category,
    double rating
  ) async {
    if (!_isAdmin) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final data = {
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'rating': rating,
      };

      return await _firestoreService.updateProduct(productId, data);
    } catch (e) {
      print('Error updating product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (!_isAdmin) return false;

    _isLoading = true;
    notifyListeners();

    try {
      return await _firestoreService.deleteProduct(productId);
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  OrderModel? getOrderById(String orderId) {
    try {
      return _allOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  UserModel? getUserById(String userId) {
    try {
      return _allUsers.firstWhere((user) => user.uid == userId);
    } catch (e) {
      return null;
    }
  }
} 