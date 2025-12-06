import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Overview")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder(
            future: _loadDashboardData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data as Map<String, dynamic>;

              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1,
                children: [
                  _statCard("Total Orders", "${data['totalOrders']}"),
                  _statCard("Revenue", "₹${data['revenue']}"),
                  _statCard("Active Users", "${data['users']}"),
                  _statCard("Menu Items", "${data['menuItems']}"),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 🔥 Fetch real data from Firestore
  Future<Map<String, dynamic>> _loadDashboardData() async {
    final ordersSnapshot =
    await FirebaseFirestore.instance.collection('orders').get();

    final usersSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    final productsSnapshot =
    await FirebaseFirestore.instance.collection('menuItems').get();

    // 🔢 Total Orders
    int totalOrders = ordersSnapshot.docs.length;

    // 💰 Total Revenue (sum of totalPrice field)
    double revenue = 0;
    for (var doc in ordersSnapshot.docs) {
      if (doc.data().containsKey('totalPrice')) {
        revenue += doc['totalPrice'] * 1.0;
      }
    }

    return {
      "totalOrders": totalOrders,
      "revenue": revenue,
      "users": usersSnapshot.docs.length,
      "menuItems": productsSnapshot.docs.length,
    };
  }

  Widget _statCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),

    );

  }
}
