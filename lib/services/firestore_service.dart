// lib/services/firestore_service.dart
import 'package:topd_apps/models/menu_item.dart';
import 'package:topd_apps/models/app_order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // -------------------------
  // MENU ITEMS (Existing)
  // -------------------------
  Stream<List<MenuItem>> getMenuItems() {
    debugPrint('FirestoreService: Fetching menu items...');

    return _db.collection('menuItems').snapshots().map((snapshot) {
      debugPrint('Snapshot received: ${snapshot.docs.length} items');

      try {
        return snapshot.docs
            .where((doc) => doc.data().isNotEmpty)
            .map((doc) =>
            MenuItem.fromFirestore(doc.data(), doc.id))
            .toList();
      } catch (e, st) {
        debugPrint('ERROR parsing menu items: $e');
        debugPrint('Stacktrace: $st');
        return <MenuItem>[];
      }
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

  // ================================================================
  // 🔥 NEW FEATURE 1 — DYNAMIC CATEGORIES LIST
  // ================================================================
  Stream<List<String>> getCategories() {
    return _db.collection("menuItems").snapshots().map((snapshot) {
      final categories = snapshot.docs
          .map((doc) => doc["category"]?.toString() ?? "Other")
          .toSet()
          .toList();

      categories.sort();
      return categories;
    });
  }

  // ================================================================
  // 🔥 NEW FEATURE 2 — CATEGORY → IMAGE (1 image per category)
  // ================================================================
  Stream<Map<String, String>> getCategoryImages() {
    return _db.collection("menuItems").snapshots().map((snapshot) {
      final Map<String, String> categoryImages = {};

      for (var doc in snapshot.docs) {
        final cat = doc["category"] ?? "Other";
        final img = doc["imageUrl"] ?? "";

        // Store only 1 image per category (first item)
        categoryImages.putIfAbsent(cat, () => img);
      }

      return categoryImages;
    });
  }

  // ================================================================
  // 🔥 NEW FEATURE 3 — GET MENU ITEMS BY CATEGORY
  // ================================================================
  Stream<List<MenuItem>> getMenuItemsByCategory(String category) {
    if (category == "All") {
      return getMenuItems();
    }

    return _db
        .collection("menuItems")
        .where("category", isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // -------------------------
  // ORDER OPERATIONS (Existing)
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
      try {
        return snapshot.docs
            .map((doc) => AppOrder.fromFirestore(doc.data(), doc.id))
            .toList();
      } catch (e) {
        debugPrint('ERROR parsing orders: $e');
        return <AppOrder>[];
      }
    });
  }
}
