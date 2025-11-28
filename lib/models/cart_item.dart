import 'menu_item.dart';

class CartItem {
  final MenuItem item;
  int quantity; // <-- NOT final so we can change it

  CartItem({
    required this.item,
    this.quantity = 1,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      item: MenuItem.fromMap(map['item']),
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap(),
      'quantity': quantity,
    };
  }

  double get totalPrice => item.price * quantity;
}
