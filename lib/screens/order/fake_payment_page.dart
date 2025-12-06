import 'package:flutter/material.dart';

class FakePaymentPage extends StatefulWidget {
  final double totalAmount;
  final Function(String paymentMethod) onPaymentSuccess;

  const FakePaymentPage({
    super.key,
    required this.totalAmount,
    required this.onPaymentSuccess,
  });

  @override
  State<FakePaymentPage> createState() => _FakePaymentPageState();
}

class _FakePaymentPageState extends State<FakePaymentPage> {
  String selectedPayment = "COD";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Payment Method")),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Payment Option",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text("Cash on Delivery (COD)"),
              leading: Radio(
                value: "COD",
                groupValue: selectedPayment,
                onChanged: (value) => setState(() => selectedPayment = value!),
              ),
            ),
            ListTile(
              title: const Text("UPI (Demo Payment)"),
              subtitle: const Text("Google Pay, PhonePe, Paytm"),
              leading: Radio(
                value: "UPI",
                groupValue: selectedPayment,
                onChanged: (value) => setState(() => selectedPayment = value!),
              ),
            ),
            ListTile(
              title: const Text("Card Payment (Demo)"),
              subtitle: const Text("Visa, MasterCard, RuPay"),
              leading: Radio(
                value: "CARD",
                groupValue: selectedPayment,
                onChanged: (value) => setState(() => selectedPayment = value!),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  widget.onPaymentSuccess(selectedPayment);
                },
                child: const Text(
                  "Pay Now",
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

