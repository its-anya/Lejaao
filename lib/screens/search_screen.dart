import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query, ProductProvider productProvider) async {
    if (query.length < 2) return;
    
    setState(() {
      _isSearching = true;
    });
    
    await productProvider.searchProducts(query);
    
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          productProvider.clearFilters();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _performSearch(value, productProvider),
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  productProvider.clearFilters();
                }
              },
            ),
          ),
          
          // Search button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _performSearch(_searchController.text, productProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('SEARCH'),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _buildSearchResults(productProvider.products),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'No products found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (ctx, index) {
        final product = products[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, error, _) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, size: 30),
                  ),
                ),
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  product.category,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(' ${product.rating}'),
                    const Spacer(),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                cartProvider.addItem(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to cart!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            },
          ),
        );
      },
    );
  }
} 