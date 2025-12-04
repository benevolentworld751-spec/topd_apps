import 'package:flutter/material.dart';
import 'admin_home.dart';
import 'admin_orders.dart';
import 'admin_products.dart';
import 'admin_users.dart';
import 'admin_reviews.dart'; // <-- import Reviews page

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    AdminHome(),
    AdminOrders(),
    AdminProducts(),
    AdminUsers(),
    AdminReviewsScreen(), // <-- add Reviews page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _sideMenu(),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }

  // ---------------- LEFT MENU ----------------
  Widget _sideMenu() {
    return Container(
      width: 230,
      color: Colors.deepOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Admin Panel",
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          _menuItem(Icons.dashboard, "Dashboard", 0),
          _menuItem(Icons.list_alt, "Orders", 1),
          _menuItem(Icons.fastfood, "Products", 2),
          _menuItem(Icons.people, "Users", 3),
          _menuItem(Icons.star, "Reviews", 4), // <-- Reviews menu item

          const Spacer(),
          _menuItem(Icons.logout, "Logout", 99, isLogout: true),
        ],
      ),
    );
  }

  // ---------------- MENU ITEM ----------------
  Widget _menuItem(
      IconData icon,
      String title,
      int index, {
        bool isLogout = false,
      }) {
    bool isSelected = selectedIndex == index;

    return InkWell(
      onTap: () {
        if (isLogout) {
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }

        setState(() => selectedIndex = index);
      },
      child: Container(
        color: isSelected ? Colors.white.withOpacity(0.18) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            )
          ],
        ),
      ),
    );
  }
}
