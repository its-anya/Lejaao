import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateUserAddress(String uid, String address) async {
    await _firestore.collection('users').doc(uid).update({'address': address});
  }

  // Product operations
  Future<List<Product>> getProducts() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Product?> getProductById(String productId) async {
    try {
      // Validate productId is not empty
      if (productId.isEmpty) {
        print('Error: Attempted to fetch product with empty ID');
        return null;
      }
      
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists && doc.data() != null) {
        return Product.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final snapshot = await _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    query = query.toLowerCase();
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .where((product) => 
            product.name.toLowerCase().contains(query) || 
            product.description.toLowerCase().contains(query))
        .toList();
  }

  // Order operations
  Future<String> createOrder(OrderModel order) async {
    final docRef = await _firestore.collection('orders').add(order.toMap());
    return docRef.id;
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();
    final orders = snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
        .toList();
    
    // Sort by orderDate manually to avoid requiring composite index
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    
    // Load product details for each order
    await _populateOrderProducts(orders);
    
    return orders;
  }
  
  // Populate order items with product details
  Future<void> _populateOrderProducts(List<OrderModel> orders) async {
    for (var order in orders) {
      for (var item in order.products) {
        // Skip items with empty productId
        if (item.productId.isEmpty) {
          print('Warning: Order ${order.id} contains item with empty productId');
          continue;
        }
        
        final product = await getProductById(item.productId);
        if (product != null) {
          item.product = product;
        }
      }
    }
  }
  
  // Admin operations
  Future<bool> checkIfAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      return doc.exists && doc.data() != null && (doc.data()?['isAdmin'] == true);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
  
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .get();
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
          .toList();
      
      // Sort by orderDate manually to avoid requiring composite index
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      
      // Load product details for each order
      await _populateOrderProducts(orders);
      
      return orders;
    } catch (e) {
      print('Error fetching all orders: $e');
      return [];
    }
  }
  
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists && doc.data() != null) {
        final order = OrderModel.fromMap(doc.id, doc.data()!);
        
        // Load product details
        await _populateOrderProducts([order]);
        
        return order;
      }
      return null;
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }
  
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus
      });
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }
  
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }
  
  Future<bool> createProduct(Product product) async {
    try {
      await _firestore.collection('products').add(product.toMap());
      return true;
    } catch (e) {
      print('Error creating product: $e');
      return false;
    }
  }
  
  Future<bool> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('products').doc(productId).update(data);
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }
  
  Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }
} 