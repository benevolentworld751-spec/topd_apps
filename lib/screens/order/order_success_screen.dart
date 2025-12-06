// lib/screens/order/order_success_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_history_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  Future<bool> saveOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderData);

      debugPrint("Order $orderId saved successfully.");
      return true;
    } catch (e) {
      debugPrint("Error saving order: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: saveOrder(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Order Confirmed!'),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Icon(
                    Icons.check_circle_outline,
                    size: 150,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Your order has been placed successfully!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),
                  Text("Order ID: $orderId"),

                  const SizedBox(height: 32),
                  Text(
                    "We're preparing your delicious meal. "
                        "You can track it in 'My Orders'.",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text("Back to Home"),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text("View My Orders"),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
