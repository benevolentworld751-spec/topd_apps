import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum OrderStatus { pending, preparing, onTheWay, delivered, cancelled }

OrderStatus parseStatus(String status) {
  switch (status.toLowerCase()) {
    case 'preparing':
      return OrderStatus.preparing;
    case 'on the way':
      return OrderStatus.onTheWay;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'pending':
    default:
      return OrderStatus.pending;
  }
}

class AdminOrders extends StatelessWidget {
  const AdminOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Orders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders yet"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final data = orderDoc.data() as Map<String, dynamic>;

              final orderId = data['id'] ?? orderDoc.id;
              final statusString = data['status'] ?? "pending";
              final status = parseStatus(statusString);
              final deliveryAddress = data['deliveryAddress'] ?? "N/A";
              final totalAmount = (data['totalAmount'] ?? 0).toDouble();
              final orderDate = data['orderDate'] != null
                  ? (data['orderDate'] as Timestamp).toDate()
                  : DateTime.now();
              final formattedDate =
              DateFormat('dd MMM yyyy, hh:mm a').format(orderDate);

              final items = (data['items'] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>();

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                child: ExpansionTile(
                  title: Text(
                    "Order ID: ${orderId.substring(0, 8)}...",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Delivery: $deliveryAddress"),
                      Text("Amount: ₹$totalAmount"),
                      Row(
                        children: [
                          const Text("Status: "),
                          _buildStatusChip(status),
                        ],
                      ),
                      Text("Date: $formattedDate"),
                    ],
                  ),
                  children: [
                    const Divider(),
                    ...items.map((e) {
                      final item = e['item'] as Map<String, dynamic>? ?? {};
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['imageUrl'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) =>
                            const Icon(Icons.broken_image),
                          ),
                        ),
                        title: Text(item['name'] ?? 'Unnamed'),
                        subtitle: Text(
                          "Category: ${item['category'] ?? 'N/A'}\nPrice: ₹${item['price'] ?? 0}",
                        ),
                        trailing: Text("Qty: ${e['quantity'] ?? 0}"),
                      );
                    }).toList(),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(orderDoc.id)
                                  .update({'status': value});
                              debugPrint(
                                  "Updated order ${orderDoc.id} to $value");
                            } catch (e) {
                              debugPrint("Error updating status: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: "pending", child: Text("Pending")),
                            PopupMenuItem(value: "preparing", child: Text("Preparing")),
                            PopupMenuItem(value: "on the way", child: Text("On the way")),
                            PopupMenuItem(value: "delivered", child: Text("Delivered")),
                            PopupMenuItem(value: "cancelled", child: Text("Cancelled")),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Build status chip with color
  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case OrderStatus.preparing:
        color = Colors.blue;
        label = 'Preparing';
        break;
      case OrderStatus.onTheWay:
        color = Colors.indigo;
        label = 'On the way';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        label = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}


