import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:topd_apps/models/cart_item.dart';
import 'package:topd_apps/services/cart_service.dart';
import 'package:topd_apps/screens/order/order_success_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/review_dialog.dart';
import 'fake_payment_page.dart';

class OrderSummaryScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const OrderSummaryScreen({super.key, required this.cartItems});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _confirmOrder(String orderId, String paymentMethod) async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter delivery address")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartService = Provider.of<CartService>(context, listen: false);

    setState(() => _isProcessing = true);

    final orderData = {
      'id': orderId,
      'userId': user.uid,
      'items': cartService.cartItems.map((c) => {
        'item': {
          'name': c.item.name,
          'price': c.item.price,
          'image': c.item.imageUrl,
          'category': c.item.category,
        },
        'quantity': c.quantity,
      }).toList(),
      'totalAmount': cartService.total,
      'subtotal': cartService.subtotal,
      'tax': cartService.tax,
      'deliveryFee': cartService.deliveryFee,
      'status': 'pending',
      'deliveryAddress': _addressController.text,
      'paymentMethod': paymentMethod,
      'orderDate': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderData);
      cartService.clearCart();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId, orderData: orderData),
        ),
      );

      // Show review popup
      Future.delayed(const Duration(milliseconds: 500), () {
        showDialog(
          context: context,
          builder: (_) => ReviewDialog(
            onSubmit: (double rating, String feedback) {
              FirebaseFirestore.instance.collection('reviews').add({
                'userId': user.uid,
                'orderId': orderId,
                'rating': rating,
                'feedback': feedback,
                'paymentMethod': paymentMethod,
                'amountPaid': cartService.total,
                'createdAt': FieldValue.serverTimestamp(),
              });
            },
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Order Summary")),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Delivery Address",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter your full delivery address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text("Items",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...cartService.cartItems.map((c) => _buildItemRow(c)),
            const Divider(height: 32),
            _buildSummaryRow("Subtotal", cartService.subtotal),
            _buildSummaryRow("Tax (8%)", cartService.tax),
            _buildSummaryRow("Delivery Fee", cartService.deliveryFee),
            const Divider(height: 32),
            _buildSummaryRow("Total", cartService.total, isBold: true, fontSize: 20),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final orderId = FirebaseFirestore.instance.collection('orders').doc().id;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FakePaymentPage(
                      totalAmount: cartService.total,
                      onPaymentSuccess: (selectedPayment) => _confirmOrder(orderId, selectedPayment),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("Confirm Order & Pay", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(CartItem cartItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Image.network(cartItem.item.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
          const SizedBox(width: 12),
          Expanded(child: Text("${cartItem.quantity}x ${cartItem.item.name}", style: const TextStyle(fontSize: 16))),
          Text("\$${(cartItem.quantity * cartItem.item.price).toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("\$${amount.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isBold ? Colors.blue : Colors.black)),
        ],
      ),
    );
  }
}

