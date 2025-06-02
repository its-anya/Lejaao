import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String? _selectedUserId;
  final List<Map<String, dynamic>> _selectedProducts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.fetchAllUsers();
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchProducts();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _addProduct(Product product) {
    // Check if product is already in the list
    final existingIndex = _selectedProducts.indexWhere(
      (item) => item['product'].id == product.id,
    );

    setState(() {
      if (existingIndex >= 0) {
        // Increment quantity if already in list
        _selectedProducts[existingIndex]['quantity']++;
      } else {
        // Add new product to list
        _selectedProducts.add({
          'product': product,
          'quantity': 1,
        });
      }
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeProduct(index);
      return;
    }
    
    setState(() {
      _selectedProducts[index]['quantity'] = quantity;
    });
  }

  double _calculateTotal() {
    return _selectedProducts.fold(0, (total, item) {
      return total + (item['product'].price * item['quantity']);
    });
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }
    
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderItems = _selectedProducts.map((item) {
        final product = item['product'] as Product;
        // Ensure productId is not empty
        if (product.id.isEmpty) {
          throw Exception('Product ID cannot be empty');
        }
        return OrderItem(
          productId: product.id,
          quantity: item['quantity'],
          product: product,
        );
      }).toList();

      final success = await Provider.of<AdminProvider>(context, listen: false)
          .createNewOrder(
        _selectedUserId!,
        _addressController.text,
        orderItems,
        _calculateTotal(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create order')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'Select Customer',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedUserId,
                      items: adminProvider.allUsers.isEmpty 
                          ? [const DropdownMenuItem(value: '', child: Text('No users available'))]
                          : adminProvider.allUsers
                              .map(
                                (user) => DropdownMenuItem(
                                  value: user.uid,
                                  child: Text(
                                    '${user.displayName} (${user.email})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedUserId = value as String?;
                          
                          // Pre-fill address if user has one
                          if (_selectedUserId != null) {
                            final user = adminProvider.getUserById(_selectedUserId!);
                            if (user != null && user.address.isNotEmpty) {
                              _addressController.text = user.address;
                            }
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a customer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter delivery address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showProductsDialog(context, productProvider.products);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _selectedProducts.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'No products added yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedProducts.length,
                            itemBuilder: (ctx, index) {
                              final item = _selectedProducts[index];
                              final product = item['product'] as Product;
                              final quantity = item['quantity'] as int;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(8),
                                  leading: product.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            product.imageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, error, _) => Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey.shade300,
                                              child: const Icon(Icons.image_not_supported),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.image),
                                        ),
                                  title: Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          _updateQuantity(index, quantity - 1);
                                        },
                                      ),
                                      Text(
                                        quantity.toString(),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          _updateQuantity(index, quantity + 1);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          _removeProduct(index);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_calculateTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitOrder,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        'Create Order',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showProductsDialog(BuildContext context, List<Product> products) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Products'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (ctx, index) {
              final product = products[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          product.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, error, _) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported, size: 20),
                          ),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, size: 20),
                      ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$${product.price.toStringAsFixed(2)}'),
                    Text(
                      'Category: ${product.category}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    _addProduct(product);
                    Navigator.of(ctx).pop();
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 