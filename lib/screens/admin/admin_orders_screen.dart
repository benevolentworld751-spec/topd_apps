import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. SHARED MODELS (Same as User App)
// ==========================================

enum OrderStatus { pending, preparing, delivered, cancelled, onTheWay, unknown }

OrderStatus parseStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'preparing':
      return OrderStatus.preparing;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'on the way': // Note: Lowercase matches your User App logic
      return OrderStatus.onTheWay;
    case 'pending':
      return OrderStatus.pending;
    default:
      return OrderStatus.unknown;
  }
}

// Helper to convert Enum back to String for Firestore updates
String statusToString(OrderStatus status) {
  switch (status) {
    case OrderStatus.preparing: return 'preparing';
    case OrderStatus.delivered: return 'delivered';
    case OrderStatus.cancelled: return 'cancelled';
    case OrderStatus.onTheWay: return 'on the way';
    case OrderStatus.pending: return 'pending';
    default: return 'pending';
  }
}

class AppOrderItem {
  final String name;
  final String category;
  final double price;
  final int quantity;
  final String image;

  AppOrderItem({
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.image,
  });

  factory AppOrderItem.fromMap(Map<String, dynamic>? map) {
    if (map == null) return AppOrderItem(name: 'Unnamed', category: 'N/A', price: 0.0, quantity: 1, image: '');
    final item = map['item'] as Map<String, dynamic>? ?? {};
    return AppOrderItem(
      name: item['name'] ?? 'Unnamed',
      category: item['category'] ?? 'N/A',
      price: (item['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      image: item['image'] ?? '',
    );
  }
}

class AppOrder {
  final String id;
  final String userId; // Added this so Admin knows who ordered
  final DateTime orderDate;
  final double totalAmount;
  final OrderStatus status;
  final String deliveryAddress;
  final List<AppOrderItem> items;
  final DocumentReference reference; // To update data easily

  AppOrder({
    required this.id,
    required this.userId,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.items,
    required this.reference,
  });

  factory AppOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final itemList = (data['items'] as List<dynamic>? ?? [])
        .map((e) => AppOrderItem.fromMap(e as Map<String, dynamic>?))
        .toList();

    return AppOrder(
      id: doc.id,
      userId: data['userId'] ?? 'Unknown User',
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: parseStatus(data['status'] as String?),
      deliveryAddress: data['deliveryAddress'] ?? 'N/A',
      items: itemList,
      reference: doc.reference,
    );
  }
}

// ==========================================
// 2. ADMIN ORDERS SCREEN
// ==========================================

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: StreamBuilder<QuerySnapshot>(
        // Get all orders, sorted by newest first
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          final orders = snapshot.data!.docs.map((doc) => AppOrder.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              return AdminOrderCard(order: orders[i]);
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. ADMIN ORDER CARD
// ==========================================

class AdminOrderCard extends StatelessWidget {
  final AppOrder order;
  const AdminOrderCard({super.key, required this.order});

  // Function to update status in Firestore
  Future<void> _updateStatus(BuildContext context, OrderStatus newStatus) async {
    try {
      await order.reference.update({
        'status': statusToString(newStatus),
      });
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order updated to ${statusToString(newStatus)}")),
        );
      }
    } catch (e) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating order: $e"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(12.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order: ...${order.id.substring(order.id.length - 6)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '₹${order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate)),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(order.status),
                const Spacer(),
                const Icon(Icons.touch_app, size: 16, color: Colors.grey),
                const Text(" Details", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          // --- Admin Controls ---
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Action:", style: TextStyle(fontWeight: FontWeight.bold)),
                PopupMenuButton<OrderStatus>(
                  onSelected: (newStatus) => _updateStatus(context, newStatus),
                  itemBuilder: (context) => [
                    _buildPopupItem(OrderStatus.preparing, Icons.kitchen, "Mark Preparing"),
                    _buildPopupItem(OrderStatus.onTheWay, Icons.delivery_dining, "Mark On Way"),
                    _buildPopupItem(OrderStatus.delivered, Icons.check_circle, "Mark Delivered"),
                    const PopupMenuDivider(),
                    _buildPopupItem(OrderStatus.cancelled, Icons.cancel, "Cancel Order", isDestructive: true),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Text("Update Status", style: TextStyle(color: Colors.white)),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // --- Order Details (Same as User) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Customer Info"),
                Text("User ID: ${order.userId}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text("Address: ${order.deliveryAddress}"),
                const SizedBox(height: 16),
                _buildSectionHeader("Items"),
                ...order.items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item.image,
                      width: 40, height: 40, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(width: 40, height: 40, color: Colors.grey[300], child: const Icon(Icons.fastfood, size: 20)),
                    ),
                  ),
                  title: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text("${item.quantity} x ₹${item.price}"),
                  trailing: Text("₹${(item.price * item.quantity).toStringAsFixed(2)}"),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<OrderStatus> _buildPopupItem(OrderStatus status, IconData icon, String text, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(icon, color: isDestructive ? Colors.red : Colors.black54),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: isDestructive ? Colors.red : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  // Reusing the User App's chip style
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(color: chipColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}