import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'orders_management_screen.dart';
import 'products_management_screen.dart';
import 'users_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() {
      _checkAdminStatus();
    });
  }

  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    await Provider.of<AdminProvider>(context, listen: false).checkAdminStatus();
    
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildDashboardItem(
      String title, IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!adminProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have admin privileges.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your store with the options below',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildDashboardItem(
                    'Orders',
                    Icons.shopping_bag,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const OrdersManagementScreen(),
                        ),
                      );
                    },
                    Colors.purple,
                  ),
                  _buildDashboardItem(
                    'Products',
                    Icons.inventory,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const ProductsManagementScreen(),
                        ),
                      );
                    },
                    Colors.green,
                  ),
                  _buildDashboardItem(
                    'Users',
                    Icons.people,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const UsersManagementScreen(),
                        ),
                      );
                    },
                    Colors.blue,
                  ),
                  _buildDashboardItem(
                    'Statistics',
                    Icons.bar_chart,
                    () {
                      // Navigator to statistics screen when implemented
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Statistics coming soon!'),
                        ),
                      );
                    },
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 