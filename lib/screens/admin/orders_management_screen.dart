import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/order_model.dart';
import 'order_detail_screen.dart';
import 'create_order_screen.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  bool _isLoading = false;
  String _filterStatus = 'All';
  final List<String> _statusOptions = ['All', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    
    await Provider.of<AdminProvider>(context, listen: false).fetchAllOrders();
    await Provider.of<AdminProvider>(context, listen: false).fetchAllUsers();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> orders) {
    if (_filterStatus == 'All') {
      return orders;
    }
    return orders.where((order) => order.status == _filterStatus).toList();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
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
    final orders = _getFilteredOrders(adminProvider.allOrders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const CreateOrderScreen(),
            ),
          ).then((_) => _loadOrders());
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Order',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text('Filter by status: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _statusOptions.contains(_filterStatus) ? _filterStatus : _statusOptions[0],
                        onChanged: (newValue) {
                          if (newValue == null) return;
                          setState(() {
                            _filterStatus = newValue;
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
                    ],
                  ),
                ),
                Expanded(
                  child: orders.isEmpty
                      ? const Center(
                          child: Text(
                            'No orders found',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (ctx, i) {
                            final order = orders[i];
                            final user = adminProvider.getUserById(order.userId);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order.id.substring(0, 8)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Customer: ${user?.displayName ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${order.products.length} items • \$${order.totalPrice.toStringAsFixed(2)}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${_formatDate(order.orderDate)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
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
                                    const SizedBox(height: 4),
                                    const Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => OrderDetailScreen(orderId: order.id),
                                    ),
                                  ).then((_) => _loadOrders());
                                },
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