// lib/screens/order/order_success_screen.dart
import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_history_screen.dart'; // import your order history screen

Future<bool> saveOrderToFirestore(String orderId, Map<String, dynamic> orderData) async {
  try {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .set(orderData);
    debugPrint("Order $orderId saved successfully.");
    return true;
  } catch (e) {
    debugPrint("Error saving order $orderId: $e");
    return false;
  }
}

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  OrderSuccessScreen({super.key, required this.orderId, required Map<String, Object> orderData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed!'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Optional Lottie animation
                // Lottie.asset(
                //   'assets/animations/success.json',
                //   width: 200,
                //   height: 200,
                //   repeat: false,
                // ),

                const SizedBox(height: 10),

                // Success Icon fallback
                Icon(
                  Icons.check_circle_outline,
                  size: 150,
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(height: 32),

                Text(
                  'Your order has been placed successfully!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'Order ID: $orderId',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.grey[700]),
                ),

                const SizedBox(height: 32),

                Text(
                  "We're preparing your delicious meal. You can track its status in the 'My Orders' section.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                const SizedBox(height: 48),

                // Back to Home Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Back to Home'),
                ),

                const SizedBox(height: 16),

                // View My Orders Button
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('View My Orders'),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
