import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

enum OrderStatus { pending, preparing, delivered, cancelled, onTheWay, unknown }

OrderStatus parseStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'preparing':
      return OrderStatus.preparing;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'on the way':
      return OrderStatus.onTheWay;
    case 'pending':
      return OrderStatus.pending;
    default:
      return OrderStatus.unknown;
  }
}

class AppOrderItem {
  final String name;
  final String category;
  final double price;
  final int quantity;
  final String imageUrl;

  AppOrderItem({
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory AppOrderItem.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return AppOrderItem(
        name: 'Unnamed',
        category: 'N/A',
        price: 0.0,
        quantity: 1,
        imageUrl: '',
      );
    }
    final item = map['item'] as Map<String, dynamic>? ?? {};
    return AppOrderItem(
      name: item['name'] ?? 'Unnamed',
      category: item['category'] ?? 'N/A',
      price: (item['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      imageUrl: item['imageUrl'] ?? '',
    );
  }

  double get totalPrice => price * quantity;
}

class AppOrder {
  final String id;
  final DateTime orderDate;
  final double totalAmount;
  final OrderStatus status;
  final String deliveryAddress;
  final List<AppOrderItem> items;

  AppOrder({
    required this.id,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.items,
  });

  factory AppOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final itemList = (data['items'] as List<dynamic>? ?? [])
        .map((e) => AppOrderItem.fromMap(e as Map<String, dynamic>?))
        .toList();

    return AppOrder(
      id: data['id'] ?? doc.id,
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: parseStatus(data['status'] as String?),
      deliveryAddress: data['deliveryAddress'] ?? 'N/A',
      items: itemList,
    );
  }
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your order history.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No past orders yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text('Order something delicious from the menu.'),
                ],
              ),
            );
          }

          final orders =
          snapshot.data!.docs.map((doc) => AppOrder.fromFirestore(doc)).toList();

          return RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return OrderCard(order: orders[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final AppOrder order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16.0),
        title: Text(
          'Order ID: ${order.id.substring(0, 8)}...',
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate)}'),
            Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
            Row(
              children: [
                const Text('Status: '),
                _buildStatusChip(order.status),
              ],
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                ...order.items.map(
                      (item) => ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) =>
                        const Icon(Icons.broken_image),
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text("Category: ${item.category}\nPrice: ₹${item.price}"),
                    trailing: Text("Qty: ${item.quantity}"),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Delivery Address:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(order.deliveryAddress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildStatusChip(OrderStatus status) {
  Color chipColor;
  String statusText;

  switch (status) {
    case OrderStatus.pending:
      chipColor = Colors.orange;
      statusText = 'Pending';
      break;
    case OrderStatus.preparing:
      chipColor = Colors.blue;
      statusText = 'Preparing';
      break;
    case OrderStatus.onTheWay:
      chipColor = Colors.indigo;
      statusText = 'On the way';
      break;
    case OrderStatus.delivered:
      chipColor = Colors.green;
      statusText = 'Delivered';
      break;
    case OrderStatus.cancelled:
      chipColor = Colors.red;
      statusText = 'Cancelled';
      break;
    case OrderStatus.unknown:
      chipColor = Colors.grey;
      statusText = 'Unknown';
      break;
  }

  return Chip(
    label: Text(
      statusText,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    backgroundColor: chipColor,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );
}
