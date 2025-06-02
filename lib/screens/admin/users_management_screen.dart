import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({Key? key}) : super(key: key);

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    await Provider.of<AdminProvider>(context, listen: false).fetchAllUsers();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }
    
    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      return user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  void _showUserDetailsDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              const SizedBox(height: 8),
              _buildDetailRow('Phone', user.phoneNumber.isEmpty 
                  ? 'Not provided' 
                  : user.phoneNumber),
              const SizedBox(height: 8),
              _buildDetailRow('Address', user.address.isEmpty 
                  ? 'Not provided' 
                  : user.address),
              const SizedBox(height: 8),
              _buildDetailRow('Account Created', 
                  user.createdAt != null 
                      ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                      : 'Unknown'),
              const SizedBox(height: 16),
              const Text(
                'Orders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              FutureBuilder(
                future: _getUserOrders(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  final orderCount = snapshot.data as int? ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Total Orders: $orderCount'),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label + ':',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Future<int> _getUserOrders(String userId) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final orders = adminProvider.allOrders;
    return orders.where((order) => order.userId == userId).length;
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final users = _getFilteredUsers(adminProvider.allUsers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Users',
                      hintText: 'Enter name or email',
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
                ),
                Expanded(
                  child: users.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (ctx, i) {
                            final user = users[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueGrey,
                                  child: Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email),
                                    if (user.phoneNumber.isNotEmpty)
                                      Text(
                                        'Phone: ${user.phoneNumber}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  _showUserDetailsDialog(context, user);
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