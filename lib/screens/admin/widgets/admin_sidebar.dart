import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.deepOrange.shade700,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            "Admin Panel",
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          _navItem(Icons.dashboard, "Dashboard", 0),
          _navItem(Icons.receipt_long, "Orders", 1),
          _navItem(Icons.restaurant_menu, "Products", 2),
          _navItem(Icons.people, "Users", 3),

          const Spacer(),
          _navItem(Icons.logout, "Logout", 99),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String title, int index) {
    return ListTile(
      selected: selectedIndex == index,
      selectedTileColor: Colors.white24,
      onTap: () => onItemSelected(index),
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }
}
