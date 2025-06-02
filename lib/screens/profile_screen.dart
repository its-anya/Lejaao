import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/order_provider.dart';
import '../providers/admin_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin/admin_dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() {
      _fetchUserData();
      _checkAdminStatus();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<UserProvider>(context, listen: false).fetchUserData();
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null && user.address.isNotEmpty) {
        _addressController.text = user.address;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      await Provider.of<AdminProvider>(context, listen: false).checkAdminStatus();
      setState(() {
        _isAdmin = Provider.of<AdminProvider>(context, listen: false).isAdmin;
      });
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> _updateAddress() async {
    if (_addressController.text.isNotEmpty) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateAddress(_addressController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address updated successfully')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log out. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (ctx, userProvider, _) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = userProvider.user;
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User profile
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Menu items
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _getMenuItems().length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final menuItem = _getMenuItems()[index];
                  IconData iconData;
                  Color iconColor = Colors.grey;

                  switch (index) {
                    case 0: // My Orders
                      iconData = Icons.shopping_bag;
                      break;
                    case 1: // Edit Profile
                      iconData = Icons.edit;
                      break;
                    case 2: // Privacy Policy
                      iconData = Icons.privacy_tip;
                      break;
                    case 3: // Help Center
                      iconData = Icons.help;
                      break;
                    case 4: // Logout
                      iconData = Icons.logout;
                      iconColor = Colors.red;
                      break;
                    default:
                      iconData = Icons.article;
                  }

                  return ListTile(
                    leading: Icon(iconData, color: iconColor),
                    title: Text(menuItem['title']),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: menuItem['onTap'],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMenuItems() {
    final menuItems = [
      {
        'title': 'My Orders',
        'icon': Icons.shopping_bag,
        'onTap': () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => const OrdersScreen(),
          );
        },
      },
      {
        'title': 'Edit Profile',
        'icon': Icons.edit,
        'onTap': () {
          _showUpdateAddressDialog();
        },
      },
      {
        'title': 'Privacy Policy',
        'icon': Icons.privacy_tip,
        'onTap': () {
          _showPrivacyPolicyDialog();
        },
      },
      {
        'title': 'Help Center',
        'icon': Icons.help,
        'onTap': () {
          _showHelpCenterDialog();
        },
      },
      {
        'title': 'Logout',
        'icon': Icons.logout,
        'onTap': () {
          _logout();
        },
      },
    ];

    // Add admin panel option if user is admin
    if (_isAdmin) {
      menuItems.insert(0, {
        'title': 'Admin Panel',
        'icon': Icons.admin_panel_settings,
        'onTap': () {
          Navigator.of(context).pushNamed(AdminDashboard.routeName);
        },
      });
    }

    return menuItems;
  }

  void _showUpdateAddressDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Address'),
        content: TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Delivery Address',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('UPDATE'),
            onPressed: () {
              _updateAddress();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This Privacy Policy describes how your personal information is collected, used, and shared when you visit or make a purchase from Lejaao.\n\n'
            'PERSONAL INFORMATION WE COLLECT\n\n'
            'When you visit the site, we automatically collect certain information about your device, including information about your web browser, IP address, time zone, and some of the cookies that are installed on your device.\n\n'
            'Additionally, as you browse the site, we collect information about the individual web pages or products that you view, what websites or search terms referred you to the site, and information about how you interact with the site.\n\n'
            'When you make a purchase or attempt to make a purchase through the site, we collect certain information from you, including your name, billing address, shipping address, payment information, email address, and phone number. We refer to this information as "Order Information".',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help Center'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FAQ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('Q: How do I track my order?'),
              Text('A: You can track your order in My Orders section.'),
              SizedBox(height: 12),
              Text('Q: How do I return a product?'),
              Text('A: Please contact our customer support within 7 days of delivery.'),
              SizedBox(height: 12),
              Text('Q: What payment methods do you accept?'),
              Text('A: We currently support Cash on Delivery (COD).'),
              SizedBox(height: 16),
              Text(
                'Contact Us',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('Email: support@lejaao.com'),
              Text('Phone: +91-1234567890'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh orders when the screen opens
    Future.delayed(Duration.zero, () {
      Provider.of<OrderProvider>(context, listen: false).fetchUserOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: Consumer<OrderProvider>(
        builder: (ctx, orderProvider, _) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = orderProvider.orders;
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Your order history will appear here'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (ctx, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ORDER #${order.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: order.status == 'Delivered'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: order.status == 'Delivered'
                                    ? Colors.green.shade900
                                    : Colors.orange.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(order.orderDate.toString().substring(0, 16)),
                      const SizedBox(height: 8),
                      Text(
                        '${order.products.length} item(s) - ₹${order.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Delivery Address:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        order.address,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 