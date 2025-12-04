// lib/services/firestore_service.dart
import 'package:topd_apps/models/menu_item.dart';
import 'package:topd_apps/models/app_order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:uuid/uuid.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // -------------------------
  // Menu Operations
  // -------------------------


  Stream<List<MenuItem>> getMenuItems() {
    debugPrint('FirestoreService: Fetching menu items...');

    return _db.collection('menuItems').snapshots().map((snapshot) {
      debugPrint('Snapshot received: ${snapshot.docs.length} items');

      try {
        final menuItems = snapshot.docs
            .where((doc) => doc.data().isNotEmpty) // skip empty docs
            .map((doc) {
          debugPrint('Processing MenuItem doc: ${doc.id}');
          return MenuItem.fromFirestore(doc.data(), doc.id);
        })
            .toList();

        return menuItems;
      } catch (e, st) {
        debugPrint('ERROR parsing menu items: $e');
        debugPrint('Stacktrace: $st');
        return <MenuItem>[];
      }
    }).handleError((error, stacktrace) {
      debugPrint('Stream ERROR in getMenuItems: $error');
      throw error;
    });
  }

  Future<void> addMenuItem(MenuItem item) async {
    try {
      await _db.collection('menuItems').add(item.toFirestore());
      debugPrint('FirestoreService: MenuItem added successfully.');
    } catch (e, st) {
      debugPrint('ERROR adding menu item: $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  // -------------------------
  // Order Operations
  // -------------------------


  Future<void> placeOrder(AppOrder order) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('ERROR - User not logged in to place order.');
      throw Exception('User not logged in to place order.');
    }

    final orderId = _uuid.v4();
    debugPrint('Placing order ID: $orderId for user: ${user.uid}');

    try {
      await _db.collection('orders').doc(orderId).set(
        order.toFirestore()..['id'] = orderId,
      );
      debugPrint('Order $orderId placed successfully.');
    } catch (e, st) {
      debugPrint('ERROR placing order $orderId: $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  Stream<List<AppOrder>> getUserOrders(String userId) {
    debugPrint('Fetching orders for user ID: $userId');

    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      debugPrint('Snapshot received: ${snapshot.docs.length} orders');

      try {
        final orders = snapshot.docs
            .where((doc) => doc.data().isNotEmpty)
            .map((doc) {
          debugPrint('Processing order ID: ${doc.id}');
          return AppOrder.fromFirestore(doc.data(), doc.id);
        })
            .toList();

        return orders;
      } catch (e, st) {
        debugPrint('ERROR parsing user orders: $e');
        debugPrint('Stacktrace: $st');
        return <AppOrder>[];
      }
    }).handleError((error, stacktrace) {
      debugPrint('Stream ERROR in getUserOrders: $error');
      throw error;
    });
  }
}
