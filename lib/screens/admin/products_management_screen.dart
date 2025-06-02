import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import 'edit_product_screen.dart';

class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductsManagementScreen> createState() => _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Electronics', 'Clothing', 'Books', 'Home', 'Beauty', 'Sports', 'Other'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    List<Product> filteredProducts = products;
    
    // Filter by category
    if (_filterCategory != 'All') {
      filteredProducts = filteredProducts.where(
        (product) => product.category == _filterCategory
      ).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredProducts = filteredProducts.where(
        (product) => product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query)
      ).toList();
    }
    
    return filteredProducts;
  }

  Future<void> _deleteProduct(BuildContext context, String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<AdminProvider>(context, listen: false)
          .deleteProduct(productId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        _loadProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete product')),
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
    final productProvider = Provider.of<ProductProvider>(context);
    final products = _getFilteredProducts(productProvider.products);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const EditProductScreen(),
            ),
          ).then((_) => _loadProducts());
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Product',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Products',
                          hintText: 'Enter name or description',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text('Category: '),
                            const SizedBox(width: 8),
                            ...List.generate(
                              _categories.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(_categories[index]),
                                  selected: _filterCategory == _categories[index],
                                  onSelected: (selected) {
                                    setState(() {
                                      _filterCategory = _categories[index];
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: products.isEmpty
                      ? const Center(
                          child: Text(
                            'No products found',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (ctx, i) {
                            final product = products[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: product.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          product.imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, error, _) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.image_not_supported),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image),
                                      ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      'Category: ${product.category}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: Colors.amber),
                                        Text(
                                          ' ${product.rating.toStringAsFixed(1)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => EditProductScreen(
                                              product: product,
                                            ),
                                          ),
                                        ).then((_) => _loadProducts());
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _deleteProduct(context, product.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 