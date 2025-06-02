import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;
  String? _selectedStatus;
  final List<String> _statusOptions = ['Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  Future<void> _updateOrderStatus() async {
    if (_selectedStatus == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await Provider.of<AdminProvider>(context, listen: false)
          .updateOrderStatus(widget.orderId, _selectedStatus!);

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order status')),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final order = adminProvider.getOrderById(widget.orderId);
    final user = order != null ? adminProvider.getUserById(order.userId) : null;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(
          child: Text('Order not found'),
        ),
      );
    }

    if (_selectedStatus == null || !_statusOptions.contains(_selectedStatus)) {
      _selectedStatus = order.status;
      if (!_statusOptions.contains(_selectedStatus)) {
        _selectedStatus = _statusOptions[0];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 8)}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order.id.substring(0, 8)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _getStatusColor(order.status),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  order.status,
                                  style: TextStyle(
                                    color: _getStatusColor(order.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Date: ${_formatDate(order.orderDate)}'),
                          const SizedBox(height: 8),
                          Text('Total: \$${order.totalPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Name: ${user?.displayName ?? 'Unknown'}'),
                          const SizedBox(height: 4),
                          Text('Email: ${user?.email ?? 'Unknown'}'),
                          const SizedBox(height: 4),
                          Text('Phone: ${user?.phoneNumber ?? 'Not provided'}'),
                          const SizedBox(height: 8),
                          const Text(
                            'Delivery Address:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(order.address),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.products.length,
                    itemBuilder: (ctx, i) {
                      final item = order.products[i];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: item.productImageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    item.productImageUrl,
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
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Category: ${item.productCategory}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '\$${item.productPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quantity: ${item.quantity}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Update Order Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedStatus,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                            items: _statusOptions
                                .map<DropdownMenuItem<String>>(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _updateOrderStatus,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text('Update Status'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 