import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/product_model.dart';

class EditProductScreen extends StatefulWidget {
  final Product? product;

  const EditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _ratingController = TextEditingController();
  String _selectedCategory = 'Electronics';
  final List<String> _categories = ['Electronics', 'Clothing', 'Books', 'Home', 'Beauty', 'Sports', 'Other'];
  bool _isLoading = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _imageUrlController.text = widget.product!.imageUrl;
      _ratingController.text = widget.product!.rating.toString();
      _selectedCategory = widget.product!.category;
    } else {
      // Default values for new product
      _ratingController.text = '0.0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text;
      final description = _descriptionController.text;
      final price = double.parse(_priceController.text);
      final imageUrl = _imageUrlController.text.isEmpty 
          ? 'https://firebasestorage.googleapis.com/v0/b/lejaao.appspot.com/o/product_placeholder.jpg?alt=media' 
          : _imageUrlController.text;
      final rating = double.parse(_ratingController.text);

      bool success;
      if (_isEditing) {
        success = await Provider.of<AdminProvider>(context, listen: false)
            .updateProduct(
          widget.product!.id,
          name,
          description,
          price,
          imageUrl,
          _selectedCategory,
          rating,
        );
      } else {
        success = await Provider.of<AdminProvider>(context, listen: false)
            .createNewProduct(
          name,
          description,
          price,
          imageUrl,
          _selectedCategory,
          rating,
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Product updated successfully' : 'Product created successfully'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Failed to update product' : 'Failed to create product'),
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter product description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter price';
                        }
                        try {
                          final price = double.parse(value);
                          if (price <= 0) {
                            return 'Price must be greater than zero';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategory,
                      items: _categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedCategory = value as String;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        border: OutlineInputBorder(),
                        hintText: 'https://example.com/image.jpg',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          try {
                            final uri = Uri.parse(value);
                            if (!uri.isAbsolute) {
                              return 'Please enter a valid URL';
                            }
                          } catch (e) {
                            return 'Please enter a valid URL';
                          }
                        }
                        // URL is optional, will use placeholder if empty
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ratingController,
                            decoration: const InputDecoration(
                              labelText: 'Rating (0-5)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter rating';
                              }
                              try {
                                final rating = double.parse(value);
                                if (rating < 0 || rating > 5) {
                                  return 'Rating must be between 0 and 5';
                                }
                              } catch (e) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _imageUrlController.text.isNotEmpty
                              ? Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      _imageUrlController.text,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, error, _) => Container(
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: Icon(Icons.image_not_supported),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Center(
                                    child: Text('Image Preview'),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        _isEditing ? 'Update Product' : 'Create Product',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 