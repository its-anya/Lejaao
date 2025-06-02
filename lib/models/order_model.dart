import '../models/product_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final String address;
  final List<OrderItem> products;
  final double totalPrice;
  final DateTime orderDate;
  final String status;

  OrderModel({
    required this.id,
    required this.userId,
    required this.address,
    required this.products,
    required this.totalPrice,
    required this.orderDate,
    required this.status,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    List<OrderItem> productsList = [];
    if (map['products'] != null) {
      final products = map['products'] as List;
      productsList = products.map((item) => OrderItem.fromMap(item)).toList();
    }

    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      address: map['address'] ?? '',
      products: productsList,
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      orderDate: map['orderDate'] != null 
        ? (map['orderDate'] as dynamic).toDate() 
        : DateTime.now(),
      status: map['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'address': address,
      'products': products.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'orderDate': orderDate,
      'status': status,
    };
  }
}

class OrderItem {
  final String productId;
  final int quantity;
  Product? _product; // Internal cached product

  OrderItem({
    required this.productId,
    required this.quantity,
    Product? product,
  }) : _product = product;

  // Getter for product with null check
  Product? get product => _product;
  
  // Safe getter methods for product properties
  String get productName => _product?.name ?? 'Unknown Product';
  String get productCategory => _product?.category ?? 'Unknown Category';
  double get productPrice => _product?.price ?? 0.0;
  String get productImageUrl => _product?.imageUrl ?? '';
  
  // Setter for product
  set product(Product? value) {
    _product = value;
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    // Check for both "productId" and "productid" (lowercase) variations
    final productId = map['productId'] ?? map['productid'] ?? '';
    
    // Skip items with empty productId
    if (productId.isEmpty) {
      print('Warning: Encountered OrderItem with empty productId in map: $map');
    }
    
    return OrderItem(
      productId: productId,
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
} 