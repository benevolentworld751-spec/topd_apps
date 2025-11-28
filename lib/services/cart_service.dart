// lib/services/cart_service.dart
import 'package:topd_apps/models/cart_item.dart';
import 'package:topd_apps/models/menu_item.dart';
import 'package:flutter/material.dart';

class CartService with ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * 0.08; // Example tax rate
  double get deliveryFee => 5.00; // Example delivery fee
  double get total => subtotal + tax + deliveryFee;

  int get totalItemsInCart => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void addItemToCart(MenuItem item) {
    int existingIndex = _cartItems.indexWhere((cartItem) => cartItem.item.id == item.id);
    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity++;
    } else {
      _cartItems.add(CartItem(item: item));
    }
    notifyListeners();
  }

  void removeItemFromCart(MenuItem item) {
    int existingIndex = _cartItems.indexWhere((cartItem) => cartItem.item.id == item.id);
    if (existingIndex != -1) {
      if (_cartItems[existingIndex].quantity > 1) {
        _cartItems[existingIndex].quantity--;
      } else {
        _cartItems.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void removeAllOfItemFromCart(MenuItem item) {
    _cartItems.removeWhere((cartItem) => cartItem.item.id == item.id);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}