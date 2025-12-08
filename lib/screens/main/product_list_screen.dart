import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:topd_apps/models/product.dart'; // Ensure this model exists
import 'package:topd_apps/services/cart_service.dart';

// IMPORTANT: If your CartService expects 'Product', use 'Product'.
// If it expects 'MenuItem', use 'MenuItem'. I will assume 'Product' here based on your cast.

class ProductListScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const ProductListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body:  StreamBuilder<QuerySnapshot>(
        // 1. Load ALL items (Remove the .where filter temporarily)
        stream: FirebaseFirestore.instance.collection('menuItems').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Database is empty"));
          }

          // 2. Filter manually in the app (Ignores case and extra spaces)
          final allItems = snapshot.data!.docs;
          final filteredItems = allItems.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final itemCategory = (data['category'] ?? '').toString();

            // Compare ignoring lowercase/uppercase and spaces
            return itemCategory.trim().toLowerCase() == categoryId.trim().toLowerCase();
          }).toList();

          if (filteredItems.isEmpty) {
            return Center(
              child: Text("No items found for: $categoryName"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final data = filteredItems[index].data() as Map<String, dynamic>;
              return MenuItemCard(
                itemId: filteredItems[index].id,
                data: data,
              );
            },
          );
        },
      ),

    );
  }
}

class MenuItemCard extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> data;

  const MenuItemCard({super.key, required this.itemId, required this.data});

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  int _selectedVariantIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 1. Extract Data
    final name = widget.data['name'] ?? 'Unknown';
    final image = widget.data['image'] ?? '';
    final isVeg = widget.data['isVeg'] ?? false;
    final description = widget.data['description'] ?? ''; // Added this
    final category = widget.data['category'] ?? ''; // Added this

    // 2. Handle Variants Logic
    List<dynamic> variantsList = [];
    if (widget.data['variants'] is List) {
      variantsList = widget.data['variants'];
    } else if (widget.data['variants'] is Map) {
      variantsList.add(widget.data['variants']);
    } else if (widget.data['price'] != null) {
      variantsList.add({'price': widget.data['price'], 'unit': 'Full'});
    }

    if (variantsList.isEmpty) return const SizedBox();

    final currentVariant = variantsList[_selectedVariantIndex];
    final double currentPrice = (currentVariant['price'] ?? 0).toDouble();
    final currentUnit = currentVariant['unit'] ?? 'Full';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: image.isNotEmpty
                  ? Image.network(
                image, width: 90, height: 90, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                    width: 90, height: 90, color: Colors.grey[200], child: const Icon(Icons.fastfood)),
              )
                  : Container(
                  width: 90, height: 90, color: Colors.grey[200], child: const Icon(Icons.fastfood)),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, color: isVeg ? Colors.green : Colors.red, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Variant Dropdown
                  if (variantsList.length > 1)
                    DropdownButton<int>(
                      value: _selectedVariantIndex,
                      isDense: true,
                      items: List.generate(variantsList.length, (index) {
                        final v = variantsList[index];
                        return DropdownMenuItem(value: index, child: Text("${v['unit']}"));
                      }),
                      onChanged: (val) => setState(() => _selectedVariantIndex = val!),
                    )
                  else
                    Text("$currentUnit", style: TextStyle(color: Colors.grey[600], fontSize: 13)),

                  const SizedBox(height: 8),

                  // Price and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₹$currentPrice", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),

                      ElevatedButton(
                        onPressed: () {
                          // FIX: Create a Product directly instead of casting MenuItem
                          // This prevents the "type 'MenuItem' is not a subtype of 'Product'" error
                          final itemToAdd = Product(
                            id: widget.itemId,
                            name: name,
                            imageUrl: image,
                            price: currentPrice,
                            description: description,
                            category: category,
                          );

                          Provider.of<CartService>(context, listen: false)
                              .addItemToCart(itemToAdd);

                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Added $name"),
                                duration: const Duration(seconds: 1),
                                backgroundColor: Colors.green,
                              )
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            minimumSize: const Size(0, 32)
                        ),
                        child: const Text("ADD"),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}