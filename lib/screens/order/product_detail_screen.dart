import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/cart_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final dynamic data;

  const ProductDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(data['name']),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: data.id,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Image.network(
                data['imageUrl'],
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              data['name'],
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              "₹${data['price']}",
              style: const TextStyle(
                fontSize: 22,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              data["description"] ?? "No description available.",
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),

          const Spacer(),
        ],
      ),

      // Add to Cart Bottom Bar
        bottomNavigationBar: GestureDetector(
          onTap: () {
            final product = Product(
              id: data.id,
              name: data['name'],
              price: (data['price'] as num).toDouble(),
              imageUrl: data['imageUrl'],
              description: data['description'] ?? '',
            );

            Provider.of<CartService>(context, listen: false)
                .addItemToCart(product);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${product.name} added to cart")),
            );
          },
          child: Container(
            height: 65,
            color: Colors.redAccent,
            child: const Center(
              child: Text(
                "Add to Cart",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        )


      // bottomNavigationBar: Container(
      //   height: 65,
      //   decoration: const BoxDecoration(
      //     color: Colors.redAccent,
      //   ),
      //   child: const Center(
      //     child: Text(
      //       "Add to Cart",
      //       style: TextStyle(
      //         color: Colors.white,
      //         fontSize: 20,
      //         fontWeight: FontWeight.bold,
      //       ),
      //     ),
      //   ),
      // ),
    );
  }
}
