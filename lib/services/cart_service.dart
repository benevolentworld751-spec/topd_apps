import 'package:flutter/material.dart';
import 'package:topd_apps/models/cart_item.dart';
import 'package:topd_apps/models/product.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  // Add item
  void addItemToCart(Product product) {
    final index = _cartItems.indexWhere((item) => item.item.id == product.id);

    if (index >= 0) {
      _cartItems[index].quantity++;
    } else {
      _cartItems.add(CartItem(item: product));
    }

    notifyListeners();
  }

  // Remove one quantity
  void removeItemFromCart(Product product) {
    final index = _cartItems.indexWhere((item) => item.item.id == product.id);

    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Remove entire product
  void removeAllOfItemFromCart(Product product) {
    _cartItems.removeWhere((item) => item.item.id == product.id);
    notifyListeners();
  }

  // Clear all
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // ⭐ ADD THIS ⭐
  int get totalItemsInCart {
    int total = 0;
    for (var item in _cartItems) {
      total += item.quantity;
    }
    return total;
  }
  // Calculations
  double get subtotal =>
      _cartItems.fold(0, (sum, item) => sum + (item.item.price * item.quantity));

  double get tax => subtotal * 0.08;

  double get deliveryFee => subtotal == 0 ? 0 : 2.50;

  double get total => subtotal + tax + deliveryFee;
}
