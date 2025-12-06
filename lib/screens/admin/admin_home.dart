import 'package:flutter/material.dart';


class AdminHome extends StatelessWidget {
  const AdminHome({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _tile(context, 'Categories', Icons.category, '/admin/categories'),
            _tile(context, 'Menu Items', Icons.fastfood, '/admin/menu_items'),
            _tile(context, 'Orders', Icons.receipt_long, '/admin/orders'),
            _tile(context, 'Users', Icons.people, '/admin/users'),
          ],
        ),
      ),
    );
  }


  Widget _tile(BuildContext ctx, String title, IconData icon, String route) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(ctx).pushNamed(route),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}