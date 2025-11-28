// lib/models/app_order.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item.dart';
import 'cart_item.dart'; // <-- USE THE REAL CARTITEM HERE ONLY

enum OrderStatus { pending, preparing, delivered, cancelled }

class AppOrder {
  final String id;
  final List<CartItem> items; // using cart_item.dart CartItem
  final double totalAmount;
  final DateTime orderDate;
  final String deliveryAddress;
  final OrderStatus status;
  final String userId;

  AppOrder({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.deliveryAddress,
    required this.status,
    required this.userId,
  });

  factory AppOrder.fromFirestore(Map<String, dynamic> data, String docId) {
    return AppOrder(
      id: data['id'] ?? docId,
      userId: data['userId'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      deliveryAddress: data['deliveryAddress'] ?? 'N/A',
      status: _statusFromString(data['status']),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'totalAmount': totalAmount,
      'orderDate': orderDate,
      'deliveryAddress': deliveryAddress,
      'status': status.name,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  static OrderStatus _statusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

